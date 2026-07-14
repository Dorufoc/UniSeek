<script setup lang="ts">
import { ref, onMounted, reactive } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search } from '@element-plus/icons-vue'
import {
  listEnterprises,
  auditEnterprise,
  type EnterpriseRecord,
  type PageResult
} from '@/api/admin'

const loading = ref(false)
const tableData = ref<EnterpriseRecord[]>([])
const total = ref(0)
const activeTab = ref<number | string>('all')
const dialogVisible = ref(false)
const currentEnterprise = ref<EnterpriseRecord | null>(null)
const rejectReason = ref('')

const params = reactive({
  page: 1,
  pageSize: 10,
  auditStatus: undefined as number | undefined,
  keyword: ''
})

const fetchData = async () => {
  loading.value = true
  try {
    params.auditStatus = typeof activeTab.value === 'number' ? activeTab.value : undefined
    const data: PageResult<EnterpriseRecord> = await listEnterprises(params)
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

const openDetailDialog = (row: EnterpriseRecord) => {
  currentEnterprise.value = row
  rejectReason.value = ''
  dialogVisible.value = true
}

const handleAudit = async (approved: boolean) => {
  if (!currentEnterprise.value) return
  if (!approved && !rejectReason.value.trim()) {
    ElMessage.warning('请填写驳回原因')
    return
  }
  const confirmText = approved ? '确认通过该企业资质？' : '确认驳回该企业资质？'
  try {
    await ElMessageBox.confirm(confirmText, '操作确认', { type: 'warning' })
    await auditEnterprise(currentEnterprise.value.id, {
      approved,
      rejectReason: rejectReason.value || undefined
    })
    ElMessage.success(approved ? '审核通过' : '已驳回')
    dialogVisible.value = false
    fetchData()
  } catch {
    // 用户取消操作
  }
}

const getStatusTag = (status: number) => {
  const map: Record<number, { text: string; type: string }> = {
    0: { text: '待审核', type: 'info' },
    1: { text: '已认证', type: 'success' },
    2: { text: '已驳回', type: 'danger' }
  }
  return map[status] || { text: '未知', type: 'info' }
}

onMounted(() => {
  fetchData()
})
</script>

<template>
  <div class="page-container">
    <h2 class="page-title">企业审核</h2>

    <el-card shadow="never">
      <div class="table-header">
        <el-tabs v-model="activeTab" @tab-change="handleTabChange">
          <el-tab-pane label="全部" name="all" />
          <el-tab-pane :label="'待审核'" :name="0" />
          <el-tab-pane :label="'已认证'" :name="1" />
          <el-tab-pane :label="'已驳回'" :name="2" />
        </el-tabs>
        <el-input
          v-model="params.keyword"
          placeholder="搜索公司名称"
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
        <el-table-column prop="companyName" label="公司名称" min-width="160" show-overflow-tooltip />
        <el-table-column prop="creditCode" label="信用代码" width="180">
          <template #default="{ row }">
            {{ row.creditCode ? row.creditCode.substring(0, 6) + '****' + row.creditCode.substring(14) : '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="industry" label="所属行业" width="100" />
        <el-table-column prop="createTime" label="提交时间" width="160" />
        <el-table-column label="状态" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="getStatusTag(row.auditStatus).type as any" size="small">
              {{ getStatusTag(row.auditStatus).text }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="100" align="center">
          <template #default="{ row }">
            <el-button
              v-if="row.auditStatus === 0"
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
      title="企业资质审核"
      width="600px"
      :close-on-click-modal="false"
    >
      <template v-if="currentEnterprise">
        <el-descriptions :column="1" border>
          <el-descriptions-item label="公司全称">
            {{ currentEnterprise.companyName }}
          </el-descriptions-item>
          <el-descriptions-item label="信用代码">
            {{ currentEnterprise.creditCode }}
          </el-descriptions-item>
          <el-descriptions-item label="营业执照">
            <el-image
              v-if="currentEnterprise.licenseImgUrl"
              :src="currentEnterprise.licenseImgUrl"
              :preview-src-list="[currentEnterprise.licenseImgUrl]"
              fit="contain"
              style="width: 200px; height: 140px"
              :preview-teleported="true"
            />
            <span v-else>未上传</span>
          </el-descriptions-item>
          <el-descriptions-item label="所属行业">
            {{ currentEnterprise.industry || '-' }}
          </el-descriptions-item>
          <el-descriptions-item label="公司简介">
            {{ currentEnterprise.description || '-' }}
          </el-descriptions-item>
          <el-descriptions-item label="提交时间">
            {{ currentEnterprise.createTime }}
          </el-descriptions-item>
        </el-descriptions>

        <div v-if="currentEnterprise.auditStatus === 0" class="audit-actions">
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
