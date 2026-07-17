<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { searchTasks, getAllTags, type TaskVO } from '@/api/task'
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

// 多标签筛选
const tags = ref<string[]>([])
const tagInput = ref('')
const allTags = ref<string[]>([])          // 所有可用标签（从后端加载）
const showTagSuggestions = ref(false)      // 是否显示推荐下拉
const tagInputRef = ref<any>(null)         // 标签输入框引用，用于手动失焦

// 计算推荐标签：有输入时模糊匹配，无输入时随机取 8 个
const suggestedTags = computed(() => {
  const input = tagInput.value.trim()
  let filtered = allTags.value.filter(t => !tags.value.includes(t))
  if (input) {
    filtered = filtered.filter(t => t.includes(input))
  }
  // 随机打乱后取前 8 个
  const shuffled = [...filtered].sort(() => Math.random() - 0.5)
  return shuffled.slice(0, 8)
})

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

const salaryRangeText = (min: number, max: number, unit: number): string => {
  if (min === 0 && max === 0) return '面议'
  return `${formatSalary(min)}-${formatSalary(max)}/${salaryUnitLabel(unit)}`
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
  regionIds: undefined as string | undefined,
  categoryId: undefined as number | undefined,
  categoryIds: undefined as string | undefined,
  jobType: undefined as number | undefined,
  salaryMin: undefined as number | undefined,
  salaryMax: undefined as number | undefined,
  salaryUnit: undefined as number | undefined,
  sortBy: 'create_time' as string,
  sortOrder: 'desc' as string
})

const regionCascaderValue = ref<number[]>([])
const categoryCascaderValue = ref<number | undefined>(undefined)

// ── 结算方式 & 薪资输入 ──
const salaryMinInput = ref<number | undefined>(undefined)
const salaryMaxInput = ref<number | undefined>(undefined)

const settlementType = ref<number | undefined>(undefined)

// 是否包含「面议」（salary_min=0, salary_max=0）的职位，默认勾选
const includeNegotiable = ref(true)

const unitLabel = computed(() => {
  if (settlementType.value === undefined || settlementType.value === 2) return '元/月'
  if (settlementType.value === 0) return '元/天'
  if (settlementType.value === 1) return '元/时'
  return '元/月'
})

const setSettlementType = (val: number | undefined) => {
  settlementType.value = val
  filter.salaryUnit = val
  page.value = 1
  loadTasks()
}

const isSalaryEmpty = computed(() => {
  const minEmpty = salaryMinInput.value == null || Number.isNaN(salaryMinInput.value)
  const maxEmpty = salaryMaxInput.value == null || Number.isNaN(salaryMaxInput.value)
  return minEmpty && maxEmpty
})

const onSalaryChange = () => {
  filter.salaryMin = salaryMinInput.value
  filter.salaryMax = salaryMaxInput.value
  page.value = 1
  loadTasks()
}

// 递归收集所有子孙分类 ID
const collectDescendantIds = (nodes: CategoryVO[], targetId: number): number[] => {
  for (const node of nodes) {
    if (node.id === targetId) {
      const ids: number[] = [node.id]
      const collect = (children: CategoryVO[]) => {
        for (const child of children) {
          ids.push(child.id)
          if (child.children?.length) collect(child.children)
        }
      }
      if (node.children?.length) collect(node.children)
      return ids
    }
    if (node.children?.length) {
      const result = collectDescendantIds(node.children, targetId)
      if (result.length > 0) return result
    }
  }
  return []
}

// 递归收集所有子孙地区 ID
const collectRegionDescendantIds = (nodes: RegionVO[], targetId: number): number[] => {
  for (const node of nodes) {
    if (node.id === targetId) {
      const ids: number[] = [node.id]
      const collect = (children: RegionVO[]) => {
        for (const child of children) {
          ids.push(child.id)
          if (child.children?.length) collect(child.children)
        }
      }
      if (node.children?.length) collect(node.children)
      return ids
    }
    if (node.children?.length) {
      const result = collectRegionDescendantIds(node.children, targetId)
      if (result.length > 0) return result
    }
  }
  return []
}

// ── 级联选择器变更 ──
const onRegionChange = (val: number[]) => {
  filter.regionId = val.length > 0 ? val[val.length - 1] : undefined
  filter.regionIds = undefined
  if (val.length > 0) {
    const ids = collectRegionDescendantIds(regionTree.value, val[val.length - 1])
    if (ids.length > 1) {
      filter.regionIds = ids.join(',')
    }
  }
  page.value = 1
  loadTasks()
}

const onCategoryChange = (val: number | undefined) => {
  filter.categoryId = val ?? undefined
  filter.categoryIds = undefined
  if (val != null) {
    const ids = collectDescendantIds(categoryTree.value, val)
    if (ids.length > 1) {
      filter.categoryIds = ids.join(',')
    }
  }
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
      categoryId: filter.categoryIds ? undefined : filter.categoryId,
      categoryIds: filter.categoryIds,
      regionId: filter.regionIds ? undefined : filter.regionId,
      regionIds: filter.regionIds,
      jobType: filter.jobType,
      salaryMin: filter.salaryMin,
      salaryMax: filter.salaryMax,
      salaryUnit: filter.salaryUnit,
      includeNegotiable: includeNegotiable.value,
      tags: tags.value.length > 0 ? tags.value.join(',') : undefined,
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
  filter.regionIds = undefined
  filter.categoryId = undefined
  filter.categoryIds = undefined
  filter.jobType = undefined
  filter.salaryMin = undefined
  filter.salaryMax = undefined
  filter.salaryUnit = undefined
  tags.value = []
  settlementType.value = undefined
  salaryMinInput.value = undefined
  salaryMaxInput.value = undefined
  includeNegotiable.value = true
  regionCascaderValue.value = []
  categoryCascaderValue.value = undefined
  keyword.value = ''
  page.value = 1
  loadTasks()
}

// ── 多标签操作 ──
const addTag = () => {
  const val = tagInput.value.trim()
  if (!val) return
  // 避免重复标签
  if (tags.value.includes(val)) {
    tagInput.value = ''
    return
  }
  tags.value.push(val)
  tagInput.value = ''
  showTagSuggestions.value = false
  page.value = 1
  loadTasks()
}

const removeTag = (index: number) => {
  tags.value.splice(index, 1)
  page.value = 1
  loadTasks()
}

// ── 标签推荐交互 ──
const onFocusTagInput = () => {
  showTagSuggestions.value = true
}
const onBlurTagInput = () => {
  // 延迟关闭，让点击推荐项的事件先触发
  setTimeout(() => { showTagSuggestions.value = false }, 200)
}
const addSuggestionTag = (tag: string) => {
  if (tags.value.includes(tag)) return
  tags.value.push(tag)
  tagInput.value = ''
  showTagSuggestions.value = false
  tagInputRef.value?.blur()
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
  const [cats, regions, tagList] = await Promise.all([
    getCategories().catch(() => [] as CategoryVO[]),
    getRegionTree().catch(() => [] as RegionVO[]),
    getAllTags().catch(() => [] as string[])
  ])
  allTags.value = tagList || []
  categoryTree.value = cats
  regionTree.value = regions

  if (appStore.searchKeyword) {
    keyword.value = appStore.searchKeyword
    appStore.setSearchKeyword('')
  }

  const q = route.query.q as string
  if (q) keyword.value = q

  const categoryIdParam = route.query.categoryId as string
  if (categoryIdParam) {
    filter.categoryId = Number(categoryIdParam)
    if (cats.length > 0) {
      const ids = collectDescendantIds(cats, filter.categoryId)
      if (ids.length > 1) {
        filter.categoryIds = ids.join(',')
      }
      categoryCascaderValue.value = filter.categoryId
    }
  }

  // 读取 tag URL 参数（支持单标签和多标签兜底）
  const tagParam = route.query.tag as string
  if (tagParam) {
    tags.value = tagParam.split(',').map(t => t.trim()).filter(Boolean)
  }

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
          placeholder="搜索职位名称"
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
            :props="{ value: 'id', label: 'name', children: 'children', checkStrictly: true, emitPath: true, expandTrigger: 'hover' }"
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
            :props="{ value: 'id', label: 'name', children: 'children', checkStrictly: true, emitPath: false, expandTrigger: 'hover' }"
            placeholder="请选择类别"
            size="default"
            clearable
            style="width:100%"
            @change="onCategoryChange"
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

        <!-- 结算方式 -->
        <div class="filter-section">
          <h4 class="filter-title">结算方式</h4>
          <div class="filter-options">
            <span
              :class="['filter-option', { active: settlementType === undefined }]"
              @click="setSettlementType(undefined)"
            >不限</span>
            <span
              :class="['filter-option', { active: settlementType === 2 }]"
              @click="setSettlementType(2)"
            >月结</span>
            <span
              :class="['filter-option', { active: settlementType === 0 }]"
              @click="setSettlementType(0)"
            >日结</span>
            <span
              :class="['filter-option', { active: settlementType === 1 }]"
              @click="setSettlementType(1)"
            >时薪</span>
          </div>
        </div>

        <!-- 标签筛选 -->
        <div class="filter-section">
          <h4 class="filter-title">职位标签</h4>
          <div class="tag-input-row">
            <div class="tag-input-relative">
              <el-input
                ref="tagInputRef"
                v-model="tagInput"
                placeholder="输入标签后按 Enter 添加"
                size="small"
                clearable
                class="tag-input"
                @keyup.enter="addTag"
                @focus="onFocusTagInput"
                @blur="onBlurTagInput"
              />
              <!-- 推荐标签下拉 -->
              <div class="tag-suggestions" v-if="showTagSuggestions && suggestedTags.length > 0">
                <div class="tag-suggestions-header">推荐标签</div>
                <div class="tag-suggestions-body">
                  <span
                    class="tag-suggestion-item"
                    v-for="t in suggestedTags"
                    :key="t"
                    @mousedown.prevent="addSuggestionTag(t)"
                  >
                    {{ t }}
                  </span>
                </div>
              </div>
            </div>
            <button class="tag-add-btn" @click="addTag" :disabled="!tagInput.trim()">添加</button>
          </div>
          <div class="tag-list" v-if="tags.length > 0">
            <span class="tag-chip" v-for="(t, i) in tags" :key="i">
              {{ t }}
              <span class="tag-chip-close" @click="removeTag(i)">&times;</span>
            </span>
          </div>
        </div>

        <div class="filter-section">
          <h4 class="filter-title">薪资范围</h4>
          <div class="salary-input-row">
            <div class="salary-input-wrapper">
              <el-input v-model.number="salaryMinInput" :placeholder="`最低薪资__${unitLabel}`" size="small" clearable />
            </div>
            <span class="salary-separator">—</span>
            <div class="salary-input-wrapper">
              <el-input v-model.number="salaryMaxInput" :placeholder="`最高薪资__${unitLabel}`" size="small" clearable />
            </div>
          </div>
          <button class="salary-confirm-btn" :disabled="isSalaryEmpty" @click="onSalaryChange">确定</button>
          <label class="include-negotiable">
            <input type="checkbox" v-model="includeNegotiable" @change="onSalaryChange" />
            <span>包含面议</span>
          </label>
          <p v-if="settlementType === undefined" class="salary-hint">* 日结/时薪岗位将按 22天/8小时 统一折算为预估月薪进行匹配</p>
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
                  <span class="job-salary">{{ salaryRangeText(task.salaryMin, task.salaryMax, task.salaryUnit) }}</span>
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
  height: 48px;
  gap: 0;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 12px rgba(0,0,0,0.15);
}

.search-input {
  flex: 1;
  height: 100%;
}

.search-input :deep(.el-input) {
  height: 100%;
}

.search-input :deep(.el-input__wrapper) {
  border-radius: 0;
  box-shadow: none !important;
  height: 100%;
  box-sizing: border-box;
}

.search-btn {
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

.search-btn:hover {
  background: #0062cc;
}

.active-filters {
  max-width: 1200px;
  margin: 0 auto;
  padding: 8px 24px 0;
}
.filter-chip {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 12px;
  font-size: 13px;
  background: rgba(0, 122, 255, 0.08);
  color: #1762FB;
  border: 1px solid rgba(0, 122, 255, 0.2);
  border-radius: 16px;
}
.chip-close {
  cursor: pointer;
  font-size: 16px;
  line-height: 1;
  color: #1762FB;
  opacity: 0.6;
  transition: opacity 0.2s;
}
.chip-close:hover {
  opacity: 1;
}

.tag-input-row {
  display: flex;
  gap: 6px;
  width: 100%;
}

.tag-input-relative {
  position: relative;
  flex: 1;
  min-width: 0;
}

.tag-input {
  width: 100%;
}

.tag-input :deep(.el-input__wrapper) {
  border-radius: 6px;
  padding: 1px 8px;
}

.tag-add-btn {
  padding: 0 10px;
  border: none;
  background: #1762FB;
  color: #fff;
  font-size: 12px;
  border-radius: 6px;
  cursor: pointer;
  white-space: nowrap;
  flex-shrink: 0;
  transition: background 0.2s;
}

.tag-add-btn:hover:not(:disabled) {
  background: #0062cc;
}

.tag-add-btn:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.tag-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 8px;
}

.tag-chip {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 10px;
  font-size: 13px;
  background: rgba(0, 122, 255, 0.08);
  color: #1762FB;
  border: 1px solid rgba(0, 122, 255, 0.2);
  border-radius: 16px;
}

.tag-chip-close {
  cursor: pointer;
  font-size: 15px;
  line-height: 1;
  color: #1762FB;
  opacity: 0.6;
  transition: opacity 0.2s;
}

.tag-chip-close:hover {
  opacity: 1;
}

.tag-suggestions {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  background: #fff;
  border: 1px solid #e4e6ef;
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.10);
  z-index: 100;
  margin-top: 4px;
  overflow: hidden;
}

.tag-suggestions-header {
  padding: 6px 12px;
  font-size: 12px;
  color: #999;
  background: #fafafa;
  border-bottom: 1px solid #f0f0f5;
}

.tag-suggestions-body {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  padding: 8px 12px;
}

.tag-suggestion-item {
  padding: 4px 10px;
  font-size: 13px;
  border: 1px solid #e4e6ef;
  color: #666;
  border-radius: 14px;
  cursor: pointer;
  transition: all 0.15s;
  user-select: none;
}

.tag-suggestion-item:hover {
  border-color: #1762FB;
  color: #1762FB;
  background: rgba(0, 122, 255, 0.04);
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

.salary-input-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.salary-input-wrapper {
  flex: 1;
  position: relative;
}

.salary-input-wrapper :deep(.el-input__wrapper) {
  padding: 1px 4px;
}

.salary-input-wrapper :deep(.el-input__inner) {
  font-size: 12px;
}

.salary-input-wrapper :deep(.el-input__inner::placeholder) {
  font-size: 11px;
}

.salary-separator {
  color: #ccc;
  flex-shrink: 0;
}

.salary-confirm-btn {
  width: 100%;
  margin-top: 10px;
  padding: 6px 0;
  border: none;
  background: #1762FB;
  color: #fff;
  font-size: 13px;
  border-radius: 6px;
  cursor: pointer;
  transition: background 0.2s;
}
.salary-confirm-btn:hover:not(:disabled) {
  background: #0062cc;
}
.salary-confirm-btn:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.include-negotiable {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 10px;
  font-size: 13px;
  color: #666;
  cursor: pointer;
  user-select: none;
}
.include-negotiable input[type="checkbox"] {
  width: 14px;
  height: 14px;
  cursor: pointer;
  accent-color: #1762FB;
}

.salary-hint {
  font-size: 12px;
  color: #999;
  margin: 8px 0 0;
  line-height: 1.5;
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
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
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
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  min-width: 0;
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
