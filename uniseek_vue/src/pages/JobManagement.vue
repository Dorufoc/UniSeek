<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import { getEnterpriseTasks, updateTaskStatus, type TaskVO } from '@/api/task'

const router = useRouter()
const loading = ref(false)
const tasks = ref<TaskVO[]>([])

// 状态映射
const statusMap: Record<number, { label: string; type: 'success' | 'warning' | 'info' | 'danger' }> = {
  0: { label: '待审核', type: 'warning' },
  1: { label: '招聘中', type: 'success' },
  2: { label: '已满员', type: 'danger' },
  3: { label: '已过期', type: 'info' },
  4: { label: '已下架', type: 'info' }
}

// 岗位类型映射
const jobTypeMap: Record<number, string> = {
  1: '全职',
  2: '兼职',
  3: '实习'
}

// 薪资单位映射（与后端 TaskVO 保持一致）
const salaryUnitMap: Record<number, string> = {
  0: '日结',
  1: '时薪',
  2: '月结'
}

// 格式化时间，仅显示日期
const formatDate = (dateStr: string | null) => {
  if (!dateStr) return '-'
  return dateStr.substring(0, 10)
}

// 加载本企业职位列表
const loadTasks = async () => {
  loading.value = true
  try {
    const res = await getEnterpriseTasks()
    tasks.value = res.data?.records || []
  } catch (err: any) {
    if (err?.message?.includes('未找到企业信息')) {
      ElMessage.warning('请先完成企业资质认证')
      router.push('/enterprise-cert')
    }
  } finally {
    loading.value = false
  }
}

// 切换职位状态：招聘中 <-> 已下架
const toggleStatus = async (task: TaskVO) => {
  const targetStatus = task.status === 1 ? 4 : 1
  const actionText = targetStatus === 1 ? '上架' : '下架'

  try {
    await ElMessageBox.confirm(`确定要${actionText}该职位吗？`, '提示', { type: 'warning' })
  } catch {
    return
  }

  try {
    await updateTaskStatus(task.id, targetStatus)
    ElMessage.success(`${actionText}成功`)
    await loadTasks()
  } catch {
    // 错误已由响应拦截器提示
  }
}

// 判断当前状态是否允许上下架操作
const canToggle = (status: number) => status === 1 || status === 4

// 计算已投递数量显示
const appliedText = (task: TaskVO) => {
  return `${task.applicationCount || 0} 人投递`
}

onMounted(loadTasks)
</script>

<template>
  <div class="job-management-page">
    <div class="management-header">
      <h2 class="management-title">职位管理</h2>
      <el-button type="primary" :icon="Plus" @click="router.push('/post-job')">
        发布职位
      </el-button>
    </div>

    <div v-if="loading" class="loading-tip">加载中...</div>

    <div v-else-if="tasks.length === 0" class="empty-block">
      <el-empty description="暂无职位，点击右上角发布职位" />
    </div>

    <div v-else class="job-list">
      <el-card v-for="task in tasks" :key="task.id" class="job-card" shadow="hover">
        <div class="job-header">
          <div class="job-title-wrap">
            <span class="job-title">{{ task.title }}</span>
            <el-tag :type="statusMap[task.status]?.type || 'info'" size="small">
              {{ statusMap[task.status]?.label || '未知' }}
            </el-tag>
          </div>
          <div class="job-salary">
            {{ task.salaryMin }}-{{ task.salaryMax }} 元 / {{ salaryUnitMap[task.salaryUnit] || '月' }}
          </div>
        </div>

        <div class="job-meta">
          <span>{{ jobTypeMap[task.jobType] || '其他' }}</span>
          <span>{{ task.regionName || '-' }}</span>
          <span>名额 {{ task.remainingQuota }}/{{ task.totalQuota }}</span>
          <span>报名截止：{{ formatDate(task.deadline) }}</span>
        </div>

        <div class="job-tags">
          <el-tag v-for="tag in task.tag" :key="tag" size="small" type="info" class="job-tag">
            {{ tag }}
          </el-tag>
        </div>

        <div class="job-footer">
          <div class="job-stats">
            <span>{{ appliedText(task) }}</span>
            <span class="job-time">发布于 {{ formatDate(task.createTime) }}</span>
          </div>
          <div class="job-actions">
            <el-button
              v-if="canToggle(task.status)"
              :type="task.status === 1 ? 'danger' : 'success'"
              size="small"
              @click="toggleStatus(task)"
            >
              {{ task.status === 1 ? '下架' : '上架' }}
            </el-button>
            <el-button size="small" @click="$router.push(`/jobs/${task.id}`)">查看详情</el-button>
          </div>
        </div>
      </el-card>
    </div>
  </div>
</template>

<style scoped>
.job-management-page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 24px;
}

.management-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: #fff;
  padding: 16px 24px;
  border-radius: 8px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  margin-bottom: 24px;
}

.management-title {
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

.job-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.job-card {
  color: #000;
}

.job-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.job-title-wrap {
  display: flex;
  align-items: center;
  gap: 10px;
}

.job-title {
  font-size: 16px;
  font-weight: 600;
  color: #000;
}

.job-salary {
  font-size: 16px;
  font-weight: 600;
  color: #f56c6c;
}

.job-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  font-size: 13px;
  color: #666;
  margin-bottom: 12px;
}

.job-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 16px;
}

.job-tag {
  color: #000;
}

.job-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 12px;
  border-top: 1px solid #eee;
}

.job-stats {
  display: flex;
  gap: 16px;
  font-size: 13px;
  color: #666;
}

.job-time {
  color: #999;
}

.job-actions {
  display: flex;
  gap: 8px;
}
</style>
