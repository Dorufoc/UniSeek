<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { Search } from '@element-plus/icons-vue'

const router = useRouter()
const appStore = useAppStore()
// 搜索关键词，双向绑定到搜索输入框
const keyword = ref('')

// 热门职位列表，用于首页快速搜索入口
const hotJobs = ['售前客服', '设备维修保养工程师', 'IT咨询顾问', 'IT技术支持', '系统管理员', '实施顾问', 'Java开发', '产品经理', 'UI设计师', '运维工程师']

// 处理搜索：将关键词存入全局状态并跳转到职位搜索页
const handleSearch = () => {
  appStore.setSearchKeyword(keyword.value)
  router.push('/jobs')
}
</script>

<template>
  <div class="home-page">
    <!-- 首页主视觉区域 -->
    <section class="hero-section">
      <!-- 搜索框卡片：包含职位类型标签、搜索输入框和搜索按钮 -->
      <div class="hero-search-card">
        <div class="search-type">职位类型</div>
        <el-input
          v-model="keyword"
          size="large"
          placeholder="搜索职位、公司"
          :prefix-icon="Search"
          clearable
          @keyup.enter="handleSearch"
        />
        <button class="search-btn" @click="handleSearch">
          搜索
        </button>
      </div>

      <!-- 热门职位标签：点击可快速搜索对应职位 -->
      <div class="hot-jobs">
        <span class="hot-label">热门职位：</span>
        <button
          v-for="job in hotJobs"
          :key="job"
          class="hot-tag"
          @click="keyword = job; handleSearch()"
        >
          {{ job }}
        </button>
      </div>
    </section>
  </div>
</template>

<style scoped>
.home-page {
  min-height: calc(100vh - 60px);
  background: linear-gradient(180deg, #e8f4fd 0%, #f5f7fa 100%);
}

.hero-section {
  max-width: 900px;
  margin: 0 auto;
  padding: 80px 24px 60px;
}

.hero-search-card {
  display: flex;
  align-items: center;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
  overflow: hidden;
  height: 60px;
}

.search-type {
  padding: 0 24px;
  font-size: 16px;
  color: #000;
  font-weight: 500;
  white-space: nowrap;
  border-right: 1px solid var(--border);
  height: 100%;
  display: flex;
  align-items: center;
}

.hero-search-card :deep(.el-input__wrapper) {
  box-shadow: none !important;
  border-radius: 0;
  padding-left: 20px;
}

.hero-search-card :deep(.el-input__inner) {
  font-size: 16px;
  height: 58px;
}

.search-btn {
  width: 140px;
  height: 100%;
  border: none;
  background: #007AFF;
  color: #fff;
  font-size: 18px;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.2s;
}

.search-btn:hover {
  opacity: 0.92;
}

.hot-jobs {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 20px;
  padding-left: 8px;
}

.hot-label {
  font-size: 14px;
  color: #000;
}

.hot-tag {
  padding: 6px 14px;
  font-size: 14px;
  color: #000;
  background: #fff;
  border: 1px solid var(--border);
  border-radius: 20px;
  cursor: pointer;
  transition: all 0.2s;
}

.hot-tag:hover {
  color: #007AFF;
  border-color: #007AFF;
  background: rgba(0, 122, 255, 0.05);
}

@media (max-width: 768px) {
  .hero-section {
    padding: 40px 16px;
  }

  .hero-search-card {
    flex-direction: column;
    height: auto;
  }

  .search-type {
    width: 100%;
    border-right: none;
    border-bottom: 1px solid var(--border);
    justify-content: center;
    padding: 12px 0;
  }

  .hero-search-card :deep(.el-input__wrapper) {
    padding: 8px 16px;
  }

  .search-btn {
    width: 100%;
    padding: 14px 0;
  }
}
</style>
