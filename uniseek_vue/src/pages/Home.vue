<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useUserStore } from '@/stores/user'
import { searchTasks, getEnterpriseTasks, type TaskVO } from '@/api/task'
import { getTaskApplications, type TaskApplication } from '@/api/application'
import { getMyEnterprise, getHotEnterprises, type EnterpriseInfo, type HotEnterprise } from '@/api/enterprise'
import { getCategories, type CategoryVO } from '@/api/category'
import { initChatSession } from '@/api/chat'
import request from '@/api/index'
import { Search, Monitor, Briefcase, TrendCharts, ChatDotSquare, ChatDotRound, User, Brush, DataAnalysis, Files, KnifeFork, Notebook, Box, ShoppingBag, EditPen, Service, Van, Scissor, ToiletPaper, Camera } from '@element-plus/icons-vue'

const router = useRouter()
const appStore = useAppStore()
const userStore = useUserStore()

const isRecruiter = computed(() => userStore.userInfo?.role === 1)

const keyword = ref('')

// ── 搜索类型下拉 ──
const searchTypeOpen = ref(false)
const searchType = ref<'position' | 'company'>('position')
const searchTypeLabel = computed(() => searchType.value === 'position' ? '职位' : '公司')

const selectSearchType = (type: 'position' | 'company') => {
  searchType.value = type
  searchTypeOpen.value = false
}

const handleSearch = () => {
  searchTypeOpen.value = false
  appStore.setSearchKeyword(keyword.value)
  if (searchType.value === 'company') {
    router.push(`/company?q=${encodeURIComponent(keyword.value)}`)
  } else {
    router.push('/jobs')
  }
}

const quickSearch = (kw: string) => {
  keyword.value = kw
  appStore.setSearchKeyword(kw)
  if (searchType.value === 'company') {
    router.push(`/company?q=${encodeURIComponent(kw)}`)
  } else {
    router.push('/jobs')
  }
}

// ── 求职者首页数据 ──
const recommendJobs = ref<TaskVO[]>([])
const categoryTree = ref<CategoryVO[]>([])
const hotKeywords = computed(() =>
  searchType.value === 'position'
    ? categoryTree.value.filter(c => c.name !== '其他').slice(0, 10).map(c => c.name)
    : hotEnterprises.value.slice(0, 10).map(e => e.companyName)
)
const hotEnterprises = ref<HotEnterprise[]>([])

// ── 无限加载 ──
const seekerPage = ref(1)
const seekerLoading = ref(false)
const seekerHasMore = ref(true)
const seekerPageSize = 6
const sentinel = ref<HTMLElement | null>(null)
let observer: IntersectionObserver | null = null

const loadMoreJobs = async () => {
  if (seekerLoading.value || !seekerHasMore.value) return
  seekerLoading.value = true
  try {
    const result = await searchTasks({ pageSize: seekerPageSize, sortBy: 'popular', page: seekerPage.value })
    if (result.records.length < seekerPageSize) {
      seekerHasMore.value = false
    }
    recommendJobs.value.push(...result.records)
    seekerPage.value++
  } catch {
    seekerHasMore.value = false
  } finally {
    seekerLoading.value = false
  }
}

// ── 招聘者首页数据 ──
const enterprise = ref<EnterpriseInfo | null>(null)
interface JobWithApplicants {
  job: TaskVO
  applications: TaskApplication[]
}
const jobsWithApplicants = ref<JobWithApplicants[]>([])
const recruiterLoading = ref(false)

// 每个岗位的折叠状态（true=折叠，false=展开）
const collapsedJobs = ref<Record<number, boolean>>({})

const toggleCollapse = (jobId: number) => {
  collapsedJobs.value[jobId] = !collapsedJobs.value[jobId]
}

const isCollapsed = (jobId: number) => {
  return collapsedJobs.value[jobId] === true // 默认折叠
}

// 首页仅显示待处理状态的投递：0=已投递(待审核), 1=待面试, 2=待定
const ACTIVE_STATUSES = [0, 1, 2]

const goToJob = (id: number) => {
  router.push(`/jobs/${id}`)
}

const goToJobs = (categoryId?: number) => {
  if (categoryId) {
    appStore.setSearchKeyword('')
    router.push({ path: '/jobs', query: { categoryId } })
  } else {
    router.push('/jobs')
  }
}

/** HR 联系求职者：先确保会话存在，再跳转到消息页 */
const handleContact = async (appId: number) => {
  try {
    await initChatSession(appId)
  } catch {
    // 静默，已存在则跳过
  }
  router.push(`/messages?chat=${appId}`)
}

const formatSalary = (val: number): string => {
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
  return map[type] || ''
}

const statusLabel = (status: number) => {
  const map: Record<number, string> = { 0: '已投递', 1: '待面试', 2: '待定', 3: '已录用', 4: '已淘汰', 5: '已完成' }
  return map[status] || '未知'
}

const statusType = (status: number) => {
  if (status === 0) return ''
  if (status === 1) return 'warning'
  if (status === 2) return 'info'
  if (status === 3) return 'success'
  if (status === 4) return 'danger'
  if (status === 5) return ''
  return ''
}

// 解析简历快照
const parseSnapshot = (snapshot: string | null) => {
  if (!snapshot) return null
  try {
    return JSON.parse(snapshot)
  } catch {
    return null
  }
}

// 解析技能列表（支持 JSON 数组字符串 或 逗号分隔字符串）
const parseSkills = (skills: unknown): string[] => {
  if (!skills) return []
  if (Array.isArray(skills)) return skills
  if (typeof skills === 'string') {
    try {
      const parsed = JSON.parse(skills)
      return Array.isArray(parsed) ? parsed : []
    } catch {
      return skills.split(',').map(s => s.trim()).filter(Boolean)
    }
  }
  return []
}

// ── 简历发送状态检查 ──
// 记录每个投递记录中求职者是否曾通过聊天发送过简历（messageType=2）
const hasSentResumeMap = ref<Record<number, boolean>>({})

/** 批量检查所有求职者是否发送过简历 */
const checkSentResumes = async (allApps: { applicationId: number; applicantId: number }[]) => {
  const map: Record<number, boolean> = {}
  // 分批并发，每批最多 6 个
  const batchSize = 6
  for (let i = 0; i < allApps.length; i += batchSize) {
    const batch = allApps.slice(i, i + batchSize)
    await Promise.allSettled(
      batch.map(async ({ applicationId, applicantId }) => {
        try {
          const messages = await request.get<any, any[]>(
            `/chat/sessions/${applicationId}/messages`,
            { params: { pageSize: 20 }, _silent: true } as any
          )
          // 检查是否有求职者发出的类型为 2（简历文件）的消息
          const hasResume = messages.some(
            (msg: any) => msg.senderId === applicantId && msg.messageType === 2
          )
          if (hasResume) map[applicationId] = true
        } catch {
          // 无会话或获取失败，视为未发送
        }
      })
    )
  }
  hasSentResumeMap.value = map
}

const catColors = ['#1762FB', '#e74c3c', '#27ae60', '#f39c12', '#9b59b6', '#1abc9c', '#e67e22', '#3498db']
const catIcons = [Monitor, Briefcase, TrendCharts, ChatDotSquare, User, Brush, DataAnalysis, Files]

const categoryIconMap: Record<string, any> = {
  '餐饮服务': KnifeFork,
  '家教辅导': Notebook,
  '快递物流': Van,
  '促销导购': ShoppingBag,
  '翻译': ChatDotRound,
  '写作': EditPen,
  '客服': Service,
  '物流': Van,
  '美容美发': Scissor,
  '家政保洁': ToiletPaper,
  '摄影摄像': Camera,
  '话务客服': Service,
  '文案写作': EditPen,
}
const getCategoryIcon = (name: string, fallbackIdx: number) => {
  return categoryIconMap[name] || catIcons[fallbackIdx % catIcons.length]
}

interface StaggeredItem { cat: CategoryVO; originalIdx: number; uid: string }
const staggeredRows = computed(() => {
  const list = categoryTree.value
  const row1: StaggeredItem[] = []
  const row2: StaggeredItem[] = []
  list.forEach((c, i) => {
    const item: StaggeredItem = { cat: c, originalIdx: i, uid: String(c.id) }
    if (i % 2 === 0) row1.push(item)
    else row2.push(item)
  })
  return { row1, row2 }
})
const marqueeRow1 = computed(() => {
  const orig = staggeredRows.value.row1
  return [...orig, ...orig.map(item => ({ ...item, uid: 'd-' + item.uid }))]
})
const marqueeRow2 = computed(() => {
  const orig = staggeredRows.value.row2
  return [...orig, ...orig.map(item => ({ ...item, uid: 'd-' + item.uid }))]
})

const cardStyle = (idx: number) => {
  const color = catColors[idx % catColors.length]
  return {
    '--card-color': color,
    background: `linear-gradient(135deg, ${color}33, ${color}14)`
  }
}

const closeSearchTypeMenu = (e: MouseEvent) => {
  const target = e.target as HTMLElement
  if (!target.closest('.search-type-dropdown')) {
    searchTypeOpen.value = false
  }
}

onMounted(async () => {
  document.addEventListener('click', closeSearchTypeMenu)

  if (isRecruiter.value) {
    recruiterLoading.value = true
    try {
      enterprise.value = await getMyEnterprise()
      const taskPage = await getEnterpriseTasks(1, 100)
      const tasks = taskPage.records || []
      if (tasks.length > 0) {
        const results = await Promise.allSettled(
          tasks.map(async (job) => {
            try {
              const appPage = await getTaskApplications(job.id, 1, 100)
              return { job, applications: appPage.records || [] }
            } catch {
              return { job, applications: [] }
            }
          })
        )
        jobsWithApplicants.value = results
          .filter(r => r.status === 'fulfilled')
          .map(r => (r as PromiseFulfilledResult<JobWithApplicants>).value)

        // 投递加载完成后检查求职者是否发送过简历附件
        const allApps = jobsWithApplicants.value.flatMap(({ applications }) =>
          applications.map(app => ({ applicationId: app.id, applicantId: app.applicantId }))
        )
        checkSentResumes(allApps)
      }
    } catch {
      // 静默失败
    } finally {
      recruiterLoading.value = false
    }
  } else {
    // ── 求职者首页 ──
    const [cats] = await Promise.all([
      getCategories().catch(() => [] as CategoryVO[])
    ])
    hotEnterprises.value = await getHotEnterprises(12).catch(() => [])
    categoryTree.value = cats.filter(c => c.name !== '其他')

    // 首次加载推荐职位
    await loadMoreJobs()

    // 设置 IntersectionObserver 实现无限滚动
    observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting) {
          loadMoreJobs()
        }
      },
      { rootMargin: '200px' }
    )
    if (sentinel.value) {
      observer.observe(sentinel.value)
    }
  }
})

onUnmounted(() => {
  document.removeEventListener('click', closeSearchTypeMenu)
  if (observer) {
    observer.disconnect()
    observer = null
  }
})
</script>

<template>
  <div class="home-page">
    <!-- ────────────────── 招聘者首页 ────────────────── -->
    <template v-if="isRecruiter">
      <section class="recruiter-header">
        <div class="section-inner">
          <h1 class="company-name">{{ enterprise?.companyName || '我的企业' }}</h1>
          <p class="company-desc">以下是你所在企业发布的岗位及求职者投递情况</p>
        </div>
      </section>

      <section class="recruiter-dashboard">
        <div class="section-inner">
          <div v-if="recruiterLoading" class="loading-tip">加载中...</div>
          <div v-else-if="jobsWithApplicants.length === 0" class="empty-card">
            <h3>暂无岗位数据</h3>
            <p>还没有发布任何岗位，或没有求职者投递</p>
            <button
              v-if="enterprise?.auditStatus === 1"
              class="add-job-btn"
              @click="router.push('/post-job')"
            >
              添加新岗位
            </button>
          </div>
          <div v-else class="job-list">
            <div v-for="({ job, applications }) in jobsWithApplicants" :key="job.id" class="job-section">
              <div class="job-section-header" @click="toggleCollapse(job.id)">
                <div class="collapse-toggle">
                  <span :class="['collapse-arrow', { collapsed: !isCollapsed(job.id) }]">▾</span>
                </div>
                <div class="job-section-title">
                  <h3>{{ job.title }}</h3>
                  <span class="job-section-salary">{{ salaryRangeText(job.salaryMin, job.salaryMax, job.salaryUnit) }}</span>
                </div>
                <div class="job-section-meta">
                  <span class="job-section-type">{{ jobTypeLabel(job.jobType) }}</span>
                  <span class="job-section-address" v-if="job.address">{{ job.address }}</span>
                  <span class="applicant-count">{{ applications.length }} 人投递</span>
                </div>
                <button class="detail-btn" @click.stop="goToJob(job.id)">详情</button>
              </div>

              <div class="applicants-list" v-show="isCollapsed(job.id)">
                <template v-if="applications.length > 0">
                  <div
                    v-for="app in applications.filter(a => ACTIVE_STATUSES.includes(a.status))"
                    :key="app.id"
                    class="applicant-card"
                  >
                    <div class="applicant-info">
                      <div class="applicant-name">
                        {{ parseSnapshot(app.resumeSnapshot)?.realName || '未知' }}
                      </div>
                      <div class="applicant-detail">
                        <span v-if="parseSnapshot(app.resumeSnapshot)?.education">{{ parseSnapshot(app.resumeSnapshot)?.education }}</span>
                        <span v-if="parseSnapshot(app.resumeSnapshot)?.school">{{ parseSnapshot(app.resumeSnapshot)?.school }}</span>
                      </div>
                    <div class="applicant-skills" v-if="parseSkills(parseSnapshot(app.resumeSnapshot)?.skills).length > 0">
                      <span
                        v-for="skill in parseSkills(parseSnapshot(app.resumeSnapshot)?.skills).slice(0, 5)"
                        :key="skill"
                        class="skill-tag"
                      >{{ skill }}</span>
                      <span
                        v-if="parseSkills(parseSnapshot(app.resumeSnapshot)?.skills).length > 5"
                        class="skill-tag-more"
                      >+{{ parseSkills(parseSnapshot(app.resumeSnapshot)?.skills).length - 5 }}</span>
                    </div>
                    </div>
                    <div class="applicant-status">
                      <el-tag :type="statusType(app.status)" size="small">{{ statusLabel(app.status) }}</el-tag>
                    </div>
                    <div class="applicant-actions">
                      <button class="action-btn" @click="handleContact(app.id)">联系</button>
                      <el-tooltip
                        :content="hasSentResumeMap[app.id] ? '' : '当前用户暂未向您发送过简历'"
                        :disabled="!!hasSentResumeMap[app.id]"
                        placement="top"
                        :show-after="300"
                      >
                        <router-link
                          v-if="hasSentResumeMap[app.id]"
                          :to="`/resume-pool?applicantId=${app.applicantId}`"
                          class="action-btn"
                        >查看简历</router-link>
                        <span v-else class="action-btn action-btn-disabled">查看简历</span>
                      </el-tooltip>
                    </div>
                  </div>
                  <div
                    v-if="applications.filter(a => !ACTIVE_STATUSES.includes(a.status)).length > 0"
                    class="applicant-hidden-hint"
                  >
                    还有 {{ applications.filter(a => !ACTIVE_STATUSES.includes(a.status)).length }} 个已结束的投递记录
                  </div>
                </template>
                <div v-else class="no-applicants">暂无投递</div>
              </div>
            </div>
          </div>
        </div>
      </section>
    </template>

    <!-- ────────────────── 求职者首页 ────────────────── -->
    <template v-else>
      <!-- Hero 搜索区 -->
      <section class="hero-section">
        <div class="hero-content">
          <h1 class="hero-tagline">找到你心仪的工作</h1>
          <p class="hero-sub">UniSeek 智能推荐，让好工作主动来找你</p>
          <div class="hero-search-card">
            <div class="search-type-dropdown">
              <div class="search-type" @click.stop="searchTypeOpen = !searchTypeOpen">
                {{ searchTypeLabel }}
                <span class="search-type-arrow">▾</span>
              </div>
              <div v-if="searchTypeOpen" class="search-type-menu">
                <div :class="['search-type-item', { active: searchType === 'position' }]" @click="selectSearchType('position')">职位</div>
                <div :class="['search-type-item', { active: searchType === 'company' }]" @click="selectSearchType('company')">公司</div>
              </div>
            </div>
            <el-input
              v-model="keyword"
              size="large"
              :placeholder="searchType === 'position' ? '搜索职位名称' : '搜索公司名称'"
              :prefix-icon="Search"
              clearable
              class="search-input"
              @keyup.enter="handleSearch"
            />
            <button class="search-btn" @click="handleSearch">搜索</button>
          </div>
          <div class="hot-keywords">
            <span class="hot-label">热门搜索：</span>
            <button
              v-for="kw in hotKeywords"
              :key="kw"
              class="hot-tag"
              @click="quickSearch(kw)"
            >{{ kw }}</button>
          </div>
        </div>
      </section>

      <!-- 分类导航区（双行自动滚动） -->
      <section class="category-section" v-if="categoryTree.length > 0">
        <div class="section-inner">
          <div class="section-header">
            <h2>热门职位分类</h2>
            <button class="view-all-btn" @click="goToJobs()">查看全部</button>
          </div>
          <div class="category-scroll-2row">
            <div class="category-track-2row">
              <div class="category-row">
                <div
                  v-for="item in marqueeRow1"
                  :key="item.uid"
                  class="category-card"
                  :style="cardStyle(item.originalIdx)"
                  @click="goToJobs(item.cat.id)"
                >
                  <div class="cat-header">
                    <component :is="getCategoryIcon(item.cat.name, item.originalIdx)" class="cat-icon" />
                    <span class="cat-name">{{ item.cat.name }}</span>
                  </div>
                  <span class="cat-count" v-if="item.cat.children && item.cat.children.length">{{ item.cat.children.length }}个子类</span>
                </div>
              </div>
              <div class="category-row category-row-offset">
                <div
                  v-for="item in marqueeRow2"
                  :key="item.uid"
                  class="category-card"
                  :style="cardStyle(item.originalIdx)"
                  @click="goToJobs(item.cat.id)"
                >
                  <div class="cat-header">
                    <component :is="getCategoryIcon(item.cat.name, item.originalIdx)" class="cat-icon" />
                    <span class="cat-name">{{ item.cat.name }}</span>
                  </div>
                  <span class="cat-count" v-if="item.cat.children && item.cat.children.length">{{ item.cat.children.length }}个子类</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <!-- 热门公司推荐 -->
      <section class="companies-section" v-if="hotEnterprises.length > 0">
        <div class="section-inner">
          <div class="section-header">
            <h2>热门公司推荐</h2>
            <button class="view-all-btn" @click="router.push('/company')">查看更多</button>
          </div>
          <div class="company-grid">
            <div
              v-for="item in hotEnterprises"
              :key="item.id"
              class="company-card"
              @click="router.push(`/company?id=${item.id}`)"
            >
              <div class="company-card-top">
                <div class="company-card-avatar">
                  {{ item.companyName.charAt(0) }}
                </div>
                <div class="company-card-info">
                  <h3 class="company-card-name">{{ item.companyName }}</h3>
                  <span class="company-card-industry">{{ item.industry }}</span>
                </div>
                <span class="company-card-score">热度 {{ item.heatScore }}</span>
              </div>
              <div class="company-card-bottom">
                <span class="company-card-region" v-if="item.regionName">{{ item.regionName }}</span>
                <span class="company-card-jobs">在招 {{ item.activeJobCount }} 个岗位</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      <!-- 推荐职位区（瀑布流无限加载） -->
      <section class="jobs-section">
        <div class="section-inner">
          <div class="section-header">
            <h2>推荐职位</h2>
            <button class="view-all-btn" @click="goToJobs()">查看全部职位</button>
          </div>
          <div v-if="recommendJobs.length > 0" class="job-grid">
            <div
              v-for="job in recommendJobs"
              :key="job.id"
              class="job-card"
              @click="goToJob(job.id)"
            >
              <div class="job-card-top">
                <h3 class="job-card-title">{{ job.title }}</h3>
                <span class="job-card-salary">{{ salaryRangeText(job.salaryMin, job.salaryMax, job.salaryUnit) }}</span>
              </div>
              <div class="job-card-meta">
                <span class="job-card-company">{{ job.enterpriseName }}</span>
                <span class="job-card-type">{{ jobTypeLabel(job.jobType) }}</span>
              </div>
              <div class="job-card-bottom">
                <span class="job-card-location" v-if="job.address">{{ job.address }}</span>
                <span class="job-card-category" v-if="job.categoryName">{{ job.categoryName }}</span>
              </div>
            </div>
          </div>

          <!-- 空状态 -->
          <div v-if="recommendJobs.length === 0 && !seekerLoading" class="empty-card">
            <h3>还没有职位数据</h3>
            <p>请先导入种子数据，或由招聘者发布新职位</p>
          </div>

          <!-- 无限加载触发器 -->
          <div ref="sentinel" class="sentinel">
            <div v-if="seekerLoading" class="loading-indicator">加载中...</div>
            <div v-else-if="recommendJobs.length > 0 && !seekerHasMore" class="no-more">已展示全部职位</div>
          </div>
        </div>
      </section>
    </template>
  </div>
</template>

<style scoped>
.home-page {
  min-height: calc(100vh - 60px);
  background: #f5f7fa;
}

/* ── 招聘者头部 ── */
.recruiter-header {
  background: linear-gradient(rgba(13,27,42,0.2), rgba(13,27,42,0.2)), url('/background.jpg') center / cover no-repeat;
  padding: 40px 24px;
}

.company-name {
  font-size: 28px;
  font-weight: 800;
  color: #fff;
  margin: 0 0 8px;
}

.company-desc {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.6);
  margin: 0;
}

/* ── 招聘者仪表盘 ── */
.recruiter-dashboard {
  padding-bottom: 40px;
}

.job-list {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.job-section {
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 1px 4px rgba(0,0,0,0.06);
  overflow: hidden;
}

.job-section-header {
  padding: 18px 24px;
  cursor: pointer;
  border-bottom: 1px solid #f0f0f0;
  transition: background 0.2s;
}

.job-section-header:hover {
  background: #f8f9fb;
}

.job-section-title {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 6px;
}

.job-section-title h3 {
  font-size: 17px;
  font-weight: 600;
  color: #1a1a2e;
  margin: 0;
}

.job-section-salary {
  font-size: 15px;
  font-weight: 700;
  color: #e74c3c;
}

.job-section-meta {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 13px;
  color: #999;
}

.job-section-type {
  padding: 2px 8px;
  border-radius: 4px;
  background: rgba(23, 98, 251, 0.08);
  color: #1762FB;
  font-size: 11px;
}

.applicant-count {
  margin-left: auto;
  font-weight: 500;
  color: #1762FB;
}

.detail-btn {
  flex-shrink: 0;
  margin-left: auto;
  padding: 6px 16px;
  font-size: 13px;
  border: 1px solid #1762FB;
  border-radius: 6px;
  background: #fff;
  color: #1762FB;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.detail-btn:hover {
  background: #1762FB;
  color: #fff;
}

/* ── 折叠/展开 ── */
.job-section-header {
  display: flex;
  align-items: center;
  gap: 12px;
}

.collapse-toggle {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  border-radius: 8px;
  color: #999;
  transition: background 0.2s, color 0.2s;
  cursor: pointer;
}

.collapse-toggle:hover {
  background: rgba(0, 0, 0, 0.05);
  color: #555;
}

.collapse-arrow {
  font-size: 18px;
  transition: transform 0.25s ease;
  display: inline-block;
  user-select: none;
}

.collapse-arrow.collapsed {
  transform: rotate(-90deg);
}

/* ── 求职者卡片 ── */
.applicants-list {
  padding: 12px 24px;
}

.applicant-card {
  display: flex;
  align-items: center;
  padding: 12px 0;
  border-bottom: 1px solid #f5f5f5;
  gap: 16px;
}

.applicant-card:last-child {
  border-bottom: none;
}

.applicant-info {
  flex: 1;
  min-width: 0;
}

.applicant-name {
  font-size: 15px;
  font-weight: 600;
  color: #1a1a2e;
  margin-bottom: 4px;
}

.applicant-detail {
  display: flex;
  gap: 10px;
  font-size: 13px;
  color: #888;
  margin-bottom: 4px;
}

.applicant-skills {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  margin-top: 4px;
}

.skill-tag {
  display: inline-block;
  padding: 2px 8px;
  font-size: 11px;
  color: #1762FB;
  background: rgba(23, 98, 251, 0.08);
  border-radius: 4px;
  line-height: 1.5;
}

.skill-tag-more {
  display: inline-block;
  padding: 2px 6px;
  font-size: 11px;
  color: #999;
  background: #f5f5f5;
  border-radius: 4px;
  line-height: 1.5;
}

.applicant-status {
  flex-shrink: 0;
}

.applicant-actions {
  display: flex;
  gap: 8px;
  flex-shrink: 0;
}

.action-btn {
  padding: 5px 14px;
  font-size: 13px;
  border-radius: 6px;
  text-decoration: none;
  color: #1762FB;
  background: rgba(23, 98, 251, 0.06);
  transition: all 0.2s;
  white-space: nowrap;
  border: none;
  cursor: pointer;
  font-family: inherit;
  line-height: 1.5;
}

.action-btn:hover {
  background: rgba(23, 98, 251, 0.12);
}

.action-btn-disabled {
  cursor: not-allowed;
  opacity: 0.45;
  user-select: none;
}

.no-applicants {
  padding: 18px 24px;
  text-align: center;
  font-size: 14px;
  color: #bbb;
}

.applicant-hidden-hint {
  padding: 12px 0;
  text-align: center;
  font-size: 13px;
  color: #ccc;
  border-top: 1px solid #f5f5f5;
  margin-top: 4px;
}

.loading-tip {
  text-align: center;
  padding: 60px 20px;
  font-size: 15px;
  color: #999;
}

/* ── 通用 section ── */
.section-inner {
  max-width: 1200px;
  margin: 0 auto;
  padding: 40px 24px;
}

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
}

.section-header h2 {
  font-size: 22px;
  font-weight: 700;
  color: #1a1a2e;
  margin: 0;
}

.view-all-btn {
  font-size: 14px;
  color: #1762FB;
  background: none;
  border: none;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 4px;
  transition: background 0.2s;
}

.view-all-btn:hover {
  background: rgba(23, 98, 251, 0.06);
}

/* ── 求职者 Hero ── */
.hero-section {
  background: linear-gradient(rgba(13,27,42,0.2), rgba(13,27,42,0.2)), url('/background.jpg') center / cover no-repeat;
  padding: 90px 24px;
}

.hero-content {
  max-width: 900px;
  margin: 0 auto;
  text-align: center;
}

.hero-tagline {
  font-size: 36px;
  font-weight: 800;
  color: #fff;
  margin: 0 0 12px;
}

.hero-sub {
  font-size: 16px;
  color: rgba(255, 255, 255, 0.7);
  margin: 0 0 32px;
}

.hero-search-card {
  display: flex;
  align-items: center;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
  height: 56px;
  max-width: 700px;
  margin: 0 auto;
}

.search-type-dropdown {
  position: relative;
  height: 100%;
  flex-shrink: 0;
}

.search-type {
  padding: 0 20px;
  font-size: 16px;
  color: #1a1a2e;
  font-weight: 600;
  white-space: nowrap;
  border-right: 1px solid #e8e8f0;
  height: 100%;
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  user-select: none;
  border-radius: 12px 0 0 12px;
}

.search-type:hover {
  background: rgba(0, 0, 0, 0.02);
}

.search-type-arrow {
  font-size: 12px;
  color: #999;
  transition: transform 0.2s;
}

.search-type-menu {
  position: absolute;
  top: 100%;
  left: 0;
  width: 100%;
  min-width: 100px;
  background: #fff;
  border: 1px solid #e8e8f0;
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
  z-index: 200;
  overflow: hidden;
}

.search-type-item {
  padding: 12px 20px;
  font-size: 14px;
  color: #333;
  cursor: pointer;
  transition: background 0.15s;
}

.search-type-item:hover {
  background: #f5f7fa;
}

.search-type-item.active {
  color: #1762FB;
  font-weight: 600;
  background: rgba(23, 98, 251, 0.06);
}

.search-input {
  flex: 1;
}

.search-input :deep(.el-input__wrapper) {
  box-shadow: none !important;
  border-radius: 0;
  padding: 0 16px;
  height: 54px;
}

.search-btn {
  width: 120px;
  height: 100%;
  border: none;
  background: #1762FB;
  color: #fff;
  font-size: 17px;
  font-weight: 600;
  cursor: pointer;
  flex-shrink: 0;
  border-radius: 0 12px 12px 0;
  transition: background 0.2s;
}

.search-btn:hover {
  background: #0062cc;
}

.hot-keywords {
  display: flex;
  align-items: center;
  justify-content: center;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 18px;
}

.hot-label {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.5);
}

.hot-tag {
  padding: 4px 14px;
  font-size: 13px;
  color: rgba(255, 255, 255, 0.8);
  background: rgba(255, 255, 255, 0.12);
  border: none;
  border-radius: 16px;
  cursor: pointer;
  transition: all 0.2s;
}

.hot-tag:hover {
  background: rgba(255, 255, 255, 0.22);
  color: #fff;
}

/* ── 分类卡片 ── */
.category-scroll-2row {
  overflow: hidden;
  padding: 16px 0 28px 0;
  mask-image: linear-gradient(to right, transparent 0, #000 40px, #000 calc(100% - 40px), transparent 100%);
  -webkit-mask-image: linear-gradient(to right, transparent 0, #000 40px, #000 calc(100% - 40px), transparent 100%);
}

.category-track-2row {
  display: inline-flex;
  flex-direction: column;
  gap: 12px;
  animation: category-scroll-2row 60s linear infinite;
}

.category-scroll-2row:hover .category-track-2row {
  animation-play-state: paused;
}

.category-row {
  display: flex;
  gap: 12px;
  flex-shrink: 0;
}

.category-row-offset {
  margin-left: 140px;
}

@keyframes category-scroll-2row {
  0% { transform: translateX(0); }
  100% { transform: translateX(-50%); }
}

.category-card {
  display: flex;
  flex-direction: column;
  width: 280px;
  min-height: 50px;
  flex-shrink: 0;
  border-radius: 8px;
  padding: 10px 14px;
  cursor: pointer;
  box-shadow: 0 1px 4px rgba(0,0,0,0.06);
  transition: all 0.3s ease;
  border: none;
}

.category-card:hover {
  background: var(--card-color) !important;
  box-shadow: 0 8px 28px var(--card-color);
}

.category-card:hover .cat-name {
  color: #fff;
}

.category-card:hover .cat-icon,
.category-card:hover .cat-count {
  color: #fff;
  opacity: 0.7;
}

.cat-header {
  display: flex;
  align-items: center;
  gap: 6px;
}

.cat-name {
  font-size: 27px;
  font-weight: 700;
  color: var(--card-color);
  line-height: 1.3;
}

.cat-icon {
  width: 27px;
  height: 27px;
  color: var(--card-color);
  opacity: 0.5;
  flex-shrink: 0;
}

.cat-count {
  margin-top: auto;
  align-self: flex-end;
  font-size: 11px;
  color: var(--card-color);
  opacity: 0.5;
}

/* ── 推荐职位卡片 ── */
.job-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}

.job-card {
  background: #fff;
  border-radius: 10px;
  padding: 18px 20px;
  cursor: pointer;
  box-shadow: 0 1px 4px rgba(0,0,0,0.06);
  transition: all 0.2s;
}

.job-card:hover {
  box-shadow: 0 4px 16px rgba(23, 98, 251, 0.1);
}

.job-card-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
  gap: 12px;
}

.job-card-title {
  font-size: 16px;
  font-weight: 600;
  color: #1a1a2e;
  margin: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.job-card-salary {
  font-size: 16px;
  font-weight: 700;
  color: #e74c3c;
  white-space: nowrap;
}

.job-card-meta {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 8px;
}

.job-card-company {
  font-size: 14px;
  color: #555;
}

.job-card-type {
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 4px;
  background: rgba(23, 98, 251, 0.08);
  color: #1762FB;
}

.job-card-bottom {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 8px;
}

.job-card-location,
.job-card-category {
  font-size: 12px;
  color: #999;
}

/* ── 无限加载 ── */
.sentinel {
  text-align: center;
  padding: 20px 0;
}

.loading-indicator {
  font-size: 14px;
  color: #999;
}

.no-more {
  font-size: 13px;
  color: #ccc;
}

/* ── 空状态 ── */
.empty-card {
  text-align: center;
  padding: 60px 20px;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 1px 4px rgba(0,0,0,0.06);
}

.empty-card h3 {
  font-size: 18px;
  color: #666;
  margin: 0 0 8px;
}

.empty-card p {
  font-size: 14px;
  color: #bbb;
  margin: 0 0 20px;
}

.add-job-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 10px 28px;
  font-size: 15px;
  font-weight: 600;
  color: #fff;
  background: #1762FB;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: opacity 0.2s;
}
.add-job-btn:hover {
  opacity: 0.92;
}

/* ── 热门公司卡片 ── */
.company-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
}

.company-card {
  background: #fff;
  border-radius: 10px;
  padding: 18px 20px;
  cursor: pointer;
  box-shadow: 0 1px 4px rgba(0,0,0,0.06);
  transition: all 0.2s;
}

.company-card:hover {
  box-shadow: 0 4px 16px rgba(23, 98, 251, 0.1);
}

.company-card-top {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 10px;
}

.company-card-avatar {
  width: 44px;
  height: 44px;
  border-radius: 10px;
  background: linear-gradient(135deg, #1762FB, #00a8ff);
  color: #fff;
  font-size: 20px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.company-card-info {
  flex: 1;
  min-width: 0;
}

.company-card-name {
  font-size: 15px;
  font-weight: 600;
  color: #1a1a2e;
  margin: 0 0 4px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.company-card-industry {
  font-size: 12px;
  color: #999;
}

.company-card-score {
  font-size: 12px;
  font-weight: 500;
  color: #e67e22;
  white-space: nowrap;
  flex-shrink: 0;
}

.company-card-bottom {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 12px;
  color: #999;
}

.company-card-region {
  color: #888;
}

.company-card-jobs {
  color: #1762FB;
  font-weight: 500;
}

/* ── 响应式 ── */
@media (max-width: 768px) {
  .hero-section {
    padding: 60px 16px;
  }

  .hero-tagline {
    font-size: 26px;
  }

  .hero-search-card {
    flex-direction: column;
    height: auto;
    border-radius: 12px;
  }

  .search-type {
    width: 100%;
    border-right: none;
    border-bottom: 1px solid #e8e8f0;
    justify-content: center;
    padding: 12px 0;
  }

  .search-type-dropdown {
    width: 100%;
  }

  .search-type-menu {
    width: 100%;
  }

  .search-btn {
    width: 100%;
    padding: 14px 0;
  }

  .category-card {
    width: 180px;
    padding: 8px 12px;
    border-radius: 6px;
  }
  .cat-name {
    font-size: 22px;
  }
  .cat-icon {
    width: 22px;
    height: 22px;
  }
  .cat-count {
    font-size: 10px;
  }
  .category-row-offset {
    margin-left: 90px;
  }
  .category-scroll-2row {
    mask-image: linear-gradient(to right, transparent 0, #000 20px, #000 calc(100% - 20px), transparent 100%);
    -webkit-mask-image: linear-gradient(to right, transparent 0, #000 20px, #000 calc(100% - 20px), transparent 100%);
  }

  .company-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .job-grid {
    grid-template-columns: 1fr;
  }

  .applicant-card {
    flex-wrap: wrap;
  }

  .applicant-actions {
    width: 100%;
    justify-content: flex-end;
  }
}
</style>
