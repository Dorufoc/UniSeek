<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import {
  DataBoard,
  DocumentChecked,
  Tickets,
  User,
  UserFilled,

  Notebook,
  Fold,
  Expand,
  SwitchButton,
  ArrowDown
} from '@element-plus/icons-vue'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const isCollapse = ref(false)
const activeMenu = ref(route.path)

watch(() => route.path, (path) => {
  activeMenu.value = path
})

const menuItems = [
  { path: '/admin/dashboard', title: '工作台', icon: DataBoard },
  { path: '/admin/enterprises', title: '企业审核', icon: DocumentChecked },
  { path: '/admin/tasks', title: '职位审核', icon: Tickets },
  { path: '/admin/users', title: '用户管理', icon: User },

  { path: '/admin/logs', title: '操作日志', icon: Notebook }
]

const breadcrumbs = computed(() => {
  const item = menuItems.find(m => m.path === route.path)
  return item ? item.title : ''
})

const handleLogout = () => {
  userStore.logout()
  router.push('/login')
}
</script>

<template>
  <el-container class="admin-layout">
    <!-- 左侧菜单栏 -->
    <el-aside :width="isCollapse ? '64px' : '220px'" class="admin-aside">
      <div class="logo-area" @click="router.push('/admin/dashboard')">
        <img v-if="!isCollapse" src="@/assets/uniseek_text_white_ZH.svg" alt="UniSeek" class="logo-img" />
        <img v-else src="@/assets/uniseek-icon.png" alt="UniSeek" class="logo-icon-mini" />
      </div>
      <el-menu
        :default-active="activeMenu"
        :collapse="isCollapse"
        :collapse-transition="false"
        router
        background-color="#1F2634"
        text-color="#bfcbd9"
        active-text-color="#1762FB"
        class="admin-menu"
      >
        <el-menu-item v-for="item in menuItems" :key="item.path" :index="item.path">
          <el-icon><component :is="item.icon" /></el-icon>
          <template #title>{{ item.title }}</template>
        </el-menu-item>
      </el-menu>
    </el-aside>

    <!-- 右侧内容区域 -->
    <el-container>
      <!-- 顶部栏 -->
      <el-header class="admin-header">
        <div class="header-left">
          <el-icon class="collapse-btn" @click="isCollapse = !isCollapse">
            <Fold v-if="!isCollapse" />
            <Expand v-else />
          </el-icon>
          <el-breadcrumb separator="/">
            <el-breadcrumb-item :to="{ path: '/admin/dashboard' }">管理后台</el-breadcrumb-item>
            <el-breadcrumb-item v-if="breadcrumbs">{{ breadcrumbs }}</el-breadcrumb-item>
          </el-breadcrumb>
        </div>
        <div class="header-right">
          <el-dropdown trigger="click">
            <span class="user-info">
              <el-avatar :size="32" icon="UserFilled" />
              <span class="nickname">{{ userStore.userInfo?.nickname || '管理员' }}</span>
              <el-icon><arrow-down /></el-icon>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item @click="router.push('/')">返回前台</el-dropdown-item>
                <el-dropdown-item divided @click="handleLogout">
                  <el-icon><SwitchButton /></el-icon>
                  退出登录
                </el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>

      <!-- 内容区 -->
      <el-main class="admin-main">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<style scoped>
.admin-layout {
  height: 100vh;
  overflow: hidden;
}

.admin-aside {
  background: #1F2634;
  transition: width 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 2px 0 8px rgba(0, 0, 0, 0.08);
}

.logo-area {
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  transition: all 0.3s ease;
}

.logo-area:hover {
  background: rgba(255, 255, 255, 0.04);
}

.logo-img {
  height: 20px;
  width: auto;
  display: block;
  transition: transform 0.3s ease;
}

.logo-area:hover .logo-img {
  /* 移除缩放动画 */
}

.logo-icon-mini {
  height: 28px;
  width: auto;
  display: block;
  object-fit: contain;
  /* 将图标填充为白色 */
  filter: brightness(0) invert(1);
  transition: transform 0.3s ease;
}

.admin-menu {
  border-right: none;
  flex: 1;
  overflow-y: auto;
  background: transparent !important;
}

.admin-menu::-webkit-scrollbar {
  width: 6px;
}

.admin-menu::-webkit-scrollbar-track {
  background: transparent;
}

.admin-menu::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 3px;
}

.admin-menu::-webkit-scrollbar-thumb:hover {
  background: rgba(255, 255, 255, 0.2);
}

.admin-menu .el-menu-item {
  height: 52px;
  line-height: 52px;
  margin: 4px 8px;
  border-radius: 8px;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  color: rgba(255, 255, 255, 0.75) !important;
}

.admin-menu .el-menu-item:hover {
  background: rgba(23, 98, 251, 0.15) !important;
  color: #fff !important;
}

.admin-menu .el-menu-item.is-active {
  background: linear-gradient(135deg, #1762FB 0%, #0052e6 100%) !important;
  color: #fff !important;
  font-weight: 600;
  box-shadow: 0 4px 12px rgba(23, 98, 251, 0.3);
}

.admin-menu .el-menu-item .el-icon {
  font-size: 18px;
  margin-right: 12px;
}

/* 收起时图标居中 */
.admin-menu.el-menu--collapse .el-menu-item .el-icon {
  margin-right: 0;
}

.admin-menu.el-menu--collapse .el-menu-item {
  margin: 4px 0;
  display: flex;
  justify-content: center;
}

.admin-header {
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #fff;
  border-bottom: 1px solid #e2e8f0;
  padding: 0 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
}

.header-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.collapse-btn {
  font-size: 20px;
  cursor: pointer;
  color: #64748b;
  transition: all 0.25s ease;
  padding: 8px;
  border-radius: 6px;
}

.collapse-btn:hover {
  color: #1762FB;
  background: rgba(23, 98, 251, 0.08);
}

.header-right {
  display: flex;
  align-items: center;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  color: #1a1a2e;
  font-size: 14px;
  padding: 6px 12px;
  border-radius: 8px;
  transition: all 0.25s ease;
}

.user-info:hover {
  background: rgba(23, 98, 251, 0.08);
  color: #1762FB;
}

.nickname {
  max-width: 140px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-weight: 500;
}

.admin-main {
  background: #f8fafc;
  padding: 24px;
  overflow-y: auto;
  height: calc(100vh - 64px);
}

.admin-main::-webkit-scrollbar {
  width: 8px;
}

.admin-main::-webkit-scrollbar-track {
  background: #f1f5f9;
}

.admin-main::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 4px;
}

.admin-main::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}
</style>
