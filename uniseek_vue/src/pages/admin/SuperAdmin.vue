<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const userStore = useUserStore()
</script>

<template>
  <div class="super-admin-page">
    <div class="admin-container">
      <div class="admin-header">
        <h1>系统管理</h1>
        <p class="admin-desc">超级管理员控制面板 — 管理平台用户、企业认证、职位审核等</p>
      </div>

      <div class="admin-grid">
        <div class="admin-card" @click="$router.push('/')">
          <div class="card-icon user-icon">
            <span>👥</span>
          </div>
          <div class="card-info">
            <h3>用户管理</h3>
            <p>查看和管理所有平台用户</p>
          </div>
        </div>

        <div class="admin-card" @click="$router.push('/')">
          <div class="card-icon cert-icon">
            <span>📋</span>
          </div>
          <div class="card-info">
            <h3>企业认证审核</h3>
            <p>审核企业资质认证申请</p>
          </div>
        </div>

        <div class="admin-card" @click="$router.push('/')">
          <div class="card-icon job-icon">
            <span>💼</span>
          </div>
          <div class="card-info">
            <h3>职位审核</h3>
            <p>审核平台发布的职位信息</p>
          </div>
        </div>

        <div class="admin-card" @click="$router.push('/')">
          <div class="card-icon sys-icon">
            <span>⚙️</span>
          </div>
          <div class="card-info">
            <h3>系统设置</h3>
            <p>平台配置与参数管理</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.super-admin-page {
  min-height: calc(100vh - 60px);
  background: #f0f2f5;
  padding: 32px 24px;
  box-sizing: border-box;
}

.admin-container {
  max-width: 1000px;
  margin: 0 auto;
}

.admin-header {
  margin-bottom: 32px;
}

.admin-header h1 {
  font-size: 24px;
  font-weight: 700;
  color: #1a1a2e;
  margin: 0 0 8px;
}

.admin-desc {
  font-size: 14px;
  color: #999;
  margin: 0;
}

.admin-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}

.admin-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 24px;
  background: #fff;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.25s;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
}

.admin-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.1);
}

.card-icon {
  width: 52px;
  height: 52px;
  min-width: 52px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
}

.card-icon.user-icon {
  background: rgba(0, 122, 255, 0.1);
}

.card-icon.cert-icon {
  background: rgba(46, 125, 50, 0.1);
}

.card-icon.job-icon {
  background: rgba(255, 152, 0, 0.1);
}

.card-icon.sys-icon {
  background: rgba(156, 39, 176, 0.1);
}

.card-info h3 {
  font-size: 16px;
  font-weight: 600;
  color: #1a1a2e;
  margin: 0 0 4px;
}

.card-info p {
  font-size: 13px;
  color: #999;
  margin: 0;
}

@media (max-width: 640px) {
  .admin-grid {
    grid-template-columns: 1fr;
  }

  .super-admin-page {
    padding: 20px 16px;
  }
}
</style>
