<script setup lang="ts">
import { ref, onMounted, reactive } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  listComplaints,
  getComplaintDetail,
  handleComplaint,
  type ComplaintRecord,
  type PageResult
} from '@/api/admin'

const loading = ref(false)
const tableData = ref<ComplaintRecord[]>([])
const total = ref(0)
const activeTab = ref<number | string>('all')
const dialogVisible = ref(false)
const detailLoading = ref(false)
const currentComplaint = ref<ComplaintRecord | null>(null)
const handleResult = ref('')

const params = reactive({
  page: 1,
  pageSize: 10,
  status: undefined as number | undefined,
  targetType: undefined as number | undefined
})

const fetchData = async () => {
  loading.value = true
  try {
    params.status = typeof activeTab.value === 'number' ? activeTab.value : undefined
    const data: PageResult<ComplaintRecord> = await listComplaints(params)
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

const openDetailDialog = async (row: ComplaintRecord) => {
  dialogVisible.value = true
  handleResult.value = ''
  detailLoading.value = true
  try {
    currentComplaint.value = await getComplaintDetail(row.id)
  } catch {
    currentComplaint.value = row
  } finally {
    detailLoading.value = false
  }
}

const handleResolve = async (status: number) => {
  if (!currentComplaint.value) return
  if (!handleResult.value.trim()) {
    ElMessage.warning('请填写处理结果或驳回原因')
    return
  }
  const isResolve = status === 2
  const confirmText = isResolve ? '确认结案该投诉？' : '确认驳回该投诉？'
  try {
    await ElMessageBox.confirm(confirmText, '操作确认', { type: 'warning' })
    await handleComplaint(currentComplaint.value.id, {
      status,
      handleResult: handleResult.value
    })
    ElMessage.success(isResolve ? '投诉已结案' : '投诉已驳回')
    dialogVisible.value = false
    fetchData()
  } catch {
    // 用户取消
  }
}

const targetTypeText = (type: number) => {
  return type === 1 ? '企业' : '用户'
}

const complaintTypeText = (type: number) => {
  const map: Record<number, string> = { 1: '虚假信息', 2: '违规行为', 3: '其他' }
  return map[type] || '未知'
}

const getStatusTag = (status: number) => {
  const map: Record<number, { text: string; type: string }> = {
    0: { text: '待处理', type: 'danger' },
    1: { text: '处理中', type: 'warning' },
    2: { text: '已结案', type: 'success' }
  }
  return map[status] || { text: '未知', type: 'info' }
}

onMounted(() => {
  fetchData()
})
</script>

<template>
  <div class="page-container">
    <h2 class="page-title">投诉处理</h2>

    <el-card shadow="never">
      <div class="table-header">
        <el-tabs v-model="activeTab" @tab-change="handleTabChange">
          <el-tab-pane label="全部" name="all" />
          <el-tab-pane :label="'待处理'" :name="0" />
          <el-tab-pane :label="'已结案'" :name="2" />
        </el-tabs>
        <el-select
          v-model="params.targetType"
          placeholder="被投诉对象类型"
          clearable
          style="width: 160px"
          @change="fetchData"
        >
          <el-option label="全部" value="" />
          <el-option label="企业" :value="1" />
          <el-option label="用户" :value="2" />
        </el-select>
      </div>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="complainantName" label="投诉人" width="100" />
        <el-table-column label="被投诉对象" min-width="140" show-overflow-tooltip>
          <template #default="{ row }">
            {{ targetTypeText(row.targetType) }}：{{ row.targetName || row.targetId }}
          </template>
        </el-table-column>
        <el-table-column label="投诉类型" width="100" align="center">
          <template #default="{ row }">
            {{ complaintTypeText(row.type) }}
          </template>
        </el-table-column>
        <el-table-column prop="content" label="投诉内容" min-width="160" show-overflow-tooltip />
        <el-table-column prop="createTime" label="提交时间" width="160" />
        <el-table-column label="状态" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="getStatusTag(row.status).type as any" size="small">
              {{ getStatusTag(row.status).text }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" align="center">
          <template #default="{ row }">
            <el-button
              v-if="row.status === 0"
              type="primary"
              size="small"
              link
              @click="openDetailDialog(row)"
            >
              处理
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
      title="处理投诉"
      width="600px"
      :close-on-click-modal="false"
    >
      <template v-if="currentComplaint">
        <el-descriptions :column="1" border v-loading="detailLoading">
          <el-descriptions-item label="投诉人">
            {{ currentComplaint.complainantName || '-' }}（{{ currentComplaint.complainantPhone || '-' }}）
          </el-descriptions-item>
          <el-descriptions-item label="被投诉对象">
            {{ targetTypeText(currentComplaint.targetType) }}：{{ currentComplaint.targetName || '-' }}
          </el-descriptions-item>
          <el-descriptions-item label="投诉类型">
            {{ complaintTypeText(currentComplaint.type) }}
          </el-descriptions-item>
          <el-descriptions-item label="投诉内容">
            {{ currentComplaint.content }}
          </el-descriptions-item>
          <el-descriptions-item label="提交时间">
            {{ currentComplaint.createTime }}
          </el-descriptions-item>
        </el-descriptions>

        <div v-if="currentComplaint.status === 0" class="handle-actions">
          <el-input
            v-model="handleResult"
            type="textarea"
            :rows="4"
            placeholder="处理结果或驳回原因（必填）"
          />
          <div class="handle-buttons">
            <el-button @click="dialogVisible = false">取消</el-button>
            <el-button type="danger" @click="handleResolve(0)">驳回投诉</el-button>
            <el-button type="primary" @click="handleResolve(2)">确认结案</el-button>
          </div>
        </div>
        <div v-else class="handle-result">
          <div class="result-label">处理结果：</div>
          <div class="result-content">{{ currentComplaint.handleResult || '-' }}</div>
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

.handle-actions {
  margin-top: 20px;
}

.handle-buttons {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 12px;
}

.handle-result {
  margin-top: 20px;
  padding: 16px;
  background: #f5f7fa;
  border-radius: 4px;
}

.result-label {
  font-weight: 600;
  margin-bottom: 8px;
  color: #303133;
}

.result-content {
  color: #606266;
  line-height: 1.6;
}
</style>
