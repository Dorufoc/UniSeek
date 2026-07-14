<script setup lang="ts">
import { ref, reactive, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { ElMessage } from 'element-plus'
import { loginByPassword, register } from '@/api/auth'
import { Phone, Message, Lock, User, ChatDotRound, Wallet, Search } from '@element-plus/icons-vue'

const router = useRouter()
const userStore = useUserStore()

const activeTab = ref<'login' | 'register'>('login')
const loading = ref(false)
const agreed = ref(false)
const role = ref<'seeker' | 'recruiter' | ''>('')

const form = reactive({
  phone: '',
  password: '',
  confirmPassword: '',
  username: '',
  email: ''
})

const phonePattern = /^1[3-9]\d{9}$/
const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

const isPhoneValid = computed(() => phonePattern.test(form.phone))
const isPasswordValid = computed(() => form.password.length >= 6 && form.password.length <= 20)
const isConfirmPasswordValid = computed(() => form.password === form.confirmPassword)
const isUsernameValid = computed(() => form.username.trim().length >= 2 && form.username.trim().length <= 20)
const isEmailValid = computed(() => emailPattern.test(form.email))
const isRoleValid = computed(() => role.value !== '')

const canLogin = computed(() => {
  return isPhoneValid.value && isPasswordValid.value && agreed.value
})

const canRegister = computed(() => {
  return isRoleValid.value && isUsernameValid.value && isEmailValid.value && isPasswordValid.value && isConfirmPasswordValid.value && agreed.value
})

const handleLogin = async () => {
  if (!canLogin.value) return
  loading.value = true
  try {
    const res = await loginByPassword({ phone: form.phone, password: form.password })
    userStore.setToken(res.token)
    userStore.setUserInfo({
      userId: res.userId,
      nickname: res.nickname,
      avatar: res.avatar
    })
    ElMessage.success('登录成功')
    const target = userStore.userInfo?.role === 'recruiter' ? '/post-job' : '/'
    router.replace(target)
  } catch {
    // 错误已在拦截器中处理
  } finally {
    loading.value = false
  }
}

const handleRegister = async () => {
  if (!canRegister.value) return
  loading.value = true
  try {
    const res = await register({
      username: form.username.trim(),
      email: form.email.trim(),
      password: form.password
    })
    userStore.setToken(res.token)
    userStore.setUserInfo({
      userId: res.userId,
      nickname: res.nickname,
      avatar: res.avatar,
      role: role.value
    })
    ElMessage.success('注册成功')
    const target = role.value === 'recruiter' ? '/post-job' : '/'
    router.replace(target)
  } catch {
    // 错误已在拦截器中处理
  } finally {
    loading.value = false
  }
}

const switchTab = (tab: 'login' | 'register') => {
  activeTab.value = tab
  form.password = ''
  form.confirmPassword = ''
  form.username = ''
  form.email = ''
  role.value = ''
  agreed.value = false
}
</script>

<template>
  <div class="login-container">
    <div class="login-card">
      <div class="card-brand">
        <div class="brand-content">
          <h1 class="brand-name">UniSeek</h1>
          <p class="brand-desc">智能匹配，让求职更高效</p>
        </div>
      </div>

      <div class="card-form">
        <div class="form-tabs">
          <button
            :class="['tab-btn', { active: activeTab === 'login' }]"
            @click="switchTab('login')"
          >
            登录
          </button>
          <button
            :class="['tab-btn', { active: activeTab === 'register' }]"
            @click="switchTab('register')"
          >
            注册
          </button>
        </div>

        <!-- 登录表单 -->
        <template v-if="activeTab === 'login'">
          <div class="form-body">
            <div class="input-group">
              <el-input
                v-model="form.phone"
                size="large"
                placeholder="请输入手机号"
                maxlength="11"
                clearable
                :prefix-icon="Phone"
              />
              <span v-if="form.phone && !isPhoneValid" class="input-error">请输入正确的手机号</span>
            </div>

            <div class="input-group">
              <el-input
                v-model="form.password"
                type="password"
                size="large"
                placeholder="请输入密码"
                show-password
                :prefix-icon="Lock"
              />
            </div>

            <div class="form-options">
              <label class="agree-label">
                <el-checkbox v-model="agreed" />
                <span>
                  已阅读并同意
                  <a href="#" onclick="return false">《用户协议》</a>和<a href="#" onclick="return false">《隐私政策》</a>
                </span>
              </label>
            </div>

            <button
              class="submit-btn"
              :disabled="!canLogin || loading"
              :class="{ loading }"
              @click="handleLogin"
            >
              {{ loading ? '登录中...' : '登录' }}
            </button>
          </div>
        </template>

        <!-- 注册表单 -->
        <template v-else>
          <div class="form-body">
            <!-- 角色选择 -->
            <div class="role-select-group">
              <span class="role-select-label">选择身份</span>
              <div class="role-toggle">
                <button
                  :class="['role-btn', { active: role === 'seeker' }]"
                  @click="role = 'seeker'"
                >
                  <el-icon :size="18"><Search /></el-icon>
                  <span>我是求职者</span>
                </button>
                <button
                  :class="['role-btn', { active: role === 'recruiter' }]"
                  @click="role = 'recruiter'"
                >
                  <el-icon :size="18"><Wallet /></el-icon>
                  <span>我是招聘者</span>
                </button>
              </div>
            </div>

            <div class="input-group">
              <el-input
                v-model="form.username"
                size="large"
                placeholder="请输入用户名称"
                maxlength="20"
                clearable
                :prefix-icon="User"
              />
              <span v-if="form.username && !isUsernameValid" class="input-error">用户名称需为2-20个字符</span>
            </div>

            <div class="input-group">
              <el-input
                v-model="form.email"
                size="large"
                placeholder="请输入邮箱"
                clearable
                :prefix-icon="Message"
              />
              <span v-if="form.email && !isEmailValid" class="input-error">请输入正确的邮箱格式</span>
            </div>

            <div class="input-group">
              <el-input
                v-model="form.password"
                type="password"
                size="large"
                placeholder="请设置密码（6-20位）"
                show-password
                :prefix-icon="Lock"
              />
              <span v-if="form.password && !isPasswordValid" class="input-error">密码长度需为6-20位</span>
            </div>

            <div class="input-group">
              <el-input
                v-model="form.confirmPassword"
                type="password"
                size="large"
                placeholder="请确认密码"
                show-password
                :prefix-icon="Lock"
              />
              <span v-if="form.confirmPassword && !isConfirmPasswordValid" class="input-error">两次密码输入不一致</span>
            </div>

            <div class="form-options">
              <label class="agree-label">
                <el-checkbox v-model="agreed" />
                <span>
                  已阅读并同意
                  <a href="#" onclick="return false">《用户协议》</a>和<a href="#" onclick="return false">《隐私政策》</a>
                </span>
              </label>
            </div>

            <button
              class="submit-btn"
              :disabled="!canRegister || loading"
              :class="{ loading }"
              @click="handleRegister"
            >
              {{ loading ? '注册中...' : '注册' }}
            </button>
          </div>
        </template>

        <div class="other-login">
          <div class="divider">
            <span>其他方式登录</span>
          </div>
          <div class="social-btns">
            <button class="social-btn" title="微信登录">
              <el-icon :size="22"><ChatDotRound /></el-icon>
            </button>
            <button class="social-btn" title="支付宝登录">
              <el-icon :size="22"><Wallet /></el-icon>
            </button>
            <button class="social-btn" title="邮箱登录">
              <el-icon :size="22"><Message /></el-icon>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #e8f4fd 0%, #d6ebfa 50%, #cce5ff 100%);
  padding: 24px;
  box-sizing: border-box;
}

@media (prefers-color-scheme: dark) {
  .login-container {
    background: linear-gradient(135deg, #0d1b2a 0%, #1b2838 50%, #0a1628 100%);
  }
}

.login-card {
  display: flex;
  width: 860px;
  max-width: 100%;
  min-height: 560px;
  background: var(--bg);
  border-radius: 16px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.12), 0 8px 20px rgba(0, 0, 0, 0.08);
  overflow: hidden;
}

.card-brand {
  flex: 1;
  background: linear-gradient(135deg, #007AFF 0%, #0056b3 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 48px;
  position: relative;
  overflow: hidden;
}

.card-brand::before {
  content: '';
  position: absolute;
  top: -50%;
  right: -50%;
  width: 100%;
  height: 100%;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 50%;
  transform: scale(2);
}

.card-brand::after {
  content: '';
  position: absolute;
  bottom: -30%;
  left: -30%;
  width: 80%;
  height: 80%;
  background: rgba(255, 255, 255, 0.03);
  border-radius: 50%;
}

.brand-content {
  position: relative;
  z-index: 1;
  text-align: center;
}

.brand-name {
  font-size: 42px;
  font-weight: 800;
  color: #fff;
  margin: 0 0 12px;
  letter-spacing: 2px;
}

.brand-desc {
  font-size: 16px;
  color: rgba(255, 255, 255, 0.8);
  margin: 0;
  letter-spacing: 1px;
}

.card-form {
  flex: 1;
  padding: 48px 40px;
  display: flex;
  flex-direction: column;
}

.form-tabs {
  display: flex;
  margin-bottom: 32px;
  border-bottom: 2px solid var(--border);
}

.tab-btn {
  flex: 1;
  padding: 12px 0;
  font-size: 18px;
  font-weight: 500;
  border: none;
  background: none;
  color: var(--text);
  cursor: pointer;
  position: relative;
  transition: color 0.3s;
}

.tab-btn.active {
  color: #007AFF;
  font-weight: 600;
}

.tab-btn.active::after {
  content: '';
  position: absolute;
  bottom: -2px;
  left: 0;
  right: 0;
  height: 2px;
  background: #007AFF;
}

.form-body {
  flex: 1;
}

.role-select-group {
  margin-bottom: 24px;
}

.role-select-label {
  display: block;
  font-size: 14px;
  color: var(--text);
  margin-bottom: 10px;
}

.role-toggle {
  display: flex;
  gap: 12px;
}

.role-btn {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 12px 16px;
  font-size: 14px;
  border: 2px solid var(--border);
  border-radius: 8px;
  background: var(--bg);
  color: var(--text);
  cursor: pointer;
  transition: all 0.2s;
}

.role-btn:hover {
  border-color: #007AFF;
}

.role-btn.active {
  border-color: #007AFF;
  background: rgba(0, 122, 255, 0.08);
  color: #007AFF;
  font-weight: 500;
}

.input-group {
  margin-bottom: 20px;
}

.input-error {
  display: block;
  font-size: 12px;
  color: #e74c3c;
  margin-top: 4px;
  padding-left: 4px;
}

.form-options {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 24px;
}

.agree-label {
  display: flex;
  align-items: center;
  font-size: 13px;
  color: var(--text);
  cursor: pointer;
}

.agree-label a {
  color: #007AFF;
  text-decoration: none;
}

.submit-btn {
  width: 100%;
  height: 46px;
  font-size: 16px;
  font-weight: 600;
  color: #fff;
  background: #007AFF;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: opacity 0.2s, transform 0.1s;
  letter-spacing: 2px;
}

.submit-btn:hover:not(:disabled) {
  opacity: 0.92;
}

.submit-btn:active:not(:disabled) {
  transform: scale(0.98);
}

.submit-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.submit-btn.loading {
  opacity: 0.7;
}

.other-login {
  margin-top: auto;
  padding-top: 24px;
}

.divider {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
}

.divider::before,
.divider::after {
  content: '';
  flex: 1;
  height: 1px;
  background: var(--border);
}

.divider span {
  font-size: 13px;
  color: #999;
  white-space: nowrap;
}

.social-btns {
  display: flex;
  justify-content: center;
  gap: 24px;
}

.social-btn {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  border: 1px solid var(--border);
  background: var(--bg);
  color: var(--text);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.social-btn:hover {
  border-color: #007AFF;
  color: #007AFF;
  background: rgba(0, 122, 255, 0.1);
}

@media (max-width: 768px) {
  .login-card {
    flex-direction: column;
    min-height: auto;
  }

  .card-brand {
    padding: 32px 24px;
  }

  .brand-name {
    font-size: 32px;
  }

  .card-form {
    padding: 32px 24px;
  }

  .role-toggle {
    flex-direction: column;
  }
}
</style>
