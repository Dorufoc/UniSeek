<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
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
const route = useRoute()

const tasks = ref<TaskVO[]>([])
const selectedTaskId = ref<number | null>(null)
const applications = ref<TaskApplication[]>([])
const loadingTasks = ref(false)
const loadingApps = ref(false)

// Tab 切换：从 URL query 读取，默认 pool
const activeTab = computed<'pool' | 'interview'>(() =>
  (route.query.tab as string) === 'interview' ? 'interview' : 'pool'
)

// 简历池：排除已淘汰和已完成，保留可操作的记录
const poolApplications = computed(() =>
  applications.value.filter(a => ![1, 4, 5].includes(a.status))
)

// 面试安排：仅显示已安排面试的记录
const interviewApplications = computed(() =>
  applications.value.filter(a => a.status === 1)
)

// 简历详情弹窗
const resumeDetailDialogVisible = ref(false)
const currentResume = ref<ResumeSnapshot | null>(null)

const openResumeDialog = (snapshotJson: string | null) => {
  const snapshot = parseSnapshot(snapshotJson)
  if (snapshot) {
    currentResume.value = snapshot
    resumeDetailDialogVisible.value = true
  } else {
    ElMessage.warning('简历数据无效')
  }
}

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
    tasks.value = res?.records || []
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
    applications.value = res?.records || []
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
  } catch (e: any) {
    ElMessage.error(e?.message || '操作失败')
  }
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
  } catch (e: any) {
    ElMessage.error(e?.message || '操作失败')
  }
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
  } catch (e: any) {
    ElMessage.error(e?.message || '操作失败')
  }
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
  } catch (e: any) {
    ElMessage.error(e?.message || '操作失败')
  }
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
  }
  return actions
}
</script>

<template>
  <div class="resume-pool-page">
    <div class="pool-header">
      <h2 class="pool-title">{{ activeTab === 'interview' ? '面试安排' : '简历池' }}</h2>
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

    <template v-else>
      <!-- 加载中 -->
      <div v-if="loadingApps" class="loading-tip">加载投递记录中...</div>

      <!-- 简历池 Tab -->
      <template v-if="!loadingApps && activeTab === 'pool'">
        <div v-if="poolApplications.length" class="application-list">
          <el-card v-for="app in poolApplications" :key="app.id" class="application-card" shadow="hover">
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
                <div v-if="app.status === 4 && app.rejectReason" class="info-line meta reject-reason">
                  淘汰原因：{{ app.rejectReason }}
                </div>
                <div class="info-line meta">
                  投递时间：{{ formatDateTime(app.createTime) }}
                </div>
              </div>
            </div>
            <div class="application-actions">
              <el-button size="small" @click="openResumeDialog(app.resumeSnapshot)">查看简历</el-button>
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
        <div v-else class="empty-block">
          <el-empty description="简历池暂无候选人，等待求职者投递" />
        </div>
      </template>

      <!-- 面试安排 Tab -->
      <template v-if="!loadingApps && activeTab === 'interview'">
        <div v-if="interviewApplications.length" class="interview-list">
          <div v-for="app in interviewApplications" :key="app.id" class="interview-card">
            <div class="interview-header">
              <div class="interview-avatar">{{ parseSnapshot(app.resumeSnapshot)?.realName?.charAt(0) || '?' }}</div>
              <div class="interview-person">
                <span class="interview-name">{{ parseSnapshot(app.resumeSnapshot)?.realName || '未知姓名' }}</span>
                <el-tag :type="statusTypes[app.status]" size="small">{{ statusLabels[app.status] }}</el-tag>
              </div>
              <div class="interview-actions">
                <el-button size="small" @click="openResumeDialog(app.resumeSnapshot)">查看简历</el-button>
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
            </div>
            <div class="interview-detail">
              <div class="interview-detail-item">
                <span class="interview-detail-label">面试时间</span>
                <span class="interview-detail-value">{{ formatDateTime(app.interviewTime) || '待定' }}</span>
              </div>
              <div class="interview-detail-item">
                <span class="interview-detail-label">面试地点</span>
                <span class="interview-detail-value">{{ app.interviewLocation || '待定' }}</span>
              </div>
              <div class="interview-detail-item">
                <span class="interview-detail-label">投递时间</span>
                <span class="interview-detail-value">{{ formatDateTime(app.createTime) }}</span>
              </div>
            </div>
          </div>
        </div>
        <div v-else class="empty-block">
          <el-empty description="暂无面试安排" />
        </div>
      </template>
    </template>

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

    <!-- 简历详情弹窗（人才库卡片风格） -->
    <el-dialog v-model="resumeDetailDialogVisible" title="简历详情" width="560px" destroy-on-close>
      <template v-if="currentResume">
        <div class="talent-detail">
          <div class="talent-detail-header">
            <div class="talent-detail-avatar">{{ (currentResume.realName || '?').charAt(0) }}</div>
            <div class="talent-detail-info">
              <div class="talent-detail-name">{{ currentResume.realName || '未知' }}</div>
              <div class="talent-detail-meta">
                <span v-if="currentResume.gender !== undefined">{{ currentResume.gender === 0 ? '男' : '女' }}</span>
                <span v-if="currentResume.birthDate">{{ currentResume.birthDate }}</span>
                <span>{{ currentResume.education || '-' }}</span>
                <span>{{ currentResume.school || '-' }}</span>
              </div>
            </div>
          </div>
          <div v-if="currentResume.skills" class="talent-detail-section">
            <h4 class="talent-section-title">技能标签</h4>
            <div class="talent-tags">
              <el-tag
                v-for="tag in currentResume.skills.split(/[,，、\s]+/).filter(Boolean)"
                :key="tag"
                size="small"
                class="talent-tag"
              >
                {{ tag }}
              </el-tag>
            </div>
          </div>
          <div v-if="currentResume.experience" class="talent-detail-section">
            <h4 class="talent-section-title">工作经历</h4>
            <p class="talent-section-content">{{ currentResume.experience }}</p>
          </div>
          <div v-if="currentResume.attachmentUrl" class="talent-detail-section">
            <h4 class="talent-section-title">附件简历</h4>
            <el-link type="primary" :href="currentResume.attachmentUrl" target="_blank" :underline="false">
              点击下载附件简历
            </el-link>
          </div>
        </div>
      </template>
      <template #footer>
        <el-button @click="resumeDetailDialogVisible = false">关闭</el-button>
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

/* 面试安排卡片 */
.interview-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.interview-card {
  background: #fff;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
}

.interview-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
}

.interview-avatar {
  width: 44px;
  height: 44px;
  line-height: 44px;
  text-align: center;
  border-radius: 50%;
  background: #409eff;
  color: #fff;
  font-size: 18px;
  flex-shrink: 0;
}

.interview-person {
  flex: 1;
  display: flex;
  align-items: center;
  gap: 8px;
}

.interview-name {
  font-size: 16px;
  font-weight: 600;
  color: #000;
}

.interview-actions {
  display: flex;
  gap: 8px;
  flex-shrink: 0;
}

.interview-detail {
  display: flex;
  gap: 24px;
  padding-top: 12px;
  border-top: 1px solid #f0f0f0;
}

.interview-detail-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.interview-detail-label {
  font-size: 12px;
  color: #999;
}

.interview-detail-value {
  font-size: 14px;
  color: #000;
  font-weight: 500;
}

/* 人才库风格简历详情弹窗 */
.talent-detail {
  padding: 8px 0;
}

.talent-detail-header {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 24px;
  padding-bottom: 20px;
  border-bottom: 1px solid #f0f0f0;
}

.talent-detail-avatar {
  width: 64px;
  height: 64px;
  line-height: 64px;
  text-align: center;
  border-radius: 50%;
  background: #409eff;
  color: #fff;
  font-size: 26px;
  flex-shrink: 0;
}

.talent-detail-info {
  flex: 1;
}

.talent-detail-name {
  font-size: 20px;
  font-weight: 600;
  color: #000;
  margin-bottom: 6px;
}

.talent-detail-meta {
  display: flex;
  gap: 12px;
  font-size: 14px;
  color: #666;
}

.talent-detail-section {
  margin-bottom: 20px;
}

.talent-section-title {
  font-size: 14px;
  font-weight: 600;
  color: #333;
  margin: 0 0 8px;
  padding-left: 8px;
  border-left: 3px solid #409eff;
}

.talent-section-content {
  font-size: 14px;
  color: #555;
  line-height: 1.6;
  margin: 0;
  white-space: pre-wrap;
}

.talent-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.talent-tag {
  color: #000;
}
</style>
