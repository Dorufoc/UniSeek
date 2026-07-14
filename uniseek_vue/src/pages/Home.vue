<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { searchTasks, type TaskVO } from '@/api/task'
import { getCategories, type CategoryVO } from '@/api/category'
import { Search } from '@element-plus/icons-vue'

const router = useRouter()
const appStore = useAppStore()
const keyword = ref('')

const recommendJobs = ref<TaskVO[]>([])
const categoryTree = ref<CategoryVO[]>([])
const hotKeywords = ['Java', '前端', '销售', '客服', '服务员', '设计', '运营', '行政', '会计', '编辑']

const handleSearch = () => {
  appStore.setSearchKeyword(keyword.value)
  router.push('/jobs')
}

const quickSearch = (kw: string) => {
  keyword.value = kw
  appStore.setSearchKeyword(kw)
  router.push('/jobs')
}

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

const jobTypeLabel = (type: number) => {
  const map: Record<number, string> = { 1: '全职', 2: '兼职', 3: '实习' }
  return map[type] || ''
}

// ── 模拟分类图标色 ──
const catColors = ['#007AFF', '#e74c3c', '#27ae60', '#f39c12', '#9b59b6', '#1abc9c', '#e67e22', '#3498db']

onMounted(async () => {
  const [cats, jobs] = await Promise.all([
    getCategories().catch(() => [] as CategoryVO[]),
    searchTasks({ pageSize: 8, sortBy: 'popular' }).catch(() => ({ records: [] as TaskVO[], total: 0, page: 1, pageSize: 8, totalPages: 0 }))
  ])
  categoryTree.value = cats.slice(0, 8)
  recommendJobs.value = jobs.records
})
</script>

<template>
  <div class="home-page">
    <!-- Hero 搜索区 -->
    <section class="hero-section">
      <div class="hero-content">
        <h1 class="hero-tagline">找到你心仪的工作</h1>
        <p class="hero-sub">UniSeek 智能推荐，让好工作主动来找你</p>
        <div class="hero-search-card">
          <div class="search-type">职位</div>
          <el-input
            v-model="keyword"
            size="large"
            placeholder="搜索职位、公司名称"
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

    <!-- 分类导航区 -->
    <section class="category-section" v-if="categoryTree.length > 0">
      <div class="section-inner">
        <div class="section-header">
          <h2>热门职位分类</h2>
          <button class="view-all-btn" @click="goToJobs()">查看全部</button>
        </div>
        <div class="category-grid">
          <div
            v-for="(cat, idx) in categoryTree"
            :key="cat.id"
            class="category-card"
            :style="{ borderTopColor: catColors[idx % catColors.length] }"
            @click="goToJobs(cat.id)"
          >
            <span class="cat-name">{{ cat.name }}</span>
            <span class="cat-count" v-if="cat.children && cat.children.length">{{ cat.children.length }}个子类</span>
          </div>
        </div>
      </div>
    </section>

    <!-- 推荐职位区 -->
    <section class="jobs-section" v-if="recommendJobs.length > 0">
      <div class="section-inner">
        <div class="section-header">
          <h2>推荐职位</h2>
          <button class="view-all-btn" @click="goToJobs()">查看全部职位</button>
        </div>
        <div class="job-grid">
          <div
            v-for="job in recommendJobs"
            :key="job.id"
            class="job-card"
            @click="goToJob(job.id)"
          >
            <div class="job-card-top">
              <h3 class="job-card-title">{{ job.title }}</h3>
              <span class="job-card-salary">{{ formatSalary(job.salaryMin) }}-{{ formatSalary(job.salaryMax) }}/{{ salaryUnitLabel(job.salaryUnit) }}</span>
            </div>
            <div class="job-card-meta">
              <span class="job-card-company">{{ job.enterpriseName }}</span>
              <span class="job-card-type">{{ jobTypeLabel(job.jobType) }}</span>
            </div>
            <div class="job-card-bottom">
              <span class="job-card-location" v-if="job.address">{{ job.address }}</span>
              <span class="job-card-category" v-if="job.categoryName">{{ job.categoryName }}</span>
            </div>
            <div class="job-card-tags" v-if="job.tag && job.tag.length > 0">
              <span class="job-tag" v-for="(t, i) in job.tag.slice(0, 3)" :key="i">{{ t }}</span>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- 数据为空提示 -->
    <section class="empty-section" v-else>
      <div class="section-inner">
        <div class="empty-card">
          <h3>还没有职位数据</h3>
          <p>请先导入种子数据，或由招聘者发布新职位</p>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.home-page {
  min-height: calc(100vh - 60px);
  background: #f5f7fa;
}

/* ── Hero ── */
.hero-section {
  background: linear-gradient(135deg, #0d1b2a 0%, #1b3a5c 100%);
  padding: 60px 24px;
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
  overflow: hidden;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
  height: 56px;
  max-width: 700px;
  margin: 0 auto;
}

.search-type {
  padding: 0 24px;
  font-size: 16px;
  color: #1a1a2e;
  font-weight: 600;
  white-space: nowrap;
  border-right: 1px solid #e8e8f0;
  height: 100%;
  display: flex;
  align-items: center;
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
  background: #007AFF;
  color: #fff;
  font-size: 17px;
  font-weight: 600;
  cursor: pointer;
  flex-shrink: 0;
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
  color: #007AFF;
  background: none;
  border: none;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 4px;
  transition: background 0.2s;
}

.view-all-btn:hover {
  background: rgba(0, 122, 255, 0.06);
}

/* ── 分类卡片 ── */
.category-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
}

.category-card {
  background: #fff;
  border-radius: 10px;
  padding: 20px 16px;
  cursor: pointer;
  border-top: 3px solid #007AFF;
  box-shadow: 0 1px 4px rgba(0,0,0,0.06);
  transition: all 0.2s;
}

.category-card:hover {
  box-shadow: 0 4px 16px rgba(0,0,0,0.1);
  transform: translateY(-2px);
}

.cat-name {
  display: block;
  font-size: 16px;
  font-weight: 600;
  color: #1a1a2e;
  margin-bottom: 6px;
}

.cat-count {
  font-size: 12px;
  color: #aaa;
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
  box-shadow: 0 4px 16px rgba(0, 122, 255, 0.1);
  transform: translateY(-1px);
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
  background: rgba(0, 122, 255, 0.08);
  color: #007AFF;
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

.job-card-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.job-tag {
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 4px;
  background: #f5f7fa;
  color: #999;
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
  margin: 0;
}

/* ── 响应式 ── */
@media (max-width: 768px) {
  .hero-section {
    padding: 40px 16px;
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

  .search-btn {
    width: 100%;
    padding: 14px 0;
  }

  .category-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .job-grid {
    grid-template-columns: 1fr;
  }
}
</style>
