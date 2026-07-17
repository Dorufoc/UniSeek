<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Search } from '@element-plus/icons-vue'
import { getEnterpriseList, getEnterpriseById, type EnterpriseListParams } from '@/api/enterprise'
import { getEnterprisePublishedTasks } from '@/api/task'
import { getRegionTree } from '@/api/region'
import { getCategories } from '@/api/category'
import type { EnterpriseInfo } from '@/api/enterprise'
import type { TaskVO } from '@/api/task'
import type { RegionVO } from '@/api/region'
import type { CategoryVO } from '@/api/category'

const route = useRoute()
const router = useRouter()

const PAGE_SIZE = 12

// ── 列表数据（分页加载） ──
const enterprises = ref<EnterpriseInfo[]>([])
const loading = ref(false)
const page = ref(1)
const total = ref(0)

const totalPages = computed(() => Math.ceil(total.value / PAGE_SIZE))
const displayPages = computed(() => computeDisplayPages(page.value, totalPages.value))

// ── 筛选条件 ──
const keyword = ref('')
const selectedIndustry = ref<string[]>([])
const regionCascaderValue = ref<number[]>([])

// ── 排序 ──
const sortBy = ref<string>('')
const sortOrder = ref<string>('desc')
const setSort = (field: string) => {
  if (sortBy.value === field) {
    sortOrder.value = sortOrder.value === 'desc' ? 'asc' : 'desc'
  } else {
    sortBy.value = field
    sortOrder.value = 'desc'
  }
  resetAndReload()
}

// ── 其他数据 ──
const categoryTree = ref<CategoryVO[]>([])
const regions = ref<RegionVO[]>([])
const regionNameMap = ref<Record<number, string>>({})
const selectedEnterprise = ref<EnterpriseInfo | null>(null)
const enterpriseJobs = ref<TaskVO[]>([])
const jobsLoading = ref(false)
const showDetail = ref(false)

// ── 分页展示辅助 ──
const computeDisplayPages = (current: number, total: number): number[] => {
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1)
  const pages: number[] = []
  if (current <= 4) {
    for (let i = 1; i <= 5; i++) pages.push(i)
    pages.push(-1)
    pages.push(total)
  } else if (current >= total - 3) {
    pages.push(1)
    pages.push(-1)
    for (let i = total - 4; i <= total; i++) pages.push(i)
  } else {
    pages.push(1)
    pages.push(-1)
    for (let i = current - 1; i <= current + 1; i++) pages.push(i)
    pages.push(-1)
    pages.push(total)
  }
  return pages
}

// ── 翻页 ──
const goToPage = (p: number) => {
  if (p < 1 || p > totalPages.value || p === page.value) return
  page.value = p
  loadEnterprises()
}

// ── 构建 API 请求参数 ──
const buildParams = (): EnterpriseListParams => {
  const params: EnterpriseListParams = { page: page.value, pageSize: PAGE_SIZE }
  const kw = keyword.value.trim()
  if (kw) params.keyword = kw
  if (selectedIndustry.value.length > 0) {
    params.industry = selectedIndustry.value[0]
  }
  const val = regionCascaderValue.value
  if (val.length > 0) {
    params.regionId = val[val.length - 1]
  }
  if (sortBy.value) {
    params.sortBy = sortBy.value
    params.sortOrder = sortOrder.value
  }
  return params
}

// ── 加载企业列表 ──
const loadEnterprises = async () => {
  loading.value = true
  try {
    const result = await getEnterpriseList(buildParams())
    enterprises.value = result.records || []
    total.value = result.total
  } catch {
    enterprises.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

// ── 根据 ID 直接加载企业详情 ──
const loadEnterpriseById = async (id: number) => {
  try {
    const enterprise = await getEnterpriseById(id)
    viewCompany(enterprise)
  } catch {
    // 企业不存在或加载失败，保持列表页
  }
}

// ── 筛选条件变更 → 重置到第1页并重新加载 ──
const resetAndReload = () => {
  page.value = 1
  loadEnterprises()
}

// ── 重置筛选 ──
const resetFilters = () => {
  keyword.value = ''
  selectedIndustry.value = []
  regionCascaderValue.value = []
  resetAndReload()
}

// ── 执行搜索 ──
const handleSearch = () => {
  resetAndReload()
}

// ── 加载分类 ──
const loadCategories = async () => {
  try {
    categoryTree.value = await getCategories()
  } catch {
    categoryTree.value = []
  }
}

// 地区父级映射（子ID → 父ID），用于向上查找省市名称
const regionParentMap = ref<Record<number, number>>({})

// 获取地区显示名：省 + 地级市（跳过区县）
const getRegionDisplay = (regionId: number | null | undefined): string => {
  if (!regionId || !regionParentMap.value[regionId]) return ''
  // 收集从当前节点到根的路径
  const path: number[] = [regionId]
  let pid = regionParentMap.value[regionId]
  while (pid) {
    path.unshift(pid)
    pid = regionParentMap.value[pid]
  }
  // 取省和地级市（第1、2级），跳过区县
  const names = path.slice(0, 2).map(id => regionNameMap.value[id] || '').filter(Boolean)
  return names.join(' ')
}

// ── 加载地区树 ──
const loadRegions = async () => {
  try {
    const tree = await getRegionTree()
    regions.value = tree
    const map: Record<number, string> = {}
    const parentMap: Record<number, number> = {}
    const walk = (list: RegionVO[], parentId?: number) => {
      for (const r of list) {
        map[r.id] = r.name
        if (parentId !== undefined) parentMap[r.id] = parentId
        if (r.children) walk(r.children, r.id)
      }
    }
    walk(tree)
    regionNameMap.value = map
    regionParentMap.value = parentMap
  } catch {
    regions.value = []
  }
}

// ── 查看公司详情 ──
const viewCompany = async (item: EnterpriseInfo) => {
  selectedEnterprise.value = item
  showDetail.value = true
  // 更新URL，使刷新后仍定位到该公司详情；
  // 用 push 保留列表页历史，返回时回到列表页
  const currentId = route.query.id
  if (String(item.id) !== currentId) {
    router.push({ query: { ...route.query, id: item.id } })
  }
  jobsLoading.value = true
  try {
    enterpriseJobs.value = await getEnterprisePublishedTasks(item.id)
  } catch {
    enterpriseJobs.value = []
  } finally {
    jobsLoading.value = false
  }
}

// ── 跳转职位详情 ──
const goToJob = (jobId: number) => {
  router.push(`/jobs/${jobId}`)
}

// ── 薪资/类型辅助 ──
const salaryUnitLabel = (unit?: number) => {
  if (unit === 0) return '/日'
  if (unit === 1) return '/时'
  return '/月'
}
const jobTypeLabel = (type?: number) => {
  if (type === 1) return '全职'
  if (type === 2) return '兼职'
  if (type === 3) return '实习'
  return ''
}

onMounted(() => {
  const q = route.query.q as string | undefined
  if (q) keyword.value = q

  loadRegions()
  loadCategories()
  loadEnterprises().then(() => {
    // 路由指定企业ID → 直接进入详情
    const id = route.query.id
    if (id) {
      const target = enterprises.value.find(e => String(e.id) === id)
      if (target) {
        viewCompany(target)
      } else {
        // 不在当前列表页中，直接按 ID 加载
        loadEnterpriseById(Number(id))
      }
    }
  })
})

// 监听路由参数变化
watch(() => route.query.q, (q) => {
  keyword.value = (q as string) || ''
})
// 监听 id 参数：消失时返回列表，变化时切换公司详情
watch(() => route.query.id, (id) => {
  if (!id) {
    // 回到列表视图
    showDetail.value = false
    selectedEnterprise.value = null
    enterpriseJobs.value = []
  } else if (id !== String(selectedEnterprise.value?.id)) {
    // URL 指向另一个公司，从已加载的列表中查找并展示
    const target = enterprises.value.find(e => String(e.id) === id)
    if (target) {
      viewCompany(target)
    } else {
      loadEnterpriseById(Number(id))
    }
  }
})

</script>

<template>
  <!-- 列表视图 -->
  <div v-if="!showDetail" class="company-page">
    <!-- 搜索栏（全宽） -->
    <div class="search-bar">
      <div class="search-bar-inner">
        <el-input
          v-model="keyword"
          size="large"
          placeholder="搜索企业名称"
          :prefix-icon="Search"
          clearable
          class="search-input"
          @keyup.enter="handleSearch"
        ></el-input>
        <button class="search-btn" @click="handleSearch">搜索</button>
      </div>
    </div>

    <div class="jobs-body">
      <!-- 左侧筛选面板 -->
      <aside class="filter-panel">
        <div class="filter-section">
          <h4 class="filter-title">分类</h4>
          <el-cascader
            v-model="selectedIndustry"
            :options="categoryTree"
            :props="{ value: 'name', label: 'name', children: 'children', checkStrictly: true, emitPath: true, expandTrigger: 'hover' }"
            placeholder="全部行业"
            size="default"
            clearable
            style="width:100%"
            @change="resetAndReload"
          />
        </div>
        <div class="filter-section">
          <h4 class="filter-title">地区</h4>
          <el-cascader
            v-model="regionCascaderValue"
            :options="regions"
            :props="{ value: 'id', label: 'name', children: 'children', checkStrictly: true, emitPath: true, expandTrigger: 'hover' }"
            placeholder="请选择地区"
            size="default"
            clearable
            style="width:100%"
            @change="resetAndReload"
          />
        </div>
        <button class="reset-btn" @click="resetFilters">重置筛选</button>
      </aside>

      <!-- 右侧内容 -->
      <div class="main-content">
        <div class="page-header">
          <h2 class="page-title">企业列表</h2>
          <p class="page-desc">所有已认证的企业</p>
        </div>

          <div class="sort-bar">
            <span class="result-count">共 {{ total }} 个企业</span>
            <div class="sort-tabs">
              <span
                :class="['sort-tab', { active: sortBy === '' }]"
                @click="setSort('')"
              >默认</span>
              <span
                :class="['sort-tab', { active: sortBy === 'jobCount' }]"
                @click="setSort('jobCount')"
              >在招岗位
                <span v-if="sortBy === 'jobCount'" class="sort-arrow">{{ sortOrder === 'desc' ? '↓' : '↑' }}</span>
              </span>
              <span
                :class="['sort-tab', { active: sortBy === 'avgSalary' }]"
                @click="setSort('avgSalary')"
              >平均薪资
                <span v-if="sortBy === 'avgSalary'" class="sort-arrow">{{ sortOrder === 'desc' ? '↓' : '↑' }}</span>
              </span>
            </div>
          </div>

        <div v-if="loading" class="loading-tip">加载中...</div>
        <div v-else-if="enterprises.length === 0" class="empty-tip">暂无已认证的企业</div>
        <div v-else class="company-list">
          <div
            v-for="item in enterprises"
            :key="item.id"
            class="company-card"
            @click="viewCompany(item)"
          >
          <div class="company-logo">{{ item.companyName.charAt(0) }}</div>
          <div class="company-info">
            <h3 class="company-name">{{ item.companyName }}</h3>
            <p class="company-meta">
              <span v-if="item.industry" class="tag">{{ item.industry }}</span>
              <span v-if="item.regionId" class="tag region-tag">{{ getRegionDisplay(item.regionId) }}</span>
            </p>
            <p class="company-desc">{{ item.description || '暂无简介' }}</p>
          </div>
          </div>
        </div>
        <!-- 分页 -->
        <div class="pagination" v-if="totalPages > 1">
          <button :disabled="page === 1" @click="goToPage(page - 1)">上一页</button>
          <button
            v-for="p in displayPages"
            :key="p"
            :class="{ active: p === page }"
            @click="goToPage(p)"
          >{{ p === -1 ? '…' : p }}</button>
          <button :disabled="page === totalPages" @click="goToPage(page + 1)">下一页</button>
        </div>
      </div>
    </div>
  </div>

  <!-- 公司详情视图 -->
  <div v-else-if="selectedEnterprise" class="company-page">
    <div class="jobs-body">
      <div class="detail-container">
        <div class="detail-header">
          <button class="back-btn" @click="router.back()">&larr; 返回</button>
        </div>

        <div class="company-detail-card">
          <div class="detail-logo">{{ selectedEnterprise.companyName.charAt(0) }}</div>
          <div class="detail-info">
            <h2 class="detail-name">{{ selectedEnterprise.companyName }}</h2>
            <p class="detail-meta">
              <span v-if="selectedEnterprise.industry" class="tag">{{ selectedEnterprise.industry }}</span>
              <span v-if="selectedEnterprise.regionId" class="tag region-tag">{{ getRegionDisplay(selectedEnterprise.regionId) }}</span>
            </p>
            <p class="detail-desc">{{ selectedEnterprise.description || '暂无简介' }}</p>
          </div>
        </div>

        <h3 class="section-title">招聘中的职位</h3>

        <div v-if="jobsLoading" class="loading-tip">加载中...</div>

        <div v-else-if="enterpriseJobs.length === 0" class="empty-tip">该企业暂无招聘中的职位</div>

        <div v-else class="job-list">
          <div
            v-for="job in enterpriseJobs"
            :key="job.id"
            class="job-card"
            @click="goToJob(job.id)"
          >
            <div class="job-top">
              <h4 class="job-title">{{ job.title }}</h4>
              <span class="job-salary">&yen;{{ job.salaryMin }}-{{ job.salaryMax }}{{ salaryUnitLabel(job.salaryUnit) }}</span>
            </div>
            <div class="job-meta">
              <span class="job-type">{{ jobTypeLabel(job.jobType) }}</span>
              <span>{{ job.regionName }}</span>
              <span>{{ job.address }}</span>
            </div>
            <div class="job-tags" v-if="job.tag && job.tag.length > 0">
              <span v-for="t in job.tag.slice(0, 3)" :key="t" class="tag">{{ t }}</span>
            </div>
            <div class="job-bottom">
              <span class="job-count">{{ job.applicationCount }} 人投递</span>
              <span class="job-status" v-if="job.status === 1">招聘中</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.company-page {
  min-height: calc(100vh - 60px);
  background: #f5f7fa;
}

.page-header {
  margin-bottom: 16px;
}

.page-title {
  font-size: 20px;
  font-weight: 600;
  color: #1a1a2e;
  margin: 0 0 4px;
}

.page-desc {
  font-size: 14px;
  color: #999;
  margin: 0;
}

/* 搜索栏 */
.search-bar {
  background: linear-gradient(rgba(31,38,52,0.6), rgba(31,38,52,0.6)), url('/background.jpg') center / cover no-repeat;
  padding: 20px 24px;
}

.search-bar-inner {
  max-width: 1200px;
  margin: 0 auto;
  display: flex;
  height: 48px;
  gap: 0;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 12px rgba(0,0,0,0.15);
}

.search-bar-inner .search-input {
  flex: 1;
  height: 100%;
}

.search-bar-inner .search-input :deep(.el-input) {
  height: 100%;
}

.search-bar-inner .search-input :deep(.el-input__wrapper) {
  border-radius: 0;
  box-shadow: none !important;
  height: 100%;
  box-sizing: border-box;
}

.search-bar-inner .search-btn {
  width: 120px;
  height: 100%;
  border: none;
  background: #1762FB;
  color: #fff;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  flex-shrink: 0;
  transition: background 0.2s;
}

.search-bar-inner .search-btn:hover {
  background: #0062cc;
}

/* ── 主体布局（左侧筛选 + 右侧列表） ── */
.jobs-body {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px 24px;
  display: flex;
  gap: 20px;
  align-items: flex-start;
}

/* ── 左侧筛选面板 ── */
.filter-panel {
  width: 280px;
  flex-shrink: 0;
  background: #fff;
  border-radius: 10px;
  padding: 20px 16px;
  box-shadow: 0 1px 4px rgba(0,0,0,0.06);
  position: sticky;
  top: 80px;
}

.filter-section {
  margin-bottom: 20px;
  padding-bottom: 18px;
  border-bottom: 1px solid #f0f0f5;
}

.filter-section:last-of-type {
  border-bottom: none;
}

.filter-title {
  font-size: 14px;
  font-weight: 600;
  color: #1a1a2e;
  margin: 0 0 12px;
}

.reset-btn {
  width: 100%;
  padding: 10px;
  font-size: 14px;
  border: 1px solid #e4e6ef;
  background: #fff;
  color: #999;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.reset-btn:hover {
  border-color: #1762FB;
  color: #1762FB;
}

/* ── 右侧内容 ── */
.main-content {
  flex: 1;
  min-width: 0;
}

.sort-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #fff;
  border-radius: 10px;
  padding: 0 20px;
  height: 48px;
  margin-bottom: 12px;
  box-shadow: 0 1px 4px rgba(0,0,0,0.06);
}

.result-count {
  font-size: 14px;
  color: #999;
}

.sort-tabs {
  display: flex;
  gap: 4px;
}

.sort-tab {
  padding: 6px 14px;
  font-size: 13px;
  color: #666;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
  user-select: none;
}

.sort-tab:hover {
  background: #f5f7fa;
}

.sort-tab.active {
  color: #1762FB;
  background: rgba(0, 122, 255, 0.06);
  font-weight: 600;
}

.sort-arrow {
  font-size: 11px;
  margin-left: 2px;
}

/* 企业列表 */
.company-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.company-card {
  display: flex;
  gap: 16px;
  padding: 20px;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  cursor: pointer;
  transition: box-shadow 0.2s, transform 0.15s;
}

.company-card:hover {
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
  transform: translateY(-2px);
}

.company-logo {
  width: 56px;
  height: 56px;
  min-width: 56px;
  border-radius: 12px;
  background: linear-gradient(135deg, #1762FB, #5aacff);
  color: #fff;
  font-size: 22px;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
}

.company-info {
  flex: 1;
  min-width: 0;
}

.company-name {
  font-size: 16px;
  font-weight: 600;
  color: #000;
  margin: 0 0 8px;
}

.company-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin: 0 0 8px;
}

.tag {
  display: inline-block;
  padding: 2px 10px;
  font-size: 12px;
  color: #1762FB;
  background: rgba(0, 122, 255, 0.08);
  border-radius: 4px;
}

.region-tag {
  color: #00b578;
  background: rgba(0, 181, 120, 0.08);
}

.company-desc {
  font-size: 13px;
  color: #666;
  line-height: 1.5;
  margin: 0;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* 公司详情容器 */
.detail-container {
  flex: 1;
  min-width: 0;
}

/* 公司详情头 */
.detail-header {
  margin-bottom: 16px;
}

.back-btn {
  padding: 8px 0;
  font-size: 14px;
  color: #1762FB;
  background: none;
  border: none;
  cursor: pointer;
}

.back-btn:hover {
  color: #0056b3;
}

.company-detail-card {
  display: flex;
  gap: 20px;
  padding: 24px;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  margin-bottom: 24px;
}

.detail-logo {
  width: 72px;
  height: 72px;
  min-width: 72px;
  border-radius: 16px;
  background: linear-gradient(135deg, #1762FB, #5aacff);
  color: #fff;
  font-size: 28px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
}

.detail-info {
  flex: 1;
}

.detail-name {
  font-size: 20px;
  font-weight: 700;
  color: #000;
  margin: 0 0 10px;
}

.detail-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin: 0 0 10px;
}

.detail-desc {
  font-size: 14px;
  color: #666;
  line-height: 1.6;
  margin: 0;
}

.section-title {
  font-size: 18px;
  font-weight: 600;
  color: #000;
  margin: 0 0 16px;
}

/* 职位列表 */
.job-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.job-card {
  padding: 20px;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  cursor: pointer;
  transition: box-shadow 0.2s;
}

.job-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.job-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.job-title {
  font-size: 16px;
  font-weight: 600;
  color: #000;
  margin: 0;
}

.job-salary {
  font-size: 16px;
  font-weight: 700;
  color: #e74c3c;
  white-space: nowrap;
}

.job-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  font-size: 13px;
  color: #666;
  margin-bottom: 8px;
}

.job-type {
  color: #1762FB;
}

.job-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-bottom: 8px;
}

.job-bottom {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
  color: #999;
  padding-top: 8px;
  border-top: 1px solid #f0f0f5;
}

.job-status {
  color: #00b578;
  font-weight: 500;
}

.loading-tip, .empty-tip {
  text-align: center;
  padding: 60px 20px;
  color: #999;
  background: #fff;
  border-radius: 10px;
}

/* ── 分页 ── */
.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 8px;
  margin-top: 20px;
  padding: 16px 0;
}

.pagination button {
  min-width: 40px;
  height: 36px;
  padding: 0 14px;
  border: 1px solid #e4e6ef;
  background: #fff;
  color: #555;
  border-radius: 6px;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.pagination button:hover:not(:disabled):not(.active) {
  border-color: #1762FB;
  color: #1762FB;
}

.pagination button.active {
  background: #1762FB;
  border-color: #1762FB;
  color: #fff;
}

.pagination button:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .jobs-body {
    flex-direction: column;
  }
  .filter-panel {
    width: 100%;
    position: static;
  }
}
</style>
