<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { getMyApplications, type TaskApplication } from '@/api/application'
import { getTaskById, type TaskVO } from '@/api/task'
import { listFavorites as fetchFavorites, removeFavorite } from '@/api/favorite'
import { useUserStore } from '@/stores/user'
import {
  ArrowLeft, Document, ChatLineSquare, Star, StarFilled,
  Clock, Check, Close, VideoCamera, MapLocation, Search, Warning
} from '@element-plus/icons-vue'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

// 根据 query 参数设置初始 tab
const activeTab = ref<'applications' | 'interviews' | 'favorites'>(
  (route.query.tab as any) === 'interviews' ? 'interviews'
  : (route.query.tab as any) === 'favorites' ? 'favorites'
  : 'applications'
)
const loading = ref(false)

// 投递记录数据
const applications = ref<TaskApplication[]>([])
const appTaskMap = ref<Record<number, TaskVO>>({})

// 收藏职位数据
const favorites = ref<TaskVO[]>([])

// 展开的投递记录ID
const expandedApp = ref<number | null>(null)

const toggleExpand = (id: number) => {
  expandedApp.value = expandedApp.value === id ? null : id
}

// 状态配置
const statusConfig: Record<number, { label: string; color: string; bg: string }> = {
  0: { label: '已投递', color: '#1762FB', bg: 'rgba(0,122,255,0.08)' },
  1: { label: '待面试', color: '#f0ad4e', bg: 'rgba(240,173,78,0.1)' },
  2: { label: '待定', color: '#909399', bg: 'rgba(144,147,153,0.1)' },
  3: { label: '已录用', color: '#2ecc71', bg: 'rgba(46,204,113,0.1)' },
  4: { label: '已淘汰', color: '#e74c3c', bg: 'rgba(231,76,60,0.1)' },
  5: { label: '已完成', color: '#8e44ad', bg: 'rgba(142,68,173,0.1)' }
}

// 格式化时间
const formatTime = (t: string) => {
  if (!t) return ''
  return t.replace('T', ' ').substring(0, 16)
}

// 加载投递记录
const loadApplications = async () => {
  loading.value = true
  try {
    const result = await getMyApplications(1, 50)
    applications.value = result.records
    await Promise.all(result.records.map(async (app) => {
      try {
        const task = await getTaskById(app.taskId)
        appTaskMap.value[app.taskId] = task
      } catch { /* 职位可能已删除 */ }
    }))
  } catch { /* API 失败 */ }
  await loadFavorites()
  loading.value = false
}

// 加载收藏职位
const loadFavorites = async () => {
  try {
    const result = await fetchFavorites(1, 50)
    favorites.value = result.records || []
  } catch { favorites.value = [] }
}

// 取消收藏
const toggleFavorite = async (task: TaskVO) => {
  try {
    await removeFavorite(task.id)
    favorites.value = favorites.value.filter(f => f.id !== task.id)
    ElMessage.success('已取消收藏')
  } catch { /* 错误已在拦截器处理 */ }
}

// 跳转到职位详情
const goToJob = (id: number) => {
  router.push(`/jobs/${id}`)
}

// 统计数字
const appStats = computed(() => {
  const total = applications.value.length
  const interviewing = applications.value.filter(a => a.status === 1).length
  const hired = applications.value.filter(a => a.status === 3).length
  return { total, interviewing, hired }
})

onMounted(() => {
  loadApplications()
})
</script>

<template>
  <div class="my-apps-page">
    <div class="page-container">
      <!-- 顶部标题栏 -->
      <div class="page-header">
        <h2 class="page-title">我的求职</h2>
      </div>

      <!-- Tab 导航 -->
      <div class="tab-bar">
        <button
          :class="['tab-item', { active: activeTab === 'applications' }]"
          @click="activeTab = 'applications'"
        >
          <el-icon :size="16"><Document /></el-icon>
          <span>投递记录</span>
          <span v-if="appStats.total" class="tab-count">{{ appStats.total }}</span>
        </button>
        <button
          :class="['tab-item', { active: activeTab === 'interviews' }]"
          @click="activeTab = 'interviews'"
        >
          <el-icon :size="16"><VideoCamera /></el-icon>
          <span>面试邀请</span>
          <span v-if="appStats.interviewing" class="tab-count highlight">{{ appStats.interviewing }}</span>
        </button>
        <button
          :class="['tab-item', { active: activeTab === 'favorites' }]"
          @click="activeTab = 'favorites'"
        >
          <el-icon :size="16"><StarFilled /></el-icon>
          <span>收藏职位</span>
          <span v-if="favorites.length" class="tab-count">{{ favorites.length }}</span>
        </button>
      </div>

      <!-- 投递记录 Tab -->
      <template v-if="activeTab === 'applications'">
        <!-- 统计卡片 -->
        <div v-if="applications.length" class="stats-row">
          <div class="stat-card">
            <span class="stat-num">{{ appStats.total }}</span>
            <span class="stat-label">全部投递</span>
          </div>
          <div class="stat-card interviewing">
            <span class="stat-num">{{ appStats.interviewing }}</span>
            <span class="stat-label">待面试</span>
          </div>
          <div class="stat-card hired">
            <span class="stat-num">{{ appStats.hired }}</span>
            <span class="stat-label">已录用</span>
          </div>
        </div>

        <!-- 列表 -->
        <div v-if="applications.length" class="app-list">
          <div
            v-for="app in applications"
            :key="app.id"
            class="app-card"
            :class="{ expanded: expandedApp === app.id }"
          >
            <!-- 卡片头部 -->
            <div class="app-card-header" @click="toggleExpand(app.id)">
              <div class="app-card-left">
                <h4 class="app-job-title">
                  {{ appTaskMap[app.taskId]?.title || '职位 #' + app.taskId }}
                </h4>
                <p class="app-company">
                  {{ appTaskMap[app.taskId]?.enterpriseName || '未知企业' }}
                </p>
              </div>
              <div class="app-card-right">
                <span
                  class="status-badge"
                  :style="{ color: statusConfig[app.status]?.color, background: statusConfig[app.status]?.bg }"
                >
                  {{ statusConfig[app.status]?.label || '未知' }}
                </span>
                <span class="app-time">{{ formatTime(app.createTime) }}</span>
              </div>
            </div>

            <!-- 展开详情 -->
            <div v-if="expandedApp === app.id" class="app-card-detail">
              <div class="detail-grid">
                <div class="detail-item">
                  <span class="detail-label">投递时间</span>
                  <span class="detail-value">{{ formatTime(app.createTime) }}</span>
                </div>
                <div v-if="app.interviewTime" class="detail-item">
                  <span class="detail-label">面试时间</span>
                  <span class="detail-value highlight">{{ formatTime(app.interviewTime) }}</span>
                </div>
                <div v-if="app.interviewLocation" class="detail-item">
                  <span class="detail-label">面试地点</span>
                  <span class="detail-value">{{ app.interviewLocation }}</span>
                </div>
                <div v-if="app.rejectReason" class="detail-item">
                  <span class="detail-label">淘汰原因</span>
                  <span class="detail-value danger">{{ app.rejectReason }}</span>
                </div>
                <div v-if="app.hrNote" class="detail-item full-width">
                  <span class="detail-label">HR备注</span>
                  <span class="detail-value note">{{ app.hrNote }}</span>
                </div>
              </div>

              <div class="detail-actions">
                <button class="action-btn" @click.stop="goToJob(app.taskId)">
                  <el-icon :size="14"><Search /></el-icon> 查看职位
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- 空状态 -->
        <div v-else class="empty-state">
          <el-icon :size="48" class="empty-icon"><Document /></el-icon>
          <p class="empty-title">还没有投递记录</p>
          <p class="empty-desc">去发现心仪的职位，立即投递吧</p>
          <button class="empty-action" @click="router.push('/jobs')">浏览职位</button>
        </div>
      </template>

      <!-- 面试邀请 Tab -->
      <template v-if="activeTab === 'interviews'">
        <div v-if="applications.filter(a => a.status === 1).length" class="interview-list">
          <div
            v-for="app in applications.filter(a => a.status === 1)"
            :key="'int-' + app.id"
            class="interview-card"
          >
            <div class="interview-icon">
              <el-icon :size="22"><VideoCamera /></el-icon>
            </div>
            <div class="interview-body">
              <h4 class="interview-title">{{ appTaskMap[app.taskId]?.title || '职位 #' + app.taskId }}</h4>
              <p class="interview-content">
                面试时间：{{ formatTime(app.interviewTime) || '待定' }}<br/>
                面试地点：{{ app.interviewLocation || '待定' }}
              </p>
              <span class="interview-time">{{ formatTime(app.updateTime) }}</span>
            </div>
            <div class="interview-action">
              <button class="action-btn primary" @click="goToJob(app.taskId)">查看详情</button>
            </div>
          </div>
        </div>

        <div v-else class="empty-state">
          <el-icon :size="48" class="empty-icon"><VideoCamera /></el-icon>
          <p class="empty-title">暂无面试邀请</p>
          <p class="empty-desc">投递简历后，HR会对合适的候选人发送面试邀请</p>
        </div>
      </template>

      <!-- 收藏职位 Tab -->
      <template v-if="activeTab === 'favorites'">
        <div v-if="favorites.length" class="favorite-list">
          <div
            v-for="task in favorites"
            :key="task.id"
            class="favorite-card"
            @click="goToJob(task.id)"
          >
            <div class="fav-card-main">
              <h4 class="fav-title">{{ task.title }}</h4>
              <p class="fav-company">{{ task.enterpriseName }}</p>
              <div class="fav-tags">
                <span class="fav-tag salary">{{ task.salaryMin === 0 && task.salaryMax === 0 ? '面议' : '¥' + task.salaryMin + '-' + task.salaryMax + '/' + (task.salaryUnit === 1 ? '日' : task.salaryUnit === 2 ? '时' : '月') }}</span>
                <span class="fav-tag type">{{ task.jobType === 1 ? '全职' : task.jobType === 2 ? '兼职' : '实习' }}</span>
                <span class="fav-tag" v-if="task.address">{{ task.address }}</span>
              </div>
            </div>
            <button class="fav-btn" @click.stop="toggleFavorite(task)">
              <el-icon :size="20" color="#f0ad4e">
                <StarFilled />
              </el-icon>
            </button>
          </div>
        </div>

        <div v-else class="empty-state">
          <el-icon :size="48" class="empty-icon"><Star /></el-icon>
          <p class="empty-title">还没有收藏职位</p>
          <p class="empty-desc">浏览职位时点击星标，即可收藏心仪职位</p>
          <button class="empty-action" @click="router.push('/jobs')">去发现职位</button>
        </div>
      </template>
    </div>
  </div>
</template>

<style scoped>
.my-apps-page {
  min-height: calc(100vh - 60px);
  background: #f5f7fa;
  padding: 24px;
  box-sizing: border-box;
}

.page-container {
  max-width: 900px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 20px;
}

.page-title {
  font-size: 22px;
  font-weight: 700;
  color: #1a1a1a;
  margin: 0;
}

/* Tab 导航 */
.tab-bar {
  display: flex;
  background: #fff;
  border-radius: 12px;
  padding: 4px;
  margin-bottom: 16px;
  box-shadow: 0 1px 4px rgba(0,0,0,0.06);
}

.tab-item {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 12px 16px;
  font-size: 14px;
  color: #666;
  background: transparent;
  border: none;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s;
}

.tab-item:hover {
  color: #1762FB;
  background: rgba(0,122,255,0.05);
}

.tab-item.active {
  color: #1762FB;
  background: rgba(0,122,255,0.08);
  font-weight: 500;
}

.tab-count {
  font-size: 12px;
  padding: 1px 7px;
  background: #f0f0f5;
  border-radius: 10px;
  color: #666;
}

.tab-count.highlight {
  background: rgba(240,173,78,0.15);
  color: #f0ad4e;
}

/* 统计卡片 */
.stats-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
  margin-bottom: 16px;
}

.stat-card {
  background: #fff;
  border-radius: 10px;
  padding: 16px;
  text-align: center;
  box-shadow: 0 1px 4px rgba(0,0,0,0.06);
}

.stat-num {
  display: block;
  font-size: 28px;
  font-weight: 700;
  color: #1762FB;
  margin-bottom: 4px;
}

.stat-card.interviewing .stat-num { color: #f0ad4e; }
.stat-card.hired .stat-num { color: #2ecc71; }

.stat-label {
  font-size: 13px;
  color: #555;
}

/* 投递列表 */
.app-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.app-card {
  background: #fff;
  border-radius: 10px;
  box-shadow: 0 1px 4px rgba(0,0,0,0.06);
  overflow: hidden;
  transition: box-shadow 0.2s;
}

.app-card:hover {
  box-shadow: 0 2px 12px rgba(0,0,0,0.08);
}

.app-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 20px;
  cursor: pointer;
}

.app-card-left {
  min-width: 0;
  flex: 1;
}

.app-job-title {
  font-size: 16px;
  font-weight: 600;
  color: #1a1a1a;
  margin: 0 0 4px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.app-company {
  font-size: 13px;
  color: #555;
  margin: 0;
}

.app-card-right {
  text-align: right;
  min-width: 100px;
}

.status-badge {
  display: inline-block;
  padding: 3px 10px;
  font-size: 12px;
  font-weight: 500;
  border-radius: 12px;
  margin-bottom: 4px;
}

.app-time {
  display: block;
  font-size: 12px;
  color: #777;
}

/* 展开详情 */
.app-card-detail {
  border-top: 1px solid #f0f0f5;
  padding: 16px 20px;
  background: #fafbfc;
}

.detail-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.detail-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.detail-item.full-width {
  grid-column: span 2;
}

.detail-label {
  font-size: 12px;
  color: #666;
}

.detail-value {
  font-size: 14px;
  color: var(--text);
}

.detail-value.highlight { color: #1762FB; font-weight: 500; }
.detail-value.danger { color: #e74c3c; }
.detail-value.note { background: #fff; padding: 8px 12px; border-radius: 6px; border: 1px solid #f0f0f5; }

.detail-actions {
  margin-top: 14px;
  display: flex;
  gap: 10px;
}

.action-btn {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 7px 16px;
  font-size: 13px;
  color: #1762FB;
  background: rgba(0,122,255,0.06);
  border: 1px solid rgba(0,122,255,0.2);
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
}

.action-btn:hover { background: rgba(0,122,255,0.12); }
.action-btn.primary { color: #fff; background: #1762FB; border-color: #1762FB; }
.action-btn.primary:hover { background: #0066d6; }

/* 面试邀请 */
.interview-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.interview-card {
  background: #fff;
  border-radius: 10px;
  padding: 20px;
  display: flex;
  gap: 14px;
  box-shadow: 0 1px 4px rgba(0,0,0,0.06);
  align-items: flex-start;
}

.interview-icon {
  width: 44px;
  height: 44px;
  border-radius: 10px;
  background: rgba(240,173,78,0.1);
  color: #f0ad4e;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.interview-body {
  flex: 1;
  min-width: 0;
}

.interview-title {
  font-size: 15px;
  font-weight: 600;
  color: #1a1a1a;
  margin: 0 0 6px;
}

.interview-content {
  font-size: 14px;
  color: #333;
  line-height: 1.6;
  margin: 0 0 8px;
}

.interview-time {
  font-size: 12px;
  color: #777;
}

.interview-action {
  flex-shrink: 0;
  align-self: center;
}

/* 收藏列表 */
.favorite-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.favorite-card {
  background: #fff;
  border-radius: 10px;
  padding: 18px 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  box-shadow: 0 1px 4px rgba(0,0,0,0.06);
  cursor: pointer;
  transition: box-shadow 0.2s;
}

.favorite-card:hover {
  box-shadow: 0 2px 12px rgba(0,0,0,0.08);
}

.fav-card-main {
  min-width: 0;
  flex: 1;
}

.fav-title {
  font-size: 16px;
  font-weight: 600;
  color: #1a1a1a;
  margin: 0 0 4px;
}

.fav-company {
  font-size: 13px;
  color: #555;
  margin: 0 0 8px;
}

.fav-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.fav-tag {
  font-size: 12px;
  padding: 2px 8px;
  border-radius: 4px;
  background: #f0f0f5;
  color: #555;
}

.fav-tag.salary { color: #e74c3c; background: rgba(231,76,60,0.06); }
.fav-tag.type { color: #1762FB; background: rgba(0,122,255,0.06); }

.fav-btn {
  padding: 8px;
  border: none;
  background: transparent;
  cursor: pointer;
  flex-shrink: 0;
}

/* 空状态 */
.empty-state {
  text-align: center;
  padding: 60px 20px;
}

.empty-icon {
  color: #dcdce4;
  margin-bottom: 16px;
}

.empty-title {
  font-size: 16px;
  color: #999;
  margin: 0 0 8px;
}

.empty-desc {
  font-size: 14px;
  color: #bbb;
  margin: 0 0 20px;
}

.empty-action {
  padding: 10px 28px;
  font-size: 14px;
  color: #fff;
  background: #1762FB;
  border: none;
  border-radius: 20px;
  cursor: pointer;
}

.empty-action:hover {
  background: #0066d6;
}

/* 响应式 */
@media (max-width: 768px) {
  .my-apps-page { padding: 16px 12px; }
  .tab-item { padding: 10px 8px; font-size: 13px; gap: 4px; }
  .app-card-header { padding: 14px 16px; }
  .stats-row { grid-template-columns: repeat(3, 1fr); gap: 8px; }
  .stat-card { padding: 12px; }
  .stat-num { font-size: 22px; }
  .detail-grid { grid-template-columns: 1fr; }
  .detail-item.full-width { grid-column: span 1; }
}
</style>
