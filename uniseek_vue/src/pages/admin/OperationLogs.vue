<script setup lang="ts">
import { ref, onMounted, reactive } from 'vue'
import {
  listOperationLogs,
  type OperationLogRecord,
  type PageResult
} from '@/api/admin'

const loading = ref(false)
const tableData = ref<OperationLogRecord[]>([])
const total = ref(0)

const params = reactive({
  page: 1,
  pageSize: 10,
  operatorId: undefined as number | undefined,
  operationType: '' as string,
  startTime: '' as string,
  endTime: '' as string
})

const operationTypes = [
  'USER_REGISTER',
  'USER_LOGIN',
  'ENTERPRISE_SUBMIT',
  'ENTERPRISE_AUDIT',
  'TASK_PUBLISH',
  'TASK_AUDIT',
  'TASK_OFFLINE',
  'APPLICATION_DELIVER',
  'APPLICATION_HIRE',
  'APPLICATION_REJECT',
  'COMPLAINT_HANDLE',
  'REAL_NAME_AUTH',
  'ADMIN_SET_ROLE',
  'REGISTER',
  'LOGIN',
  'LOGOUT',
  'CHANGE_PASSWORD',
  'UPDATE_PHONE',
  'UPDATE_EMAIL',
  'SAVE_RESUME',
  'UPLOAD_RESUME',
  'APPLICATION_INTERVIEW',
  'APPLICATION_PENDING',
  'APPLICATION_COMPLETE'
]

const operationTypeMap: Record<string, string> = {
  USER_REGISTER: '用户注册',
  USER_LOGIN: '用户登录',
  ENTERPRISE_SUBMIT: '企业资质提交',
  ENTERPRISE_AUDIT: '企业资质审核',
  TASK_PUBLISH: '职位发布',
  TASK_AUDIT: '职位审核',
  TASK_OFFLINE: '职位下架',
  APPLICATION_DELIVER: '求职者投递',
  APPLICATION_HIRE: '录用求职者',
  APPLICATION_REJECT: '淘汰求职者',
  COMPLAINT_HANDLE: '投诉处理',
  REAL_NAME_AUTH: '实名认证',
  ADMIN_SET_ROLE: '管理员设权',
  REGISTER: '注册',
  LOGIN: '登录',
  LOGOUT: '登出',
  CHANGE_PASSWORD: '修改密码',
  UPDATE_PHONE: '更新手机号',
  UPDATE_EMAIL: '更新邮箱',
  SAVE_RESUME: '保存简历',
  UPLOAD_RESUME: '上传简历',
  APPLICATION_INTERVIEW: '邀约面试',
  APPLICATION_PENDING: '待处理',
  APPLICATION_COMPLETE: '投递结算'
}

const fetchData = async () => {
  loading.value = true
  try {
    const data: PageResult<OperationLogRecord> = await listOperationLogs({
      page: params.page,
      pageSize: params.pageSize,
      operatorId: params.operatorId,
      operationType: params.operationType || undefined,
      startTime: params.startTime || undefined,
      endTime: params.endTime || undefined
    })
    tableData.value = data.records
    total.value = data.total
  } catch {
    tableData.value = []
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  params.page = 1
  fetchData()
}

const handleReset = () => {
  params.operatorId = undefined
  params.operationType = ''
  params.startTime = ''
  params.endTime = ''
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

const formatDetail = (detail: string) => {
  if (!detail) return '-'
  try {
    return JSON.stringify(JSON.parse(detail), null, 2)
  } catch {
    return detail
  }
}

onMounted(() => {
  fetchData()
})
</script>

<template>
  <div class="page-container">
    <h2 class="page-title">操作日志</h2>

    <el-card shadow="never">
      <div class="filter-bar">
        <el-select
          v-model="params.operationType"
          placeholder="操作类型"
          clearable
          style="width: 160px"
        >
          <el-option
            v-for="type in operationTypes"
            :key="type"
            :label="operationTypeMap[type] || type"
            :value="type"
          />
        </el-select>
        <el-input
          v-model="params.operatorId"
          placeholder="操作人ID"
          clearable
          style="width: 140px"
          type="number"
        />
        <el-date-picker
          v-model="params.startTime"
          type="datetime"
          placeholder="开始时间"
          value-format="YYYY-MM-DD HH:mm:ss"
          style="width: 190px"
        />
        <span class="date-separator">至</span>
        <el-date-picker
          v-model="params.endTime"
          type="datetime"
          placeholder="结束时间"
          value-format="YYYY-MM-DD HH:mm:ss"
          style="width: 190px"
        />
        <el-button type="primary" @click="handleSearch">查询</el-button>
        <el-button @click="handleReset">重置</el-button>
      </div>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column type="expand">
          <template #default="{ row }">
            <div class="detail-panel">
              <pre class="detail-json">{{ formatDetail(row.detail) }}</pre>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="createTime" label="操作时间" width="160" />
        <el-table-column prop="operatorName" label="操作人" width="120" show-overflow-tooltip>
          <template #default="{ row }">
            {{ row.operatorName || '系统' }}
          </template>
        </el-table-column>
        <el-table-column label="操作类型" width="140" show-overflow-tooltip>
          <template #default="{ row }">
            {{ operationTypeMap[row.operationType] || row.operationType }}
          </template>
        </el-table-column>
        <el-table-column prop="targetType" label="目标类型" width="110" show-overflow-tooltip />
        <el-table-column prop="targetId" label="目标ID" width="80" align="center" />
        <el-table-column prop="ipAddress" label="IP 地址" width="140" show-overflow-tooltip />
        <el-table-column label="操作详情" min-width="180">
          <template #default="{ row }">
            <span class="detail-preview">{{ row.detail ? row.detail.substring(0, 60) + (row.detail.length > 60 ? '...' : '') : '-' }}</span>
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

.filter-bar {
  display: flex;
  gap: 12px;
  margin-bottom: 16px;
  flex-wrap: wrap;
  align-items: center;
}

.date-separator {
  color: #909399;
  font-size: 13px;
}

.table-pagination {
  margin-top: 16px;
  justify-content: flex-end;
}

.detail-panel {
  padding: 12px 16px;
  background: #f5f7fa;
}

.detail-json {
  margin: 0;
  font-size: 12px;
  line-height: 1.6;
  white-space: pre-wrap;
  word-break: break-all;
  color: #606266;
}

.detail-preview {
  color: #909399;
  font-size: 12px;
}
</style>
