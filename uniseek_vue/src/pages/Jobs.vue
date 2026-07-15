<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { searchTasks, type TaskVO } from '@/api/task'
import { getCategories, type CategoryVO } from '@/api/category'
import { getRegionTree, type RegionVO } from '@/api/region'
import { useAppStore } from '@/stores/app'
import { Search } from '@element-plus/icons-vue'

const router = useRouter()
const route = useRoute()
const appStore = useAppStore()

const keyword = ref('')
const loading = ref(false)
const tasks = ref<TaskVO[]>([])
const total = ref(0)
const page = ref(1)
const pageSize = 12

const totalPages = computed(() => Math.ceil(total.value / pageSize))

const categoryTree = ref<CategoryVO[]>([])
const regionTree = ref<RegionVO[]>([])

// ── 格式化函数 ──
const formatSalary = (val: number): string => {
  if (val >= 1000) {
    const k = val / 1000
    return k % 1 === 0 ? k + 'K' : k.toFixed(1) + 'K'
  }
  return String(val)
}

const computeDisplayPages = (current: number, total: number): number[] => {
  const pages: number[] = []
  let start = Math.max(1, current - 2)
  let end = Math.min(total, current + 2)
  if (end - start < 4) {
    if (start === 1) end = Math.min(total, start + 4)
    else start = Math.max(1, end - 4)
  }
  for (let i = start; i <= end; i++) pages.push(i)
  return pages
}

const displayPages = computed(() => computeDisplayPages(page.value, totalPages.value))

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

const jobTypeStyle = (type: number) => {
  const map: Record<number, string> = {
    1: 'type-fulltime',
    2: 'type-parttime',
    3: 'type-intern'
  }
  return map[type] || ''
}

// ── 筛选状态 ──
const filter = reactive({
  regionId: undefined as number | undefined,
  categoryId: undefined as number | undefined,
  jobType: undefined as number | undefined,
  salaryMin: undefined as number | undefined,
  salaryMax: undefined as number | undefined,
  sortBy: 'create_time' as string,
  sortOrder: 'desc' as string
})

const regionCascaderValue = ref<number[]>([])
const categoryCascaderValue = ref<number[]>([])

const salaryPresets = [
  { label: '3K以下', min: undefined as number | undefined, max: 3000 },
  { label: '3K-5K', min: 3000, max: 5000 },
  { label: '5K-10K', min: 5000, max: 10000 },
  { label: '10K-15K', min: 10000, max: 15000 },
  { label: '15K-20K', min: 15000, max: 20000 },
  { label: '20K-50K', min: 20000, max: 50000 },
  { label: '50K以上', min: 50000, max: undefined as number | undefined }
]

const activeSalaryPreset = ref<number>(-1)

const setSalaryPreset = (index: number) => {
  if (activeSalaryPreset.value === index) {
    activeSalaryPreset.value = -1
    filter.salaryMin = undefined
    filter.salaryMax = undefined
  } else {
    activeSalaryPreset.value = index
    const preset = salaryPresets[index]
    filter.salaryMin = preset.min
    filter.salaryMax = preset.max
  }
  page.value = 1
  loadTasks()
}

// ── 级联选择器变更 ──
const onRegionChange = (val: number[]) => {
  filter.regionId = val.length > 0 ? val[val.length - 1] : undefined
  page.value = 1
  loadTasks()
}

const onCategoryChange = (val: number[]) => {
  filter.categoryId = val.length > 0 ? val[val.length - 1] : undefined
  page.value = 1
  loadTasks()
}

const setJobType = (type: number | undefined) => {
  filter.jobType = filter.jobType === type ? undefined : type
  page.value = 1
  loadTasks()
}

const setSort = (sortBy: string) => {
  if (filter.sortBy === sortBy) {
    filter.sortOrder = filter.sortOrder === 'desc' ? 'asc' : 'desc'
  } else {
    filter.sortBy = sortBy
    filter.sortOrder = 'desc'
  }
  page.value = 1
  loadTasks()
}

// ── 加载数据 ──
const loadTasks = async () => {
  loading.value = true
  try {
    const result = await searchTasks({
      keyword: keyword.value || undefined,
      categoryId: filter.categoryId,
      regionId: filter.regionId,
      jobType: filter.jobType,
      salaryMin: filter.salaryMin,
      salaryMax: filter.salaryMax,
      sortBy: filter.sortBy,
      sortOrder: filter.sortOrder,
      page: page.value,
      pageSize
    })
    tasks.value = result.records
    total.value = result.total
  } catch {
    /* ignore */
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  page.value = 1
  loadTasks()
}

const resetFilters = () => {
  filter.regionId = undefined
  filter.categoryId = undefined
  filter.jobType = undefined
  filter.salaryMin = undefined
  filter.salaryMax = undefined
  activeSalaryPreset.value = -1
  regionCascaderValue.value = []
  categoryCascaderValue.value = []
  keyword.value = ''
  page.value = 1
  loadTasks()
}

const goToDetail = (id: number) => {
  router.push(`/jobs/${id}`)
}

const goToPage = (p: number) => {
  if (p < 1 || p > totalPages.value || p === page.value) return
  page.value = p
  loadTasks()
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

// ── 初始化 ──
onMounted(async () => {
  const [cats, regions] = await Promise.all([
    getCategories().catch(() => [] as CategoryVO[]),
    getRegionTree().catch(() => [] as RegionVO[])
  ])
  categoryTree.value = cats
  regionTree.value = regions

  if (appStore.searchKeyword) {
    keyword.value = appStore.searchKeyword
    appStore.setSearchKeyword('')
  }

  const q = route.query.q as string
  if (q) keyword.value = q

  loadTasks()
})
</script>

<template>
  <div class="jobs-page">
    <!-- 搜索栏 -->
    <div class="search-bar">
      <div class="search-bar-inner">
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
    </div>

    <div class="jobs-body">
      <!-- 左侧筛选面板 -->
      <aside class="filter-panel">
        <div class="filter-section">
          <h4 class="filter-title">工作地点</h4>
          <el-cascader
            v-model="regionCascaderValue"
            :options="regionTree"
            :props="{ value: 'id', label: 'name', children: 'children', checkStrictly: true, emitPath: true }"
            placeholder="请选择地区"
            size="default"
            clearable
            style="width:100%"
            @change="onRegionChange as any"
          />
        </div>

        <div class="filter-section">
          <h4 class="filter-title">职位类别</h4>
          <el-cascader
            v-model="categoryCascaderValue"
            :options="categoryTree"
            :props="{ value: 'id', label: 'name', children: 'children', checkStrictly: true, emitPath: true }"
            placeholder="请选择类别"
            size="default"
            clearable
            style="width:100%"
            @change="onCategoryChange as any"
          />
        </div>

        <div class="filter-section">
          <h4 class="filter-title">工作类型</h4>
          <div class="filter-options">
            <span
              :class="['filter-option', { active: filter.jobType === undefined }]"
              @click="setJobType(undefined)"
            >不限</span>
            <span
              :class="['filter-option', { active: filter.jobType === 1 }]"
              @click="setJobType(1)"
            >全职</span>
            <span
              :class="['filter-option', { active: filter.jobType === 2 }]"
              @click="setJobType(2)"
            >兼职</span>
            <span
              :class="['filter-option', { active: filter.jobType === 3 }]"
              @click="setJobType(3)"
            >实习</span>
          </div>
        </div>

        <div class="filter-section">
          <h4 class="filter-title">薪资范围（月）</h4>
          <div class="filter-options salary-presets">
            <span
              v-for="(preset, idx) in salaryPresets"
              :key="idx"
              :class="['filter-option', { active: activeSalaryPreset === idx }]"
              @click="setSalaryPreset(idx)"
            >{{ preset.label }}</span>
          </div>
        </div>

        <button class="reset-btn" @click="resetFilters">重置筛选</button>
      </aside>

      <!-- 右侧内容 -->
      <div class="main-content">
        <!-- 排序栏 -->
        <div class="sort-bar">
          <span class="result-count">共 {{ total }} 个职位</span>
          <div class="sort-tabs">
            <span
              :class="['sort-tab', { active: filter.sortBy === 'create_time' }]"
              @click="setSort('create_time')"
            >
              最新
              <span v-if="filter.sortBy === 'create_time'" class="sort-arrow">{{ filter.sortOrder === 'desc' ? '↓' : '↑' }}</span>
            </span>
            <span
              :class="['sort-tab', { active: filter.sortBy === 'salary_max' }]"
              @click="setSort('salary_max')"
            >
              薪资
              <span v-if="filter.sortBy === 'salary_max'" class="sort-arrow">{{ filter.sortOrder === 'desc' ? '↓' : '↑' }}</span>
            </span>
            <span
              :class="['sort-tab', { active: filter.sortBy === 'popular' }]"
              @click="setSort('popular')"
            >
              热门
              <span v-if="filter.sortBy === 'popular'" class="sort-arrow">{{ filter.sortOrder === 'desc' ? '↓' : '↑' }}</span>
            </span>
          </div>
        </div>

        <!-- 职位列表 -->
        <div class="job-list">
          <template v-if="loading">
            <div v-for="i in 4" :key="i" class="job-card skeleton">
              <div class="sk-left">
                <div class="sk-line w-60"></div>
                <div class="sk-line w-40"></div>
                <div class="sk-line w-30"></div>
              </div>
              <div class="sk-right">
                <div class="sk-line w-20"></div>
                <div class="sk-line w-30"></div>
              </div>
            </div>
          </template>

          <template v-else-if="tasks.length > 0">
            <div
              v-for="task in tasks"
              :key="task.id"
              class="job-card"
              @click="goToDetail(task.id)"
            >
              <div class="job-card-body">
                <div class="job-info">
                  <div class="job-title-row">
                    <h3 class="job-title">{{ task.title }}</h3>
                    <span :class="['job-type-badge', jobTypeStyle(task.jobType)]">{{ jobTypeLabel(task.jobType) }}</span>
                    <span v-if="task.status === 2" class="job-type-badge type-full">已满员</span>
                  </div>
                  <p class="job-company">{{ task.enterpriseName }}</p>
                  <div class="job-meta">
                    <span class="meta-item" v-if="task.address">
                      <span class="meta-dot">···</span>{{ task.address }}
                    </span>
                    <span class="meta-item" v-if="task.categoryName">
                      <span class="meta-dot">···</span>{{ task.categoryName }}
                    </span>
                  </div>
                  <div class="job-tags" v-if="task.tag && task.tag.length > 0">
                    <span class="job-tag" v-for="(t, i) in task.tag.slice(0, 5)" :key="i">{{ t }}</span>
                  </div>
                </div>
                <div class="job-salary-info">
                  <span class="job-salary">{{ formatSalary(task.salaryMin) }}-{{ formatSalary(task.salaryMax) }}<small>/{{ salaryUnitLabel(task.salaryUnit) }}</small></span>
                  <span class="job-applicants" v-if="task.applicationCount > 0">{{ task.applicationCount }}人已投递</span>
                </div>
              </div>
            </div>
          </template>

          <template v-else>
            <div class="empty-state">
              <div class="empty-icon">*</div>
              <p>暂无符合条件的职位</p>
              <span class="empty-tip">试试调整筛选条件或搜索其他关键词</span>
            </div>
          </template>
        </div>

        <!-- 分页 -->
        <div class="pagination" v-if="totalPages > 1">
          <button :disabled="page === 1" @click="goToPage(page - 1)">上一页</button>
          <button
            v-for="p in displayPages"
            :key="p"
            :class="{ active: p === page }"
            @click="goToPage(p)"
          >{{ p }}</button>
          <button :disabled="page === totalPages" @click="goToPage(page + 1)">下一页</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.jobs-page {
  min-height: calc(100vh - 60px);
  background: #f5f7fa;
}

.search-bar {
  background: linear-gradient(rgba(13,27,42,0.2), rgba(13,27,42,0.2)), url('/background.jpg') center / cover no-repeat;
  padding: 20px 24px;
}

.search-bar-inner {
  max-width: 1200px;
  margin: 0 auto;
  display: flex;
  gap: 0;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 12px rgba(0,0,0,0.15);
}

.search-input {
  flex: 1;
}

.search-input :deep(.el-input__wrapper) {
  border-radius: 0;
  box-shadow: none !important;
  height: 48px;
}

.search-btn {
  width: 120px;
  height: 48px;
  border: none;
  background: #1762FB;
  color: #fff;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  flex-shrink: 0;
  transition: background 0.2s;
}

.search-btn:hover {
  background: #0062cc;
}

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
  width: 260px;
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

.filter-options {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.filter-option {
  padding: 6px 14px;
  font-size: 13px;
  border: 1px solid #e4e6ef;
  color: #666;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
  user-select: none;
}

.filter-option:hover {
  border-color: #1762FB;
  color: #1762FB;
}

.filter-option.active {
  border-color: #1762FB;
  background: rgba(0, 122, 255, 0.06);
  color: #1762FB;
  font-weight: 600;
}

.salary-presets .filter-option {
  width: calc(50% - 4px);
  text-align: center;
  padding: 8px 6px;
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

/* ── 职位卡片 ── */
.job-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.job-card {
  background: #fff;
  border-radius: 10px;
  padding: 18px 24px;
  cursor: pointer;
  box-shadow: 0 1px 4px rgba(0,0,0,0.06);
  transition: all 0.2s;
}

.job-card:hover {
  box-shadow: 0 4px 16px rgba(0, 122, 255, 0.12);
  transform: translateY(-1px);
}

.job-card-body {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 20px;
}

.job-info {
  flex: 1;
  min-width: 0;
}

.job-title-row {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 6px;
}

.job-title {
  font-size: 16px;
  font-weight: 600;
  color: #1a1a2e;
  margin: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 400px;
}

.job-type-badge {
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 4px;
  font-weight: 500;
  white-space: nowrap;
  flex-shrink: 0;
}

.type-fulltime {
  background: rgba(0, 122, 255, 0.08);
  color: #1762FB;
}

.type-parttime {
  background: rgba(231, 76, 60, 0.08);
  color: #e74c3c;
}

.type-intern {
  background: rgba(46, 204, 113, 0.08);
  color: #27ae60;
}

.type-full {
  background: rgba(149, 165, 166, 0.15);
  color: #7f8c8d;
}

.job-company {
  font-size: 14px;
  color: #444;
  margin: 0 0 8px;
}

.job-meta {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
  margin-bottom: 8px;
}

.meta-item {
  font-size: 13px;
  color: #888;
  display: flex;
  align-items: center;
  gap: 4px;
}

.meta-dot {
  font-size: 12px;
}

.job-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.job-tag {
  font-size: 12px;
  padding: 2px 8px;
  border-radius: 4px;
  background: #f5f7fa;
  color: #7f8c8d;
}

.job-salary-info {
  text-align: right;
  flex-shrink: 0;
  min-width: 140px;
}

.job-salary {
  display: block;
  font-size: 18px;
  font-weight: 700;
  color: #e74c3c;
  margin-bottom: 4px;
}

.job-salary small {
  font-size: 13px;
  font-weight: 500;
}

.job-applicants {
  font-size: 12px;
  color: #bbb;
}

/* ── 骨架屏 ── */
.job-card.skeleton {
  cursor: default;
  pointer-events: none;
}

.sk-line {
  height: 14px;
  background: linear-gradient(90deg, #eee 25%, #f5f5f5 50%, #eee 75%);
  background-size: 200% 100%;
  border-radius: 4px;
  margin-bottom: 10px;
  animation: shimmer 1.5s infinite;
}

.w-60 { width: 60%; }
.w-40 { width: 40%; }
.w-30 { width: 30%; }
.w-20 { width: 80px; }

@keyframes shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}

/* ── 空状态 ── */
.empty-state {
  text-align: center;
  padding: 80px 20px;
  background: #fff;
  border-radius: 10px;
}

.empty-icon {
  font-size: 48px;
  margin-bottom: 16px;
}

.empty-state p {
  font-size: 16px;
  color: #666;
  margin: 0 0 8px;
}

.empty-tip {
  font-size: 13px;
  color: #bbb;
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
  min-width: 36px;
  height: 36px;
  padding: 0 12px;
  border: 1px solid #e4e6ef;
  background: #fff;
  color: #666;
  border-radius: 6px;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
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

/* ── 响应式 ── */
@media (max-width: 900px) {
  .jobs-body {
    flex-direction: column;
    padding: 12px;
  }

  .filter-panel {
    width: 100%;
    position: static;
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
    padding: 12px 16px;
  }

  .filter-section {
    flex: 1;
    min-width: 140px;
    margin-bottom: 0;
    padding-bottom: 0;
    border-bottom: none;
  }

  .job-card-body {
    flex-direction: column;
  }

  .job-salary-info {
    text-align: left;
  }

  .job-title {
    font-size: 15px;
  }
}
</style>
