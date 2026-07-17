<script setup lang="ts">
import { ref, reactive, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { ElMessage } from 'element-plus'
import { loginByPassword, register } from '@/api/auth'
import { Phone, Message, Lock, User, ChatDotRound, Wallet, Search } from '@element-plus/icons-vue'

const router = useRouter()
const userStore = useUserStore()

// 当前激活的选项卡：登录或注册
const activeTab = ref<'login' | 'register'>('login')
// 提交加载状态
const loading = ref(false)
// 用户协议和隐私政策勾选状态
const agreed = ref(false)

// 注册时的角色选择：null 未选择，0 求职者，1 招聘者
const role = ref<0 | 1 | null>(null)

// 登录/注册表单数据
const form = reactive({
  phone: '',
  email: '',
  password: '',
  confirmPassword: '',
  nickname: ''
})

// 手机号正则校验：1 开头，第二位为 3-9，共 11 位数字
const phonePattern = /^1[3-9]\d{9}$/

// 手机号格式校验
const isPhoneValid = computed(() => phonePattern.test(form.phone))
// 邮箱格式校验
const isEmailValid = computed(() => /^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/.test(form.email))
// 密码长度校验：6-20 位
const isPasswordValid = computed(() => form.password.length >= 6 && form.password.length <= 20)
// 两次密码一致性校验
const isConfirmPasswordValid = computed(() => form.password === form.confirmPassword)
// 昵称长度校验：2-20 个字符
const isNicknameValid = computed(() => form.nickname.trim().length >= 2 && form.nickname.trim().length <= 20)
// 角色是否已选择
const isRoleValid = computed(() => role.value !== null)

// 登录按钮是否可用：手机号 + 密码 + 同意协议均满足
const canLogin = computed(() => {
  return isPhoneValid.value && isPasswordValid.value && agreed.value
})

// 注册按钮是否可用：角色 + 手机号 + 邮箱 + 昵称 + 密码 + 确认密码均满足
const canRegister = computed(() => {
  return isRoleValid.value && isPhoneValid.value && isEmailValid.value && isNicknameValid.value && isPasswordValid.value && isConfirmPasswordValid.value
})

// 处理登录：调用登录接口，保存 token 和用户信息，根据角色跳转不同页面
const handleLogin = async () => {
  if (!canLogin.value) return
  loading.value = true
  try {
    const res = await loginByPassword({ phone: form.phone, password: form.password })
    userStore.setToken(res.token)
    // 登录时优先使用本地已存储的角色（注册时设定），防止 Mock 默认值覆盖
    const storedUser = JSON.parse(localStorage.getItem('uniseek_user') || 'null')
    const userInfo = { ...res.userInfo, role: storedUser?.role ?? res.userInfo.role }
    userStore.setUserInfo(userInfo)
    ElMessage.success('登录成功')
    // 管理员 -> 管理后台，其他人使用 redirect 参数或回首页
    const target = userInfo.role >= 9 ? '/admin/dashboard'
      : (router.currentRoute.value.query.redirect as string) || '/'
    router.replace(target)
  } catch {
    // 错误已在拦截器中处理
  } finally {
    loading.value = false
  }
}

// 处理注册：调用注册接口，保存 token 和用户信息，根据角色跳转不同页面
const handleRegister = async () => {
  if (!canRegister.value) return
  loading.value = true
  try {
    const res = await register({
      phone: form.phone,
      email: form.email.trim(),
      password: form.password,
      confirmPassword: form.confirmPassword,
      nickname: form.nickname.trim(),
      role: role.value as number
    })
    userStore.setToken(res.token)
    // 用界面选择的角色覆盖后端返回的角色，确保注册后跳转正确
    const userInfo = { ...res.userInfo, role: role.value as number }
    userStore.setUserInfo(userInfo)
    ElMessage.success('注册成功')
    // 注册后跳转：优先使用 redirect 参数，否则招聘者去企业认证、求职者回首页
    const redirect = (router.currentRoute.value.query.redirect as string)
    const target = redirect || (role.value === 1 ? '/enterprise-cert' : '/')
    router.replace(target)
  } catch {
    // 错误已在拦截器中处理
  } finally {
    loading.value = false
  }
}

// 切换登录/注册选项卡，重置表单和角色选择状态
const switchTab = (tab: 'login' | 'register') => {
  activeTab.value = tab
  form.email = ''
  form.password = ''
  form.confirmPassword = ''
  form.nickname = ''
  role.value = null
}

</script>

<template>
  <div class="login-container">
    <div class="login-card">
      <!-- 左侧品牌展示区 -->
      <div class="card-brand">
        <img src="@/assets/uniseek_pic.png" alt="UniSeek" class="brand-image" />
      </div>

      <!-- 右侧表单区域 -->
      <div class="card-form">
        <!-- 登录/注册选项卡切换 -->
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

        <!-- 登录表单区域 -->
        <template v-if="activeTab === 'login'">
          <div class="form-body">
            <!-- 手机号输入 -->
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

            <!-- 密码输入 -->
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

            <!-- 用户协议和隐私政策勾选 -->
            <div class="form-options">
              <label class="agree-label">
                <el-checkbox v-model="agreed" size="small" />
                <span>我已阅读并同意</span>
                <router-link to="/user-agreement" target="_blank">用户协议</router-link>
                <span>和</span>
                <router-link to="/privacy-policy" target="_blank">隐私政策</router-link>
              </label>
            </div>

            <!-- 登录按钮 -->
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

        <!-- 注册表单区域 -->
        <template v-else>
          <div class="form-body">
            <!-- 角色选择：求职者或招聘者 -->
            <div class="role-select-group">
              <span class="role-select-label">选择身份</span>
              <div class="role-toggle">
                <!-- 求职者选项 -->
                <button
                  :class="['role-btn', { active: role === 0 }]"
                  @click="role = 0"
                >
                  <el-icon :size="18"><Search /></el-icon>
                  <span>我是求职者</span>
                </button>
                <!-- 招聘者选项 -->
                <button
                  :class="['role-btn', { active: role === 1 }]"
                  @click="role = 1"
                >
                  <el-icon :size="18"><Wallet /></el-icon>
                  <span>我是招聘者</span>
                </button>
              </div>
            </div>

            <!-- 手机号输入 -->
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

            <!-- 邮箱输入 -->
            <div class="input-group">
              <el-input
                v-model="form.email"
                size="large"
                placeholder="请输入邮箱"
                clearable
                :prefix-icon="Message"
              />
              <span v-if="form.email && !isEmailValid" class="input-error">请输入正确的邮箱地址</span>
            </div>

            <!-- 昵称输入 -->
            <div class="input-group">
              <el-input
                v-model="form.nickname"
                size="large"
                placeholder="请输入昵称（2-20位）"
                maxlength="20"
                clearable
                :prefix-icon="User"
              />
              <span v-if="form.nickname && !isNicknameValid" class="input-error">昵称需为2-20个字符</span>
            </div>

            <!-- 密码输入 -->
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

            <!-- 确认密码输入 -->
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

            <!-- 注册按钮 -->
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

        <!-- 第三方登录入口（预留） -->
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
  position: relative;
  z-index: 1;
}

.card-brand {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.brand-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
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
  color: #1762FB;
  font-weight: 600;
}

.tab-btn.active::after {
  content: '';
  position: absolute;
  bottom: -2px;
  left: 0;
  right: 0;
  height: 2px;
  background: #1762FB;
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
  border-color: #1762FB;
}

.role-btn.active {
  border-color: #1762FB;
  background: rgba(0, 122, 255, 0.08);
  color: #1762FB;
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
  color: #1762FB;
  text-decoration: none;
}

.submit-btn {
  width: 100%;
  height: 46px;
  font-size: 16px;
  font-weight: 600;
  color: #fff;
  background: #1762FB;
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
  border-color: #1762FB;
  color: #1762FB;
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
