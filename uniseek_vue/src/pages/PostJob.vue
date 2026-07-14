<script setup lang="ts">
import { ref, reactive, computed } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { OfficeBuilding, User, TrendCharts, Money, Briefcase } from '@element-plus/icons-vue'

const router = useRouter()
// 提交加载状态
const loading = ref(false)

// 发布职位表单数据
const form = reactive({
  jobTitle: '',             // 招聘职务
  companyName: '',          // 公司名称
  recruiterTitle: '',       // 招聘者职务
  companySize: '',          // 公司人数
  registeredCapital: ''     // 注册资金
})

// 公司人数选项列表
const companySizes = [
  '少于15人',
  '15-50人',
  '50-150人',
  '150-500人',
  '500-2000人',
  '2000人以上'
]

// 注册资金选项列表
const registeredCapitals = [
  '不足100万',
  '100-500万',
  '500-1000万',
  '1000-5000万',
  '5000万-1亿',
  '1亿以上'
]

// 表单是否填写完整（所有字段均非空）
const isFormValid = computed(() => {
  return form.jobTitle.trim() !== ''
    && form.companyName.trim() !== ''
    && form.recruiterTitle.trim() !== ''
    && form.companySize !== ''
    && form.registeredCapital !== ''
})

// 提交发布职位表单
const handleSubmit = async () => {
  if (!isFormValid.value) return
  loading.value = true
  try {
    // TODO: 调用后端API提交发布职位信息
    ElMessage.success('职位发布成功')
    router.push('/')
  } catch {
    ElMessage.error('发布失败，请重试')
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="post-job-page">
    <div class="post-job-container">
      <h2 class="page-title">发布职位</h2>
      <p class="page-desc">填写以下信息，快速发布招聘职位</p>

      <div class="form-section">
        <!-- 招聘职务输入 -->
        <div class="form-item">
          <label class="form-label">
            <el-icon :size="16"><Briefcase /></el-icon>
            招聘职务
          </label>
          <el-input
            v-model="form.jobTitle"
            size="large"
            placeholder="请输入招聘职务（如：Java开发工程师、产品经理）"
            maxlength="50"
            clearable
          />
        </div>

        <!-- 公司名称输入 -->
        <div class="form-item">
          <label class="form-label">
            <el-icon :size="16"><OfficeBuilding /></el-icon>
            公司名称
          </label>
          <el-input
            v-model="form.companyName"
            size="large"
            placeholder="请输入公司名称"
            maxlength="50"
            clearable
          />
        </div>

        <!-- 招聘者职务输入 -->
        <div class="form-item">
          <label class="form-label">
            <el-icon :size="16"><User /></el-icon>
            招聘者职务
          </label>
          <el-input
            v-model="form.recruiterTitle"
            size="large"
            placeholder="请输入您的职务（如：HR、部门经理、CEO）"
            maxlength="30"
            clearable
          />
        </div>

        <!-- 公司人数选择：以按钮组形式展示选项 -->
        <div class="form-item">
          <label class="form-label">
            <el-icon :size="16"><TrendCharts /></el-icon>
            公司人数
          </label>
          <div class="select-group">
            <button
              v-for="size in companySizes"
              :key="size"
              :class="['select-btn', { active: form.companySize === size }]"
              @click="form.companySize = size"
            >
              {{ size }}
            </button>
          </div>
        </div>

        <!-- 注册资金选择：以按钮组形式展示选项 -->
        <div class="form-item">
          <label class="form-label">
            <el-icon :size="16"><Money /></el-icon>
            注册资金
          </label>
          <div class="select-group">
            <button
              v-for="capital in registeredCapitals"
              :key="capital"
              :class="['select-btn', { active: form.registeredCapital === capital }]"
              @click="form.registeredCapital = capital"
            >
              {{ capital }}
            </button>
          </div>
        </div>

        <!-- 提交发布按钮 -->
        <button
          class="submit-btn"
          :disabled="!isFormValid || loading"
          :class="{ loading }"
          @click="handleSubmit"
        >
          {{ loading ? '提交中...' : '立即发布' }}
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.post-job-page {
  min-height: calc(100vh - 60px);
  background: #f5f7fa;
  padding: 40px 24px;
  box-sizing: border-box;
}

.post-job-container {
  max-width: 680px;
  margin: 0 auto;
  background: #fff;
  border-radius: 12px;
  padding: 40px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
}

.page-title {
  font-size: 24px;
  font-weight: 600;
  color: var(--text-h);
  margin: 0 0 8px;
}

.page-desc {
  font-size: 14px;
  color: #999;
  margin: 0 0 32px;
}

.form-section {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.form-item {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.form-label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 15px;
  font-weight: 500;
  color: var(--text-h);
}

.select-group {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.select-btn {
  padding: 8px 18px;
  font-size: 14px;
  border: 1px solid var(--border);
  border-radius: 6px;
  background: #fff;
  color: var(--text);
  cursor: pointer;
  transition: all 0.2s;
}

.select-btn:hover {
  border-color: #007AFF;
  color: #007AFF;
}

.select-btn.active {
  border-color: #007AFF;
  background: rgba(0, 122, 255, 0.08);
  color: #007AFF;
  font-weight: 500;
}

.submit-btn {
  width: 100%;
  height: 48px;
  font-size: 16px;
  font-weight: 600;
  color: #fff;
  background: #007AFF;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: opacity 0.2s;
  margin-top: 8px;
}

.submit-btn:hover:not(:disabled) {
  opacity: 0.92;
}

.submit-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.submit-btn.loading {
  opacity: 0.7;
}

@media (max-width: 768px) {
  .post-job-container {
    padding: 24px;
  }

  .select-group {
    flex-direction: column;
  }

  .select-btn {
    width: 100%;
  }
}
</style>
