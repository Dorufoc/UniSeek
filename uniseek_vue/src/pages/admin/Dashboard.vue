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
  { label: '累计用户', key: 'totalUsers', color: '#409eff' },
  { label: '认证企业', key: 'totalEnterprises', color: '#67c23a' },
  { label: '招聘中职位', key: 'publishedTasks', color: '#e6a23c' },
  { label: '投递总数', key: 'totalApplications', color: '#f56c6c' }
]

const pendingCards = [
  { label: '待审核企业', key: 'pendingEnterprises', path: '/admin/enterprises', color: '#409eff' },
  { label: '待审核职位', key: 'pendingTasks', path: '/admin/tasks', color: '#e6a23c' }
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
        <el-card shadow="never" class="stat-card">
          <div class="stat-label">{{ card.label }}</div>
          <div class="stat-value" :style="{ color: card.color }">
            {{ summary[card.key] ?? 0 }}
          </div>
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
          <el-table v-else :data="dailyStats" size="small" v-loading="loading">
            <el-table-column prop="date" label="日期" width="120" />
            <el-table-column prop="newUsers" label="新增用户" width="100" align="center" />
            <el-table-column prop="newEnterprises" label="新增企业" width="100" align="center" />
            <el-table-column prop="newTasks" label="新增职位" width="100" align="center" />
            <el-table-column prop="newApplications" label="新增投递" width="100" align="center" />
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
  max-width: 1400px;
}

.page-title {
  font-size: 20px;
  font-weight: 600;
  color: #303133;
  margin: 0 0 20px;
}

.overview-row {
  margin-bottom: 16px;
}

.stat-card {
  text-align: center;
}

.stat-label {
  font-size: 13px;
  color: #909399;
  margin-bottom: 8px;
}

.stat-value {
  font-size: 28px;
  font-weight: 700;
}

.chart-card,
.pending-card {
  height: 100%;
}

.empty-tip {
  text-align: center;
  color: #909399;
  padding: 40px 0;
}

.pending-list {
  display: flex;
  flex-direction: column;
}

.pending-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 0;
  border-bottom: 1px solid #ebeef5;
  cursor: pointer;
  transition: background 0.2s;
}

.pending-item:last-child {
  border-bottom: none;
}

.data-screen-row {
  cursor: default;
}

.data-screen-row:hover {
  background: transparent;
  margin: 0;
  padding-left: 0;
  padding-right: 0;
}

.pending-desc {
  font-size: 12px;
  color: #606266;
  margin-top: 2px;
}

.pending-item:hover {
  background: #f5f7fa;
  margin: 0 -20px;
  padding-left: 20px;
  padding-right: 20px;
}

.pending-label {
  font-size: 13px;
  color: #606266;
}

.pending-count {
  font-size: 24px;
  font-weight: 700;
  margin-top: 4px;
}

.pending-arrow {
  color: #c0c4cc;
  font-size: 16px;
}


</style>
