<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getTaskById, type TaskVO } from '@/api/task'
import { apply } from '@/api/application'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/stores/user'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const loading = ref(true)
const error = ref('')
const job = ref<TaskVO | null>(null)
const hasApplied = ref(false)
const applying = ref(false)

const isSeeker = computed(() => userStore.userInfo?.role === 0)
const isLoggedIn = computed(() => userStore.isLoggedIn)

const formatSalary = (val: number): string => {
  if (!val && val !== 0) return '面议'
  if (val >= 1000) {
    const k = val / 1000
    return k % 1 === 0 ? k + 'K' : k.toFixed(1) + 'K'
  }
  return String(val)
}

const salaryUnitLabel = (unit: number) => {
  if (unit === 0) return '日'
  if (unit === 1) return '时'
  if (unit === 2) return '月'
  return '月'
}

const jobTypeLabel = (type: number) => {
  const map: Record<number, string> = { 1: '全职', 2: '兼职', 3: '实习' }
  return map[type] || '未分类'
}

const statusLabel = (status: number) => {
  const map: Record<number, string> = { 0: '待审核', 1: '招聘中', 2: '已满员', 3: '已过期', 4: '已下架' }
  return map[status] || '未知'
}

const statusColor = (status: number) => {
  const map: Record<number, string> = {
    0: '#f39c12', 1: '#27ae60', 2: '#7f8c8d', 3: '#e74c3c', 4: '#95a5a6'
  }
  return map[status] || '#7f8c8d'
}

const formatDate = (dateStr: string): string => {
  if (!dateStr) return '未设置'
  return dateStr.replace('T', ' ').substring(0, 16)
}

const handleApply = async () => {
  if (!isLoggedIn.value) {
    ElMessage.warning('请先登录')
    router.push('/login')
    return
  }
  if (!isSeeker.value) {
    ElMessage.warning('仅求职者可投递简历')
    return
  }
  if (hasApplied.value) {
    ElMessage.info('您已投递过该职位')
    return
  }
  if (!job.value) return

  applying.value = true
  try {
    await apply({ taskId: job.value.id })
    ElMessage.success('投递成功')
    hasApplied.value = true
    const updated = await getTaskById(job.value.id)
    if (updated) job.value = updated
  } catch {
    /* 错误已在拦截器处理 */
  } finally {
    applying.value = false
  }
}

const descriptionParagraphs = computed(() => {
  if (!job.value?.description) return []
  return job.value.description.split('\n').filter(s => s.trim())
})

onMounted(async () => {
  const id = Number(route.params.id)
  if (!id || isNaN(id)) {
    error.value = '无效的职位ID'
    loading.value = false
    return
  }
  try {
    const data = await getTaskById(id)
    if (!data) {
      error.value = '职位不存在或已删除'
    } else {
      job.value = data
      hasApplied.value = data.hasApplied || false
    }
  } catch (e) {
    error.value = '加载失败，请检查网络或登录状态'
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="detail-page">
    <!-- 加载中 -->
    <div class="loading-state" v-if="loading">
      <div class="loading-spinner"></div>
      <p>加载职位信息...</p>
    </div>

    <!-- 错误状态 -->
    <div class="error-state" v-else-if="error">
      <div class="error-icon">⚠️</div>
      <h3>{{ error }}</h3>
      <button class="back-btn" @click="router.back()">返回</button>
    </div>

    <!-- 正常内容 -->
    <div class="detail-body" v-else-if="job">
      <button class="top-back-btn" @click="router.push(`/company?id=${job.enterpriseId}`)">&larr; 返回公司</button>

      <div class="detail-layout">
        <!-- 左侧：职位详细信息 -->
        <div class="detail-main">
          <div class="detail-header">
            <div class="header-top">
              <h1 class="job-title">{{ job.title }}</h1>
              <span class="job-salary-header">
                {{ formatSalary(job.salaryMin) }}-{{ formatSalary(job.salaryMax) }}
                <small v-if="job.salaryMin || job.salaryMax">/{{ salaryUnitLabel(job.salaryUnit) }}</small>
              </span>
            </div>
            <div class="header-meta">
              <span class="meta-tag" v-if="job.address">{{ job.address }}</span>
              <span class="meta-tag">{{ jobTypeLabel(job.jobType) }}</span>
              <span class="meta-tag" v-if="job.categoryName">{{ job.categoryName }}</span>
              <span
                class="meta-tag status-tag"
                :style="{ background: statusColor(job.status) + '18', color: statusColor(job.status), borderColor: statusColor(job.status) + '40' }"
              >{{ statusLabel(job.status) }}</span>
            </div>
          </div>

          <div class="tag-section" v-if="job.tag && job.tag.length > 0">
            <span class="tag-item" v-for="(t, i) in job.tag" :key="i">{{ t }}</span>
          </div>

          <div class="info-grid">
            <div class="info-item">
              <span class="info-label">公司名称</span>
              <span class="info-value">{{ job.enterpriseName || '未填写' }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">工作类型</span>
              <span class="info-value">{{ jobTypeLabel(job.jobType) }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">薪资</span>
              <span class="info-value">
                {{ formatSalary(job.salaryMin) }}-{{ formatSalary(job.salaryMax) }}
                <span v-if="job.salaryMin || job.salaryMax">/{{ salaryUnitLabel(job.salaryUnit) }}</span>
              </span>
            </div>
            <div class="info-item">
              <span class="info-label">招聘人数</span>
              <span class="info-value">{{ job.remainingQuota ?? 0 }}/{{ job.totalQuota ?? 0 }}人</span>
            </div>
            <div class="info-item">
              <span class="info-label">工作地点</span>
              <span class="info-value">{{ job.address || '未填写' }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">截止时间</span>
              <span class="info-value">{{ formatDate(job.deadline) }}</span>
            </div>
          </div>

          <div class="desc-section">
            <h3>职位描述</h3>
            <div class="desc-content" v-if="descriptionParagraphs.length > 0">
              <p v-for="(p, i) in descriptionParagraphs" :key="i">{{ p }}</p>
            </div>
            <p class="desc-empty" v-else>暂无详细描述</p>
          </div>
        </div>

        <!-- 右侧：企业卡片 + 投递 -->
        <div class="detail-sidebar">
          <div class="company-card">
            <div class="company-header">
              <div class="company-avatar">{{ (job.enterpriseName || '企')[0] }}</div>
              <div class="company-info">
                <h4>{{ job.enterpriseName || '未知企业' }}</h4>
                <span class="company-tag">已认证</span>
              </div>
            </div>
            <div class="company-stats">
              <div class="stat-item">
                <span class="stat-num">{{ job.applicationCount || 0 }}</span>
                <span class="stat-label">投递人数</span>
              </div>
              <div class="stat-item">
                <span class="stat-num">{{ job.totalQuota || 0 }}</span>
                <span class="stat-label">招聘名额</span>
              </div>
              <div class="stat-item">
                <span class="stat-num">{{ job.remainingQuota ?? 0 }}</span>
                <span class="stat-label">剩余名额</span>
              </div>
            </div>
          </div>

          <button
            v-if="isSeeker && job.status === 1 && !hasApplied"
            class="apply-btn"
            :disabled="applying"
            @click="handleApply"
          >
            {{ applying ? '投递中...' : '立即投递' }}
          </button>
          <button
            v-else-if="hasApplied"
            class="apply-btn applied"
            disabled
          >
            已投递
          </button>
          <button
            v-else-if="job.status !== 1"
            class="apply-btn disabled"
            disabled
          >
            {{ statusLabel(job.status) }}
          </button>
          <button
            v-else-if="!isSeeker && isLoggedIn"
            class="apply-btn disabled"
            disabled
          >
            仅限求职者
          </button>
          <button
            v-else-if="!isLoggedIn"
            class="apply-btn"
            @click="router.push('/login')"
          >
            登录后投递
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.detail-page {
  min-height: calc(100vh - 60px);
  background: #f5f7fa;
}

.detail-body {
  max-width: 1100px;
  margin: 0 auto;
  padding: 16px 24px 40px;
}

.breadcrumb {
  padding: 12px 0;
  font-size: 13px;
  color: #999;
}

.breadcrumb a {
  color: #007AFF;
  text-decoration: none;
}

.breadcrumb .sep {
  margin: 0 8px;
  color: #ccc;
}

.detail-layout {
  display: flex;
  gap: 20px;
  align-items: flex-start;
}

.detail-main {
  flex: 1;
  min-width: 0;
}

.detail-header {
  background: #fff;
  border-radius: 12px;
  padding: 28px 28px 20px;
  box-shadow: 0 1px 4px rgba(0,0,0,0.06);
}

.header-top {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 20px;
  margin-bottom: 14px;
}

.job-title {
  font-size: 24px;
  font-weight: 700;
  color: #1a1a2e;
  margin: 0;
  line-height: 1.4;
}

.job-salary-header {
  font-size: 24px;
  font-weight: 700;
  color: #e74c3c;
  white-space: nowrap;
}

.job-salary-header small {
  font-size: 14px;
  font-weight: 500;
  color: #e74c3c;
}

.header-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.meta-tag {
  padding: 4px 14px;
  font-size: 13px;
  border: 1px solid #e4e6ef;
  border-radius: 20px;
  color: #666;
  background: #f8f9fc;
}

.status-tag {
  font-weight: 500;
}

.tag-section {
  background: #fff;
  border-radius: 0 0 12px 12px;
  padding: 0 28px 20px;
  margin-top: -2px;
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.tag-item {
  padding: 5px 14px;
  font-size: 13px;
  background: rgba(0, 122, 255, 0.06);
  color: #007AFF;
  border-radius: 20px;
}

.info-grid {
  background: #fff;
  border-radius: 12px;
  margin-top: 12px;
  padding: 20px 28px;
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  box-shadow: 0 1px 4px rgba(0,0,0,0.06);
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.info-label {
  font-size: 12px;
  color: #999;
}

.info-value {
  font-size: 15px;
  color: #1a1a2e;
  font-weight: 500;
}

.desc-section {
  background: #fff;
  border-radius: 12px;
  margin-top: 12px;
  padding: 24px 28px;
  box-shadow: 0 1px 4px rgba(0,0,0,0.06);
}

.desc-section h3 {
  font-size: 18px;
  font-weight: 600;
  color: #1a1a2e;
  margin: 0 0 16px;
  padding-bottom: 12px;
  border-bottom: 1px solid #f0f0f5;
}

.desc-content p {
  font-size: 15px;
  color: #444;
  line-height: 1.8;
  margin: 0 0 12px;
}

.desc-empty {
  color: #bbb;
  font-size: 14px;
}

.detail-sidebar {
  width: 320px;
  flex-shrink: 0;
  position: sticky;
  top: 80px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.company-card {
  background: #fff;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 1px 4px rgba(0,0,0,0.06);
}

.company-header {
  display: flex;
  align-items: center;
  gap: 14px;
  padding-bottom: 16px;
  border-bottom: 1px solid #f0f0f5;
}

.company-avatar {
  width: 52px;
  height: 52px;
  border-radius: 10px;
  background: linear-gradient(135deg, #007AFF, #5856d6);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 22px;
  font-weight: 700;
  flex-shrink: 0;
}

.company-info h4 {
  font-size: 16px;
  font-weight: 600;
  color: #1a1a2e;
  margin: 0 0 6px;
}

.company-tag {
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 4px;
  background: rgba(39, 174, 96, 0.1);
  color: #27ae60;
}

.company-stats {
  display: flex;
  gap: 20px;
  padding-top: 14px;
}

.stat-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.stat-num {
  font-size: 18px;
  font-weight: 700;
  color: #1a1a2e;
}

.stat-label {
  font-size: 12px;
  color: #999;
}

.apply-btn {
  width: 100%;
  height: 48px;
  border: none;
  border-radius: 10px;
  font-size: 17px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;
  background: #007AFF;
  color: #fff;
}

.apply-btn:hover:not(:disabled) {
  background: #0062cc;
}

.apply-btn:disabled {
  cursor: not-allowed;
}

.apply-btn.applied {
  background: #27ae60;
}

.apply-btn.disabled {
  background: #bdc3c7;
  color: #fff;
}

.loading-state {
  text-align: center;
  padding: 120px 0;
  color: #bbb;
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 3px solid #f3f3f3;
  border-top: 3px solid #007AFF;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 16px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.error-state {
  text-align: center;
  padding: 120px 20px;
  background: #fff;
  max-width: 600px;
  margin: 40px auto;
  border-radius: 12px;
  box-shadow: 0 1px 4px rgba(0,0,0,0.06);
}

.error-icon {
  font-size: 48px;
  margin-bottom: 16px;
}

.error-state h3 {
  font-size: 18px;
  color: #666;
  margin: 0 0 20px;
}

.back-btn {
  padding: 10px 24px;
  background: #007AFF;
  color: #fff;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  cursor: pointer;
  transition: background 0.2s;
}

.back-btn:hover {
  background: #0062cc;
}

.top-back-btn {
  display: inline-block;
  padding: 6px 0;
  margin-bottom: 8px;
  font-size: 14px;
  color: #007AFF;
  background: none;
  border: none;
  cursor: pointer;
}

.top-back-btn:hover {
  color: #0056b3;
}

@media (max-width: 900px) {
  .detail-layout {
    flex-direction: column;
  }

  .detail-sidebar {
    width: 100%;
    position: static;
  }

  .job-title {
    font-size: 20px;
  }

  .job-salary-header {
    font-size: 20px;
  }

  .info-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>
