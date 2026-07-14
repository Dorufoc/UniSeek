<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  User, Phone, Postcard, Edit, Document, Star,
  OfficeBuilding, Briefcase, Files,
  Lock, InfoFilled, SwitchButton, ArrowRight, ChatDotSquare, VideoCamera, Setting
} from '@element-plus/icons-vue'

const router = useRouter()
const userStore = useUserStore()

const isRecruiter = computed(() => userStore.userInfo?.role === 1)
const isSuperAdmin = computed(() => userStore.userInfo?.role === 99)
const userPhone = computed(() => {
  const phone = userStore.userInfo?.phone || ''
  return phone ? phone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2') : '未绑定'
})

// 模拟统计数据（后续对接真实接口）
const seekerStats = ref({ applications: 12, interviews: 3, favorites: 8 })
const recruiterStats = ref({ receivedResumes: 23, hired: 3 })

// 菜单项点击处理
const handleMenuClick = (item: string) => {
  switch (item) {
    case 'resume':
      router.push('/resume')
      break
    case 'applications':
      ElMessage.info('投递记录功能开发中')
      break
    case 'interviews':
      ElMessage.info('面试邀请功能开发中')
      break
    case 'favorites':
      ElMessage.info('收藏职位功能开发中')
      break
    case 'enterprise':
      ElMessage.info('企业信息功能开发中')
      break
    case 'postedJobs':
      router.push('/post-job')
      break
    case 'resumePool':
      ElMessage.info('简历池功能开发中')
      break
    case 'security':
      ElMessage.info('账号安全功能开发中')
      break
    case 'superAdmin':
      router.push('/admin/super')
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
          <div class="user-avatar">
            <el-icon :size="48"><User /></el-icon>
          </div>
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
          <button class="edit-profile-btn" @click="handleMenuClick('resume')">
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
  color: #007AFF;
}

.user-name {
  font-size: 18px;
  font-weight: 600;
  color: var(--text-h);
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
  color: #007AFF;
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
  color: #999;
  margin-bottom: 16px;
}

.edit-profile-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 24px;
  font-size: 14px;
  color: #007AFF;
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
  color: #007AFF;
  line-height: 1.3;
}

.stat-label {
  font-size: 13px;
  color: #999;
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
  color: var(--text-h);
  margin: 0 0 16px;
  padding-left: 4px;
  border-left: 3px solid #007AFF;
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
  border-color: #007AFF;
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
  color: #007AFF;
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
  color: var(--text-h);
  margin-bottom: 2px;
}

.menu-info .menu-desc {
  font-size: 12px;
  color: #999;
}

.menu-arrow {
  color: #ccc;
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
  color: var(--text-h);
  white-space: nowrap;
}

.menu-item-row.logout .menu-name {
  color: #e74c3c;
}

.menu-hint {
  flex: 1;
  text-align: right;
  font-size: 13px;
  color: #999;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
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
