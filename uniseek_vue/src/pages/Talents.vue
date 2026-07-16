<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Search, User, View, Download, ChatDotRound } from '@element-plus/icons-vue'
import { searchPublishedResumes } from '@/api/resume'
import { createDirectSession } from '@/api/chat'
import { ElMessage } from 'element-plus'
import type { ResumeData } from '@/api/resume'
import PdfPreview from '@/components/PdfPreview.vue'

const getFileName = (url: string) => {
  const name = url.substring(url.lastIndexOf('/') + 1)
  return decodeURIComponent(name) || '简历附件'
}

const fileDialogVisible = ref(false)
const fileDialogUrl = ref('')
const pdfPreviewVisible = ref(false)
const openFileAction = (url: string) => {
  fileDialogUrl.value = url
  fileDialogVisible.value = true
}
const previewFile = () => {
  pdfPreviewVisible.value = true
  fileDialogVisible.value = false
}
const downloadFile = () => {
  const a = document.createElement('a')
  a.href = fileDialogUrl.value
  a.download = getFileName(fileDialogUrl.value)
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  fileDialogVisible.value = false
}

const router = useRouter()

// 人才筛选标签
const talentFilters = ['全部', '有附件简历', '在校生', '有工作经验']
const activeFilter = ref('全部')
const keyword = ref('')
const talents = ref<ResumeData[]>([])
const loading = ref(false)
const total = ref(0)
const page = ref(1)
const pageSize = 20

const loadTalents = async () => {
  loading.value = true
  try {
    const res = await searchPublishedResumes(keyword.value || undefined, page.value, pageSize)
    talents.value = res.records
    total.value = res.total
  } catch {
    talents.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  page.value = 1
  loadTalents()
}

const handlePageChange = (p: number) => {
  page.value = p
  loadTalents()
}

const contactingId = ref<number | null>(null)
const contactTalent = async (talent: ResumeData) => {
  if (!talent.userId) {
    ElMessage.warning('无法获取用户信息')
    return
  }
  contactingId.value = talent.id!
  try {
    const sessionId = await createDirectSession(talent.userId)
    router.push(`/messages?chat=${sessionId}`)
  } catch {
    ElMessage.error('创建会话失败，请重试')
  } finally {
    contactingId.value = null
  }
}

watch(keyword, (val) => {
  if (!val) {
    page.value = 1
    loadTalents()
  }
})

onMounted(() => loadTalents())

// 预解析技能标签，避免模板中重复调用
const parsedSkills = computed(() => {
  const map = new Map<number, string[]>()
  for (const t of talents.value) {
    if (t.id != null) map.set(t.id, parseSkills(t.skills))
  }
  return map
})

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
          @keyup.enter="handleSearch"
        />
        <button class="search-btn" @click="handleSearch">搜索</button>
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

    <div class="talents-list" v-loading="loading">
      <el-card
        v-for="talent in filteredTalents"
        :key="talent.id"
        class="talent-card"
        shadow="hover"
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
              <el-tag v-for="tag in parsedSkills.get(talent.id!)" :key="tag" size="small" class="talent-tag">{{ tag }}</el-tag>
            </div>
            <div class="talent-summary">{{ talent.experience ? talent.experience.substring(0, 100) + '...' : '暂无工作经历' }}</div>
          </div>
          <button
            class="contact-btn"
            :disabled="contactingId === talent.id"
            @click.stop="contactTalent(talent)"
          >
            <el-icon :size="16"><ChatDotRound /></el-icon>
            {{ contactingId === talent.id ? '联系中...' : '联系求职者' }}
          </button>
        </div>
      </el-card>

      <div v-if="!loading && filteredTalents.length === 0" class="empty-tip">
        暂无匹配人才
      </div>

      <div v-if="total > pageSize" class="pagination-wrap">
        <el-pagination
          v-model:current-page="page"
          :page-size="pageSize"
          :total="total"
          layout="prev, pager, next"
          @current-change="handlePageChange"
        />
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
          <span class="attach-link clickable" @click="openFileAction(selectedTalent.attachmentUrl!)">{{ getFileName(selectedTalent.attachmentUrl) }}</span>
        </div>
      </div>
    </el-dialog>

    <!-- 文件操作弹窗 -->
    <el-dialog v-model="fileDialogVisible" title="附件简历" width="300px" align-center>
      <div class="file-action-buttons">
        <el-button type="primary" size="large" @click="previewFile" class="file-action-btn">
          <el-icon><View /></el-icon>预览
        </el-button>
        <el-button type="primary" size="large" @click="downloadFile" class="file-action-btn">
          <el-icon><Download /></el-icon>下载
        </el-button>
      </div>
    </el-dialog>

    <!-- PDF 预览弹窗 -->
    <PdfPreview v-model:visible="pdfPreviewVisible" :url="fileDialogUrl" />
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

.search-btn {
  height: 32px;
  padding: 0 14px;
  border: none;
  background: #1762FB;
  color: #fff;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  border-radius: 4px;
  flex-shrink: 0;
  transition: background 0.2s;
}

.search-btn:hover {
  background: #0062cc;
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
  min-height: 200px;
}

.pagination-wrap {
  display: flex;
  justify-content: center;
  padding: 16px 0;
}

.talent-card {
  color: #000;
  cursor: pointer;
  transition: transform 0.15s;
  position: relative;
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

.contact-btn {
  align-self: flex-start;
  flex-shrink: 0;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 6px 14px;
  border: 1px solid #1762FB;
  background: #fff;
  color: #1762FB;
  font-size: 13px;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.contact-btn:hover:not(:disabled) {
  background: #1762FB;
  color: #fff;
}

.contact-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
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
  color: #1762FB;
  font-size: 14px;
  text-decoration: none;
}

.attach-link.clickable {
  cursor: pointer;
  text-decoration: underline;
  text-underline-offset: 2px;
}

/* 文件操作弹窗 */
.file-action-buttons {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 8px 0;
}

.file-action-btn {
  width: 100% !important;
  display: flex !important;
  align-items: center !important;
  justify-content: center !important;
  gap: 6px;
  margin: 0 !important;
}

.empty-text {
  color: #999;
  font-size: 13px;
}
</style>
