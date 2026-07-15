<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Search } from '@element-plus/icons-vue'
import { getEnterpriseList } from '@/api/enterprise'
import { getEnterprisePublishedTasks } from '@/api/task'
import { getRegionTree } from '@/api/region'
import type { EnterpriseInfo } from '@/api/enterprise'
import type { TaskVO } from '@/api/task'
import type { RegionVO } from '@/api/region'

const route = useRoute()
const router = useRouter()

// 列表数据
const enterprises = ref<EnterpriseInfo[]>([])
const loading = ref(false)

// 文本搜索
const keyword = ref('')

// 城市筛选
const allCities = ['北京', '上海', '广州', '深圳', '杭州', '成都', '武汉', '西安', '南京', '重庆', '天津', '苏州', '长沙', '郑州', '东莞', '青岛', '宁波', '厦门', '合肥', '福州']
const selectedCity = ref('')

// 地区树（用于解析 regionId 到名称）
const regions = ref<RegionVO[]>([])

// 地区名称映射
const regionNameMap = ref<Record<number, string>>({})

// 公司详情
const selectedEnterprise = ref<EnterpriseInfo | null>(null)
const enterpriseJobs = ref<TaskVO[]>([])
const jobsLoading = ref(false)
const showDetail = ref(false)

// 加载地区树
const loadRegions = async () => {
  try {
    const tree = await getRegionTree()
    regions.value = tree
    // 构建 ID → 名称映射
    const map: Record<number, string> = {}
    const walk = (list: RegionVO[]) => {
      for (const r of list) {
        map[r.id] = r.name
        if (r.children) walk(r.children)
      }
    }
    walk(tree)
    regionNameMap.value = map
  } catch {
    regions.value = []
  }
}

// 加载企业列表
const loadEnterprises = async () => {
  loading.value = true
  try {
    enterprises.value = await getEnterpriseList()
  } catch {
    enterprises.value = []
  } finally {
    loading.value = false
  }
}

// 筛选后的企业
const filteredEnterprises = computed(() => {
  return enterprises.value.filter(e => {
    // 文本搜索：按企业名或行业匹配
    const kw = keyword.value.trim().toLowerCase()
    if (kw && !e.companyName.toLowerCase().includes(kw) && !(e.industry || '').toLowerCase().includes(kw)) {
      return false
    }
    // 城市筛选
    if (selectedCity.value) {
      const name = e.regionId && regionNameMap.value[e.regionId] ? regionNameMap.value[e.regionId] : ''
      if (!name.includes(selectedCity.value)) return false
    }
    return true
  })
})

onMounted(() => {
  loadRegions()
  loadEnterprises().then(() => {
    const id = route.query.id
    if (id) {
      const target = enterprises.value.find(e => String(e.id) === id)
      if (target) viewCompany(target)
    }
  })
})

// 查看公司详情
const viewCompany = async (item: EnterpriseInfo) => {
  selectedEnterprise.value = item
  showDetail.value = true
  jobsLoading.value = true
  try {
    enterpriseJobs.value = await getEnterprisePublishedTasks(item.id)
  } catch {
    enterpriseJobs.value = []
  } finally {
    jobsLoading.value = false
  }
}

// 返回列表
const backToList = () => {
  showDetail.value = false
  selectedEnterprise.value = null
  enterpriseJobs.value = []
}

// 跳转职位详情
const goToJob = (jobId: number) => {
  router.push(`/jobs/${jobId}`)
}

// 薪资单位
const salaryUnitLabel = (unit?: number) => {
  if (unit === 0) return '/日'
  if (unit === 1) return '/时'
  return '/月'
}

// 工作类型
const jobTypeLabel = (type?: number) => {
  if (type === 1) return '全职'
  if (type === 2) return '兼职'
  if (type === 3) return '实习'
  return ''
}
</script>

<template>
  <div class="company-page">
    <!-- 公司列表视图 -->
    <template v-if="!showDetail">
      <div class="page-header">
        <h2 class="page-title">企业列表</h2>
        <p class="page-desc">所有已认证的企业</p>
      </div>

      <!-- 搜索栏 -->
      <div class="search-bar">
        <div class="search-input-wrap">
          <el-icon :size="16" class="search-icon"><Search /></el-icon>
          <input
            v-model="keyword"
            type="text"
            class="search-input"
            placeholder="搜索企业名称、行业"
          />
        </div>
        <div class="city-select-wrap">
          <span class="city-label">城市</span>
          <select v-model="selectedCity" class="city-select">
            <option value="">全部城市</option>
            <option v-for="c in allCities" :key="c" :value="c">{{ c }}</option>
          </select>
        </div>
      </div>

      <div v-if="loading" class="loading-tip">加载中...</div>

      <div v-else-if="filteredEnterprises.length === 0" class="empty-tip">暂无已认证的企业</div>

      <div v-else class="company-list">
        <div
          v-for="item in filteredEnterprises"
          :key="item.id"
          class="company-card"
          @click="viewCompany(item)"
        >
          <div class="company-logo">{{ item.companyName.charAt(0) }}</div>
          <div class="company-info">
            <h3 class="company-name">{{ item.companyName }}</h3>
            <p class="company-meta">
              <span v-if="item.industry" class="tag">{{ item.industry }}</span>
              <span v-if="item.regionId && regionNameMap[item.regionId]" class="tag region-tag">{{ regionNameMap[item.regionId] }}</span>
            </p>
            <p class="company-desc">{{ item.description || '暂无简介' }}</p>
          </div>
        </div>
      </div>
    </template>

    <!-- 公司详情视图 -->
    <template v-else-if="selectedEnterprise">
      <div class="detail-header">
        <button class="back-btn" @click="backToList">&larr; 返回企业列表</button>
      </div>

      <div class="company-detail-card">
        <div class="detail-logo">{{ selectedEnterprise.companyName.charAt(0) }}</div>
        <div class="detail-info">
          <h2 class="detail-name">{{ selectedEnterprise.companyName }}</h2>
          <p class="detail-meta">
            <span v-if="selectedEnterprise.industry" class="tag">{{ selectedEnterprise.industry }}</span>
            <span v-if="selectedEnterprise.regionId && regionNameMap[selectedEnterprise.regionId]" class="tag region-tag">{{ regionNameMap[selectedEnterprise.regionId] }}</span>
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
    </template>
  </div>
</template>

<style scoped>
.company-page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 32px 24px;
}

.page-header {
  margin-bottom: 24px;
}

.page-title {
  font-size: 22px;
  font-weight: 600;
  color: #000;
  margin: 0 0 6px;
}

.page-desc {
  font-size: 14px;
  color: #666;
  margin: 0;
}

/* 搜索栏 */
.search-bar {
  display: flex;
  gap: 12px;
  padding: 16px 20px;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  margin-bottom: 20px;
  align-items: center;
}

.search-input-wrap {
  flex: 1;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 14px;
  border: 1px solid #dcdce4;
  border-radius: 8px;
  background: #f8f9fb;
}

.search-input-wrap:focus-within {
  border-color: #1762FB;
}

.search-icon {
  color: #999;
  flex-shrink: 0;
}

.search-input {
  flex: 1;
  border: none;
  outline: none;
  padding: 10px 0;
  font-size: 14px;
  background: transparent;
  color: #000;
}

.city-select-wrap {
  display: flex;
  align-items: center;
  gap: 8px;
}

.city-label {
  font-size: 14px;
  color: #333;
  font-weight: 500;
  white-space: nowrap;
}

.city-select {
  padding: 8px 32px 8px 12px;
  font-size: 14px;
  border: 1px solid #dcdce4;
  border-radius: 8px;
  background: #fff;
  color: #000;
  cursor: pointer;
  appearance: auto;
  min-width: 120px;
}

.city-select:focus {
  border-color: #1762FB;
  outline: none;
}

/* 企业列表 */
.company-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(360px, 1fr));
  gap: 16px;
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
  padding: 48px;
  color: #999;
  background: #fff;
  border-radius: 12px;
}
</style>
