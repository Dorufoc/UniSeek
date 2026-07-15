<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { ElMessage, ElMessageBox } from 'element-plus'
import { changePassword, getRealNameAuthStatus, updatePhone, updateEmail } from '@/api/auth'
import { Lock, Phone, Message, WarningFilled, CircleCheckFilled, ArrowLeft, UserFilled } from '@element-plus/icons-vue'

const router = useRouter()
const userStore = useUserStore()

const activeSection = ref<'password' | 'phone' | 'email' | 'realName' | ''>('')
const loading = ref(false)

// ── 修改密码 ──
const passwordForm = reactive({
  oldPassword: '',
  newPassword: '',
  confirmPassword: ''
})

const isPasswordValid = computed(() => {
  return passwordForm.oldPassword.length >= 6
    && passwordForm.newPassword.length >= 6 && passwordForm.newPassword.length <= 20
    && passwordForm.confirmPassword === passwordForm.newPassword
    && passwordForm.newPassword !== passwordForm.oldPassword
})

const handleChangePassword = async () => {
  if (!isPasswordValid.value) return
  loading.value = true
  try {
    await changePassword({
      oldPassword: passwordForm.oldPassword,
      newPassword: passwordForm.newPassword,
      confirmPassword: passwordForm.confirmPassword
    })
    ElMessage.success('密码修改成功，请重新登录')
    userStore.logout()
    router.push('/login')
  } catch {
  } finally {
    loading.value = false
    passwordForm.oldPassword = ''
    passwordForm.newPassword = ''
    passwordForm.confirmPassword = ''
  }
}

// ── 修改手机号 ──
const phoneForm = reactive({
  newPhone: '',
  password: ''
})

const isPhoneValid = computed(() => /^1[3-9]\d{9}$/.test(phoneForm.newPhone) && phoneForm.password.length >= 6)

const handleUpdatePhone = async () => {
  if (!isPhoneValid.value) return
  loading.value = true
  try {
    await updatePhone({ newPhone: phoneForm.newPhone, password: phoneForm.password })
    ElMessage.success('手机号修改成功')
    activeSection.value = ''
    phoneForm.newPhone = ''
    phoneForm.password = ''
    // 刷新用户信息
    userStore.fetchUserInfo()
  } catch {
  } finally {
    loading.value = false
  }
}

// ── 修改邮箱 ──
const emailForm = reactive({
  newEmail: '',
  password: ''
})

const isEmailValid = computed(() => {
  return /^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/.test(emailForm.newEmail)
    && emailForm.password.length >= 6
})

const handleUpdateEmail = async () => {
  if (!isEmailValid.value) return
  loading.value = true
  try {
    await updateEmail({ newEmail: emailForm.newEmail, password: emailForm.password })
    ElMessage.success('邮箱修改成功')
    activeSection.value = ''
    emailForm.newEmail = ''
    emailForm.password = ''
    userStore.fetchUserInfo()
  } catch {
  } finally {
    loading.value = false
  }
}

// ── 展示 ──
const userPhone = computed(() => {
  const phone = userStore.userInfo?.phone || ''
  return phone ? phone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2') : '未绑定'
})

const userEmail = computed(() => {
  const email = userStore.userInfo?.email || ''
  if (!email) return '未绑定'
  const [name, domain] = email.split('@')
  return name.length > 2 ? name.substring(0, 2) + '***@' + domain : name + '***@' + domain
})

const realNameStatus = ref<'未认证' | '已认证'>('未认证')

onMounted(async () => {
  try {
    const result = await getRealNameAuthStatus()
    realNameStatus.value = (result?.isAuth || result?.status === 1) ? '已认证' : '未认证'
  } catch { /* 未认证 */ }
})

const toggleSection = (section: string) => {
  activeSection.value = activeSection.value === section ? '' : section
}

const handleDeleteAccount = () => {
  ElMessageBox.confirm(
    '注销后您的所有数据将被永久删除，包括简历、投递记录等。此操作不可逆转，确定要继续吗？',
    '注销账号',
    { confirmButtonText: '确认注销', cancelButtonText: '取消', type: 'warning' }
  ).then(() => {
    ElMessage.info('账号注销功能需联系客服处理')
  }).catch(() => {})
}
</script>

<template>
  <div class="security-page">
    <div class="security-container">
      <div class="page-header">
        <h2 class="page-title">
          <el-icon :size="22"><Lock /></el-icon>
          账号安全
        </h2>
        <p class="page-subtitle">管理您的密码、绑定信息和安全设置</p>
      </div>

      <div class="security-score-card">
        <div class="score-header">
          <span class="score-label">安全评分</span>
          <span class="score-level high">较高</span>
        </div>
        <div class="score-bar">
          <div class="score-fill" style="width: 75%"></div>
        </div>
        <div class="score-items">
          <div class="score-item checked">
            <el-icon :size="14"><CircleCheckFilled /></el-icon>
            <span>密码已设置</span>
          </div>
          <div class="score-item checked">
            <el-icon :size="14"><CircleCheckFilled /></el-icon>
            <span>手机号已绑定</span>
          </div>
          <div class="score-item" :class="{ checked: userStore.userInfo?.email }">
            <el-icon :size="14"><CircleCheckFilled v-if="userStore.userInfo?.email" /><WarningFilled v-else /></el-icon>
            <span>{{ userStore.userInfo?.email ? '邮箱已绑定' : '邮箱未绑定' }}</span>
          </div>
          <div class="score-item" :class="{ checked: realNameStatus === '已认证' }">
            <el-icon :size="14"><CircleCheckFilled v-if="realNameStatus === '已认证'" /><WarningFilled v-else /></el-icon>
            <span>{{ realNameStatus === '已认证' ? '已实名认证' : '未实名认证' }}</span>
          </div>
        </div>
      </div>

      <div class="settings-list">

        <!-- 修改密码 -->
        <div class="settings-card">
          <div class="settings-row" @click="toggleSection('password')">
            <div class="settings-icon">
              <el-icon :size="20"><Lock /></el-icon>
            </div>
            <div class="settings-info">
              <span class="settings-name">修改密码</span>
              <span class="settings-hint">定期更换密码可提升账号安全性</span>
            </div>
            <span class="settings-arrow" :class="{ open: activeSection === 'password' }">
              <el-icon :size="16"><ArrowLeft /></el-icon>
            </span>
          </div>

          <div v-if="activeSection === 'password'" class="settings-body">
            <div class="form-group">
              <label>当前密码</label>
              <el-input v-model="passwordForm.oldPassword" type="password" placeholder="请输入当前密码" show-password size="large" />
            </div>
            <div class="form-group">
              <label>新密码</label>
              <el-input v-model="passwordForm.newPassword" type="password" placeholder="6-20位字母、数字或特殊字符" show-password size="large" />
            </div>
            <div class="form-group">
              <label>确认新密码</label>
              <el-input v-model="passwordForm.confirmPassword" type="password" placeholder="请再次输入新密码" show-password size="large" />
              <p v-if="passwordForm.confirmPassword && passwordForm.confirmPassword !== passwordForm.newPassword" class="field-error">两次密码输入不一致</p>
              <p v-if="passwordForm.newPassword && passwordForm.newPassword.length < 6" class="field-error">密码长度不能少于6位</p>
              <p v-if="passwordForm.newPassword === passwordForm.oldPassword && passwordForm.oldPassword" class="field-error">新密码不能与当前密码相同</p>
            </div>
            <button class="save-btn" :disabled="!isPasswordValid || loading" @click="handleChangePassword">
              {{ loading ? '保存中...' : '确认修改' }}
            </button>
            <p class="form-note">修改成功后需要重新登录</p>
          </div>
        </div>

        <!-- 绑定手机号（可修改） -->
        <div class="settings-card">
          <div class="settings-row" @click="toggleSection('phone')">
            <div class="settings-icon">
              <el-icon :size="20"><Phone /></el-icon>
            </div>
            <div class="settings-info">
              <span class="settings-name">绑定手机号</span>
              <span class="settings-hint">用于登录和接收重要通知</span>
            </div>
            <span class="settings-value">{{ userPhone }}</span>
            <span class="settings-arrow" :class="{ open: activeSection === 'phone' }">
              <el-icon :size="16"><ArrowLeft /></el-icon>
            </span>
          </div>

          <div v-if="activeSection === 'phone'" class="settings-body">
            <div class="readonly-row">
              <label>当前绑定手机号</label>
              <span class="readonly-value">{{ userPhone }}</span>
            </div>
            <div class="form-group">
              <label>新手机号</label>
              <el-input v-model="phoneForm.newPhone" placeholder="输入新手机号" size="large" maxlength="11" />
              <p v-if="phoneForm.newPhone && !/^1[3-9]\d{9}$/.test(phoneForm.newPhone)" class="field-error">手机号格式不正确</p>
            </div>
            <div class="form-group">
              <label>当前密码（验证身份）</label>
              <el-input v-model="phoneForm.password" type="password" placeholder="请输入当前密码" show-password size="large" />
            </div>
            <button class="save-btn" :disabled="!isPhoneValid || loading" @click="handleUpdatePhone">
              {{ loading ? '保存中...' : '确认修改' }}
            </button>
            <p class="form-note">修改后请使用新手机号登录</p>
          </div>
        </div>

        <!-- 绑定邮箱（可修改） -->
        <div class="settings-card">
          <div class="settings-row" @click="toggleSection('email')">
            <div class="settings-icon">
              <el-icon :size="20"><Message /></el-icon>
            </div>
            <div class="settings-info">
              <span class="settings-name">绑定邮箱</span>
              <span class="settings-hint">用于接收通知和找回密码</span>
            </div>
            <span class="settings-value">{{ userEmail }}</span>
            <span class="settings-arrow" :class="{ open: activeSection === 'email' }">
              <el-icon :size="16"><ArrowLeft /></el-icon>
            </span>
          </div>

          <div v-if="activeSection === 'email'" class="settings-body">
            <div class="readonly-row">
              <label>当前绑定邮箱</label>
              <span class="readonly-value">{{ userEmail }}</span>
            </div>
            <div class="form-group">
              <label>新邮箱</label>
              <el-input v-model="emailForm.newEmail" placeholder="输入新邮箱地址" size="large" />
              <p v-if="emailForm.newEmail && !/^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/.test(emailForm.newEmail)" class="field-error">邮箱格式不正确</p>
            </div>
            <div class="form-group">
              <label>当前密码（验证身份）</label>
              <el-input v-model="emailForm.password" type="password" placeholder="请输入当前密码" show-password size="large" />
            </div>
            <button class="save-btn" :disabled="!isEmailValid || loading" @click="handleUpdateEmail">
              {{ loading ? '保存中...' : '确认修改' }}
            </button>
            <p class="form-note">修改后请使用新邮箱接收通知</p>
          </div>
        </div>

        <!-- 实名认证 -->
        <div class="settings-card">
          <div class="settings-row" @click="toggleSection('realName')">
            <div class="settings-icon verified">
              <el-icon :size="20"><UserFilled /></el-icon>
            </div>
            <div class="settings-info">
              <span class="settings-name">实名认证</span>
              <span class="settings-hint">实名认证后可正常使用平台全部功能</span>
            </div>
            <span class="settings-status" :class="{ verified: realNameStatus === '已认证' }">
              {{ realNameStatus }}
            </span>
            <span class="settings-arrow" :class="{ open: activeSection === 'realName' }">
              <el-icon :size="16"><ArrowLeft /></el-icon>
            </span>
          </div>

          <div v-if="activeSection === 'realName'" class="settings-body">
            <div class="auth-notice" :class="realNameStatus === '已认证' ? 'success' : 'warning'">
              <el-icon :size="18">
                <CircleCheckFilled v-if="realNameStatus === '已认证'" />
                <WarningFilled v-else />
              </el-icon>
              <span>{{ realNameStatus === '已认证' ? '您的账号已完成实名认证' : '您尚未完成实名认证，投递职位前需要先完成认证' }}</span>
            </div>
            <button v-if="realNameStatus !== '已认证'" class="save-btn" @click="router.push('/profile?tab=realNameAuth')">
              前往实名认证
            </button>
          </div>
        </div>
      </div>

      <!-- 危险操作区 -->
      <div class="danger-zone">
        <h3 class="danger-title">危险操作</h3>
        <div class="danger-card" @click="handleDeleteAccount">
          <div class="danger-info">
            <span class="danger-name">注销账号</span>
            <span class="danger-hint">注销后所有数据将被永久删除，不可恢复</span>
          </div>
          <span class="danger-arrow">
            <el-icon :size="16"><ArrowLeft /></el-icon>
          </span>
        </div>
      </div>

      <div class="login-info-card">
        <h4 class="info-title">登录信息</h4>
        <div class="info-row">
          <span class="info-label">上次登录时间</span>
          <span class="info-value">{{ userStore.userInfo?.lastLoginTime || '未知' }}</span>
        </div>
        <div class="info-row">
          <span class="info-label">注册时间</span>
          <span class="info-value">{{ userStore.userInfo?.createTime || '未知' }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.security-page {
  min-height: calc(100vh - 60px);
  background: #f5f7fa;
  padding: 24px;
  box-sizing: border-box;
}
.security-container { max-width: 720px; margin: 0 auto; }
.page-header { margin-bottom: 20px; }
.page-title { display: flex; align-items: center; gap: 8px; font-size: 22px; font-weight: 600; color: var(--text-h); margin: 0 0 6px; }
.page-subtitle { font-size: 14px; color: #999; margin: 0; }

.security-score-card { background: #fff; border-radius: 12px; padding: 24px; margin-bottom: 16px; box-shadow: 0 1px 4px rgba(0,0,0,0.06); }
.score-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.score-label { font-size: 15px; font-weight: 600; color: var(--text-h); }
.score-level { font-size: 14px; font-weight: 500; padding: 3px 12px; border-radius: 12px; }
.score-level.high { color: #2ecc71; background: rgba(46,204,113,0.1); }
.score-level.medium { color: #f0ad4e; background: rgba(240,173,78,0.1); }
.score-level.low { color: #e74c3c; background: rgba(231,76,60,0.1); }
.score-bar { height: 8px; background: #f0f0f5; border-radius: 4px; overflow: hidden; margin-bottom: 16px; }
.score-fill { height: 100%; background: linear-gradient(90deg, #2ecc71, #27ae60); border-radius: 4px; }
.score-items { display: grid; grid-template-columns: repeat(2, 1fr); gap: 8px; }
.score-item { display: flex; align-items: center; gap: 6px; font-size: 13px; color: #bbb; }
.score-item.checked { color: #666; }
.score-item.checked :deep(.el-icon) { color: #2ecc71; }

.settings-list { display: flex; flex-direction: column; gap: 10px; margin-bottom: 24px; }
.settings-card { background: #fff; border-radius: 12px; box-shadow: 0 1px 4px rgba(0,0,0,0.06); overflow: hidden; }
.settings-row { display: flex; align-items: center; gap: 14px; padding: 18px 20px; cursor: pointer; transition: background 0.15s; }
.settings-row:hover { background: #f8f9fb; }
.settings-icon { width: 40px; height: 40px; border-radius: 10px; background: rgba(0,122,255,0.08); color: #1762FB; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.settings-icon.verified { background: rgba(46,204,113,0.08); color: #2ecc71; }
.settings-info { flex: 1; min-width: 0; }
.settings-name { display: block; font-size: 15px; font-weight: 500; color: var(--text-h); margin-bottom: 2px; }
.settings-hint { font-size: 12px; color: #bbb; }
.settings-value { font-size: 14px; color: #999; flex-shrink: 0; }
.settings-status { font-size: 13px; padding: 3px 10px; border-radius: 12px; background: rgba(231,76,60,0.08); color: #e74c3c; flex-shrink: 0; }
.settings-status.verified { background: rgba(46,204,113,0.08); color: #2ecc71; }
.settings-arrow { color: #ccc; flex-shrink: 0; transition: transform 0.25s; }
.settings-arrow.open { transform: rotate(-90deg); }

.settings-body { border-top: 1px solid #f0f0f5; padding: 20px; background: #fafbfc; }
.form-group { margin-bottom: 16px; }
.form-group label { display: block; font-size: 14px; color: var(--text); margin-bottom: 6px; font-weight: 500; }
.field-error { font-size: 12px; color: #e74c3c; margin: 6px 0 0; }
.field-hint { font-size: 12px; color: #888; margin: 6px 0 0; }
.save-btn { width: 100%; padding: 12px 0; font-size: 15px; font-weight: 500; color: #fff; background: #1762FB; border: none; border-radius: 8px; cursor: pointer; transition: opacity 0.2s; }
.save-btn:hover:not(:disabled) { opacity: 0.9; }
.save-btn:disabled { opacity: 0.45; cursor: not-allowed; }
.form-note { font-size: 12px; color: #bbb; margin: 10px 0 0; text-align: center; }
.readonly-row { margin-bottom: 12px; }
.readonly-row label { display: block; font-size: 14px; color: var(--text); margin-bottom: 4px; }
.readonly-value { font-size: 16px; font-weight: 500; color: var(--text-h); }
.auth-notice { display: flex; align-items: center; gap: 10px; padding: 14px 16px; border-radius: 8px; font-size: 14px; margin-bottom: 16px; }
.auth-notice.success { background: rgba(46,204,113,0.06); color: #27ae60; }
.auth-notice.warning { background: rgba(240,173,78,0.06); color: #d4a017; }

.danger-zone { margin-bottom: 16px; }
.danger-title { font-size: 15px; font-weight: 600; color: #e74c3c; margin: 0 0 10px; }
.danger-card { background: #fff; border-radius: 12px; padding: 18px 20px; display: flex; align-items: center; justify-content: space-between; cursor: pointer; box-shadow: 0 1px 4px rgba(0,0,0,0.06); border: 1px solid rgba(231,76,60,0.15); }
.danger-card:hover { background: rgba(231,76,60,0.02); }
.danger-name { font-size: 15px; color: #e74c3c; font-weight: 500; display: block; margin-bottom: 2px; }
.danger-hint { font-size: 12px; color: #bbb; }
.danger-arrow { color: #e74c3c; }

.login-info-card { background: #fff; border-radius: 12px; padding: 20px; box-shadow: 0 1px 4px rgba(0,0,0,0.06); }
.info-title { font-size: 15px; font-weight: 600; color: var(--text-h); margin: 0 0 12px; }
.info-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #f5f5f5; }
.info-row:last-child { border-bottom: none; }
.info-label { font-size: 14px; color: #999; }
.info-value { font-size: 14px; color: var(--text); }

@media (max-width: 768px) {
  .security-page { padding: 16px 12px; }
  .score-items { grid-template-columns: 1fr; }
}
</style>
