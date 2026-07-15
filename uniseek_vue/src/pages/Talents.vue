<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { Search, User } from '@element-plus/icons-vue'
import { searchPublishedResumes } from '@/api/resume'
import type { ResumeData } from '@/api/resume'

// 人才筛选标签
const talentFilters = ['全部', '有附件简历', '在校生', '有工作经验']
const activeFilter = ref('全部')
const keyword = ref('')
const talents = ref<ResumeData[]>([])
const loading = ref(false)

const loadTalents = async () => {
  loading.value = true
  try {
    talents.value = await searchPublishedResumes(keyword.value || undefined)
  } catch {
    talents.value = []
  } finally {
    loading.value = false
  }
}

onMounted(() => loadTalents())

// 解析技能标签
const parseSkills = (skillsStr?: string): string[] => {
  if (!skillsStr) return []
  try {
    return JSON.parse(skillsStr)
  } catch {
    return skillsStr.split(',').filter(s => s.trim())
  }
}

const hasAttachment = (t: ResumeData) => !!t.attachmentUrl
const isStudent = (t: ResumeData) => t.school?.includes('大学') && (!t.experience || t.experience.length < 10)
const hasExperience = (t: ResumeData) => !!t.experience && t.experience.length > 10

const filteredTalents = computed(() => {
  return talents.value.filter(t => {
    const matchFilter = activeFilter.value === '全部' ? true
      : activeFilter.value === '有附件简历' ? hasAttachment(t)
      : activeFilter.value === '在校生' ? isStudent(t)
      : activeFilter.value === '有工作经验' ? hasExperience(t) : true
    return matchFilter
  })
})

// 简历详情弹窗
const detailVisible = ref(false)
const selectedTalent = ref<ResumeData | null>(null)

const viewDetail = (talent: ResumeData) => {
  selectedTalent.value = talent
  detailVisible.value = true
}

const genderLabel = (g?: number) => {
  if (g === 0) return '男'
  if (g === 1) return '女'
  return '未设置'
}
</script>

<template>
  <div class="talents-page">
    <div class="talents-header">
      <h2 class="talents-title">人才库</h2>
      <div class="talents-filter">
        <el-input
          v-model="keyword"
          placeholder="搜索姓名、技能标签"
          :prefix-icon="Search"
          clearable
          class="search-input"
        />
        <div class="filter-tabs">
          <button
            v-for="filter in talentFilters"
            :key="filter"
            :class="['filter-tab', { active: activeFilter === filter }]"
            @click="activeFilter = filter"
          >
            {{ filter }}
          </button>
        </div>
      </div>
    </div>

    <div class="talents-list">
      <el-card
        v-for="talent in filteredTalents"
        :key="talent.id"
        class="talent-card"
        shadow="hover"
        v-loading="loading"
        @click="viewDetail(talent)"
      >
        <div class="talent-main">
          <div class="talent-avatar">{{ (talent.realName || '?').charAt(0) }}</div>
          <div class="talent-info">
            <div class="talent-name">
              {{ talent.realName || '未实名' }}
              <span class="talent-meta">{{ talent.education || '未填' }}</span>
            </div>
            <div class="talent-school">{{ talent.school || '未填' }}</div>
            <div class="talent-tags">
              <el-tag v-for="tag in parseSkills(talent.skills)" :key="tag" size="small" class="talent-tag">{{ tag }}</el-tag>
            </div>
            <div class="talent-summary">{{ talent.experience ? talent.experience.substring(0, 100) + '...' : '暂无工作经历' }}</div>
          </div>
        </div>
      </el-card>

      <div v-if="!loading && filteredTalents.length === 0" class="empty-tip">
        暂无匹配人才
      </div>
    </div>

    <!-- 简历详情弹窗 -->
    <el-dialog v-model="detailVisible" title="简历详情" width="600px" :close-on-click-modal="false">
      <div v-if="selectedTalent" class="detail-content">
        <div class="detail-section">
          <h4>基本信息</h4>
          <div class="detail-row"><span class="label">姓名</span><span>{{ selectedTalent.realName || '未实名' }}</span></div>
          <div class="detail-row"><span class="label">性别</span><span>{{ genderLabel(selectedTalent.gender) }}</span></div>
          <div class="detail-row"><span class="label">出生日期</span><span>{{ selectedTalent.birthDate || '未填' }}</span></div>
        </div>
        <div class="detail-section">
          <h4>教育背景</h4>
          <div class="detail-row"><span class="label">学历</span><span>{{ selectedTalent.education || '未填' }}</span></div>
          <div class="detail-row"><span class="label">毕业院校</span><span>{{ selectedTalent.school || '未填' }}</span></div>
        </div>
        <div class="detail-section">
          <h4>技能标签</h4>
          <div class="detail-tags">
            <el-tag v-for="tag in parseSkills(selectedTalent.skills)" :key="tag" size="small" class="talent-tag">{{ tag }}</el-tag>
            <span v-if="!selectedTalent.skills" class="empty-text">无</span>
          </div>
        </div>
        <div class="detail-section">
          <h4>工作/实践经历</h4>
          <div class="detail-experience">{{ selectedTalent.experience || '暂无' }}</div>
        </div>
        <div class="detail-section" v-if="selectedTalent.attachmentUrl">
          <h4>附件简历</h4>
          <a :href="selectedTalent.attachmentUrl" target="_blank" class="attach-link">{{ selectedTalent.attachmentUrl }}</a>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<style scoped>
.talents-page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 24px;
}

.talents-header {
  background: #fff;
  padding: 16px 24px;
  border-radius: 8px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  margin-bottom: 24px;
}

.talents-title {
  font-size: 18px;
  font-weight: 600;
  color: #000;
  margin: 0 0 16px;
}

.talents-filter {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 16px;
}

.search-input {
  width: 280px;
}

.filter-tabs {
  display: flex;
  gap: 4px;
}

.filter-tab {
  padding: 8px 16px;
  font-size: 14px;
  border: none;
  background: transparent;
  color: #000;
  border-radius: 4px;
  cursor: pointer;
}

.filter-tab.active {
  background: #409eff;
  color: #fff;
}

.talents-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.talent-card {
  color: #000;
  cursor: pointer;
  transition: transform 0.15s;
}

.talent-card:hover {
  transform: translateY(-2px);
}

.talent-main {
  display: flex;
  gap: 16px;
}

.talent-avatar {
  width: 56px;
  height: 56px;
  line-height: 56px;
  text-align: center;
  border-radius: 50%;
  background: #409eff;
  color: #fff;
  font-size: 20px;
  flex-shrink: 0;
}

.talent-info {
  flex: 1;
}

.talent-name {
  font-size: 16px;
  font-weight: 600;
  color: #000;
  margin-bottom: 4px;
}

.talent-meta {
  font-size: 13px;
  color: #666;
  font-weight: normal;
  margin-left: 8px;
}

.talent-school {
  font-size: 13px;
  color: #666;
  margin-bottom: 8px;
}

.talent-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 8px;
}

.talent-tag {
  color: #000;
}

.talent-summary {
  font-size: 14px;
  color: #333;
  line-height: 1.5;
}

.talent-extra {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 16px;
  padding-top: 12px;
  border-top: 1px solid #eee;
  font-size: 13px;
  color: #666;
}

.empty-tip {
  text-align: center;
  padding: 48px;
  color: #999;
  background: #fff;
  border-radius: 8px;
}

.api-tip {
  margin-top: 16px;
  text-align: center;
  font-size: 13px;
  color: #999;
}

/* 简历详情弹窗 */
.detail-content {
  max-height: 60vh;
  overflow-y: auto;
}

.detail-section {
  margin-bottom: 20px;
}

.detail-section h4 {
  font-size: 15px;
  font-weight: 600;
  color: #000;
  margin: 0 0 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid #f0f0f5;
}

.detail-row {
  display: flex;
  padding: 6px 0;
  font-size: 14px;
}

.detail-row .label {
  width: 90px;
  color: #666;
  flex-shrink: 0;
}

.detail-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.detail-experience {
  font-size: 14px;
  line-height: 1.7;
  white-space: pre-wrap;
  color: #333;
}

.attach-link {
  color: #007AFF;
  font-size: 14px;
  text-decoration: none;
}

.empty-text {
  color: #999;
  font-size: 13px;
}
</style>
