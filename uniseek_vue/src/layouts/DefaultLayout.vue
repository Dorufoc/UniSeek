<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { useAppStore } from '@/stores/app'
import { Location, ArrowDown } from '@element-plus/icons-vue'

const router = useRouter()
const userStore = useUserStore()
const appStore = useAppStore()

// 判断当前用户是否为招聘者（role === 1 表示招聘者，0 表示求职者）
const isRecruiter = computed(() => userStore.userInfo?.role === 1)

// 判断当前用户是否为管理员（role === 9 或 99）
const isAdmin = computed(() => userStore.userInfo?.role >= 9)

// 控制城市选择弹窗的显示与隐藏
const showCityModal = ref(false)

// 热门城市列表，用于城市选择弹窗的快捷选择区域
const hotCities = ['北京', '上海', '广州', '深圳', '杭州', '成都', '武汉', '西安']

// 全国主要城市列表，用于城市选择弹窗的更多城市区域
const allCities = [
  '北京', '上海', '天津', '重庆',
  '石家庄', '太原', '呼和浩特', '沈阳', '长春', '哈尔滨',
  '南京', '杭州', '合肥', '福州', '南昌', '济南',
  '郑州', '武汉', '长沙', '广州', '南宁', '海口',
  '成都', '贵阳', '昆明', '拉萨', '西安', '兰州',
  '西宁', '银川', '乌鲁木齐', '大连', '青岛', '宁波',
  '厦门', '深圳', '苏州', '无锡', '佛山', '东莞'
]

// 选择城市：更新全局城市状态并关闭弹窗
const selectCity = (city: string) => {
  appStore.setCity(city)
  showCityModal.value = false
}
</script>

<template>
  <div class="default-layout">
    <!-- 顶部导航栏 -->
    <header class="layout-header">
      <div class="header-inner">
        <!-- 左侧区域：Logo 和城市选择器 -->
        <div class="header-left">
          <router-link to="/" class="logo">UniSeek</router-link>
          <!-- 城市选择按钮，点击弹出城市选择弹窗 -->
          <button class="city-selector" @click="showCityModal = true">
            <el-icon :size="14"><Location /></el-icon>
            <span>{{ appStore.city }}</span>
            <el-icon :size="12"><ArrowDown /></el-icon>
          </button>
        </div>

        <!-- 中部区域：主导航菜单 -->
        <nav class="header-nav">
          <router-link to="/">首页</router-link>
          <router-link to="/jobs">职位</router-link>
          <router-link to="/company">公司</router-link>
          <router-link to="/messages">消息</router-link>
          <router-link v-if="isAdmin" to="/admin/dashboard" class="super-admin-link">管理后台</router-link>
        </nav>

        <!-- 右侧区域：用户操作（登录状态根据角色显示不同入口） -->
        <div class="header-actions">
          <!-- 已登录状态 -->
          <template v-if="userStore.isLoggedIn">
            <router-link v-if="!isRecruiter" to="/resume" class="nav-user-link">简历</router-link>
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

    <!-- 城市选择弹窗：点击遮罩层关闭，点击内容区阻止冒泡 -->
    <div v-if="showCityModal" class="city-modal" @click="showCityModal = false">
      <div class="city-modal-content" @click.stop>
        <div class="city-modal-header">
          <h3>选择城市</h3>
          <button class="close-btn" @click="showCityModal = false">×</button>
        </div>
        <!-- 当前城市展示区 -->
        <div class="city-section">
          <h4>当前城市</h4>
          <button class="city-tag current">{{ appStore.city }}</button>
        </div>
        <!-- 热门城市快捷选择区 -->
        <div class="city-section">
          <h4>热门城市</h4>
          <div class="city-list">
            <button
              v-for="city in hotCities"
              :key="city"
              :class="['city-tag', { active: city === appStore.city }]"
              @click="selectCity(city)"
            >
              {{ city }}
            </button>
          </div>
        </div>
        <!-- 全国城市完整选择区 -->
        <div class="city-section">
          <h4>更多城市</h4>
          <div class="city-list">
            <button
              v-for="city in allCities"
              :key="city"
              :class="['city-tag', { active: city === appStore.city }]"
              @click="selectCity(city)"
            >
              {{ city }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.default-layout {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.layout-header {
  background: linear-gradient(90deg, #0d1b2a 0%, #1b2838 100%);
  position: sticky;
  top: 0;
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
  font-size: 24px;
  font-weight: 800;
  color: #fff;
  text-decoration: none;
  letter-spacing: 1px;
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

.header-nav a.router-link-active {
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

/* 城市选择弹窗 */
.city-modal {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding-top: 120px;
  z-index: 1000;
}

.city-modal-content {
  width: 560px;
  max-width: 90%;
  max-height: 70vh;
  overflow-y: auto;
  background: var(--bg);
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.2);
}

.city-modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
}

.city-modal-header h3 {
  font-size: 18px;
  margin: 0;
  color: var(--text-h);
}

.close-btn {
  width: 28px;
  height: 28px;
  border: none;
  background: transparent;
  font-size: 22px;
  color: #999;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.close-btn:hover {
  color: var(--text-h);
}

.city-section {
  margin-bottom: 20px;
}

.city-section h4 {
  font-size: 14px;
  color: #999;
  margin: 0 0 12px;
  font-weight: normal;
}

.city-list {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.city-tag {
  padding: 8px 16px;
  font-size: 14px;
  border: 1px solid var(--border);
  background: var(--bg);
  color: var(--text);
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
}

.city-tag:hover {
  border-color: #007AFF;
  color: #007AFF;
}

.city-tag.active,
.city-tag.current {
  border-color: #007AFF;
  background: rgba(0, 122, 255, 0.1);
  color: #007AFF;
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
