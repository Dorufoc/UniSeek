<script setup lang="ts">
import { ref, onMounted, reactive } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search } from '@element-plus/icons-vue'
import { useUserStore } from '@/stores/user'
import {
  listUsers,
  updateUserStatus,
  updateUserRole,
  type UserRecord,
  type PageResult
} from '@/api/admin'

const userStore = useUserStore()
const loading = ref(false)
const tableData = ref<UserRecord[]>([])
const total = ref(0)
const isSuperAdmin = userStore.role === 99

const params = reactive({
  page: 1,
  pageSize: 10,
  keyword: '',
  role: undefined as number | undefined,
  status: undefined as number | undefined
})

const fetchData = async () => {
  loading.value = true
  try {
    const data: PageResult<UserRecord> = await listUsers(params)
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

const handlePageChange = (page: number) => {
  params.page = page
  fetchData()
}

const handleSizeChange = (size: number) => {
  params.pageSize = size
  params.page = 1
  fetchData()
}

const handleToggleStatus = async (row: UserRecord) => {
  const newStatus = row.status === 1 ? 0 : 1
  const action = newStatus === 0 ? '禁用' : '启用'
  try {
    await ElMessageBox.confirm(`确认${action}用户「${row.nickname || row.phone}」？`, '操作确认', {
      type: 'warning'
    })
    await updateUserStatus(row.id, newStatus)
    ElMessage.success(`${action}成功`)
    fetchData()
  } catch {
    // 用户取消
  }
}

const handleSetAdmin = async (row: UserRecord) => {
  try {
    await ElMessageBox.confirm(
      `确认将用户「${row.nickname || row.phone}」设为管理员？`,
      '操作确认',
      { type: 'warning' }
    )
    await updateUserRole(row.id, 9)
    ElMessage.success('已设为管理员')
    fetchData()
  } catch {
    // 用户取消
  }
}

const handleCancelAdmin = async (row: UserRecord) => {
  try {
    await ElMessageBox.confirm(
      `确认取消用户「${row.nickname || row.phone}」的管理员权限？`,
      '操作确认',
      { type: 'warning' }
    )
    await updateUserRole(row.id, 0)
    ElMessage.success('已取消管理员')
    fetchData()
  } catch {
    // 用户取消
  }
}

const roleText = (role: number) => {
  const map: Record<number, string> = { 0: '求职者', 1: '企业HR', 9: '管理员', 99: '超级管理员' }
  return map[role] || '未知'
}

const roleTagType = (role: number) => {
  const map: Record<number, string> = { 0: 'info', 1: 'warning', 9: 'success', 99: 'danger' }
  return map[role] || 'info'
}

onMounted(() => {
  fetchData()
})
</script>

<template>
  <div class="page-container">
    <h2 class="page-title">用户管理</h2>

    <el-card shadow="never">
      <div class="filter-bar">
        <el-input
          v-model="params.keyword"
          placeholder="搜索手机号或昵称"
          clearable
          style="width: 240px"
          @clear="handleSearch"
          @keyup.enter="handleSearch"
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
        </el-input>
        <el-select v-model="params.role" placeholder="角色筛选" clearable style="width: 140px" @change="handleSearch">
          <el-option label="求职者" :value="0" />
          <el-option label="企业HR" :value="1" />
          <el-option label="管理员" :value="9" />
          <el-option label="超级管理员" :value="99" />
        </el-select>
        <el-select v-model="params.status" placeholder="状态筛选" clearable style="width: 120px" @change="handleSearch">
          <el-option label="正常" :value="1" />
          <el-option label="禁用" :value="0" />
        </el-select>
        <el-button type="primary" @click="handleSearch">查询</el-button>
      </div>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="phone" label="手机号" width="130" show-overflow-tooltip />
        <el-table-column prop="nickname" label="昵称" width="120" show-overflow-tooltip />
        <el-table-column label="角色" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="roleTagType(row.role) as any" size="small">
              {{ roleText(row.role) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="实名认证" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.realNameAuth ? 'success' : 'info'" size="small">
              {{ row.realNameAuth ? '已认证' : '未认证' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="creditScore" label="信用分" width="80" align="center" />
        <el-table-column prop="createTime" label="注册时间" width="160" />
        <el-table-column prop="lastLoginTime" label="最后登录" width="160" />
        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'danger'" size="small">
              {{ row.status === 1 ? '正常' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" :width="isSuperAdmin ? 280 : 100" align="center" fixed="right">
          <template #default="{ row }">
            <el-popconfirm
              :title="`确认${row.status === 1 ? '禁用' : '启用'}该用户？`"
              @confirm="handleToggleStatus(row)"
            >
              <template #reference>
                <el-button
                  :type="row.status === 1 ? 'danger' : 'success'"
                  size="small"
                  link
                  :disabled="row.role >= 9"
                >
                  {{ row.status === 1 ? '禁用' : '启用' }}
                </el-button>
              </template>
            </el-popconfirm>
            <template v-if="isSuperAdmin">
              <el-button
                v-if="row.role === 0 || row.role === 1"
                type="primary"
                size="small"
                link
                @click="handleSetAdmin(row)"
              >
                设为管理员
              </el-button>
              <el-button
                v-if="row.role === 9"
                type="warning"
                size="small"
                link
                @click="handleCancelAdmin(row)"
              >
                取消管理员
              </el-button>
            </template>
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

.filter-bar {
  display: flex;
  gap: 12px;
  margin-bottom: 20px;
  flex-wrap: wrap;
  align-items: center;
  padding: 16px;
  background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
  border-radius: 12px;
  border: 1px solid #e2e8f0;
}

.filter-bar :deep(.el-input__wrapper) {
  border-radius: 8px;
  transition: all 0.25s ease;
}

.filter-bar :deep(.el-input__wrapper:hover) {
  border-color: #1762FB;
}

.filter-bar :deep(.el-input__wrapper.is-focus) {
  border-color: #1762FB;
  box-shadow: 0 0 0 3px rgba(23, 98, 251, 0.1);
}

.filter-bar :deep(.el-select .el-input__wrapper) {
  border-radius: 8px;
}

.filter-bar :deep(.el-button--primary) {
  background: linear-gradient(135deg, #1762FB 0%, #0052e6 100%);
  border: none;
  border-radius: 8px;
  padding: 8px 20px;
  font-weight: 600;
  transition: all 0.25s ease;
}

.filter-bar :deep(.el-button--primary:hover) {
  box-shadow: 0 4px 12px rgba(23, 98, 251, 0.3);
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

:deep(.el-button--danger.is-link) {
  color: #ef4444;
  font-weight: 500;
  transition: all 0.2s ease;
}

:deep(.el-button--danger.is-link:hover) {
  color: #dc2626;
}

:deep(.el-button--success.is-link) {
  color: #10b981;
  font-weight: 500;
  transition: all 0.2s ease;
}

:deep(.el-button--success.is-link:hover) {
  color: #059669;
}

:deep(.el-button--warning.is-link) {
  color: #f59e0b;
  font-weight: 500;
  transition: all 0.2s ease;
}

:deep(.el-button--warning.is-link:hover) {
  color: #d97706;
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
</style>
