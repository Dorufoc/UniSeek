<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { useChatStore } from '@/stores/chat'
import { useAppStore } from '@/stores/app'
import { getMyEnterprise } from '@/api/enterprise'
import { getRealNameAuthStatus } from '@/api/auth'
import { useChatWebSocket, type WsNewMessageData } from '@/composables/useChatWebSocket'
import { WarningFilled } from '@element-plus/icons-vue'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()
const chatStore = useChatStore()
const appStore = useAppStore()

// 判断当前用户是否为招聘者（role === 1 表示招聘者，0 表示求职者）
const isRecruiter = computed(() => userStore.userInfo?.role === 1)

// 判断当前用户是否为管理员（role === 9 或 99）
const isAdmin = computed(() => userStore.userInfo?.role >= 9)

// 企业资质认证强制弹窗 — 招聘者（HR）未完成认证时，所有页面强制提示
const certDialogVisible = ref(false)
const certStatusText = ref('')
const certChecking = ref(false)
const needRealName = ref(false)

/**
 * 检查当前招聘者的企业资质认证状态。
 * 若未完成认证（未提交 / 审核中 / 已驳回）→ 弹窗拦截；已认证 → 放行。
 * 每次路由变化时重新检查（已登录状态下 /enterprise-cert 页面放行）。
 */
const checkEnterpriseCert = async () => {
  // 仅招聘者（role=1）需要企业认证；管理员和求职者跳过
  if (!isRecruiter.value) {
    certDialogVisible.value = false
    return
  }
  // 用户点击过"稍后再说"→ 不再弹窗
  if (localStorage.getItem('uniseek_cert_dialog_dismissed')) {
    certDialogVisible.value = false
    return
  }
  // 已在认证页面时不弹窗
  if (route.path === '/enterprise-cert' || route.path === '/account-security') {
    certDialogVisible.value = false
    return
  }

  certChecking.value = true
  try {
    // Step 1: 检查实名认证
    const realNameStatus = await getRealNameAuthStatus()
    if (!realNameStatus?.isAuth) {
      needRealName.value = true
      certStatusText.value = '您尚未完成实名认证，请先完成实名认证后再进行企业资质认证。'
      certDialogVisible.value = true
      return
    }

    // Step 2: 实名已通过，检查企业资质认证
    needRealName.value = false
    const info = await getMyEnterprise()
    if (info && info.auditStatus === 1) {
      certDialogVisible.value = false
      return
    }
    if (!info) {
      certStatusText.value = '您尚未提交企业资质认证，完成认证后方可使用招聘功能。'
    } else if (info.auditStatus === 0) {
      certStatusText.value = '您的企业资质认证正在审核中，请耐心等待。审核通过后方可使用招聘功能。'
    } else if (info.auditStatus === 2) {
      certStatusText.value = '您的企业资质认证已被驳回，请修改后重新提交。'
      if (info.rejectReason) {
        certStatusText.value += '\n驳回原因：' + info.rejectReason
      }
    }
    certDialogVisible.value = true
  } catch {
    needRealName.value = false
    certStatusText.value = '您尚未提交企业资质认证，完成认证后方可使用招聘功能。'
    certDialogVisible.value = true
  } finally {
    certChecking.value = false
  }
}

/** 稍后再说：设置 localStorage 标记并关闭弹窗 */
const dismissCertDialog = () => {
  localStorage.setItem('uniseek_cert_dialog_dismissed', 'true')
  certDialogVisible.value = false
}

/** 跳转到认证页面（实名 or 企业资质） */
const goToEnterpriseCert = () => {
  if (needRealName.value) {
    router.push('/account-security')
  } else {
    router.push('/enterprise-cert')
  }
}

// 布局挂载时首次检查
onMounted(() => {
  checkEnterpriseCert()
  chatStore.setCurrentUserId(userStore.userInfo?.id ?? null)
  setTimeout(() => chatStore.fetchUnreadCount(), 300)
})

// 监听当前用户 ID 变更，保持 Store 同步并刷新未读数
watch(() => userStore.userInfo?.id, (id) => {
  chatStore.setCurrentUserId(id ?? null)
  if (id) chatStore.fetchUnreadCount()
})

// ---- 全局 WebSocket 消息监听（始终在线） ----
const handleWsNewMessage = (data: WsNewMessageData) => {
  chatStore.handleWsMessage(data)
}

const { connected: wsConnected } = useChatWebSocket({
  onNewMessage: handleWsNewMessage,
  enabled: computed(() => !!userStore.userInfo?.id)
})

// WebSocket 连接成功后刷新未读数
watch(wsConnected, (val) => {
  if (val) chatStore.fetchUnreadCount()
})
// 路由变化时重新检查—确保每次页面切换都认证
watch(() => route.path, checkEnterpriseCert)
</script>

<template>
  <div class="default-layout">
    <!-- 顶部导航栏 -->
    <header class="layout-header">
      <div class="header-inner">
        <!-- 左侧区域：Logo -->
        <div class="header-left">
          <router-link to="/" class="logo">
            <img src="@/assets/uniseek_text_white_ZH.svg" alt="UniSeek" class="logo-img" />
          </router-link>
        </div>

        <!-- 中部区域：主导航菜单 -->
        <nav class="header-nav">
          <router-link to="/">首页</router-link>
          <!-- 招聘者视角：人才库 + 职位管理 -->
          <template v-if="isRecruiter">
            <router-link to="/talents">人才</router-link>
            <router-link to="/job-management">职位管理</router-link>
          </template>
          <template v-else-if="!isAdmin">
            <router-link to="/jobs">职位</router-link>
            <router-link to="/company">公司</router-link>
          </template>
          <router-link to="/messages" class="nav-msg-link">消息
            <span v-if="chatStore.totalUnreadCount > 0" class="msg-badge">{{ chatStore.totalUnreadCount > 99 ? '99+' : chatStore.totalUnreadCount }}</span>
          </router-link>
          <router-link v-if="isAdmin" to="/admin/dashboard" class="super-admin-link">管理后台</router-link>
        </nav>

        <!-- 右侧区域：用户操作（登录状态根据角色显示不同入口） -->
        <div class="header-actions">
          <!-- 已登录状态 -->
          <template v-if="userStore.isLoggedIn">
            <router-link v-if="!isRecruiter && !isAdmin" to="/resume" class="nav-user-link">简历</router-link>
            <router-link to="/profile" class="nav-user-link">个人中心</router-link>
            <span class="user-name">{{ userStore.userInfo?.nickname || '用户' }}</span>
            <button class="btn-logout" @click="userStore.logout(); router.push('/')">退出</button>
          </template>
          <!-- 未登录状态 -->
          <template v-else>
            <router-link to="/login" class="btn-login">登录 / 注册</router-link>
          </template>
        </div>
      </div>
    </header>

    <!-- 主内容区域，通过路由视图渲染对应页面 -->
    <main class="layout-main">
      <router-view />
    </main>

    <!-- 企业资质认证弹窗 — 招聘者未完成认证时提示 -->
    <el-dialog
      v-model="certDialogVisible"
      :show-close="true"
      :close-on-click-modal="false"
      :close-on-press-escape="true"
      width="400px"
      top="28vh"
      append-to-body
    >
      <div class="cert-dialog-body">
        <el-icon :size="52" color="#e6a23c">
          <WarningFilled />
        </el-icon>
        <h3 class="cert-dialog-title">{{ needRealName ? '实名认证提醒' : '企业资质认证' }}</h3>
        <p class="cert-dialog-desc">{{ certStatusText }}</p>
        <div class="cert-dialog-actions">
          <button class="cert-dialog-btn cert-dialog-btn-primary" @click="goToEnterpriseCert">{{ needRealName ? '去实名认证' : '前往认证' }}</button>
          <button class="cert-dialog-btn cert-dialog-btn-default" @click="dismissCertDialog">
            稍后再说
          </button>
        </div>
      </div>
    </el-dialog>

  </div>
</template>

<style scoped>
.default-layout {
  min-height: 100vh;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  padding-top: 60px;
}

.layout-header {
  background: #1F2634;
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 100;
}

.header-inner {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 24px;
  height: 60px;
  display: flex;
  align-items: center;
  gap: 24px;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 20px;
}

.logo {
  display: flex;
  align-items: center;
  text-decoration: none;
}

.logo-img {
  height: 32px;
  width: auto;
  display: block;
}

.city-selector {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
  font-size: 14px;
  color: #fff;
  background: rgba(255, 255, 255, 0.1);
  border: none;
  border-radius: 20px;
  cursor: pointer;
  transition: background 0.2s;
}

.city-selector:hover {
  background: rgba(255, 255, 255, 0.2);
}

.header-nav {
  display: flex;
  gap: 4px;
  flex: 1;
}

.header-nav a {
  padding: 8px 16px;
  color: rgba(255, 255, 255, 0.85);
  text-decoration: none;
  font-size: 15px;
  border-radius: 4px;
  transition: all 0.2s;
}

.header-nav a:hover {
  color: #fff;
  background: rgba(255, 255, 255, 0.1);
}

.header-nav a.router-link-exact-active,
.header-nav a:not([href="/"]).router-link-active {
  color: #fff;
  background: rgba(255, 255, 255, 0.15);
  font-weight: 500;
}

.header-nav .super-admin-link {
  color: #ffd700;
}
.header-nav .super-admin-link:hover {
  color: #fff;
  background: rgba(255, 215, 0, 0.15);
}
.header-nav .super-admin-link.router-link-active {
  color: #1a1a2e;
  background: #ffd700;
  font-weight: 600;
}

.nav-msg-link {
  position: relative;
}

.msg-badge {
  position: absolute;
  top: -6px;
  right: -8px;
  min-width: 18px;
  height: 18px;
  padding: 0 5px;
  border-radius: 9px;
  background: linear-gradient(135deg, #ff4757 0%, #ff6b81 100%);
  color: #fff;
  font-size: 11px;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  line-height: 1;
  box-shadow: 0 2px 6px rgba(255, 71, 87, 0.3);
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 16px;
}

.user-name {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.9);
}

.btn-login {
  padding: 6px 18px;
  border-radius: 20px;
  font-size: 14px;
  text-decoration: none;
  color: #fff;
  background: #1762FB;
  transition: opacity 0.2s;
}

.btn-login:hover {
  opacity: 0.9;
}

.nav-user-link {
  padding: 8px 12px;
  font-size: 15px;
  color: rgba(255, 255, 255, 0.85);
  text-decoration: none;
  border-radius: 4px;
  transition: all 0.2s;
}

.nav-user-link:hover {
  color: #fff;
  background: rgba(255, 255, 255, 0.1);
}

.nav-user-link.router-link-active {
  color: #fff;
  background: rgba(255, 255, 255, 0.15);
  font-weight: 500;
}

.btn-logout {
  padding: 6px 14px;
  border-radius: 4px;
  font-size: 14px;
  border: none;
  cursor: pointer;
  color: rgba(255, 255, 255, 0.8);
  background: transparent;
  transition: color 0.2s;
}

.btn-logout:hover {
  color: #fff;
}

.layout-main {
  flex: 1;
  background: #f5f7fa;
}

/* 企业资质认证弹窗样式 */
.cert-dialog-body {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 16px 8px 8px;
  text-align: center;
}
.cert-dialog-title {
  margin: 16px 0 8px;
  font-size: 20px;
  font-weight: 600;
  color: #1a1a2e;
}
.cert-dialog-desc {
  margin: 0 0 24px;
  font-size: 14px;
  color: #555;
  line-height: 1.6;
  white-space: pre-line;
}
.cert-dialog-actions {
  display: flex;
  gap: 12px;
  width: 100%;
}
.cert-dialog-btn {
  height: 44px;
  font-size: 16px;
  font-weight: 600;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: opacity 0.2s;
  flex: 1;
}
.cert-dialog-btn-primary {
  color: #fff;
  background: #1762FB;
}
.cert-dialog-btn-primary:hover {
  opacity: 0.92;
}
.cert-dialog-btn-default {
  color: #555;
  background: #f0f2f5;
}
.cert-dialog-btn-default:hover {
  background: #e5e7eb;
}

.cert-dialog-logout {
  margin-top: 12px;
  padding: 8px 0;
  font-size: 13px;
  color: #999;
  background: transparent;
  border: none;
  cursor: pointer;
  transition: color 0.2s;
}
.cert-dialog-logout:hover {
  color: #e74c3c;
}

@media (max-width: 768px) {
  .header-inner {
    padding: 0 16px;
    gap: 12px;
  }

  .header-nav {
    display: none;
  }

  .city-selector span {
    display: none;
  }
}
</style>
