<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Briefcase, Money, MapLocation, Timer, Collection, Calendar, TrendCharts, User, Close } from '@element-plus/icons-vue'
import { getTaskById, createTask, updateTask } from '@/api/task'
import { getCategories, type CategoryVO } from '@/api/category'
import { getRegionTree, type RegionVO } from '@/api/region'

const router = useRouter()
const route = useRoute()
const loading = ref(false)
const isEditMode = ref(false)
const editId = ref(0)

const form = reactive({
  title: '',
  categoryId: 0,
  regionId: 0,
  description: '',
  salaryMin: 0,
  salaryMax: 0,
  salaryUnit: 0,
  jobType: 1,
  totalQuota: 1,
  address: '',
  tag: [] as string[],
  deadline: ''
})

const cascaderValue = ref<number[]>([])
const regionCascaderValue = ref<number[]>([])

const onCascaderChange = (val: number[]) => {
  form.categoryId = val.length > 0 ? val[val.length - 1] : 0
}

const onRegionChange = (val: number[]) => {
  form.regionId = val.length > 0 ? val[val.length - 1] : 0
}

const salaryUnitOptions = [
  { label: '日结', value: 0 },
  { label: '时薪', value: 1 },
  { label: '月薪', value: 2 }
]

const jobTypeOptions = [
  { label: '全职', value: 1 },
  { label: '兼职', value: 2 },
  { label: '实习', value: 3 }
]

const tagOptions = ['急招', '日结', '可远程', '包吃住', '周末兼职', '长期招聘', '学生优先', '经验不限', '高薪', '弹性工作']

const categoryTree = ref<CategoryVO[]>([])
const regionTree = ref<RegionVO[]>([])

const loadOptions = async () => {
  const [cats, regs] = await Promise.all([
    getCategories().catch(() => [] as CategoryVO[]),
    getRegionTree().catch(() => [] as RegionVO[])
  ])
  categoryTree.value = cats
  regionTree.value = regs
}

const findCascaderPath = (tree: any[], targetId: number): number[] => {
  for (const node of tree) {
    if (node.id === targetId) return [node.id]
    if (node.children) {
      const path = findCascaderPath(node.children, targetId)
      if (path.length) return [node.id, ...path]
    }
  }
  return []
}

const loadTaskForEdit = async (id: number) => {
  try {
    const res = await getTaskById(id)
    if (!res) throw new Error('加载失败')
    const task = res
    form.title = task.title || ''
    form.categoryId = task.categoryId || 0
    form.regionId = task.regionId || 0
    form.description = task.description || ''
    form.salaryMin = task.salaryMin || 0
    form.salaryMax = task.salaryMax || 0
    form.salaryUnit = task.salaryUnit ?? 0
    form.jobType = task.jobType || 1
    form.totalQuota = task.totalQuota || 1
    form.address = task.address || ''
    form.tag = task.tag || []
    form.deadline = task.deadline || ''
    // 回填级联选择器
    cascaderValue.value = findCascaderPath(categoryTree.value, task.categoryId)
    regionCascaderValue.value = findCascaderPath(regionTree.value, task.regionId)
  } catch {
    ElMessage.warning('加载职位信息失败')
    router.push('/job-management')
  }
}

onMounted(async () => {
  await loadOptions()
  const idParam = route.query.id
  if (idParam) {
    isEditMode.value = true
    editId.value = Number(idParam)
    await loadTaskForEdit(editId.value)
  }
})

const toggleTag = (tag: string) => {
  const idx = form.tag.indexOf(tag)
  if (idx > -1) {
    form.tag.splice(idx, 1)
  } else {
    form.tag.push(tag)
  }
}

// 自定义标签输入
const customTagInput = ref('')

const addCustomTag = () => {
  const tag = customTagInput.value.trim()
  if (!tag) {
    ElMessage.warning('请输入标签内容')
    return
  }
  if (form.tag.includes(tag)) {
    ElMessage.warning('该标签已存在')
    return
  }
  form.tag.push(tag)
  customTagInput.value = ''
}

const removeTag = (tag: string) => {
  const idx = form.tag.indexOf(tag)
  if (idx > -1) {
    form.tag.splice(idx, 1)
  }
}

const isFormValid = computed(() => {
  return form.title.trim() !== ''
    && cascaderValue.value.length > 0
    && form.regionId > 0
    && form.description.trim() !== ''
    && form.salaryMax >= form.salaryMin
    && form.totalQuota > 0
    && form.address.trim() !== ''
    && form.deadline.trim() !== ''
})

// 判断是否为面议（最低和最高薪资均为 0）
const isNegotiableSalary = computed(() => form.salaryMin === 0 && form.salaryMax === 0)

const handleSubmit = async () => {
  if (!isFormValid.value) return
  loading.value = true
  const params = {
    title: form.title.trim(),
    categoryId: form.categoryId,
    regionId: form.regionId,
    description: form.description.trim(),
    salaryMin: form.salaryMin,
    salaryMax: form.salaryMax,
    salaryUnit: form.salaryUnit,
    jobType: form.jobType,
    totalQuota: form.totalQuota,
    address: form.address.trim(),
    tag: form.tag,
    deadline: form.deadline || null
  }
  try {
    if (isEditMode.value) {
      await updateTask(editId.value, params)
      ElMessage.success('修改已保存')
    } else {
      await createTask(params)
      ElMessage.success('职位发布成功，等待审核')
    }
    router.push('/job-management')
  } catch (err: any) {
    if (err?.message?.includes('未找到企业信息')) {
      ElMessage.warning('请先完成企业资质认证')
      router.push('/enterprise-cert')
    }
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="post-job-page">
    <div class="post-job-container">
      <h2 class="page-title">{{ isEditMode ? '编辑职位' : '发布职位' }}</h2>
      <p class="page-desc">{{ isEditMode ? '修改职位信息后保存' : '填写以下信息，发布招聘职位' }}</p>

      <div class="form-section">
        <div class="form-item">
          <label class="form-label">
            <el-icon :size="16"><Briefcase /></el-icon>
             职位标题 <span class="required-mark">*</span>
            </label>
            <el-input v-model="form.title" size="large" placeholder="例如：周末餐厅服务员、前端开发兼职" maxlength="100" clearable />
        </div>

        <div class="form-row">
          <div class="form-item flex-1">
            <label class="form-label">职位分类 <span class="required-mark">*</span></label>
            <el-cascader
              v-model="cascaderValue"
              :options="categoryTree"
              :props="{ value: 'id', label: 'name', children: 'children', checkStrictly: false }"
              placeholder="请选择职位分类"
              size="large"
              clearable
              style="width:100%"
              @change="onCascaderChange as any"
            />
          </div>
          <div class="form-item flex-1">
            <label class="form-label">工作地区 <span class="required-mark">*</span></label>
            <el-cascader
              v-model="regionCascaderValue"
              :options="regionTree"
              :props="{ value: 'id', label: 'name', children: 'children', checkStrictly: false }"
              placeholder="请选择省/市/区"
              size="large"
              clearable
              style="width:100%"
              @change="onRegionChange as any"
            />
          </div>
        </div>

        <div class="form-item">
          <label class="form-label">
            <el-icon :size="16"><Collection /></el-icon>
            职位描述
          </label>
          <el-input v-model="form.description" type="textarea" :rows="5" placeholder="详细描述工作内容、任职要求、福利待遇等" maxlength="2000" show-word-limit />
        </div>

        <div class="form-row">
          <div class="form-item flex-1">
            <label class="form-label">
              <el-icon :size="16"><Money /></el-icon>
              最低薪资（元）
            </label>
            <el-input-number v-model="form.salaryMin" :min="0" :max="999999" size="large" style="width:100%" />
          </div>
          <div class="form-item flex-1">
            <label class="form-label">
              <el-icon :size="16"><Money /></el-icon>
              最高薪资（元）
            </label>
            <el-input-number v-model="form.salaryMax" :min="0" :max="999999" size="large" style="width:100%" />
          </div>
          <div class="form-item flex-1">
            <label class="form-label">薪资单位</label>
            <el-select v-model="form.salaryUnit" size="large" style="width:100%">
              <el-option v-for="opt in salaryUnitOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
            </el-select>
          </div>
        </div>
        <div v-if="isNegotiableSalary" class="salary-reminder">
          当前薪资设置为 0-0，发布后将在职位列表展示为「<strong>面议</strong>」。若需设定具体薪资，请将最低或最高薪资改为大于 0 的值。
        </div>

        <div class="form-row">
          <div class="form-item flex-1">
            <label class="form-label">
              <el-icon :size="16"><TrendCharts /></el-icon>
              工作类型
            </label>
            <el-select v-model="form.jobType" size="large" style="width:100%">
              <el-option v-for="opt in jobTypeOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
            </el-select>
          </div>
          <div class="form-item flex-1">
            <label class="form-label">
              <el-icon :size="16"><User /></el-icon>
              招聘人数
            </label>
            <el-input-number v-model="form.totalQuota" :min="1" :max="999" size="large" style="width:100%" />
          </div>
        </div>

        <div class="form-item">
          <label class="form-label">
            <el-icon :size="16"><MapLocation /></el-icon>
             工作地址 <span class="required-mark">*</span>
            </label>
            <el-input v-model="form.address" size="large" placeholder="例如：北京市朝阳区建国路88号" maxlength="200" clearable />
        </div>

        <div class="form-item">
          <label class="form-label">
            <el-icon :size="16"><Timer /></el-icon>
            职位标签
          </label>
          <!-- 系统推荐标签 -->
          <div class="tag-group">
            <button
              v-for="tag in tagOptions"
              :key="tag"
              :class="['tag-btn', { active: form.tag.includes(tag) }]"
              @click="toggleTag(tag)"
            >
              {{ tag }}
            </button>
          </div>
          <!-- 已选标签展示（含自定义标签） -->
          <div v-if="form.tag.length > 0" class="selected-tags">
            <span v-for="tag in form.tag" :key="tag" class="selected-tag">
              {{ tag }}
              <el-icon class="tag-remove-icon" @click="removeTag(tag)">
                <Close />
              </el-icon>
            </span>
          </div>
          <!-- 自定义标签输入 -->
          <div class="custom-tag-row">
            <el-input
              v-model="customTagInput"
              size="small"
              placeholder="输入自定义标签，按回车添加"
              maxlength="20"
              clearable
              style="flex:1"
              @keyup.enter="addCustomTag"
            />
            <button class="add-tag-btn" @click="addCustomTag">添加</button>
          </div>
        </div>

        <div class="form-item">
          <label class="form-label">
            <el-icon :size="16"><Calendar /></el-icon>
             报名截止时间 <span class="required-mark">*</span>
            </label>
          <el-date-picker v-model="form.deadline" type="datetime" placeholder="选择截止时间" size="large" style="width:100%" value-format="YYYY-MM-DDTHH:mm:ss" />
        </div>

        <button class="submit-btn" :disabled="!isFormValid || loading" :class="{ loading }" @click="handleSubmit">
          {{ loading ? '提交中...' : (isEditMode ? '保存修改' : '立即发布') }}
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
  max-width: 760px;
  margin: 0 auto;
  background: #fff;
  border-radius: 12px;
  padding: 40px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
}
.page-title {
  font-size: 24px;
  font-weight: 600;
  color: #000;
  margin: 0 0 8px;
}
.page-desc {
  font-size: 14px;
  color: #000;
  margin: 0 0 32px;
}
.form-section {
  display: flex;
  flex-direction: column;
  gap: 24px;
}
.form-row {
  display: flex;
  gap: 16px;
}
.form-item {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.flex-1 {
  flex: 1;
  min-width: 0;
}
.form-label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 15px;
  font-weight: 500;
  color: #000;
}
.required-mark {
  color: #e74c3c;
  font-weight: 700;
  font-size: 16px;
}
.tag-group {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}
.tag-btn {
  padding: 8px 18px;
  font-size: 14px;
  border: 1px solid var(--border);
  border-radius: 20px;
  background: #fff;
  color: #000;
  cursor: pointer;
  transition: all 0.2s;
}
.tag-btn:hover {
  border-color: #1762FB;
  color: #1762FB;
}
.tag-btn.active {
  border-color: #1762FB;
  background: rgba(23, 98, 251, 0.08);
  color: #1762FB;
  font-weight: 500;
}
/* 已选标签展示 */
.selected-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
.selected-tag {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 10px 4px 14px;
  font-size: 13px;
  border-radius: 16px;
  background: rgba(23, 98, 251, 0.1);
  color: #1762FB;
  border: 1px solid rgba(23, 98, 251, 0.2);
}
.tag-remove-icon {
  font-size: 14px;
  cursor: pointer;
  opacity: 0.6;
  transition: opacity 0.15s;
  display: flex;
  align-items: center;
}
.tag-remove-icon:hover {
  opacity: 1;
}

/* 自定义标签输入 */
.custom-tag-row {
  display: flex;
  gap: 8px;
  align-items: center;
}
.add-tag-btn {
  height: 32px;
  padding: 0 16px;
  font-size: 13px;
  font-weight: 500;
  color: #fff;
  background: #1762FB;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  white-space: nowrap;
  transition: opacity 0.2s;
  flex-shrink: 0;
}
.add-tag-btn:hover {
  opacity: 0.9;
}

/* 面议提示 */
.salary-reminder {
  margin-top: -12px;
  padding: 10px 14px;
  font-size: 13px;
  line-height: 1.6;
  color: #e67e22;
  background: #fef9e7;
  border: 1px solid #fce4a1;
  border-radius: 8px;
}
.salary-reminder strong {
  font-weight: 600;
}

.submit-btn {
  width: 100%;
  height: 48px;
  font-size: 16px;
  font-weight: 600;
  color: #fff;
  background: #1762FB;
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
  .post-job-container { padding: 24px; }
  .form-row { flex-direction: column; }
}
</style>
