<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { useAppStore } from '@/stores/app'

const router = useRouter()
const userStore = useUserStore()
const appStore = useAppStore()

// 判断当前用户是否为招聘者（role === 1 表示招聘者，0 表示求职者）
const isRecruiter = computed(() => userStore.userInfo?.role === 1)

// 判断当前用户是否为管理员（role === 9 或 99）
const isAdmin = computed(() => userStore.userInfo?.role >= 9)
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
          <router-link to="/messages">消息</router-link>
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


  </div>
</template>

<style scoped>
.default-layout {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  padding-top: 60px;
}

.layout-header {
  background: linear-gradient(90deg, #0d1b2a 0%, #1b2838 100%);
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
  background: #007AFF;
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
