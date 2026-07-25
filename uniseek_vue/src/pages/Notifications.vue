<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Bell, Delete } from '@element-plus/icons-vue'
import { getMessages, markMessageRead, markAllRead } from '@/api/notification'
import type { NotificationItem } from '@/api/notification'

const router = useRouter()

const activeTab = ref<number | null>(null)
const notifications = ref<NotificationItem[]>([])
const total = ref(0)
const page = ref(1)
const pageSize = ref(10)
const loading = ref(false)
const markingAll = ref(false)

const tabs = [
  { label: '全部', value: null },
  { label: '面试邀请', value: 1 },
  { label: '录用通知', value: 2 },
  { label: '淘汰通知', value: 3 }
]

const typeLabels: Record<number, string> = {
  0: '系统通知',
  1: '面试邀请',
  2: '录用通知',
  3: '淘汰通知'
}

const typeColors: Record<number, string> = {
  0: '#909399',
  1: '#409eff',
  2: '#67c23a',
  3: '#f56c6c'
}

const loadNotifications = async () => {
  loading.value = true
  try {
    const params: any = { page: page.value, pageSize: pageSize.value }
    if (activeTab.value !== null) params.type = activeTab.value
    const res = await getMessages(params)
    notifications.value = res?.records || []
    total.value = res?.total || 0
  } catch {
    notifications.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

const handleMarkRead = async (item: NotificationItem) => {
  if (item.isRead === 1) return
  try {
    await markMessageRead(item.id)
    item.isRead = 1
  } catch {
    ElMessage.error('标记已读失败')
  }
}

const handleCardClick = (item: NotificationItem) => {
  handleMarkRead(item)
  if (item.type === 1) {
    router.push('/my-applications?tab=interviews')
  } else if (item.type === 2 || item.type === 3) {
    router.push('/my-applications')
  }
}

const handleMarkAllRead = async () => {
  markingAll.value = true
  try {
    await markAllRead()
    notifications.value.forEach(n => { n.isRead = 1 })
    ElMessage.success('已全部标记为已读')
  } catch {
    ElMessage.error('操作失败')
  } finally {
    markingAll.value = false
  }
}

const handleTabChange = () => {
  page.value = 1
  loadNotifications()
}

const handlePageChange = (p: number) => {
  page.value = p
  loadNotifications()
}

const formatTime = (str: string) => {
  if (!str) return '-'
  return str.replace('T', ' ').substring(0, 16)
}

watch(activeTab, handleTabChange)
onMounted(loadNotifications)
</script>

<template>
  <div class="notifications-page">
    <div class="notifications-container">
      <!-- Tab 切换 -->
      <div class="notifications-tabs">
        <div class="tabs-left">
          <span
            v-for="tab in tabs"
            :key="tab.label"
            :class="['tab-item', { active: activeTab === tab.value }]"
            @click="activeTab = tab.value"
          >{{ tab.label }}</span>
        </div>
        <el-button
          size="small"
          :icon="Delete"
          :loading="markingAll"
          @click="handleMarkAllRead"
        >全部已读</el-button>
      </div>

      <!-- 加载中 -->
      <div v-if="loading" class="list-loading">加载中...</div>

      <!-- 通知列表 -->
      <template v-else>
        <div v-if="notifications.length" class="notification-list">
          <div
            v-for="item in notifications"
            :key="item.id"
            :class="['notification-card', { unread: item.isRead === 0 }]"
            @click="handleCardClick(item)"
          >
            <div class="notification-left">
              <div class="notification-icon" :style="{ background: typeColors[item.type] || '#909399' }">
                <el-icon :size="14"><Bell /></el-icon>
              </div>
            </div>
            <div class="notification-body">
              <div class="notification-header">
                <span class="notification-title">{{ item.title }}</span>
                <span class="notification-type-tag" :style="{ color: typeColors[item.type] || '#909399', background: (typeColors[item.type] || '#909399') + '1A' }">
                  {{ typeLabels[item.type] || '系统通知' }}
                </span>
                <span v-if="item.isRead === 0" class="unread-dot"></span>
              </div>
              <div class="notification-content">{{ item.content }}</div>
              <div class="notification-time">{{ formatTime(item.createTime) }}</div>
            </div>
          </div>
        </div>
        <div v-else class="list-empty">
          <el-empty description="暂无通知" />
        </div>

        <!-- 分页 -->
        <div v-if="total > pageSize" class="list-pagination">
          <el-pagination
            background
            layout="prev, pager, next"
            :total="total"
            :page-size="pageSize"
            :current-page="page"
            @current-change="handlePageChange"
          />
        </div>
      </template>
    </div>
  </div>
</template>

<style scoped>
.notifications-page {
  min-height: calc(100vh - 60px);
  background: #f5f7fa;
  padding: 24px;
  box-sizing: border-box;
}

.notifications-container {
  max-width: 800px;
  margin: 0 auto;
}

.notifications-tabs {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #fff;
  padding: 12px 20px;
  border-radius: 8px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  margin-bottom: 16px;
}

.tabs-left {
  display: flex;
  gap: 4px;
}

.tab-item {
  padding: 6px 16px;
  font-size: 14px;
  color: #666;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s;
}

.tab-item:hover {
  color: #1762FB;
  background: rgba(23, 98, 251, 0.05);
}

.tab-item.active {
  color: #1762FB;
  background: rgba(23, 98, 251, 0.1);
  font-weight: 500;
}

.list-loading,
.list-empty {
  text-align: center;
  padding: 64px;
  background: #fff;
  border-radius: 8px;
  color: #999;
}

.notification-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.notification-card {
  display: flex;
  gap: 14px;
  padding: 16px 20px;
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.04);
  cursor: pointer;
  transition: all 0.2s;
}

.notification-card:hover {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.notification-card.unread {
  background: #f0f6ff;
}

.notification-left {
  flex-shrink: 0;
  padding-top: 2px;
}

.notification-icon {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
}

.notification-body {
  flex: 1;
  min-width: 0;
}

.notification-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
}

.notification-title {
  font-size: 15px;
  font-weight: 600;
  color: #000;
}

.notification-type-tag {
  font-size: 11px;
  padding: 1px 8px;
  border-radius: 8px;
  flex-shrink: 0;
}

.unread-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #ff4757;
  flex-shrink: 0;
  margin-left: auto;
}

.notification-content {
  font-size: 13px;
  color: #666;
  line-height: 1.5;
  margin-bottom: 6px;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

.notification-time {
  font-size: 12px;
  color: #999;
}

.list-pagination {
  display: flex;
  justify-content: center;
  padding: 24px 0;
}
</style>
