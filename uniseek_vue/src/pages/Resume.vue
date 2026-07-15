<script setup lang="ts">
import { ref, reactive, computed } from 'vue'
import { useUserStore } from '@/stores/user'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getResume, saveResume as saveResumeApi, uploadAttachment, publishResume as publishResumeApi, unpublishResume as unpublishResumeApi } from '@/api/resume'
import type { ResumeSaveParams } from '@/api/resume'
import {
  User, Edit, Plus, Close, Delete, Top, Bottom, UploadFilled,
  Check, ArrowLeft
} from '@element-plus/icons-vue'

const userStore = useUserStore()
// 隐藏的文件选择器引用
const fileInput = ref<HTMLInputElement | null>(null)

// 学历选项
const educationOptions = ['初中及以下', '高中/中专', '大专', '本科', '硕士', '博士']

// 是否处于编辑模式
const isEditing = ref(false)

// 简历表单数据
const resumeForm = reactive({
  realName: '',
  gender: -1 as number,
  birthDate: '',
  education: '',
  school: '',
  skills: [] as string[],
  experience: '',
  attachmentUrl: ''
})

// 新技能输入
const newSkill = ref('')

// 从后端加载简历数据
const loadResume = async () => {
  try {
    const data = await getResume()
    if (data) {
      let skills: string[] = []
      if (data.skills) {
        try {
          skills = JSON.parse(data.skills)
        } catch {
          skills = data.skills.split(',').filter(s => s.trim())
        }
      }
      resumeForm.realName = data.realName || ''
      resumeForm.gender = data.gender ?? -1
      resumeForm.birthDate = data.birthDate || ''
      resumeForm.education = data.education || ''
      resumeForm.school = data.school || ''
      resumeForm.skills = skills
      resumeForm.experience = data.experience || ''
      resumeForm.attachmentUrl = data.attachmentUrl || ''
      isPublished.value = data.isPublished === 1
    }
  } catch {
    // 未创建简历时不做处理
  }
}
loadResume()

// 发布状态
const isPublished = ref(false)

// 发布到人才市场
const publishToMarket = async () => {
  try {
    await publishResumeApi()
    isPublished.value = true
    ElMessage.success('简历已发布到人才市场')
  } catch {
    // 错误已在拦截器中处理
  }
}

// 从人才市场下架
const unpublishFromMarket = async () => {
  try {
    await unpublishResumeApi()
    isPublished.value = false
    ElMessage.success('简历已从人才市场下架')
  } catch {
    // 错误已在拦截器中处理
  }
}

// 简历完整度计算
const completionPercent = computed(() => {
  let total = 0
  let filled = 0
  const fields: [any, number] = [
    [resumeForm.realName, 15],
    [resumeForm.gender !== -1 ? 1 : 0, 5],
    [resumeForm.birthDate, 5],
    [resumeForm.education, 15],
    [resumeForm.school, 10],
    [resumeForm.skills.length > 0 ? 1 : 0, 20],
    [resumeForm.experience, 20],
    [resumeForm.attachmentUrl, 10]
  ]
  fields.forEach(([val, weight]) => {
    total += weight
    if (val) filled += weight
  })
  return Math.round((filled / total) * 100)
})

// 手机号脱敏显示
const maskedPhone = computed(() => {
  const phone = userStore.userInfo?.phone || ''
  return phone ? phone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2') : '未绑定'
})

// 性别文本
const genderLabel = computed(() => {
  if (resumeForm.gender === 0) return '男'
  if (resumeForm.gender === 1) return '女'
  return '未设置'
})

// 开始编辑
const startEdit = () => {
  isEditing.value = true
}

// 取消编辑
const cancelEdit = () => {
  loadResume()
  isEditing.value = false
}

// 保存简历
const saveResume = async () => {
  if (!resumeForm.realName.trim()) {
    ElMessage.warning('请输入真实姓名')
    return
  }
  try {
    const params: ResumeSaveParams = {
      gender: resumeForm.gender >= 0 ? resumeForm.gender : undefined,
      birthDate: resumeForm.birthDate || undefined,
      education: resumeForm.education || undefined,
      school: resumeForm.school || undefined,
      skills: resumeForm.skills.length > 0 ? JSON.stringify(resumeForm.skills) : undefined,
      experience: resumeForm.experience || undefined,
      attachmentUrl: resumeForm.attachmentUrl || undefined,
    }
    await saveResumeApi(params)
    ElMessage.success('简历保存成功')
    isEditing.value = false
  } catch {
    // 错误已在拦截器中处理
  }
}

// 添加技能标签
const addSkill = () => {
  const skill = newSkill.value.trim()
  if (!skill) return
  if (resumeForm.skills.includes(skill)) {
    ElMessage.warning('该技能已存在')
    return
  }
  if (resumeForm.skills.length >= 10) {
    ElMessage.warning('最多添加10个技能标签')
    return
  }
  resumeForm.skills.push(skill)
  newSkill.value = ''
}

// 删除技能标签
const removeSkill = (index: number) => {
  resumeForm.skills.splice(index, 1)
}

// 触发文件选择对话框
const triggerUpload = () => {
  fileInput.value?.click()
}

// 处理文件选择并上传
const handleFileChange = async (event: Event) => {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (!file) return

  const ext = file.name.split('.').pop()?.toLowerCase()
  if (!['pdf', 'doc', 'docx'].includes(ext || '')) {
    ElMessage.error('仅支持 PDF、DOC、DOCX 格式')
    return
  }

  if (file.size > 10 * 1024 * 1024) {
    ElMessage.error('文件大小不能超过 10MB')
    return
  }

  try {
    const result = await uploadAttachment(file)
    resumeForm.attachmentUrl = result.url
    ElMessage.success('附件简历上传成功')
    await saveResume()
  } catch (e: any) {
    ElMessage.error(e?.message || '附件上传失败，请检查网络或联系管理员')
  }
}

// 删除附件
const removeAttachment = () => {
  resumeForm.attachmentUrl = ''
}

// 右侧面板当前展开的区块（预览模式用）
const expandedSection = ref('')
const toggleSection = (key: string) => {
  expandedSection.value = expandedSection.value === key ? '' : key
}
</script>

<template>
  <div class="resume-page">
    <div class="resume-container">
      <!-- 左侧：简历档案 -->
      <div class="resume-sidebar">
        <!-- 头像区域 -->
        <div class="sidebar-avatar">
          <div class="avatar-circle">
            <el-icon :size="40"><User /></el-icon>
          </div>
          <div class="avatar-name">{{ userStore.userInfo?.nickname || '未设置昵称' }}</div>
          <div class="avatar-phone">{{ maskedPhone }}</div>
        </div>

        <!-- 简历完整度 -->
        <div class="completion-card">
          <div class="completion-header">
            <span>简历完整度</span>
            <span class="completion-percent">{{ completionPercent }}%</span>
          </div>
          <div class="completion-bar">
            <div class="completion-fill" :style="{ width: completionPercent + '%' }"></div>
          </div>
          <p class="completion-tip">
            {{ completionPercent >= 80 ? '简历很完善，投递成功率更高！' : '完善简历内容，提升投递成功率' }}
          </p>
        </div>

        <!-- 导航菜单 -->
        <div class="sidebar-nav">
          <button
            :class="['nav-item', { active: expandedSection === 'basic' }]"
            @click="toggleSection('basic')"
          >
            基本信息
          </button>
          <button
            :class="['nav-item', { active: expandedSection === 'edu' }]"
            @click="toggleSection('edu')"
          >
            教育背景
          </button>
          <button
            :class="['nav-item', { active: expandedSection === 'skills' }]"
            @click="toggleSection('skills')"
          >
            技能标签
          </button>
          <button
            :class="['nav-item', { active: expandedSection === 'exp' }]"
            @click="toggleSection('exp')"
          >
            工作经历
          </button>
          <button
            :class="['nav-item', { active: expandedSection === 'attach' }]"
            @click="toggleSection('attach')"
          >
            附件简历
          </button>
        </div>
      </div>

      <!-- 右侧：简历编辑区域 -->
      <div class="resume-main">
        <!-- 顶部操作栏 -->
        <div class="toolbar">
          <h2 class="page-title">我的简历</h2>
          <div class="toolbar-actions">
            <template v-if="!isEditing">
              <button class="btn-edit" @click="startEdit">
                <el-icon :size="16"><Edit /></el-icon>
                编辑简历
              </button>
              <button
                v-if="!isPublished"
                class="btn-publish"
                @click="publishToMarket"
              >
                发布到人才市场
              </button>
              <button
                v-else
                class="btn-unpublish"
                @click="unpublishFromMarket"
              >
                已发布 - 点击下架
              </button>
            </template>
            <template v-else>
              <button class="btn-cancel" @click="cancelEdit">取消</button>
              <button class="btn-save" @click="saveResume">
                <el-icon :size="16"><Check /></el-icon>
                保存
              </button>
            </template>
          </div>
        </div>

        <!-- 简历内容区域 -->
        <div class="resume-content">
          <!-- 预览模式 -->
          <template v-if="!isEditing">
            <!-- 基本信息 -->
            <div class="section-card" :class="{ expanded: expandedSection === 'basic' }">
              <div class="section-header" @click="toggleSection('basic')">
                <h3>基本信息</h3>
                <span class="section-toggle">{{ expandedSection === 'basic' ? '收起' : '展开' }}</span>
              </div>
              <div class="section-body">
                <div class="info-row">
                  <span class="info-label">真实姓名</span>
                  <span class="info-value">{{ resumeForm.realName || '未填写' }}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">性别</span>
                  <span class="info-value">{{ genderLabel }}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">出生日期</span>
                  <span class="info-value">{{ resumeForm.birthDate || '未填写' }}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">手机号</span>
                  <span class="info-value">{{ maskedPhone }}</span>
                </div>
              </div>
            </div>

            <!-- 教育背景 -->
            <div class="section-card" :class="{ expanded: expandedSection === 'edu' }">
              <div class="section-header" @click="toggleSection('edu')">
                <h3>教育背景</h3>
                <span class="section-toggle">{{ expandedSection === 'edu' ? '收起' : '展开' }}</span>
              </div>
              <div class="section-body">
                <div class="info-row">
                  <span class="info-label">学历</span>
                  <span class="info-value">{{ resumeForm.education || '未填写' }}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">毕业院校</span>
                  <span class="info-value">{{ resumeForm.school || '未填写' }}</span>
                </div>
              </div>
            </div>

            <!-- 技能标签 -->
            <div class="section-card" :class="{ expanded: expandedSection === 'skills' }">
              <div class="section-header" @click="toggleSection('skills')">
                <h3>技能标签</h3>
                <span class="section-toggle">{{ expandedSection === 'skills' ? '收起' : '展开' }}</span>
              </div>
              <div class="section-body">
                <div v-if="resumeForm.skills.length > 0" class="skill-tags-display">
                  <span v-for="skill in resumeForm.skills" :key="skill" class="skill-tag">{{ skill }}</span>
                </div>
                <span v-else class="empty-text">未填写技能标签</span>
              </div>
            </div>

            <!-- 工作/实践经历 -->
            <div class="section-card" :class="{ expanded: expandedSection === 'exp' }">
              <div class="section-header" @click="toggleSection('exp')">
                <h3>工作/实践经历</h3>
                <span class="section-toggle">{{ expandedSection === 'exp' ? '收起' : '展开' }}</span>
              </div>
              <div class="section-body">
                <div v-if="resumeForm.experience" class="experience-content">
                  {{ resumeForm.experience }}
                </div>
                <span v-else class="empty-text">未填写工作经历</span>
              </div>
            </div>

            <!-- 附件简历 -->
            <div class="section-card" :class="{ expanded: expandedSection === 'attach' }">
              <div class="section-header" @click="toggleSection('attach')">
                <h3>附件简历</h3>
                <span class="section-toggle">{{ expandedSection === 'attach' ? '收起' : '展开' }}</span>
              </div>
              <div class="section-body">
                <div v-if="resumeForm.attachmentUrl" class="attachment-display">
                  <span class="attachment-name">{{ resumeForm.attachmentUrl }}</span>
                </div>
                <span v-else class="empty-text">未上传附件简历</span>
              </div>
            </div>
          </template>

          <!-- 编辑模式 -->
          <template v-else>
            <!-- 基本信息编辑 -->
            <div class="section-card edit-card">
              <h3 class="edit-section-title">基本信息</h3>
              <div class="edit-form">
                <div class="form-row">
                  <label>真实姓名 <span class="required">*</span></label>
                  <input
                    v-model="resumeForm.realName"
                    type="text"
                    class="form-input"
                    placeholder="请输入真实姓名"
                    maxlength="20"
                  />
                </div>
                <div class="form-row">
                  <label>性别</label>
                  <div class="gender-options">
                    <label
                      :class="['gender-btn', { selected: resumeForm.gender === 0 }]"
                    >
                      <input v-model="resumeForm.gender" type="radio" :value="0" />
                      男
                    </label>
                    <label
                      :class="['gender-btn', { selected: resumeForm.gender === 1 }]"
                    >
                      <input v-model="resumeForm.gender" type="radio" :value="1" />
                      女
                    </label>
                  </div>
                </div>
                <div class="form-row">
                  <label>出生日期</label>
                  <el-date-picker
                    v-model="resumeForm.birthDate"
                    type="date"
                    placeholder="选择出生日期"
                    value-format="YYYY-MM-DD"
                    class="date-picker"
                  />
                </div>
                <div class="form-row">
                  <label>手机号</label>
                  <span class="readonly-text">{{ maskedPhone }}</span>
                </div>
              </div>
            </div>

            <!-- 教育背景编辑 -->
            <div class="section-card edit-card">
              <h3 class="edit-section-title">教育背景</h3>
              <div class="edit-form">
                <div class="form-row">
                  <label>学历</label>
                  <div class="option-tags">
                    <span
                      v-for="item in educationOptions"
                      :key="item"
                      :class="['option-tag', { selected: resumeForm.education === item }]"
                      @click="resumeForm.education = item"
                    >
                      {{ item }}
                    </span>
                  </div>
                </div>
                <div class="form-row">
                  <label>毕业院校</label>
                  <input
                    v-model="resumeForm.school"
                    type="text"
                    class="form-input"
                    placeholder="请输入毕业院校名称"
                    maxlength="50"
                  />
                </div>
              </div>
            </div>

            <!-- 技能标签编辑 -->
            <div class="section-card edit-card">
              <h3 class="edit-section-title">技能标签</h3>
              <div class="edit-form">
                <div class="skill-input-row">
                  <input
                    v-model="newSkill"
                    type="text"
                    class="form-input skill-input"
                    placeholder="输入技能名称，按回车添加"
                    maxlength="20"
                    @keyup.enter="addSkill"
                  />
                  <button class="btn-add-skill" @click="addSkill">
                    <el-icon :size="14"><Plus /></el-icon>
                    添加
                  </button>
                </div>
                <div v-if="resumeForm.skills.length > 0" class="skill-tags-edit">
                  <span v-for="(skill, index) in resumeForm.skills" :key="skill" class="skill-tag removable">
                    {{ skill }}
                    <button class="tag-remove" @click="removeSkill(index)">
                      <el-icon :size="12"><Close /></el-icon>
                    </button>
                  </span>
                </div>
                <p class="form-hint">最多添加10个技能标签，展示你的核心能力</p>
              </div>
            </div>

            <!-- 工作/实践经历编辑 -->
            <div class="section-card edit-card">
              <h3 class="edit-section-title">工作/实践经历</h3>
              <div class="edit-form">
                <textarea
                  v-model="resumeForm.experience"
                  class="form-textarea"
                  placeholder="请详细描述您的工作经历、实践项目或兼职经历，包括：&#10;1. 工作时间（起止时间）&#10;2. 公司/组织名称&#10;3. 担任的职务或角色&#10;4. 主要工作内容和成果"
                  rows="8"
                ></textarea>
                <p class="form-hint">详细的工作经历能帮助你获得更多面试机会</p>
              </div>
            </div>

            <!-- 附件简历编辑 -->
            <div class="section-card edit-card">
              <h3 class="edit-section-title">附件简历</h3>
              <div class="edit-form">
                <div v-if="resumeForm.attachmentUrl" class="attachment-item">
                  <span class="attachment-name">{{ resumeForm.attachmentUrl }}</span>
                  <button class="btn-remove-attach" @click="removeAttachment">
                    <el-icon :size="14"><Delete /></el-icon>
                  </button>
                </div>
                <button v-else class="upload-area" @click="triggerUpload">
                  <el-icon :size="28"><UploadFilled /></el-icon>
                  <span>上传附件简历</span>
                  <span class="upload-hint">支持 PDF、Word 格式，大小不超过10MB</span>
                </button>
                <!-- 隐藏的文件选择器 -->
                <input
                  ref="fileInput"
                  type="file"
                  accept=".pdf,.doc,.docx"
                  style="display: none"
                  @change="handleFileChange"
                />
              </div>
            </div>
          </template>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.resume-page {
  min-height: calc(100vh - 60px);
  background: #f5f7fa;
  padding: 24px;
  box-sizing: border-box;
}

.resume-container {
  max-width: 1100px;
  margin: 0 auto;
  display: flex;
  gap: 24px;
  align-items: flex-start;
}

/* ========== 左侧边栏 ========== */
.resume-sidebar {
  width: 240px;
  min-width: 240px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.sidebar-avatar {
  background: #fff;
  border-radius: 12px;
  padding: 28px 20px;
  text-align: left;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
}

.avatar-circle {
  width: 72px;
  height: 72px;
  border-radius: 50%;
  background: linear-gradient(135deg, #e8f4fd, #cce5ff);
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 0 12px;
  color: #007AFF;
}

.avatar-name {
  font-size: 16px;
  font-weight: 600;
  color: #000;
  margin-bottom: 4px;
}

.avatar-phone {
  font-size: 13px;
  color: #000;
}

.completion-card {
  background: #fff;
  border-radius: 12px;
  padding: 16px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
}

.completion-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 14px;
  color: #000;
  margin-bottom: 10px;
}

.completion-percent {
  font-weight: 700;
  color: #007AFF;
}

.completion-bar {
  height: 6px;
  background: #e8e8ed;
  border-radius: 3px;
  overflow: hidden;
  margin-bottom: 10px;
}

.completion-fill {
  height: 100%;
  background: linear-gradient(90deg, #007AFF, #5aacff);
  border-radius: 3px;
  transition: width 0.4s ease;
}

.completion-tip {
  font-size: 12px;
  color: #000;
  margin: 0;
}

.sidebar-nav {
  background: #fff;
  border-radius: 12px;
  padding: 8px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
}

.nav-item {
  display: block;
  width: 100%;
  padding: 12px 16px;
  text-align: left;
  font-size: 14px;
  color: #000;
  background: transparent;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.15s;
}

.nav-item:hover {
  background: #f0f4ff;
  color: #007AFF;
}

.nav-item.active {
  background: rgba(0, 122, 255, 0.08);
  color: #007AFF;
  font-weight: 500;
}

/* ========== 右侧主体 ========== */
.resume-main {
  flex: 1;
  min-width: 0;
}

.toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.page-title {
  font-size: 22px;
  font-weight: 600;
  color: #000;
  margin: 0;
}

.toolbar-actions {
  display: flex;
  gap: 12px;
}

.btn-edit {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 9px 22px;
  font-size: 14px;
  color: #fff;
  background: #007AFF;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-edit:hover {
  background: #0066d6;
}

.btn-cancel {
  padding: 9px 22px;
  font-size: 14px;
  color: #666;
  background: #f0f0f5;
  border: 1px solid #e0e0e8;
  border-radius: 8px;
  cursor: pointer;
}

.btn-cancel:hover {
  background: #e8e8ed;
}

.btn-save {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 9px 22px;
  font-size: 14px;
  color: #fff;
  background: #007AFF;
  border: none;
  border-radius: 8px;
  cursor: pointer;
}

.btn-save:hover {
  background: #0066d6;
}

.btn-publish {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 9px 22px;
  font-size: 14px;
  color: #fff;
  background: #00b578;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-publish:hover {
  background: #009a64;
}

.btn-unpublish {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 9px 22px;
  font-size: 14px;
  color: #666;
  background: #f0f0f5;
  border: 1px solid #e0e0e8;
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-unpublish:hover {
  background: #e8e8ed;
}

/* ========== 简历内容区 - 预览模式 ========== */
.resume-content {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.section-card {
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  overflow: hidden;
}

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 24px;
  cursor: pointer;
  transition: background 0.15s;
}

.section-header:hover {
  background: #f8f9fb;
}

.section-header h3 {
  font-size: 15px;
  font-weight: 600;
  color: #000;
  margin: 0;
}

.section-toggle {
  font-size: 13px;
  color: #007AFF;
}

.section-body {
  padding: 0 24px;
  max-height: 0;
  overflow: hidden;
  transition: max-height 0.3s ease, padding 0.3s ease;
}

.section-card.expanded .section-body {
  max-height: 600px;
  padding: 0 24px 20px;
}

.info-row {
  display: flex;
  padding: 10px 0;
  border-bottom: 1px solid #f0f0f5;
}

.info-row:last-child {
  border-bottom: none;
}

.info-label {
  width: 90px;
  min-width: 90px;
  font-size: 14px;
  color: #000;
}

.info-value {
  font-size: 14px;
  color: #000;
}

.skill-tags-display {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.skill-tag {
  display: inline-block;
  padding: 4px 12px;
  font-size: 13px;
  color: #007AFF;
  background: rgba(0, 122, 255, 0.08);
  border-radius: 4px;
}

.skill-tag.removable {
  padding-right: 4px;
  display: inline-flex;
  align-items: center;
  gap: 4px;
}

.tag-remove {
  display: inline-flex;
  align-items: center;
  padding: 2px;
  border: none;
  background: transparent;
  color: #007AFF;
  cursor: pointer;
  opacity: 0.6;
}

.tag-remove:hover {
  opacity: 1;
}

.experience-content {
  font-size: 14px;
  color: #000;
  line-height: 1.7;
  white-space: pre-wrap;
}

.empty-text {
  font-size: 14px;
  color: #ccc;
}

.attachment-display {
  display: flex;
  align-items: center;
  gap: 10px;
}

.attachment-name {
  font-size: 14px;
  color: #007AFF;
  cursor: pointer;
}

/* ========== 简历内容区 - 编辑模式 ========== */
.edit-card {
  padding: 0;
}

.edit-section-title {
  font-size: 15px;
  font-weight: 600;
  color: #000;
  margin: 0;
  padding: 18px 24px;
  border-bottom: 1px solid #f0f0f5;
}

.edit-form {
  padding: 20px 24px;
}

.form-row {
  display: flex;
  align-items: flex-start;
  margin-bottom: 20px;
}

.form-row:last-child {
  margin-bottom: 0;
}

.form-row label {
  width: 90px;
  min-width: 90px;
  font-size: 14px;
  color: #000;
  font-weight: 500;
  padding-top: 10px;
}

.required {
  color: #e74c3c;
}

.form-input {
  flex: 1;
  max-width: 400px;
  padding: 10px 14px;
  font-size: 14px;
  border: 1px solid #dcdce4;
  border-radius: 8px;
  outline: none;
  transition: border-color 0.2s;
  box-sizing: border-box;
  color: #000;
  background: #fff;
}

.form-input:focus {
  border-color: #007AFF;
  box-shadow: 0 0 0 3px rgba(0, 122, 255, 0.1);
}

.readonly-text {
  font-size: 14px;
  color: #000;
}

.date-picker {
  flex: 1;
  max-width: 400px;
}

.gender-options {
  display: flex;
  gap: 12px;
}

.gender-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 20px;
  font-size: 14px;
  border: 1px solid #dcdce4;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
  color: #000;
}

.gender-btn input {
  display: none;
}

.gender-btn:hover {
  border-color: #007AFF;
}

.gender-btn.selected {
  border-color: #007AFF;
  background: rgba(0, 122, 255, 0.06);
  color: #007AFF;
}

.option-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.option-tag {
  padding: 6px 16px;
  font-size: 13px;
  border: 1px solid #dcdce4;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
  color: #000;
}

.option-tag:hover {
  border-color: #007AFF;
}

.option-tag.selected {
  border-color: #007AFF;
  background: rgba(0, 122, 255, 0.06);
  color: #007AFF;
}

.skill-input-row {
  display: flex;
  gap: 10px;
  margin-bottom: 14px;
}

.skill-input {
  flex: 1;
  max-width: 300px;
}

.btn-add-skill {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 10px 16px;
  font-size: 13px;
  color: #007AFF;
  background: rgba(0, 122, 255, 0.06);
  border: 1px solid rgba(0, 122, 255, 0.2);
  border-radius: 8px;
  cursor: pointer;
}

.btn-add-skill:hover {
  background: rgba(0, 122, 255, 0.12);
}

.skill-tags-edit {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.form-textarea {
  flex: 1;
  padding: 12px 14px;
  font-size: 14px;
  border: 1px solid #dcdce4;
  border-radius: 8px;
  outline: none;
  resize: vertical;
  font-family: inherit;
  line-height: 1.6;
  color: #000;
  box-sizing: border-box;
  background: #fff;
}

.form-textarea:focus {
  border-color: #007AFF;
  box-shadow: 0 0 0 3px rgba(0, 122, 255, 0.1);
}

.form-hint {
  font-size: 12px;
  color: #bbb;
  margin: 8px 0 0;
}

/* 附件上传区域 */
.attachment-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  background: #fff;
  border: 1px solid #dcdce4;
  border-radius: 8px;
}

.btn-remove-attach {
  display: inline-flex;
  align-items: center;
  padding: 4px;
  border: none;
  background: transparent;
  color: #000;
  cursor: pointer;
}

.btn-remove-attach:hover {
  color: #e74c3c;
}

.upload-area {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 8px;
  width: 100%;
  padding: 36px 20px;
  font-size: 14px;
  color: #000;
  background: #fff;
  border: 2px dashed #dcdce4;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s;
}

.upload-area:hover {
  border-color: #007AFF;
  color: #007AFF;
  background: #fff;
}

.upload-hint {
  font-size: 12px;
  color: #bbb;
}

/* ========== 响应式 ========== */
@media (max-width: 768px) {
  .resume-container {
    flex-direction: column;
  }

  .resume-sidebar {
    width: 100%;
    min-width: unset;
  }

  .sidebar-nav {
    display: none;
  }

  .form-input {
    max-width: 100%;
  }

  .resume-page {
    padding: 16px;
  }
}
</style>
