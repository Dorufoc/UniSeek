<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getRealNameAuthStatus, submitRealNameAuth, changePassword } from '@/api/auth'
import type { RealNameAuthStatus } from '@/api/auth'
import { updateProfile, getUserStats } from '@/api/user'
import { uploadImage } from '@/api/upload'
import {
  User, Phone, Postcard, Edit, Document, Star,
  OfficeBuilding, Briefcase, Files,
  Lock, InfoFilled, SwitchButton, ArrowRight, ChatDotSquare, VideoCamera, Setting, Checked
} from '@element-plus/icons-vue'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const isRecruiter = computed(() => userStore.userInfo?.role === 1)
const isSuperAdmin = computed(() => userStore.userInfo?.role === 99)
const userPhone = computed(() => {
  const phone = userStore.userInfo?.phone || ''
  return phone ? phone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2') : '未绑定'
})

// 统计数据（初始为 0，由 API 加载）
const seekerStats = ref({ applications: 0, interviews: 0, favorites: 0 })
const recruiterStats = ref({ receivedResumes: 0, hired: 0 })

// 实名认证相关状态
const authDialogVisible = ref(false)
const authSubmitting = ref(false)
const authStatus = ref<RealNameAuthStatus | null>(null)
const authForm = ref({ realName: '', idCard: '' })
const idCardPattern = /^\d{17}[\dXx]$/

// 账号安全相关状态
const securityDialogVisible = ref(false)
const passwordSubmitting = ref(false)
const passwordForm = ref({ oldPassword: '', newPassword: '', confirmPassword: '' })
const isPasswordValid = computed(() => {
  const { oldPassword, newPassword, confirmPassword } = passwordForm.value
  return oldPassword.length >= 6
    && newPassword.length >= 6
    && newPassword.length <= 20
    && newPassword === confirmPassword
})

// 头像上传
const avatarFileInput = ref<HTMLInputElement | null>(null)
const avatarUploading = ref(false)

const handleAvatarClick = () => {
  avatarFileInput.value?.click()
}

const onAvatarSelected = async (e: Event) => {
  const target = e.target as HTMLInputElement
  const file = target.files?.[0]
  if (!file) return
  if (!file.type.startsWith('image/')) { ElMessage.warning('请选择图片文件'); return }
  if (file.size > 5 * 1024 * 1024) { ElMessage.warning('图片不能超过 5MB'); return }
  avatarUploading.value = true
  try {
    const data = await uploadImage(file)
    await updateProfile({ avatarUrl: data.url })
    userStore.setUserInfo({ ...userStore.userInfo, avatarUrl: data.url })
    ElMessage.success('头像更新成功')
  } catch {} finally {
    avatarUploading.value = false
    target.value = ''
  }
}

// 资料编辑（手机号/邮箱/昵称）
const profileEditing = ref(false)
const profileForm = ref({ nickname: '', phone: '', email: '' })

const openProfileEdit = () => {
  profileForm.value = {
    nickname: userStore.userInfo?.nickname || '',
    phone: userStore.userInfo?.phone?.replace(/\*\*\*\*/g, '') || '',
    email: userStore.userInfo?.email || ''
  }
  profileEditing.value = true
}

const handleProfileSave = async () => {
  try {
    const data = await updateProfile({
      nickname: profileForm.value.nickname || undefined,
      phone: profileForm.value.phone || undefined,
      email: profileForm.value.email || undefined
    })
    userStore.setUserInfo(data)
    ElMessage.success('资料更新成功')
    profileEditing.value = false
  } catch {}
}

// 校验身份证号出生日期是否合法
const isValidBirthDate = (idCard: string): boolean => {
  const year = parseInt(idCard.substring(6, 10))
  const month = parseInt(idCard.substring(10, 12))
  const day = parseInt(idCard.substring(12, 14))
  // 年份在 1900 到当前年之间
  if (year < 1900 || year > new Date().getFullYear()) return false
  // 月份 1~12
  if (month < 1 || month > 12) return false
  // 日期校验：当月天数
  const daysInMonth = new Date(year, month, 0).getDate()
  if (day < 1 || day > daysInMonth) return false
  return true
}

// 校验身份证号校验码（GB 11643-1999）
const isValidChecksum = (idCard: string): boolean => {
  const weights = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2]
  const checkCodes = ['1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2']
  let sum = 0
  for (let i = 0; i < 17; i++) {
    sum += parseInt(idCard[i]) * weights[i]
  }
  const expected = checkCodes[sum % 11]
  return idCard[17].toUpperCase() === expected
}

const isIdCardValid = computed(() => {
  const id = authForm.value.idCard.trim()
  if (!idCardPattern.test(id)) return false
  if (!isValidBirthDate(id)) return false
  if (!isValidChecksum(id)) return false
  return true
})
const isRealNameValid = computed(() => authForm.value.realName.trim().length >= 2)
const canSubmit = computed(() => isRealNameValid.value && isIdCardValid.value)

// 查询实名认证状态
const checkAuthStatus = async () => {
  try {
    authStatus.value = await getRealNameAuthStatus()
  } catch {
    authStatus.value = null
  }
}

// 打开实名认证弹窗
const openAuthDialog = () => {
  if (authStatus.value?.isAuth) {
    ElMessage.success('您已完成实名认证')
    return
  }
  authForm.value = { realName: '', idCard: '' }
  authDialogVisible.value = true
}

// 提交实名认证
const handleAuthSubmit = async () => {
  if (!canSubmit.value) return
  authSubmitting.value = true
  try {
    await submitRealNameAuth({
      realName: authForm.value.realName.trim(),
      idCard: authForm.value.idCard.trim()
    })
    ElMessage.success('实名认证提交成功')
    authDialogVisible.value = false
    await checkAuthStatus()
  } catch {
    // 错误已在拦截器中处理
  } finally {
    authSubmitting.value = false
  }
}

onMounted(async () => {
  checkAuthStatus().then(() => {
    if (route.query.tab === 'realNameAuth') {
      openAuthDialog()
    }
  })
  try {
    const stats = await getUserStats()
    if (isRecruiter.value) {
      recruiterStats.value.receivedResumes = stats.receivedResumes ?? 0
      recruiterStats.value.hired = stats.hired ?? 0
    } else {
      seekerStats.value.applications = stats.applications ?? 0
      seekerStats.value.interviews = stats.interviews ?? 0
      seekerStats.value.favorites = stats.favorites ?? 0
    }
  } catch { /* 忽略 */ }
})

// 修改密码
const handlePasswordChange = async () => {
  if (!isPasswordValid.value || passwordSubmitting.value) return
  passwordSubmitting.value = true
  try {
    await changePassword(passwordForm.value)
    ElMessage.success('密码修改成功，请重新登录')
    securityDialogVisible.value = false
    userStore.logout()
    router.push('/login')
  } catch {
  } finally {
    passwordSubmitting.value = false
  }
}

// 菜单项点击处理
const handleMenuClick = (item: string) => {
  switch (item) {
    case 'resume':
      router.push('/resume')
      break
    case 'applications':
      router.push('/my-applications')
      break
    case 'interviews':
      if (isRecruiter.value) {
        router.push('/resume-pool?tab=interview')
      } else {
        router.push('/my-applications?tab=interviews')
      }
      break
    case 'favorites':
      router.push('/my-applications?tab=favorites')
      break
    case 'enterprise':
      router.push('/enterprise-cert')
      break
    case 'editEnterprise':
      router.push('/enterprise-cert?edit=1')
      break
    case 'postedJobs':
      router.push('/post-job')
      break
    case 'resumePool':
      router.push('/resume-pool')
      break
    case 'security':
      router.push('/account-security')
      break
    case 'superAdmin':
      router.push('/admin/super')
      break
    case 'realNameAuth':
      openAuthDialog()
      break
    case 'about':
      ElMessage.info('UniSeek v1.0 - 智能兼职招聘平台')
      break
    case 'logout':
      ElMessageBox.confirm('确定要退出登录吗？', '提示', {
        type: 'warning',
        confirmButtonText: '退出',
        cancelButtonText: '取消'
      }).then(() => {
        userStore.logout()
        router.push('/login')
      }).catch(() => {})
      break
  }
}
</script>

<template>
  <div class="profile-page">
    <div class="profile-container">
      <!-- 左侧：用户信息卡片 -->
      <div class="profile-sidebar">
        <!-- 用户基本信息 -->
        <div class="user-card">
          <div class="user-avatar" @click="handleAvatarClick" title="点击更换头像">
            <template v-if="userStore.userInfo?.avatarUrl">
              <img :src="userStore.userInfo.avatarUrl" class="avatar-img" />
            </template>
            <template v-else>
              <el-icon :size="48"><User /></el-icon>
            </template>
            <div class="avatar-overlay">{{ avatarUploading ? '上传中' : '换头像' }}</div>
          </div>
          <input ref="avatarFileInput" type="file" accept="image/*" style="display:none" @change="onAvatarSelected" />
          <div class="user-name">{{ userStore.userInfo?.nickname || '未设置昵称' }}</div>
          <div class="user-role-tag">
          <span :class="['role-badge', isSuperAdmin ? 'super-admin' : isRecruiter ? 'recruiter' : 'seeker']">
            {{ isSuperAdmin ? '超级管理员' : isRecruiter ? '企业HR' : '求职者' }}
          </span>
          </div>
          <div class="user-phone">
            <el-icon :size="14"><Phone /></el-icon>
            {{ userPhone }}
          </div>
          <div class="user-phone-hint">
            如需更换手机号，请
            <span class="link-btn" @click="router.push('/account-security')">前往账号安全</span>
          </div>
          <button class="edit-profile-btn" @click="isRecruiter ? handleMenuClick('editEnterprise') : handleMenuClick('resume')">
            <el-icon :size="14"><Edit /></el-icon>
            {{ isRecruiter ? '编辑企业信息' : '编辑简历' }}
          </button>
        </div>

        <!-- 数据统计 -->
        <div class="stats-card">
          <template v-if="isRecruiter">
            <div class="stat-item">
              <span class="stat-num">{{ recruiterStats.receivedResumes }}</span>
              <span class="stat-label">收到简历</span>
            </div>
            <div class="stat-item">
              <span class="stat-num">{{ recruiterStats.hired }}</span>
              <span class="stat-label">已录取</span>
            </div>
          </template>
          <template v-else>
            <div class="stat-item">
              <span class="stat-num">{{ seekerStats.applications }}</span>
              <span class="stat-label">投递数</span>
            </div>
            <div class="stat-item">
              <span class="stat-num">{{ seekerStats.interviews }}</span>
              <span class="stat-label">面试邀请</span>
            </div>
            <div class="stat-item">
              <span class="stat-num">{{ seekerStats.favorites }}</span>
              <span class="stat-label">收藏职位</span>
            </div>
          </template>
        </div>
      </div>

      <!-- 右侧：功能菜单 -->
      <div class="profile-main">
        <!-- 超级管理员功能 -->
        <template v-if="isSuperAdmin">
          <div class="menu-section">
            <h3 class="section-title">系统管理</h3>
            <div class="menu-grid">
              <div class="menu-item" @click="handleMenuClick('superAdmin')">
                <div class="menu-icon admin-bg">
                  <el-icon :size="22"><Setting /></el-icon>
                </div>
                <div class="menu-info">
                  <span class="menu-name">管理面板</span>
                  <span class="menu-desc">用户管理、企业认证、职位审核</span>
                </div>
                <el-icon :size="16" class="menu-arrow"><ArrowRight /></el-icon>
              </div>
            </div>
          </div>
        </template>

        <!-- 招聘者功能 -->
        <template v-else-if="isRecruiter">
          <div class="menu-section">
            <h3 class="section-title">招聘管理</h3>
            <div class="menu-grid">
              <div class="menu-item" @click="handleMenuClick('enterprise')">
                <div class="menu-icon recruiter-bg">
                  <el-icon :size="22"><OfficeBuilding /></el-icon>
                </div>
                <div class="menu-info">
                  <span class="menu-name">企业信息</span>
                  <span class="menu-desc">管理企业资料与资质认证</span>
                </div>
                <el-icon :size="16" class="menu-arrow"><ArrowRight /></el-icon>
              </div>
              <div class="menu-item" @click="handleMenuClick('postedJobs')">
                <div class="menu-icon recruiter-bg">
                  <el-icon :size="22"><Briefcase /></el-icon>
                </div>
                <div class="menu-info">
                  <span class="menu-name">发布职位</span>
                  <span class="menu-desc">发布新职位或管理已发布</span>
                </div>
                <el-icon :size="16" class="menu-arrow"><ArrowRight /></el-icon>
              </div>
              <div class="menu-item" @click="handleMenuClick('resumePool')">
                <div class="menu-icon recruiter-bg">
                  <el-icon :size="22"><Files /></el-icon>
                </div>
                <div class="menu-info">
                  <span class="menu-name">简历池</span>
                  <span class="menu-desc">查看处理收到的简历投递</span>
                </div>
                <el-icon :size="16" class="menu-arrow"><ArrowRight /></el-icon>
              </div>
              <div class="menu-item" @click="handleMenuClick('interviews')">
                <div class="menu-icon recruiter-bg">
                  <el-icon :size="22"><VideoCamera /></el-icon>
                </div>
                <div class="menu-info">
                  <span class="menu-name">面试安排</span>
                  <span class="menu-desc">管理候选人面试时间地点</span>
                </div>
                <el-icon :size="16" class="menu-arrow"><ArrowRight /></el-icon>
              </div>
            </div>
          </div>
        </template>

        <!-- 求职者功能 -->
        <template v-else>
          <div class="menu-section">
            <h3 class="section-title">求职管理</h3>
            <div class="menu-grid">
              <div class="menu-item" @click="handleMenuClick('resume')">
                <div class="menu-icon seeker-bg">
                  <el-icon :size="22"><Postcard /></el-icon>
                </div>
                <div class="menu-info">
                  <span class="menu-name">我的简历</span>
                  <span class="menu-desc">编辑个人简历与附件上传</span>
                </div>
                <el-icon :size="16" class="menu-arrow"><ArrowRight /></el-icon>
              </div>
              <div class="menu-item" @click="handleMenuClick('applications')">
                <div class="menu-icon seeker-bg">
                  <el-icon :size="22"><Document /></el-icon>
                </div>
                <div class="menu-info">
                  <span class="menu-name">投递记录</span>
                  <span class="menu-desc">查看所有职位投递及状态</span>
                </div>
                <el-icon :size="16" class="menu-arrow"><ArrowRight /></el-icon>
              </div>
              <div class="menu-item" @click="handleMenuClick('interviews')">
                <div class="menu-icon seeker-bg">
                  <el-icon :size="22"><ChatDotSquare /></el-icon>
                </div>
                <div class="menu-info">
                  <span class="menu-name">面试邀请</span>
                  <span class="menu-desc">收到的面试通知与安排</span>
                </div>
                <el-icon :size="16" class="menu-arrow"><ArrowRight /></el-icon>
              </div>
              <div class="menu-item" @click="handleMenuClick('favorites')">
                <div class="menu-icon seeker-bg">
                  <el-icon :size="22"><Star /></el-icon>
                </div>
                <div class="menu-info">
                  <span class="menu-name">收藏职位</span>
                  <span class="menu-desc">收藏关注的心仪职位</span>
                </div>
                <el-icon :size="16" class="menu-arrow"><ArrowRight /></el-icon>
              </div>
            </div>
          </div>
        </template>

        <!-- 账户设置 -->
        <div class="menu-section">
          <h3 class="section-title">账户设置</h3>
          <div class="menu-list">
            <div class="menu-item-row" @click="handleMenuClick('security')">
              <div class="menu-icon small neutral-bg">
                <el-icon :size="18"><Lock /></el-icon>
              </div>
              <span class="menu-name">账号安全</span>
              <span class="menu-hint">修改密码、绑定手机</span>
              <el-icon :size="16" class="menu-arrow"><ArrowRight /></el-icon>
            </div>
            <div class="menu-item-row" @click="handleMenuClick('realNameAuth')">
              <div class="menu-icon small neutral-bg">
                <el-icon :size="18"><Checked /></el-icon>
              </div>
              <span class="menu-name">实名认证</span>
              <span class="menu-hint">{{ authStatus?.isAuth ? '已认证' : '未认证' }}</span>
              <el-icon :size="16" class="menu-arrow"><ArrowRight /></el-icon>
            </div>
            <div class="menu-item-row" @click="handleMenuClick('about')">
              <div class="menu-icon small neutral-bg">
                <el-icon :size="18"><InfoFilled /></el-icon>
              </div>
              <span class="menu-name">关于 UniSeek</span>
              <span class="menu-hint">版本 V1.0</span>
              <el-icon :size="16" class="menu-arrow"><ArrowRight /></el-icon>
            </div>
            <div class="menu-item-row logout" @click="handleMenuClick('logout')">
              <div class="menu-icon small logout-bg">
                <el-icon :size="18"><SwitchButton /></el-icon>
              </div>
              <span class="menu-name">退出登录</span>
              <span class="menu-hint"></span>
              <el-icon :size="16" class="menu-arrow"><ArrowRight /></el-icon>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 账号安全弹窗 -->
    <el-dialog v-model="securityDialogVisible" title="账号安全" width="440px" :close-on-click-modal="false" destroy-on-close>
      <div class="auth-dialog-body">
        <p class="section-label">联系方式</p>
        <div class="info-section">
          <div class="info-line"><span class="info-label">昵称</span>
            <el-input v-model="profileForm.nickname" size="small" placeholder="修改昵称" maxlength="20" v-if="profileEditing" />
            <span v-else>{{ userStore.userInfo?.nickname || '未设置' }}</span>
          </div>
          <div class="info-line"><span class="info-label">手机号</span>
            <el-input v-model="profileForm.phone" size="small" placeholder="新手机号" maxlength="11" v-if="profileEditing" />
            <span v-else>{{ userStore.userInfo?.phone || '未绑定' }}</span>
          </div>
          <div class="info-line"><span class="info-label">邮箱</span>
            <el-input v-model="profileForm.email" size="small" placeholder="新邮箱" v-if="profileEditing" />
            <span v-else>{{ userStore.userInfo?.email || '未绑定' }}</span>
          </div>
        </div>
        <div style="margin-top:12px">
          <el-button v-if="!profileEditing" size="small" @click="openProfileEdit">修改资料</el-button>
          <template v-else>
            <el-button size="small" type="primary" @click="handleProfileSave">保存</el-button>
            <el-button size="small" @click="profileEditing = false">取消</el-button>
          </template>
        </div>
        <el-divider />
        <p class="section-label">修改密码</p>
        <el-input v-model="passwordForm.oldPassword" type="password" show-password size="large" placeholder="原密码" />
        <el-input v-model="passwordForm.newPassword" type="password" show-password size="large" placeholder="新密码（6-20位）" style="margin-top:12px" />
        <el-input v-model="passwordForm.confirmPassword" type="password" show-password size="large" placeholder="确认新密码" style="margin-top:12px" />
      </div>
      <template #footer>
        <el-button @click="securityDialogVisible = false">关闭</el-button>
        <el-button type="primary" :disabled="!isPasswordValid" :loading="passwordSubmitting" @click="handlePasswordChange">确认修改密码</el-button>
      </template>
    </el-dialog>

    <!-- 实名认证弹窗 -->
    <el-dialog v-model="authDialogVisible" title="实名认证" width="440px" :close-on-click-modal="false" destroy-on-close>
      <div class="auth-dialog-body">
        <p class="auth-dialog-desc">根据国家相关法律法规，使用平台服务需完成实名认证。</p>
        <el-input v-model="authForm.realName" placeholder="请输入真实姓名" size="large" clearable maxlength="20" />
        <span v-if="authForm.realName && !isRealNameValid" class="input-error">姓名至少2个字符</span>
        <el-input
          v-model="authForm.idCard"
          placeholder="请输入18位身份证号"
          size="large"
          clearable
          maxlength="18"
          style="margin-top: 16px;"
        />
        <span v-if="authForm.idCard && !isIdCardValid" class="input-error">请输入正确的18位身份证号</span>
      </div>
      <template #footer>
        <el-button @click="authDialogVisible = false">取消</el-button>
        <el-button type="primary" :disabled="!canSubmit" :loading="authSubmitting" @click="handleAuthSubmit">
          提交认证
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.profile-page {
  min-height: calc(100vh - 60px);
  background: #f5f7fa;
  padding: 24px;
  box-sizing: border-box;
}

.profile-container {
  max-width: 1100px;
  margin: 0 auto;
  display: flex;
  gap: 24px;
  align-items: flex-start;
}

/* 左侧边栏 */
.profile-sidebar {
  width: 280px;
  min-width: 280px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.user-card {
  background: #fff;
  border-radius: 12px;
  padding: 32px 24px;
  text-align: center;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
}

.user-avatar {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: linear-gradient(135deg, #e8f4fd, #cce5ff);
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 16px;
  color: #1762FB;
  position: relative;
  overflow: hidden;
  cursor: pointer;
}
.user-avatar .avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.avatar-overlay {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(0,0,0,0.4);
  color: #fff;
  font-size: 13px;
  opacity: 0;
  transition: opacity 0.2s;
}
.user-avatar:hover .avatar-overlay { opacity: 1; }

.user-name {
  font-size: 18px;
  font-weight: 600;
  color: #000;
  margin-bottom: 8px;
}

.user-role-tag {
  margin-bottom: 12px;
}

.role-badge {
  display: inline-block;
  padding: 3px 14px;
  font-size: 12px;
  border-radius: 12px;
}

.role-badge.seeker {
  color: #1762FB;
  background: rgba(0, 122, 255, 0.1);
}

.role-badge.recruiter {
  color: #2e7d32;
  background: rgba(46, 125, 50, 0.1);
}

.role-badge.super-admin {
  color: #ff8f00;
  background: rgba(255, 143, 0, 0.1);
}

.user-phone {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  font-size: 14px;
  color: #000;
  margin-bottom: 4px;
}

.user-phone-hint {
  font-size: 12px;
  color: #999;
  text-align: center;
  margin-bottom: 16px;
}

.link-btn {
  color: #007AFF;
  cursor: pointer;
  text-decoration: underline;
}

.link-btn:hover {
  color: #0056b3;
}

.edit-profile-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 24px;
  font-size: 14px;
  color: #1762FB;
  background: rgba(0, 122, 255, 0.06);
  border: 1px solid rgba(0, 122, 255, 0.2);
  border-radius: 20px;
  cursor: pointer;
  transition: all 0.2s;
}

.edit-profile-btn:hover {
  background: rgba(0, 122, 255, 0.12);
}

/* 统计卡片 */
.stats-card {
  background: #fff;
  border-radius: 12px;
  padding: 20px;
  display: flex;
  justify-content: space-around;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
}

.stat-item {
  text-align: center;
}

.stat-num {
  display: block;
  font-size: 24px;
  font-weight: 700;
  color: #1762FB;
  line-height: 1.3;
}

.stat-label {
  font-size: 13px;
  color: #000;
}

/* 右侧主体 */
.profile-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.menu-section {
  background: #fff;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  color: #000;
  margin: 0 0 16px;
  padding-left: 4px;
  border-left: 3px solid #1762FB;
  padding: 0 0 0 10px;
  line-height: 1.2;
}

/* 网格菜单 */
.menu-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}

.menu-item {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 16px;
  border-radius: 10px;
  border: 1px solid var(--border);
  cursor: pointer;
  transition: all 0.2s;
}

.menu-item:hover {
  border-color: #1762FB;
  background: rgba(0, 122, 255, 0.03);
  box-shadow: 0 2px 8px rgba(0, 122, 255, 0.08);
}

.menu-icon {
  width: 44px;
  height: 44px;
  min-width: 44px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.menu-icon.seeker-bg {
  background: rgba(0, 122, 255, 0.08);
  color: #1762FB;
}

.menu-icon.recruiter-bg {
  background: rgba(46, 125, 50, 0.08);
  color: #2e7d32;
}

.menu-icon.admin-bg {
  background: rgba(255, 143, 0, 0.08);
  color: #ff8f00;
}

.menu-info {
  flex: 1;
  min-width: 0;
}

.menu-info .menu-name {
  display: block;
  font-size: 15px;
  font-weight: 500;
  color: #000;
  margin-bottom: 2px;
}

.menu-info .menu-desc {
  font-size: 12px;
  color: #000;
}

.menu-arrow {
  color: #000;
  flex-shrink: 0;
}

/* 列表菜单 */
.menu-list {
  display: flex;
  flex-direction: column;
}

.menu-item-row {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px 16px;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.menu-item-row:hover {
  background: #f8f9fb;
}

.menu-icon.small {
  width: 36px;
  height: 36px;
  min-width: 36px;
  border-radius: 8px;
}

.menu-icon.neutral-bg {
  background: #f0f0f5;
  color: #666;
}

.menu-icon.logout-bg {
  background: rgba(231, 76, 60, 0.08);
  color: #e74c3c;
}

.menu-item-row .menu-name {
  font-size: 15px;
  color: #000;
  white-space: nowrap;
}

.menu-item-row.logout .menu-name {
  color: #e74c3c;
}

.menu-hint {
  flex: 1;
  text-align: right;
  font-size: 13px;
  color: #000;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* 实名认证弹窗 */
.auth-dialog-body {
  padding: 4px 0;
}

.auth-dialog-desc {
  font-size: 14px;
  color: #000;
  margin: 0 0 20px;
  line-height: 1.6;
}

.auth-dialog-body .input-error {
  display: block;
  font-size: 12px;
  color: #e74c3c;
  margin-top: 4px;
  padding-left: 4px;
}

/* 账号安全 */
.info-section {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-bottom: 4px;
}
.info-line {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 14px;
  color: #000;
}
.info-line .info-label {
  width: 80px;
  color: #000;
  flex-shrink: 0;
}
.section-label {
  font-size: 14px;
  font-weight: 500;
  color: #000;
  margin: 0 0 12px;
}

@media (max-width: 768px) {
  .profile-container {
    flex-direction: column;
  }

  .profile-sidebar {
    width: 100%;
    min-width: unset;
  }

  .menu-grid {
    grid-template-columns: 1fr;
  }

  .profile-page {
    padding: 16px;
  }
}
</style>
