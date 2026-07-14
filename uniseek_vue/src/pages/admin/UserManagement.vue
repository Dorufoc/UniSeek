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
            <el-tag :type="row.realNameAuth ? 'success' : ''" size="small">
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
}

.table-pagination {
  margin-top: 16px;
  justify-content: flex-end;
}
</style>
