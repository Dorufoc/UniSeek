<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getTaskById, type TaskVO } from '@/api/task'
import { apply, type TaskApplication } from '@/api/application'
import { getRealNameAuthStatus } from '@/api/auth'
import { addFavorite, removeFavorite } from '@/api/favorite'
import { ElMessage, ElMessageBox } from 'element-plus'
import { WarningFilled } from '@element-plus/icons-vue'
import { useUserStore } from '@/stores/user'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const loading = ref(true)
const error = ref('')
const job = ref<TaskVO | null>(null)
const hasApplied = ref(false)
const applying = ref(false)
const contacting = ref(false)
const favoriting = ref(false)

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

const salaryRangeText = (min: number, max: number, unit: number): string => {
  if (min === 0 && max === 0) return '面议'
  return `${formatSalary(min)}-${formatSalary(max)}/${salaryUnitLabel(unit)}`
}

const jobTypeLabel = (type: number) => {
  const map: Record<number, string> = { 1: '全职', 2: '兼职', 3: '实习' }
  return map[type] || '未分类'
}

const statusLabel = (status: number) => {
  const map: Record<number, string> = { 0: '待审核', 1: '招聘中', 2: '已满员', 3: '已过期', 4: '已下架', 5: '已驳回' }
  return map[status] || '未知'
}

const statusColor = (status: number) => {
    const map: Record<number, string> = {
      0: '#f39c12', 1: '#27ae60', 2: '#7f8c8d', 3: '#e74c3c', 4: '#95a5a6', 5: '#e74c3c'
    }
  return map[status] || '#7f8c8d'
}

const formatDate = (dateStr: string | null | undefined): string => {
  if (!dateStr) return '未设置'
  return dateStr.replace('T', ' ').substring(0, 16)
}

const goToTag = (tag: string) => {
  router.push({ path: '/jobs', query: { tag } })
}

const goToCategory = () => {
  if (job.value?.categoryId) {
    router.push({ path: '/jobs', query: { categoryId: job.value.categoryId } })
  }
}

const handleApplyWithAuthCheck = async () => {
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

  try {
    const status = await getRealNameAuthStatus() as unknown as { isAuth: boolean }
    if (!status || !status.isAuth) {
      ElMessageBox.confirm(
        '投递职位前需要先完成实名认证，是否前往认证？',
        '实名认证提示',
        {
          confirmButtonText: '前往认证',
          cancelButtonText: '取消',
          type: 'warning'
        }
      ).then(() => {
        router.push('/profile?tab=realNameAuth')
      }).catch(() => {})
      return
    }
  } catch {
    // 忽略查询实名状态失败，交由后续投递逻辑处理
  }

  applying.value = true
  try {
    const application = await apply({ taskId: job.value.id }) as unknown as TaskApplication
    ElMessage.success('投递成功')
    hasApplied.value = true
    if (application && application.id) {
      job.value.applicationId = application.id
    }
    const updated = await getTaskById(job.value.id)
    if (updated) job.value = updated
  } catch {
    /* 错误已在拦截器处理 */
  } finally {
    applying.value = false
  }
}

const handleApply = handleApplyWithAuthCheck

/**
 * 联系 HR：未投递时先创建投递记录（生成会话），然后跳转聊天页
 */
const handleContactHr = async () => {
  if (!isLoggedIn.value) {
    ElMessage.warning('请先登录')
    router.push('/login')
    return
  }
  if (!isSeeker.value) {
    ElMessage.warning('仅求职者可联系 HR')
    return
  }
  if (!job.value) return

  contacting.value = true
  try {
    let applicationId = job.value.applicationId
    // 未投递时先自动投递，系统会在投递成功后创建会话
    if (!hasApplied.value || !applicationId) {
      const application = await apply({ taskId: job.value.id }) as unknown as TaskApplication
      if (application && application.id) {
        applicationId = application.id
        hasApplied.value = true
        job.value.applicationId = application.id
        job.value.hasApplied = true
      }
    }
    if (applicationId) {
      router.push(`/chat/${applicationId}`)
    } else {
      ElMessage.warning('会话创建失败，请稍后重试')
    }
  } catch {
    /* 错误已在拦截器处理 */
  } finally {
    contacting.value = false
  }
}

const handleToggleFavorite = async () => {
  if (!isLoggedIn.value) {
    ElMessage.warning('请先登录')
    router.push('/login')
    return
  }
  if (!job.value) return
  favoriting.value = true
  try {
    if (job.value.hasFavorited) {
      await removeFavorite(job.value.id)
      job.value.hasFavorited = false
      ElMessage.success('已取消收藏')
    } else {
      await addFavorite(job.value.id)
      job.value.hasFavorited = true
      ElMessage.success('收藏成功')
    }
  } catch {
    /* 错误已在拦截器处理 */
  } finally {
    favoriting.value = false
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
    const data = await getTaskById(id) as unknown as TaskVO | null
    if (!data) {
      error.value = '职位不存在或已删除'
    } else if (data.status !== 1 && !data.isOwner) {
      // 非招聘中的职位不对外展示详情（HR 本人发布的岗位始终可见）
      error.value = '当前岗位暂未开放'
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
      <el-icon :size="48" class="error-icon"><WarningFilled /></el-icon>
      <h3>{{ error }}</h3>
      <button class="back-btn" @click="router.back()">返回</button>
    </div>

    <!-- 正常内容 -->
    <div class="detail-body" v-else-if="job">
      <button class="top-back-btn" @click="router.back()">&larr; 返回</button>

      <div class="detail-layout">
        <!-- 左侧：职位详细信息 -->
        <div class="detail-main">
          <div class="detail-header">
            <div class="header-top">
              <h1 class="job-title">{{ job.title }}</h1>
              <span class="job-salary-header">
              {{ salaryRangeText(job.salaryMin, job.salaryMax, job.salaryUnit) }}
              </span>
            </div>
            <div class="header-meta">
              <span class="meta-tag" v-if="job.address">{{ job.address }}</span>
              <span class="meta-tag">{{ jobTypeLabel(job.jobType) }}</span>
              <span class="meta-tag category-clickable" v-if="job.categoryName" @click="goToCategory">{{ job.categoryName }}</span>
              <span
                class="meta-tag status-tag"
                :style="{ background: statusColor(job.status) + '18', color: statusColor(job.status), borderColor: statusColor(job.status) + '40' }"
              >{{ statusLabel(job.status) }}</span>
            </div>
          </div>

          <div class="tag-section" v-if="job.tag && job.tag.length > 0">
            <span class="tag-item" v-for="(t, i) in job.tag" :key="i" @click="goToTag(t)">{{ t }}</span>
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
              {{ salaryRangeText(job.salaryMin, job.salaryMax, job.salaryUnit) }}
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
          <div class="company-card" @click="router.push(`/company?id=${job.enterpriseId}`)" style="cursor: pointer;">
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

          <!-- 求职者：未登录 -->
          <button
            v-if="!isLoggedIn"
            class="apply-btn"
            @click="router.push('/login')"
          >
            登录后投递
          </button>

          <!-- 求职者：已登录但非求职者角色 -->
          <button
            v-else-if="!isSeeker && isLoggedIn"
            class="apply-btn disabled"
            disabled
          >
            仅限求职者
          </button>

          <!-- 求职者：职位不在招聘中 -->
          <button
            v-else-if="job.status !== 1"
            class="apply-btn disabled"
            disabled
          >
            {{ statusLabel(job.status) }}
          </button>

          <!-- 求职者：招聘中 -->
          <template v-else>
            <button
              v-if="!hasApplied"
              class="apply-btn"
              :disabled="applying"
              @click="handleApply"
            >
              {{ applying ? '投递中...' : '立即投递' }}
            </button>
            <button
              v-else
              class="apply-btn applied"
              disabled
            >
              已投递
            </button>
            <button
              class="apply-btn contact-btn"
              :disabled="contacting"
              @click="handleContactHr"
            >
              {{ contacting ? '正在进入聊天...' : '联系 HR' }}
            </button>
            <button
              class="apply-btn fav-btn"
              :class="{ favorited: job.hasFavorited }"
              :disabled="favoriting"
              @click="handleToggleFavorite"
            >
              {{ favoriting ? '处理中...' : (job.hasFavorited ? '已收藏' : '收藏职位') }}
            </button>
          </template>
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
  color: #1762FB;
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

.category-clickable { cursor: pointer; transition: all 0.2s; }
.category-clickable:hover { border-color: #1762FB; color: #1762FB; }

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
  background: rgba(23, 98, 251, 0.06);
  color: #1762FB;
  border-radius: 20px;
  cursor: pointer;
  transition: background 0.2s;
}

.tag-item:hover {
  background: rgba(23, 98, 251, 0.14);
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
  background: linear-gradient(135deg, #1762FB, #5856d6);
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
  background: #1762FB;
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

.apply-btn.contact-btn {
  background: #fff;
  color: #1762FB;
  border: 1px solid #1762FB;
}

.apply-btn.contact-btn:hover:not(:disabled) {
  background: rgba(23, 98, 251, 0.06);
}

.apply-btn.fav-btn {
  background: #fff;
  color: #e67e22;
  border: 1px solid #e67e22;
  font-size: 15px;
}

.apply-btn.fav-btn:hover:not(:disabled) {
  background: rgba(230, 126, 34, 0.06);
}

.apply-btn.fav-btn.favorited {
  background: #e67e22;
  color: #fff;
  border-color: #e67e22;
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
  border-top: 3px solid #1762FB;
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
  background: #1762FB;
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
  color: #1762FB;
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
