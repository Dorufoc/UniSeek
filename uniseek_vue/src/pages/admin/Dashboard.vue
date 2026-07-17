<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ArrowRight } from '@element-plus/icons-vue'
import { getStatistics, listEnterprises, listPendingTasks } from '@/api/admin'

const router = useRouter()
const summary = ref<Record<string, number>>({})
const dailyStats = ref<Array<Record<string, unknown>>>([])
const pendingCounts = reactive({
  pendingEnterprises: 0,
  pendingTasks: 0
})
const loading = ref(false)

const fetchData = async () => {
  loading.value = true
  try {
    const d = new Date()
    d.setDate(d.getDate() - 7)
    const formatLocalDate = (d: Date) => {
      const y = d.getFullYear()
      const m = String(d.getMonth() + 1).padStart(2, '0')
      const day = String(d.getDate()).padStart(2, '0')
      return `${y}-${m}-${day}`
    }
    const startDate = formatLocalDate(d) + ' 00:00:00'
    const endDate = formatLocalDate(new Date()) + ' 23:59:59'

    const [stats, entRes, taskRes] = await Promise.all([
      getStatistics(startDate, endDate),
      listEnterprises({ page: 1, pageSize: 1, auditStatus: 0 }).catch(() => ({ total: 0 })),
      listPendingTasks({ page: 1, pageSize: 1 }).catch(() => ({ total: 0 }))
    ])
    summary.value = stats.summary || {}
    dailyStats.value = stats.dailyList || []
    pendingCounts.pendingEnterprises = (entRes as any).total || 0
    pendingCounts.pendingTasks = (taskRes as any).total || 0
  } catch {
    // 接口未就绪时留空
  } finally {
    loading.value = false
  }
}

const overviewCards = [
  { label: '累计用户', key: 'totalUsers', color: '#1762FB', icon: 'User' },
  { label: '认证企业', key: 'totalEnterprises', color: '#10b981', icon: 'OfficeBuilding' },
  { label: '招聘中职位', key: 'publishedTasks', color: '#f59e0b', icon: 'Briefcase' },
  { label: '投递总数', key: 'totalApplications', color: '#ef4444', icon: 'Document' }
]

const pendingCards = [
  { label: '待审核企业', key: 'pendingEnterprises', path: '/admin/enterprises', color: '#1762FB' },
  { label: '待审核职位', key: 'pendingTasks', path: '/admin/tasks', color: '#f59e0b' }
]

onMounted(() => {
  fetchData()
})
</script>

<template>
  <div class="dashboard">
    <h2 class="page-title">工作台</h2>

    <el-row :gutter="16" class="overview-row">
      <el-col :span="6" v-for="card in overviewCards" :key="card.key">
        <el-card
          shadow="never"
          class="stat-card"
          :style="{
            '--card-color': card.color,
            background: `linear-gradient(135deg, ${card.color}33, ${card.color}14)`
          }"
        >
          <div class="stat-label">{{ card.label }}</div>
          <div class="stat-value">{{ summary[card.key] ?? 0 }}</div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="16">
      <el-col :span="16">
        <el-card shadow="never" class="chart-card">
          <template #header>
            <span>每日新增趋势（近 7 天）</span>
          </template>
          <div v-if="dailyStats.length === 0 && !loading" class="empty-tip">
            暂无统计数据
          </div>
          <el-table v-else :data="dailyStats" v-loading="loading" class="trend-table">
            <el-table-column prop="date" label="日期" min-width="120">
              <template #default="{ row }">
                <span class="date-cell">{{ row.date }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="newUsers" label="新增用户" min-width="100" align="center">
              <template #default="{ row }">
                <span class="num-cell" :class="{ 'num-zero': !row.newUsers }">{{ row.newUsers }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="newEnterprises" label="新增企业" min-width="100" align="center">
              <template #default="{ row }">
                <span class="num-cell" :class="{ 'num-zero': !row.newEnterprises }">{{ row.newEnterprises }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="newTasks" label="新增职位" min-width="100" align="center">
              <template #default="{ row }">
                <span class="num-cell" :class="{ 'num-zero': !row.newTasks }">{{ row.newTasks }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="newApplications" label="新增投递" min-width="100" align="center">
              <template #default="{ row }">
                <span class="num-cell" :class="{ 'num-zero': !row.newApplications }">{{ row.newApplications }}</span>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>

      <el-col :span="8">
        <el-card shadow="never" class="pending-card">
          <template #header>
            <span>待办事项 · 数据大屏</span>
          </template>
          <div class="pending-list">
            <div
              v-for="item in pendingCards"
              :key="item.key"
              class="pending-item"
              @click="router.push(item.path)"
            >
              <div class="pending-left">
                <div class="pending-label">{{ item.label }}</div>
              <div class="pending-count" :style="{ color: item.color }">
                {{ pendingCounts[item.key as keyof typeof pendingCounts] }}
              </div>
              </div>
              <el-icon class="pending-arrow"><ArrowRight /></el-icon>
            </div>
            <div class="pending-item data-screen-row">
              <div class="pending-left">
                <div class="pending-label">数据大屏</div>
                <div class="pending-desc">实时数据统计与可视化</div>
              </div>
              <el-button type="primary" @click="router.push('/screenpreview')">数据展示</el-button>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<style scoped>
.dashboard {
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

.overview-row {
  margin-bottom: 24px;
}

.stat-card {
  text-align: center;
  border-radius: 12px;
  border: none;
}

.stat-label {
  font-size: 14px;
  color: var(--card-color);
  margin-bottom: 12px;
  font-weight: 500;
}

.stat-value {
  font-size: 32px;
  font-weight: 700;
  letter-spacing: -0.5px;
  color: var(--card-color);
}

.chart-card,
.pending-card {
  height: 100%;
  border-radius: 12px;
}

.chart-card :deep(.el-card__header),
.pending-card :deep(.el-card__header) {
  background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
  border-bottom: 1px solid #e2e8f0;
  padding: 16px 20px;
  font-weight: 600;
  color: #1a1a2e;
}

.empty-tip {
  text-align: center;
  color: #94a3b8;
  padding: 60px 0;
  font-size: 14px;
}

.pending-list {
  display: flex;
  flex-direction: column;
}

.pending-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px;
  border-bottom: 1px solid #e2e8f0;
  cursor: pointer;
  transition: all 0.25s ease;
  border-radius: 8px;
  margin: -4px -8px;
}

.pending-item:hover {
  background: linear-gradient(135deg, rgba(23, 98, 251, 0.04) 0%, rgba(23, 98, 251, 0.08) 100%);
}

.pending-item:last-child {
  border-bottom: none;
}

.data-screen-row {
  cursor: default;
}

.data-screen-row:hover {
  background: transparent;
  margin: -4px -8px;
  transform: none;
}

.pending-desc {
  font-size: 13px;
  color: #64748b;
  margin-top: 4px;
}

.pending-label {
  font-size: 14px;
  color: #475569;
  font-weight: 500;
}

.pending-count {
  font-size: 28px;
  font-weight: 700;
  margin-top: 6px;
  letter-spacing: -0.5px;
}

.pending-arrow {
  color: #cbd5e1;
  font-size: 18px;
  transition: all 0.25s ease;
}

.pending-item:hover .pending-arrow {
  color: #1762FB;
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
  text-transform: none;
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

:deep(.el-table__row:hover > td.el-table__cell) {
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

/* 趋势表格专用样式 */
.trend-table {
  width: 100%;
  margin: 0 -4px;
}

.trend-table :deep(.el-table__header-wrapper) {
  border-radius: 10px 10px 0 0;
}

.trend-table :deep(.el-table__body-wrapper) {
  border-radius: 0 0 10px 10px;
}

.date-cell {
  font-variant-numeric: tabular-nums;
  font-weight: 500;
  color: #475569;
  letter-spacing: 0.2px;
}

.num-cell {
  font-variant-numeric: tabular-nums;
  font-weight: 600;
  color: #1a1a2e;
  font-size: 14px;
}

.num-zero {
  color: #cbd5e1;
  font-weight: 400;
}
</style>
