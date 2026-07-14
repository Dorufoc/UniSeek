<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { ElMessage } from 'element-plus'
import { UploadFilled, WarningFilled, CircleCheckFilled, Clock } from '@element-plus/icons-vue'

const router = useRouter()
const userStore = useUserStore()

// 加载并提交状态
const loading = ref(false)
// 当前认证状态：none=未提交, pending=待审核, approved=已认证, rejected=已驳回
const certStatus = ref<'none' | 'pending' | 'approved' | 'rejected'>('none')
// 驳回原因
const rejectReason = ref('')

// 行业选项
const industryOptions = [
  '互联网/IT', '金融/保险', '教育培训', '餐饮服务', '零售/批发',
  '房地产/建筑', '医疗/健康', '文化/传媒', '制造/能源', '物流/运输',
  '家政/生活服务', '旅游/酒店', '农业/渔业', '其他'
]

// 企业资质表单数据
const form = reactive({
  companyName: '',
  licenseImgName: '',
  industry: '',
  description: ''
})

// 从 localStorage 恢复认证状态和表单数据
const savedCert = localStorage.getItem('uniseek_enterprise_cert')
if (savedCert) {
  const data = JSON.parse(savedCert)
  certStatus.value = data.status || 'none'
  rejectReason.value = data.rejectReason || ''
  if (data.form) {
    Object.assign(form, data.form)
  }
}

// 模拟营业执照上传
const handleUpload = () => {
  form.licenseImgName = '营业执照_' + (form.companyName || '企业') + '.jpg'
  ElMessage.success('营业执照上传成功')
}

// 移除营业执照
const removeLicense = () => {
  form.licenseImgName = ''
}

// 提交企业资质认证
const handleSubmit = async () => {
  loading.value = true
  try {
    await new Promise(resolve => setTimeout(resolve, 300))
    const certData = {
      status: 'approved' as const,
      form: {
        companyName: form.companyName.trim(),
        licenseImgName: form.licenseImgName,
        industry: form.industry,
        description: form.description.trim()
      }
    }
    localStorage.setItem('uniseek_enterprise_cert', JSON.stringify(certData))
    certStatus.value = 'approved'
    ElMessage.success('认证成功')
    router.replace('/')
  } catch {
    ElMessage.error('提交失败，请重试')
  } finally {
    loading.value = false
  }
}

// 重新提交（当审核被驳回时）
const handleResubmit = () => {
  certStatus.value = 'none'
  rejectReason.value = ''
}

// 进入首页
const goHome = () => {
  router.replace('/')
}

// 跳过认证（仅已认证用户可用）
const skipCert = () => {
  router.replace('/')
}
</script>

<template>
  <div class="cert-page">
    <div class="cert-container">
      <!-- 头部 -->
      <div class="cert-header">
        <h1 class="cert-logo">UniSeek</h1>
        <p class="cert-subtitle">企业资质认证</p>
      </div>

      <!-- 待审核状态 -->
      <div v-if="certStatus === 'pending'" class="status-card pending">
        <div class="status-icon">
          <el-icon :size="48"><Clock /></el-icon>
        </div>
        <h2 class="status-title">资质审核中</h2>
        <p class="status-desc">
          您的企业资质认证已提交，正在等待运营管理员审核。审核结果将通过站内消息通知您。
        </p>
        <p class="status-hint">审核期间您可以先浏览平台内容</p>
        <button class="btn-primary" @click="goHome">进入 UniSeek</button>
      </div>

      <!-- 已认证状态 -->
      <div v-else-if="certStatus === 'approved'" class="status-card approved">
        <div class="status-icon">
          <el-icon :size="48"><CircleCheckFilled /></el-icon>
        </div>
        <h2 class="status-title">认证已通过</h2>
        <p class="status-desc">您的企业资质已通过审核，现在可以发布职位了。</p>
        <button class="btn-primary" @click="goHome">进入 UniSeek</button>
      </div>

      <!-- 已驳回状态 -->
      <div v-else-if="certStatus === 'rejected'" class="status-card rejected">
        <div class="status-icon">
          <el-icon :size="48"><WarningFilled /></el-icon>
        </div>
        <h2 class="status-title">资质审核未通过</h2>
        <p class="status-desc">驳回原因：{{ rejectReason || '资质材料不符合要求' }}</p>
        <p class="status-hint">请根据驳回原因修改后重新提交</p>
        <button class="btn-resubmit" @click="handleResubmit">重新提交认证</button>
      </div>

      <!-- 认证表单（未提交或重新提交） -->
      <div v-else class="cert-form-card">
        <div class="form-intro">
          <el-icon :size="20"><WarningFilled /></el-icon>
          <span>发布职位前请先完成企业资质认证，审核通过后即可发布职位</span>
        </div>

        <div class="form-section">
          <h3 class="section-title">企业基本信息</h3>

          <div class="form-row">
            <label>公司全称 <span class="required">*</span></label>
            <input
              v-model="form.companyName"
              type="text"
              class="form-input"
              placeholder="请填写与营业执照一致的公司全称"
              maxlength="100"
            />
          </div>

          <div class="form-row">
            <label>营业执照 <span class="required">*</span></label>
            <div v-if="form.licenseImgName" class="license-added">
              <span>{{ form.licenseImgName }}</span>
              <button class="btn-remove" @click="removeLicense">移除</button>
            </div>
            <button v-else class="upload-area" @click="handleUpload">
              <el-icon :size="32"><UploadFilled /></el-icon>
              <span>点击上传营业执照</span>
              <span class="upload-hint">支持 JPG、PNG 格式，大小不超过 5MB</span>
            </button>
          </div>

          <div class="form-row">
            <label>所属行业 <span class="required">*</span></label>
            <div class="industry-grid">
              <span
                v-for="item in industryOptions"
                :key="item"
                :class="['industry-tag', { selected: form.industry === item }]"
                @click="form.industry = item"
              >
                {{ item }}
              </span>
            </div>
          </div>

          <div class="form-row">
            <label>公司简介 <span class="required">*</span></label>
            <textarea
              v-model="form.description"
              class="form-textarea"
              placeholder="请简要描述公司的主营业务、规模和发展方向（至少10个字）"
              rows="4"
            ></textarea>
            <span class="char-count">{{ form.description.length }}/500</span>
          </div>
        </div>

        <div class="form-actions">
          <button
            class="btn-submit"
            :disabled="loading"
            @click="handleSubmit"
          >
            {{ loading ? '提交中...' : '提交认证' }}
          </button>
        </div>

        <p class="form-footer-note">
          提交后，运营管理员将在 1-2 个工作日内完成审核
        </p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.cert-page {
  min-height: 100vh;
  background: linear-gradient(135deg, #f0f4fa 0%, #e8f0f8 100%);
  padding: 40px 24px;
  box-sizing: border-box;
}

.cert-container {
  max-width: 680px;
  margin: 0 auto;
}

/* 头部 */
.cert-header {
  text-align: center;
  margin-bottom: 32px;
}

.cert-logo {
  font-size: 32px;
  font-weight: 800;
  color: #007AFF;
  margin: 0;
  letter-spacing: 2px;
}

.cert-subtitle {
  font-size: 16px;
  color: #666;
  margin: 8px 0 0;
}

/* 状态卡片 */
.status-card {
  background: #fff;
  border-radius: 16px;
  padding: 48px 40px;
  text-align: center;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.06);
}

.status-icon {
  margin-bottom: 20px;
}

.status-card.pending .status-icon { color: #f0ad4e; }
.status-card.approved .status-icon { color: #2ecc71; }
.status-card.rejected .status-icon { color: #e74c3c; }

.status-title {
  font-size: 22px;
  font-weight: 600;
  color: var(--text-h);
  margin: 0 0 12px;
}

.status-desc {
  font-size: 15px;
  color: #666;
  line-height: 1.6;
  margin: 0 0 12px;
}

.status-hint {
  font-size: 13px;
  color: #999;
  margin: 0 0 28px;
}

.btn-primary {
  padding: 12px 40px;
  font-size: 15px;
  color: #fff;
  background: #007AFF;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-primary:hover {
  background: #0066d6;
}

.btn-resubmit {
  padding: 12px 40px;
  font-size: 15px;
  color: #007AFF;
  background: rgba(0, 122, 255, 0.08);
  border: 1px solid #007AFF;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-resubmit:hover {
  background: rgba(0, 122, 255, 0.15);
}

/* 表单卡片 */
.cert-form-card {
  background: #fff;
  border-radius: 16px;
  padding: 0;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.06);
  overflow: hidden;
}

.form-intro {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 16px 28px;
  background: rgba(0, 122, 255, 0.06);
  font-size: 14px;
  color: #007AFF;
  border-bottom: 1px solid #f0f0f5;
}

.form-section {
  padding: 28px;
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-h);
  margin: 0 0 24px;
  padding-bottom: 12px;
  border-bottom: 1px solid #f0f0f5;
}

.form-row {
  margin-bottom: 24px;
}

.form-row:last-child {
  margin-bottom: 0;
}

.form-row label {
  display: block;
  font-size: 14px;
  font-weight: 500;
  color: var(--text);
  margin-bottom: 8px;
}

.required {
  color: #e74c3c;
}

.form-input {
  width: 100%;
  padding: 11px 14px;
  font-size: 14px;
  border: 1px solid #dcdce4;
  border-radius: 8px;
  outline: none;
  transition: border-color 0.2s;
  box-sizing: border-box;
  color: var(--text-h);
}

.form-input:focus {
  border-color: #007AFF;
  box-shadow: 0 0 0 3px rgba(0, 122, 255, 0.1);
}

/* 营业执照上传 */
.license-added {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  background: #f8f9fb;
  border-radius: 8px;
  font-size: 14px;
  color: var(--text);
}

.btn-remove {
  font-size: 13px;
  color: #999;
  background: transparent;
  border: none;
  cursor: pointer;
}

.btn-remove:hover {
  color: #e74c3c;
}

.upload-area {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 36px 20px;
  font-size: 14px;
  color: #999;
  background: #f8f9fb;
  border: 2px dashed #dcdce4;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s;
}

.upload-area:hover {
  border-color: #007AFF;
  color: #007AFF;
  background: rgba(0, 122, 255, 0.03);
}

.upload-hint {
  font-size: 12px;
  color: #bbb;
}

/* 行业选择 */
.industry-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.industry-tag {
  padding: 7px 16px;
  font-size: 13px;
  border: 1px solid #dcdce4;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
  color: var(--text);
}

.industry-tag:hover {
  border-color: #007AFF;
  color: #007AFF;
}

.industry-tag.selected {
  border-color: #007AFF;
  background: rgba(0, 122, 255, 0.06);
  color: #007AFF;
  font-weight: 500;
}

/* 简介 */
.form-textarea {
  width: 100%;
  padding: 12px 14px;
  font-size: 14px;
  border: 1px solid #dcdce4;
  border-radius: 8px;
  outline: none;
  resize: vertical;
  font-family: inherit;
  line-height: 1.6;
  color: var(--text-h);
  box-sizing: border-box;
}

.form-textarea:focus {
  border-color: #007AFF;
  box-shadow: 0 0 0 3px rgba(0, 122, 255, 0.1);
}

.char-count {
  display: block;
  text-align: right;
  font-size: 12px;
  color: #bbb;
  margin-top: 4px;
}

/* 提交按钮 */
.form-actions {
  padding: 0 28px 28px;
}

.btn-submit {
  width: 100%;
  padding: 13px 0;
  font-size: 16px;
  font-weight: 600;
  color: #fff;
  background: #007AFF;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: opacity 0.2s;
}

.btn-submit:hover:not(:disabled) {
  opacity: 0.9;
}

.btn-submit:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}

.form-footer-note {
  text-align: center;
  font-size: 13px;
  color: #bbb;
  padding: 0 28px 28px;
  margin: 0;
}

@media (max-width: 768px) {
  .cert-page {
    padding: 24px 16px;
  }

  .status-card {
    padding: 32px 24px;
  }

  .form-section {
    padding: 20px;
  }

  .form-actions {
    padding: 0 20px 20px;
  }
}
</style>
