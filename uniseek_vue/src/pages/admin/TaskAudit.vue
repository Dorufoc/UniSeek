<script setup lang="ts">
import { ref, onMounted, reactive } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search } from '@element-plus/icons-vue'
import {
  listTasks,
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
  rejected: undefined as boolean | undefined,
  keyword: ''
})

const fetchData = async () => {
  loading.value = true
  try {
    const data: PageResult<TaskRecord> = await listTasks({
      page: params.page,
      pageSize: params.pageSize,
      status: params.status,
      keyword: params.keyword || undefined,
      rejected: params.rejected
    })
    tableData.value = data.records
    total.value = data.total
  } catch {
    tableData.value = []
  } finally {
    loading.value = false
  }
}

const handleTabChange = (tab: number | string) => {
  activeTab.value = tab
  params.page = 1
  params.rejected = undefined
  if (tab === 'rejected') {
    params.status = undefined
    params.rejected = true
  } else if (tab === 0) {
    params.status = 0
    params.rejected = false
  } else {
    params.status = typeof tab === 'number' ? tab : undefined
  }
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

const getStatusTag = (status: number, rejectReason?: string) => {
  const map: Record<number, { text: string; type: string }> = {
    0: { text: '待审核', type: 'info' },
    1: { text: '招聘中', type: 'success' },
    2: { text: '已满员', type: 'warning' },
    3: { text: '已过期', type: 'info' },
    4: { text: '已下架', type: 'danger' },
    5: { text: '已驳回', type: 'danger' }
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
          <el-tab-pane label="已驳回" name="rejected" />
          <el-tab-pane :label="'招聘中'" :name="1" />
          <el-tab-pane :label="'已满员'" :name="2" />
          <el-tab-pane :label="'已过期'" :name="3" />
          <el-tab-pane :label="'已下架'" :name="4" />
        </el-tabs>
        <el-input
          v-model="params.keyword"
           placeholder="搜索职位标题"
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
            {{ row.salaryMin === 0 && row.salaryMax === 0 ? '面议' : row.salaryMin + ' - ' + row.salaryMax + ' 元/' + salaryUnitText(row.salaryUnit) }}
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
            <el-tag :type="getStatusTag(row.status, row.rejectReason).type as any" size="small">
              {{ getStatusTag(row.status, row.rejectReason).text }}
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
            {{ currentTask.salaryMin === 0 && currentTask.salaryMax === 0 ? '面议' : currentTask.salaryMin + ' - ' + currentTask.salaryMax + ' 元/' + salaryUnitText(currentTask.salaryUnit) }}
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
          <el-descriptions-item v-if="currentTask.rejectReason" label="驳回原因">
            <span style="color: #f56c6c;">{{ currentTask.rejectReason }}</span>
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
  animation: admin-fade-in 0.4s ease;
}

@keyframes admin-fade-in {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.page-title {
  font-size: 24px;
  font-weight: 700;
  color: #1a1a2e;
  margin: 0 0 24px;
  letter-spacing: -0.3px;
}

.table-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding: 16px;
  background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
  border-radius: 12px;
  border: 1px solid #e2e8f0;
}

.table-header :deep(.el-tabs) {
  flex: 1;
}

.table-header :deep(.el-tabs__header) {
  margin-bottom: 0;
}

.table-header :deep(.el-tabs__nav-wrap::after) {
  display: none;
}

.table-header :deep(.el-tabs__item) {
  font-weight: 500;
  transition: all 0.25s ease;
  padding: 0 20px;
}

.table-header :deep(.el-tabs__item.is-active) {
  color: #1762FB;
  font-weight: 600;
}

.table-header :deep(.el-tabs__active-bar) {
  background: linear-gradient(90deg, #1762FB 0%, #0052e6 100%);
  height: 3px;
  border-radius: 2px;
}

.table-header :deep(.el-input__wrapper) {
  border-radius: 8px;
  transition: all 0.25s ease;
}

.table-header :deep(.el-input__wrapper:hover) {
  border-color: #1762FB;
}

.table-header :deep(.el-input__wrapper.is-focus) {
  border-color: #1762FB;
  box-shadow: 0 0 0 3px rgba(23, 98, 251, 0.1);
}

:deep(.el-table) {
  border-radius: 10px;
  overflow: hidden;
  font-size: 13px;
}

:deep(.el-table::before) {
  display: none;
}

:deep(.el-table th) {
  background: #f1f5f9 !important;
  color: #64748b;
  font-weight: 600;
  font-size: 12px;
  letter-spacing: 0.3px;
  padding: 12px 0;
  border-bottom: 1px solid #e2e8f0;
}

:deep(.el-table th .cell) {
  padding: 0 16px;
}

:deep(.el-table td) {
  color: #334155;
  font-size: 13px;
  padding: 0;
  border-bottom: 1px solid #f1f5f9;
}

:deep(.el-table td .cell) {
  padding: 10px 16px;
  line-height: 1.5;
}

:deep(.el-table__body tr) {
  transition: background 0.2s ease;
}

:deep(.el-table__row:hover > td) {
  background: #f8fafc !important;
}

:deep(.el-table--striped .el-table__body tr.el-table__row--striped td) {
  background: #fafbfc !important;
}

:deep(.el-table--striped .el-table__body tr.el-table__row--striped:hover > td) {
  background: #f1f5f9 !important;
}

:deep(.el-table__body tr:last-child td) {
  border-bottom: none;
}

:deep(.el-tag) {
  border-radius: 6px;
  font-weight: 500;
  padding: 4px 10px;
  font-size: 12px;
  border: none;
}

:deep(.el-tag--success) {
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  color: white;
}

:deep(.el-tag--danger) {
  background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
  color: white;
}

:deep(.el-tag--warning) {
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  color: white;
}

:deep(.el-tag--info) {
  background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%);
  color: white;
}

:deep(.el-button--primary.is-link) {
  color: #1762FB;
  font-weight: 500;
  transition: all 0.2s ease;
}

:deep(.el-button--primary.is-link:hover) {
  color: #0052e6;
}

.table-pagination {
  margin-top: 24px;
  justify-content: flex-end;
  padding: 16px 0;
}

:deep(.el-pagination .el-pager li) {
  border-radius: 6px;
  font-weight: 500;
  transition: all 0.2s ease;
}

:deep(.el-pagination .el-pager li.is-active) {
  background: linear-gradient(135deg, #1762FB 0%, #0052e6 100%);
  color: white;
  box-shadow: 0 2px 8px rgba(23, 98, 251, 0.3);
}

:deep(.el-pagination .el-pager li:hover) {
  /* 移除位移动画 */
}

:deep(.el-dialog) {
  border-radius: 16px;
  overflow: hidden;
  max-height: 85vh;
  display: flex;
  flex-direction: column;
}

:deep(.el-dialog__body) {
  overflow-y: auto;
  flex: 1;
  padding: 24px;
}

:deep(.el-dialog__body::-webkit-scrollbar) {
  width: 6px;
}

:deep(.el-dialog__body::-webkit-scrollbar-thumb) {
  background: #cbd5e1;
  border-radius: 3px;
}

:deep(.el-dialog__body::-webkit-scrollbar-thumb:hover) {
  background: #94a3b8;
}

:deep(.el-dialog__footer) {
  flex-shrink: 0;
  padding: 16px 24px;
  border-top: 1px solid #e2e8f0;
}

:deep(.el-dialog__header) {
  background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
  border-bottom: 1px solid #e2e8f0;
  padding: 20px 24px;
  flex-shrink: 0;
}

:deep(.el-dialog__title) {
  font-weight: 600;
  color: #1a1a2e;
  font-size: 18px;
}

:deep(.el-descriptions) {
  border-radius: 8px;
  overflow: hidden;
}

:deep(.el-descriptions__label) {
  font-weight: 600;
  color: #475569;
  background: #f8fafc;
  min-width: 100px;
  width: 100px;
}

.audit-actions {
  margin-top: 24px;
}

.audit-buttons {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 16px;
}

.audit-buttons :deep(.el-button) {
  border-radius: 8px;
  padding: 10px 24px;
  font-weight: 600;
  transition: all 0.25s ease;
}

.audit-buttons :deep(.el-button--primary) {
  background: linear-gradient(135deg, #1762FB 0%, #0052e6 100%);
  border: none;
}

.audit-buttons :deep(.el-button--primary:hover) {
  box-shadow: 0 4px 12px rgba(23, 98, 251, 0.3);
}

.audit-buttons :deep(.el-button--danger) {
  background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
  border: none;
}

.audit-buttons :deep(.el-button--danger:hover) {
  box-shadow: 0 4px 12px rgba(239, 68, 68, 0.3);
}
</style>
