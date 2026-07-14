<script setup lang="ts">
import { ref, onMounted, reactive } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search } from '@element-plus/icons-vue'
import {
  listPendingTasks,
  auditTask,
  type TaskRecord,
  type PageResult
} from '@/api/admin'

const loading = ref(false)
const tableData = ref<TaskRecord[]>([])
const total = ref(0)
const activeTab = ref<number | string>('all')
const dialogVisible = ref(false)
const currentTask = ref<TaskRecord | null>(null)
const rejectReason = ref('')

const params = reactive({
  page: 1,
  pageSize: 10,
  status: undefined as number | undefined,
  keyword: ''
})

const fetchData = async () => {
  loading.value = true
  try {
    const data: PageResult<TaskRecord> = await listPendingTasks(params.page, params.pageSize)
    tableData.value = data.records
    total.value = data.total
  } catch {
    tableData.value = []
  } finally {
    loading.value = false
  }
}

const handleTabChange = () => {
  params.page = 1
  fetchData()
}

const handlePageChange = (page: number) => {
  params.page = page
  fetchData()
}

const handleSizeChange = (size: number) => {
  params.pageSize = size
  params.page = 1
  fetchData()
}

const openDetailDialog = (row: TaskRecord) => {
  currentTask.value = row
  rejectReason.value = ''
  dialogVisible.value = true
}

const handleAudit = async (approved: boolean) => {
  if (!currentTask.value) return
  if (!approved && !rejectReason.value.trim()) {
    ElMessage.warning('请填写驳回原因')
    return
  }
  const confirmText = approved ? '确认通过该职位？' : '确认驳回该职位？'
  try {
    await ElMessageBox.confirm(confirmText, '操作确认', { type: 'warning' })
    await auditTask(currentTask.value.id, {
      approved,
      rejectReason: rejectReason.value || undefined
    })
    ElMessage.success(approved ? '审核通过，职位已上架' : '已驳回')
    dialogVisible.value = false
    fetchData()
  } catch {
    // 用户取消
  }
}

const salaryUnitText = (unit: number) => {
  const map: Record<number, string> = { 0: '日结', 1: '时薪', 2: '月结' }
  return map[unit] || '未知'
}

const jobTypeText = (type: number) => {
  const map: Record<number, string> = { 1: '全职', 2: '兼职', 3: '实习' }
  return map[type] || '未知'
}

const getStatusTag = (status: number) => {
  const map: Record<number, { text: string; type: string }> = {
    0: { text: '待审核', type: 'info' },
    1: { text: '招聘中', type: 'success' },
    2: { text: '已满员', type: 'warning' },
    3: { text: '已过期', type: 'info' },
    4: { text: '已下架', type: 'danger' }
  }
  return map[status] || { text: '未知', type: 'info' }
}

onMounted(() => {
  fetchData()
})
</script>

<template>
  <div class="page-container">
    <h2 class="page-title">职位审核</h2>

    <el-card shadow="never">
      <div class="table-header">
        <el-tabs v-model="activeTab" @tab-change="handleTabChange">
          <el-tab-pane label="全部" name="all" />
          <el-tab-pane :label="'待审核'" :name="0" />
          <el-tab-pane :label="'招聘中'" :name="1" />
          <el-tab-pane :label="'已满员'" :name="2" />
          <el-tab-pane :label="'已过期'" :name="3" />
          <el-tab-pane :label="'已下架'" :name="4" />
        </el-tabs>
        <el-input
          v-model="params.keyword"
          placeholder="搜索职位标题（前端过滤）"
          clearable
          style="width: 240px"
          @clear="fetchData"
          @keyup.enter="fetchData"
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
        </el-input>
      </div>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="title" label="职位标题" min-width="160" show-overflow-tooltip />
        <el-table-column prop="enterpriseName" label="发布企业" width="160" show-overflow-tooltip />
        <el-table-column label="薪资" width="160">
          <template #default="{ row }">
            {{ row.salaryMin }} - {{ row.salaryMax }} 元/{{ salaryUnitText(row.salaryUnit) }}
          </template>
        </el-table-column>
        <el-table-column label="类型" width="80" align="center">
          <template #default="{ row }">
            {{ jobTypeText(row.jobType) }}
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="发布时间" width="160" />
        <el-table-column label="状态" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="getStatusTag(row.status).type as any" size="small">
              {{ getStatusTag(row.status).text }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="100" align="center">
          <template #default="{ row }">
            <el-button
              v-if="row.status === 0"
              type="primary"
              size="small"
              link
              @click="openDetailDialog(row)"
            >
              审核
            </el-button>
            <el-button
              v-else
              size="small"
              link
              @click="openDetailDialog(row)"
            >
              查看
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        v-if="total > 0"
        class="table-pagination"
        v-model:current-page="params.page"
        v-model:page-size="params.pageSize"
        :total="total"
        :page-sizes="[10, 20, 50]"
        layout="total, sizes, prev, pager, next"
        @current-change="handlePageChange"
        @size-change="handleSizeChange"
      />
    </el-card>

    <el-dialog
      v-model="dialogVisible"
      title="职位审核"
      width="650px"
      :close-on-click-modal="false"
    >
      <template v-if="currentTask">
        <el-descriptions :column="1" border>
          <el-descriptions-item label="职位标题">
            {{ currentTask.title }}
          </el-descriptions-item>
          <el-descriptions-item label="发布企业">
            {{ currentTask.enterpriseName || '-' }}
          </el-descriptions-item>
          <el-descriptions-item label="薪资">
            {{ currentTask.salaryMin }} - {{ currentTask.salaryMax }} 元/{{ salaryUnitText(currentTask.salaryUnit) }}
          </el-descriptions-item>
          <el-descriptions-item label="岗位类型">
            {{ jobTypeText(currentTask.jobType) }}
          </el-descriptions-item>
          <el-descriptions-item label="招聘名额">
            {{ currentTask.totalQuota }} 人（剩余：{{ currentTask.remainingQuota }} 人）
          </el-descriptions-item>
          <el-descriptions-item label="工作地址">
            {{ currentTask.address || '-' }}
          </el-descriptions-item>
          <el-descriptions-item label="截止时间">
            {{ currentTask.deadline || '-' }}
          </el-descriptions-item>
          <el-descriptions-item label="职位描述">
            <div v-html="currentTask.description" style="max-height: 200px; overflow-y: auto;"></div>
          </el-descriptions-item>
        </el-descriptions>

        <div v-if="currentTask.status === 0" class="audit-actions">
          <el-input
            v-model="rejectReason"
            type="textarea"
            :rows="3"
            placeholder="驳回原因（驳回时必填）"
          />
          <div class="audit-buttons">
            <el-button @click="dialogVisible = false">取消</el-button>
            <el-button type="danger" @click="handleAudit(false)">驳回</el-button>
            <el-button type="primary" @click="handleAudit(true)">通过</el-button>
          </div>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.page-container {
  max-width: 1400px;
}

.page-title {
  font-size: 20px;
  font-weight: 600;
  color: #303133;
  margin: 0 0 20px;
}

.table-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-bottom: 12px;
}

.table-header :deep(.el-tabs__header) {
  margin-bottom: 0;
}

.table-pagination {
  margin-top: 16px;
  justify-content: flex-end;
}

.audit-actions {
  margin-top: 20px;
}

.audit-buttons {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 12px;
}
</style>
