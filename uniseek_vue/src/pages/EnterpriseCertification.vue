<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { ElMessage, ElDialog } from 'element-plus'
import { UploadFilled, WarningFilled, CircleCheckFilled, Clock, Edit, ArrowLeft } from '@element-plus/icons-vue'
import { submitEnterprise, getMyEnterprise, updateEnterprise } from '@/api/enterprise'
import type { EnterpriseInfo } from '@/api/enterprise'
import { uploadImage } from '@/api/upload'
import { getRegionTree } from '@/api/region'
import type { RegionVO } from '@/api/region'
import { getCategories, type CategoryVO } from '@/api/category'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const loading = ref(true)
const uploading = ref(false)
const editing = ref(false)
const submitting = ref(false)
const enterpriseInfo = ref<EnterpriseInfo | null>(null)
const fileInput = ref<HTMLInputElement | null>(null)

// 分类列表（从后端获取），用于所属行业选择
const categoryOptions = ref<CategoryVO[]>([])

// 地区树（从后端获取），使用 el-cascader 分层选择
const regionTree = ref<RegionVO[]>([])
const regionCascaderValue = ref<number[]>([])

const onRegionChange = (val: number[]) => {
  form.regionId = val.length > 0 ? val[val.length - 1] : null
}

// 在树中根据叶子 ID 查找完整路径（用于编辑回显）
const findCascaderPath = (tree: RegionVO[], targetId: number | null): number[] => {
  if (!targetId) return []
  for (const node of tree) {
    if (node.id === targetId) return [node.id]
    if (node.children) {
      const path = findCascaderPath(node.children, targetId)
      if (path.length) return [node.id, ...path]
    }
  }
  return []
}

const form = reactive({
  companyName: '',
  creditCode: '',
  licenseImgUrl: '',
  industry: '',
  regionId: null as number | null,
  description: ''
})

const isFormValid = computed(() => {
  return form.companyName.trim() !== ''
    && /^[0-9A-HJ-NPQRTUWXY]{18}$/i.test(form.creditCode)
    && form.industry !== ''
})

const loadEnterprise = async () => {
  loading.value = true
  try {
    const data = await getMyEnterprise()
    enterpriseInfo.value = data
    form.companyName = data.companyName || ''
    form.creditCode = data.creditCode || ''
    form.licenseImgUrl = data.licenseImgUrl || ''
    form.industry = data.industry || ''
    form.regionId = data.regionId
    form.description = data.description || ''
    regionCascaderValue.value = findCascaderPath(regionTree.value, data.regionId)
  } catch {
    enterpriseInfo.value = null
  } finally {
    loading.value = false
  }
}

const startEdit = () => {
  editing.value = true
}

const cancelEdit = () => {
  if (enterpriseInfo.value) {
    form.companyName = enterpriseInfo.value.companyName || ''
    form.creditCode = enterpriseInfo.value.creditCode || ''
    form.licenseImgUrl = enterpriseInfo.value.licenseImgUrl || ''
    form.industry = enterpriseInfo.value.industry || ''
    form.regionId = enterpriseInfo.value.regionId
    form.description = enterpriseInfo.value.description || ''
    regionCascaderValue.value = findCascaderPath(regionTree.value, enterpriseInfo.value.regionId)
  }
  editing.value = false
}

const handleUpload = () => {
  fileInput.value?.click()
}

const onFileSelected = async (e: Event) => {
  const target = e.target as HTMLInputElement
  const file = target.files?.[0]
  if (!file) return
  if (!file.type.startsWith('image/')) {
    ElMessage.warning('请选择图片文件')
    return
  }
  if (file.size > 10 * 1024 * 1024) {
    ElMessage.warning('图片不能超过 10MB')
    return
  }
  uploading.value = true
  try {
    const data = await uploadImage(file)
    form.licenseImgUrl = data.url
    ElMessage.success('营业执照上传成功')
  } catch {} finally {
    uploading.value = false
    target.value = ''
  }
}

const removeLicense = () => {
  form.licenseImgUrl = ''
}

const handleSave = async () => {
  if (!isFormValid.value || submitting.value) return
  submitting.value = true
  try {
    const params = {
      companyName: form.companyName.trim(),
      creditCode: form.creditCode.trim().toUpperCase(),
      licenseImgUrl: form.licenseImgUrl,
      industry: form.industry,
      regionId: form.regionId,
      description: form.description.trim()
    }
    if (enterpriseInfo.value) {
      await updateEnterprise(params)
      ElMessage.success('企业信息已更新')
    } else {
      await submitEnterprise(params)
      ElMessage.success('企业信息提交成功，等待审核')
    }
    await loadEnterprise()
    editing.value = false
  } catch {} finally {
    submitting.value = false
  }
}

onMounted(async () => {
  // 并行获取地区树和分类列表（行业数据）
  const [regions, categories] = await Promise.all([
    getRegionTree().catch(() => [] as RegionVO[]),
    getCategories().catch(() => [] as CategoryVO[])
  ])
  regionTree.value = regions
  categoryOptions.value = categories
  await loadEnterprise()
  if (!enterpriseInfo.value) {
    editing.value = true
  } else if (route.query.edit === '1') {
    editing.value = true
  }
})
</script>

<template>
  <div class="cert-page">
    <button class="back-btn-top" @click="router.back()"><el-icon :size="18"><ArrowLeft /></el-icon> 返回</button>
    <div class="cert-container">
      <div v-if="loading" class="loading-state">加载中...</div>

      <!-- 已认证 → 展示企业信息 -->
      <template v-else-if="enterpriseInfo && !editing">
        <div class="status-bar" :class="['status-' + ['pending','approved','rejected'][enterpriseInfo.auditStatus]]">
          <el-icon :size="18">
            <template v-if="enterpriseInfo.auditStatus === 1"><CircleCheckFilled /></template>
            <template v-else-if="enterpriseInfo.auditStatus === 2"><WarningFilled /></template>
            <template v-else><Clock /></template>
          </el-icon>
          <span>
            {{ ['审核中，请耐心等待','已认证，可发布职位','已被驳回，请修改后重新提交'][enterpriseInfo.auditStatus] }}
          </span>
        </div>

        <h2 class="page-title">企业信息</h2>
        <div class="info-grid">
          <div class="info-row"><span class="info-label">公司全称</span><span class="info-value">{{ enterpriseInfo.companyName }}</span></div>
          <div class="info-row"><span class="info-label">信用代码</span><span class="info-value">{{ enterpriseInfo.creditCode }}</span></div>
          <div class="info-row"><span class="info-label">所属行业</span><span class="info-value">{{ enterpriseInfo.industry || '未设置' }}</span></div>
          <div class="info-row"><span class="info-label">公司简介</span><span class="info-value">{{ enterpriseInfo.description || '未设置' }}</span></div>
        </div>
        <button class="action-btn full" @click="startEdit"><el-icon :size="16"><Edit /></el-icon> 编辑企业信息</button>
      </template>

      <!-- 编辑 / 新建表单 -->
      <template v-else>
        <h2 class="page-title">{{ enterpriseInfo ? '编辑企业信息' : '企业资质认证' }}</h2>
        <p class="page-desc">{{ enterpriseInfo ? '修改企业基本信息' : '填写企业信息提交审核，认证通过后可发布职位' }}</p>

        <div class="form-section">
          <div class="form-item">
            <label class="form-label">公司全称 <span class="required">*</span></label>
            <el-input v-model="form.companyName" size="large" placeholder="与企业营业执照一致" maxlength="100" clearable />
          </div>
          <div class="form-item">
            <label class="form-label">统一社会信用代码 <span class="required">*</span></label>
            <el-input v-model="form.creditCode" size="large" placeholder="18位统一社会信用代码" maxlength="18" clearable />
          </div>
          <div class="form-row">
            <div class="form-item" style="flex:1;min-width:0">
              <label class="form-label">所属行业 <span class="required">*</span></label>
              <el-select v-model="form.industry" placeholder="选择行业" size="large" style="width:100%" filterable>
                <el-option
                  v-for="cat in categoryOptions"
                  :key="cat.id"
                  :label="cat.name"
                  :value="cat.name"
                />
              </el-select>
            </div>
            <div class="form-item" style="flex:2;min-width:0">
              <label class="form-label">所在地区</label>
              <el-cascader
                v-model="regionCascaderValue"
                :options="regionTree"
                :props="{ value: 'id', label: 'name', children: 'children', checkStrictly: false }"
                placeholder="请选择省/市/区"
                size="large"
                clearable
                style="width:100%"
                @change="onRegionChange"
              />
            </div>
          </div>
          <div class="form-item">
            <label class="form-label">营业执照</label>
            <div v-if="!form.licenseImgUrl" class="upload-area" @click="handleUpload">
              <el-icon :size="32"><UploadFilled /></el-icon>
              <span>{{ uploading ? '上传中...' : '点击上传营业执照' }}</span>
            </div>
            <div v-else class="uploaded-area">
              <el-image :src="form.licenseImgUrl" style="max-height:80px;border-radius:4px" fit="contain" />
              <button class="remove-btn" @click="removeLicense">删除</button>
            </div>
            <input ref="fileInput" type="file" accept="image/*" style="display:none" @change="onFileSelected" />
          </div>
          <div class="form-item">
            <label class="form-label">公司简介</label>
            <el-input v-model="form.description" type="textarea" :rows="4" placeholder="公司业务和规模介绍（选填）" maxlength="2000" show-word-limit />
          </div>
          <div class="form-actions">
            <button v-if="enterpriseInfo" class="cancel-btn" @click="cancelEdit">取消</button>
            <button class="submit-btn" :disabled="!isFormValid || submitting" :class="{ loading: submitting }" @click="handleSave">
              {{ submitting ? '保存中...' : '保存' }}
            </button>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>

<style scoped>
.cert-page {
  min-height: calc(100vh - 60px);
  background: #f5f7fa;
  padding: 40px 24px;
  box-sizing: border-box;
  position: relative;
}
.cert-container {
  max-width: 680px;
  margin: 0 auto;
  background: #fff;
  border-radius: 12px;
  padding: 40px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.06);
}
.loading-state { text-align: center; padding: 60px 0; font-size: 15px; color: #000; }
.page-title { font-size: 24px; font-weight: 600; color: #000; margin: 0 0 8px; }
.page-desc { font-size: 14px; color: #000; margin: 0 0 32px; }

.status-bar {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 14px;
  margin-bottom: 24px;
}
.status-0 { background: rgba(245,127,23,0.1); color: #f57f17; }
.status-1 { background: rgba(46,125,50,0.1); color: #2e7d32; }
.status-2 { background: rgba(231,76,60,0.1); color: #e74c3c; }

.back-btn-top {
  position: absolute;
  top: 16px;
  left: 16px;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 8px 14px;
  border: none;
  background: rgba(255,255,255,0.9);
  color: #000;
  font-size: 14px;
  border-radius: 8px;
  cursor: pointer;
  z-index: 10;
  box-shadow: 0 1px 4px rgba(0,0,0,0.1);
}
.back-btn-top:hover { color: #1762FB; }

.info-grid { display: flex; flex-direction: column; gap: 16px; margin-bottom: 24px; }
.info-row { display: flex; padding: 12px 0; border-bottom: 1px solid var(--border); }
.info-label { width: 120px; font-size: 14px; color: #000; flex-shrink: 0; }
.info-value { flex: 1; font-size: 14px; color: #000; }

.form-section { display: flex; flex-direction: column; gap: 24px; }
.form-row { display: flex; gap: 16px; }
.form-item { display: flex; flex-direction: column; gap: 10px; }
.flex-1 { flex: 1; min-width: 0; }
.form-label { font-size: 15px; font-weight: 500; color: #000; }
.required { color: #e74c3c; }

.upload-area {
  border: 2px dashed var(--border);
  border-radius: 8px;
  padding: 40px 20px;
  text-align: center;
  cursor: pointer;
  color: #000;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  transition: border-color 0.2s;
}
.upload-area:hover { border-color: #1762FB; color: #1762FB; }
.uploaded-area {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 12px 16px;
  background: #f0f7ff;
  border-radius: 8px;
  font-size: 14px;
  color: #000;
}
.remove-btn {
  padding: 4px 12px;
  border: none;
  background: rgba(231,76,60,0.1);
  color: #e74c3c;
  border-radius: 4px;
  cursor: pointer;
  font-size: 13px;
  margin-left: auto;
}
.form-actions {
  display: flex;
  gap: 12px;
  margin-top: 8px;
}
.submit-btn, .cancel-btn, .action-btn {
  height: 48px;
  font-size: 16px;
  font-weight: 600;
  border-radius: 8px;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
}
.submit-btn {
  flex: 1;
  color: #fff;
  background: #1762FB;
  border: none;
}
.submit-btn:hover:not(:disabled) { opacity: 0.92; }
.submit-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.submit-btn.loading { opacity: 0.7; }
.cancel-btn {
  padding: 0 24px;
  color: #000;
  background: #f5f5f5;
  border: 1px solid var(--border);
}
.action-btn.full {
  width: 100%;
  color: #1762FB;
  background: rgba(0,122,255,0.06);
  border: 1px solid rgba(0,122,255,0.2);
}
.action-btn.full:hover { background: rgba(0,122,255,0.12); }

.state-card {
  text-align: center;
  padding: 60px 40px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
}
.state-card h2 { font-size: 22px; font-weight: 600; margin: 0; color: #000; }
.state-card p { font-size: 15px; color: #000; margin: 0; }
.state-card .action-btn {
  display: inline-flex;
  padding: 10px 32px;
  border: none;
  color: #fff;
  background: #1762FB;
  font-size: 15px;
  text-decoration: none;
  margin-top: 8px;
}

@media (max-width: 768px) {
  .cert-container { padding: 24px; }
  .form-row { flex-direction: column; }
  .info-label { width: 80px; }
}
</style>
