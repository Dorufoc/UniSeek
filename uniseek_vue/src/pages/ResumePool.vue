<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getEnterpriseTasks, type TaskVO } from '@/api/task'
import {
  getTaskApplications,
  updateApplicationStatus,
  completeApplication,
  type TaskApplication,
  type ResumeSnapshot
} from '@/api/application'

const router = useRouter()

const tasks = ref<TaskVO[]>([])
const selectedTaskId = ref<number | null>(null)
const applications = ref<TaskApplication[]>([])
const loadingTasks = ref(false)
const loadingApps = ref(false)

// 状态标签与颜色
const statusLabels: Record<number, string> = {
  0: '已投递',
  1: '待面试',
  2: '待定',
  3: '已录用',
  4: '已淘汰',
  5: '已完成'
}
const statusTypes: Record<number, 'info' | 'warning' | 'success' | 'danger'> = {
  0: 'info',
  1: 'warning',
  2: 'info',
  3: 'success',
  4: 'danger',
  5: 'success'
}

// 格式化时间
const formatDateTime = (str: string | null) => {
  if (!str) return '-'
  return str.replace('T', ' ').substring(0, 16)
}

// 解析简历快照
const parseSnapshot = (json: string | null): ResumeSnapshot | null => {
  if (!json) return null
  try {
    return JSON.parse(json) as ResumeSnapshot
  } catch {
    return null
  }
}

const genderText = (gender?: number) => {
  return gender === 0 ? '男' : gender === 1 ? '女' : '-'
}

// 加载本企业职位
const loadTasks = async () => {
  loadingTasks.value = true
  try {
    const res = await getEnterpriseTasks()
    tasks.value = res.data?.records || []
    if (tasks.value.length > 0) {
      selectedTaskId.value = tasks.value[0].id
    }
  } catch (err: any) {
    if (err?.message?.includes('未找到企业信息')) {
      ElMessage.warning('请先完成企业资质认证')
      router.push('/enterprise-cert')
    }
  } finally {
    loadingTasks.value = false
  }
}

// 加载某个职位的投递记录
const loadApplications = async () => {
  if (!selectedTaskId.value) return
  loadingApps.value = true
  try {
    const res = await getTaskApplications(selectedTaskId.value)
    applications.value = res.data?.records || []
  } finally {
    loadingApps.value = false
  }
}

watch(selectedTaskId, loadApplications)
onMounted(loadTasks)

// 弹窗相关
const interviewDialogVisible = ref(false)
const rejectDialogVisible = ref(false)
const completeDialogVisible = ref(false)
const currentApplication = ref<TaskApplication | null>(null)
const interviewForm = ref({ interviewTime: '', interviewLocation: '' })
const rejectForm = ref({ rejectReason: '', hrNote: '' })
const completeForm = ref({ hrNote: '' })

// 打开面试邀请弹窗
const openInterviewDialog = (app: TaskApplication) => {
  currentApplication.value = app
  interviewForm.value = {
    interviewTime: app.interviewTime || '',
    interviewLocation: app.interviewLocation || ''
  }
  interviewDialogVisible.value = true
}

// 打开淘汰弹窗
const openRejectDialog = (app: TaskApplication) => {
  currentApplication.value = app
  rejectForm.value = { rejectReason: app.rejectReason || '', hrNote: app.hrNote || '' }
  rejectDialogVisible.value = true
}

// 打开结算弹窗
const openCompleteDialog = (app: TaskApplication) => {
  currentApplication.value = app
  completeForm.value = { hrNote: app.hrNote || '' }
  completeDialogVisible.value = true
}

// 提交面试邀请
const submitInterview = async () => {
  if (!currentApplication.value) return
  if (!interviewForm.value.interviewTime || !interviewForm.value.interviewLocation.trim()) {
    ElMessage.warning('请填写面试时间和地点')
    return
  }
  try {
    await updateApplicationStatus(currentApplication.value.id, {
      status: 1,
      interviewTime: interviewForm.value.interviewTime,
      interviewLocation: interviewForm.value.interviewLocation.trim()
    })
    ElMessage.success('面试邀请已发送')
    interviewDialogVisible.value = false
    await loadApplications()
  } catch {}
}

// 提交淘汰
const submitReject = async () => {
  if (!currentApplication.value) return
  if (!rejectForm.value.rejectReason.trim()) {
    ElMessage.warning('请填写淘汰原因')
    return
  }
  try {
    await updateApplicationStatus(currentApplication.value.id, {
      status: 4,
      rejectReason: rejectForm.value.rejectReason.trim(),
      hrNote: rejectForm.value.hrNote.trim() || undefined
    })
    ElMessage.success('已发送淘汰通知')
    rejectDialogVisible.value = false
    await loadApplications()
  } catch {}
}

// 提交录用/待定（无需额外信息）
const handleSimpleStatus = async (app: TaskApplication, targetStatus: number, actionName: string) => {
  try {
    await ElMessageBox.confirm(`确定要「${actionName}」该候选人吗？`, '提示', { type: 'warning' })
  } catch {
    return
  }
  try {
    await updateApplicationStatus(app.id, { status: targetStatus })
    ElMessage.success('操作成功')
    await loadApplications()
  } catch {}
}

// 提交结算完成
const submitComplete = async () => {
  if (!currentApplication.value) return
  try {
    await completeApplication(currentApplication.value.id, {
      hrNote: completeForm.value.hrNote.trim() || undefined
    })
    ElMessage.success('结算完成')
    completeDialogVisible.value = false
    await loadApplications()
  } catch {}
}

// 根据当前状态返回可执行操作
const availableActions = (app: TaskApplication) => {
  const actions: { label: string; type: 'primary' | 'success' | 'warning' | 'danger'; handler: () => void }[] = []
  switch (app.status) {
    case 0:
      actions.push({ label: '邀请面试', type: 'primary', handler: () => openInterviewDialog(app) })
      actions.push({ label: '待定', type: 'warning', handler: () => handleSimpleStatus(app, 2, '标记为待定') })
      actions.push({ label: '淘汰', type: 'danger', handler: () => openRejectDialog(app) })
      break
    case 1:
      actions.push({ label: '录用', type: 'success', handler: () => handleSimpleStatus(app, 3, '录用') })
      actions.push({ label: '待定', type: 'warning', handler: () => handleSimpleStatus(app, 2, '标记为待定') })
      actions.push({ label: '淘汰', type: 'danger', handler: () => openRejectDialog(app) })
      break
    case 2:
      actions.push({ label: '安排面试', type: 'primary', handler: () => openInterviewDialog(app) })
      actions.push({ label: '录用', type: 'success', handler: () => handleSimpleStatus(app, 3, '录用') })
      actions.push({ label: '淘汰', type: 'danger', handler: () => openRejectDialog(app) })
      break
    case 3:
      actions.push({ label: '完成结算', type: 'success', handler: () => openCompleteDialog(app) })
      break
  }
  return actions
}
</script>

<template>
  <div class="resume-pool-page">
    <div class="pool-header">
      <h2 class="pool-title">简历池</h2>
      <el-select
        v-model="selectedTaskId"
        placeholder="请选择职位"
        style="width: 320px"
        :loading="loadingTasks"
      >
        <el-option
          v-for="task in tasks"
          :key="task.id"
          :label="`${task.title}（${task.applicationCount || 0} 人投递）`"
          :value="task.id"
        />
      </el-select>
    </div>

    <div v-if="!selectedTaskId && !loadingTasks" class="empty-block">
      <el-empty description="暂无职位，请先发布职位" />
    </div>

    <div v-else-if="loadingApps" class="loading-tip">加载投递记录中...</div>

    <div v-else-if="applications.length === 0" class="empty-block">
      <el-empty description="该职位暂无投递记录" />
    </div>

    <div v-else class="application-list">
      <el-card v-for="app in applications" :key="app.id" class="application-card" shadow="hover">
        <div class="application-main">
          <div class="application-avatar">
            {{ parseSnapshot(app.resumeSnapshot)?.realName?.charAt(0) || '?' }}
          </div>
          <div class="application-info">
            <div class="info-line">
              <span class="candidate-name">
                {{ parseSnapshot(app.resumeSnapshot)?.realName || '未知姓名' }}
              </span>
              <el-tag :type="statusTypes[app.status]" size="small">
                {{ statusLabels[app.status] }}
              </el-tag>
            </div>
            <div class="info-line meta">
              <span>性别：{{ genderText(parseSnapshot(app.resumeSnapshot)?.gender) }}</span>
              <span>学历：{{ parseSnapshot(app.resumeSnapshot)?.education || '-' }}</span>
              <span>院校：{{ parseSnapshot(app.resumeSnapshot)?.school || '-' }}</span>
            </div>
            <div class="info-line meta">
              <span>技能：{{ parseSnapshot(app.resumeSnapshot)?.skills || '-' }}</span>
            </div>
            <div class="info-line meta">
              <span>经历：{{ parseSnapshot(app.resumeSnapshot)?.experience || '-' }}</span>
            </div>
            <div v-if="app.status === 1 && app.interviewTime" class="info-line meta">
              <span>面试安排：{{ formatDateTime(app.interviewTime) }} @ {{ app.interviewLocation || '-' }}</span>
            </div>
            <div v-if="app.status === 4 && app.rejectReason" class="info-line meta reject-reason">
              淘汰原因：{{ app.rejectReason }}
            </div>
            <div class="info-line meta">
              投递时间：{{ formatDateTime(app.createTime) }}
            </div>
          </div>
        </div>
        <div class="application-actions">
          <el-button
            v-for="action in availableActions(app)"
            :key="action.label"
            :type="action.type"
            size="small"
            @click="action.handler"
          >
            {{ action.label }}
          </el-button>
        </div>
      </el-card>
    </div>

    <!-- 面试邀请弹窗 -->
    <el-dialog v-model="interviewDialogVisible" title="发送面试邀请" width="460px" destroy-on-close>
      <el-form label-width="80px">
        <el-form-item label="面试时间">
          <el-date-picker
            v-model="interviewForm.interviewTime"
            type="datetime"
            placeholder="选择面试时间"
            value-format="YYYY-MM-DDTHH:mm:ss"
            style="width: 100%"
          />
        </el-form-item>
        <el-form-item label="面试地点">
          <el-input v-model="interviewForm.interviewLocation" placeholder="请输入面试地点" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="interviewDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitInterview">确认发送</el-button>
      </template>
    </el-dialog>

    <!-- 淘汰弹窗 -->
    <el-dialog v-model="rejectDialogVisible" title="淘汰候选人" width="460px" destroy-on-close>
      <el-form label-width="80px">
        <el-form-item label="淘汰原因">
          <el-input
            v-model="rejectForm.rejectReason"
            type="textarea"
            :rows="3"
            placeholder="请填写淘汰原因（必填，将发送给求职者）"
          />
        </el-form-item>
        <el-form-item label="HR 备注">
          <el-input
            v-model="rejectForm.hrNote"
            type="textarea"
            :rows="2"
            placeholder="内部备注（可选）"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="rejectDialogVisible = false">取消</el-button>
        <el-button type="danger" @click="submitReject">确认淘汰</el-button>
      </template>
    </el-dialog>

    <!-- 结算弹窗 -->
    <el-dialog v-model="completeDialogVisible" title="完成结算" width="460px" destroy-on-close>
      <el-form label-width="80px">
        <el-form-item label="HR 备注">
          <el-input
            v-model="completeForm.hrNote"
            type="textarea"
            :rows="3"
            placeholder="可选备注"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="completeDialogVisible = false">取消</el-button>
        <el-button type="success" @click="submitComplete">确认完成</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.resume-pool-page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 24px;
}

.pool-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: #fff;
  padding: 16px 24px;
  border-radius: 8px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  margin-bottom: 24px;
}

.pool-title {
  font-size: 18px;
  font-weight: 600;
  color: #000;
  margin: 0;
}

.loading-tip,
.empty-block {
  text-align: center;
  padding: 48px;
  background: #fff;
  border-radius: 8px;
  color: #999;
}

.application-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.application-card {
  color: #000;
}

.application-main {
  display: flex;
  gap: 16px;
}

.application-avatar {
  width: 56px;
  height: 56px;
  line-height: 56px;
  text-align: center;
  border-radius: 50%;
  background: #409eff;
  color: #fff;
  font-size: 20px;
  flex-shrink: 0;
}

.application-info {
  flex: 1;
}

.info-line {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 8px;
}

.candidate-name {
  font-size: 16px;
  font-weight: 600;
  color: #000;
}

.meta {
  font-size: 13px;
  color: #666;
  line-height: 1.5;
}

.reject-reason {
  color: #f56c6c;
}

.application-actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  margin-top: 16px;
  padding-top: 12px;
  border-top: 1px solid #eee;
}
</style>
