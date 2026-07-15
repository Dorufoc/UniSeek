<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { getChatSessions, type ChatSessionVO } from '@/api/chat'

const router = useRouter()
const sessions = ref<ChatSessionVO[]>([])
const loading = ref(true)

const formatTime = (dateStr: string): string => {
  if (!dateStr) return ''
  return dateStr.replace('T', ' ').substring(0, 16)
}

const truncate = (text: string, len = 40): string => {
  if (!text) return ''
  return text.length > len ? text.substring(0, len) + '...' : text
}

const loadSessions = async () => {
  try {
    sessions.value = await getChatSessions()
  } catch {
    sessions.value = []
  } finally {
    loading.value = false
  }
}

const handleClick = (session: ChatSessionVO) => {
  router.push(`/chat/${session.applicationId}`)
}

onMounted(loadSessions)
</script>

<template>
  <div class="messages-page">
    <h1>消息中心</h1>
    <div v-if="loading" class="loading-state">会话列表加载中...</div>
    <div v-else-if="sessions.length === 0" class="empty-state">
      暂无会话
    </div>
    <div v-else class="session-list">
      <div
        v-for="session in sessions"
        :key="session.applicationId"
        class="session-item"
        @click="handleClick(session)"
      >
        <div class="session-avatar">{{ (session.counterpartName || '对')[0] }}</div>
        <div class="session-info">
          <div class="session-header">
            <span class="counterpart-name">{{ session.counterpartName || '对方' }}</span>
            <span class="session-time">{{ formatTime(session.lastMessageTime) }}</span>
          </div>
          <div class="session-body">
            <span class="task-title">{{ session.taskTitle }}</span>
            <span class="last-message">{{ truncate(session.lastMessage) }}</span>
          </div>
        </div>
        <div v-if="session.unreadCount > 0" class="unread-badge">
          {{ session.unreadCount > 99 ? '99+' : session.unreadCount }}
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.messages-page {
  max-width: 900px;
  margin: 0 auto;
  padding: 24px;
}

.messages-page h1 {
  font-size: 22px;
  font-weight: 600;
  color: #1a1a2e;
  margin: 0 0 20px;
}

.loading-state,
.empty-state {
  text-align: center;
  padding: 80px 0;
  color: #999;
  background: #fff;
  border-radius: 12px;
}

.session-list {
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  overflow: hidden;
}

.session-item {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 16px 20px;
  cursor: pointer;
  transition: background 0.2s;
  border-bottom: 1px solid #f5f5f8;
}

.session-item:last-child {
  border-bottom: none;
}

.session-item:hover {
  background: #f8f9fc;
}

.session-avatar {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: linear-gradient(135deg, #007AFF, #5856d6);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  flex-shrink: 0;
}

.session-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.session-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.counterpart-name {
  font-size: 15px;
  font-weight: 600;
  color: #1a1a2e;
}

.session-time {
  font-size: 12px;
  color: #999;
}

.session-body {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.task-title {
  font-size: 12px;
  color: #007AFF;
}

.last-message {
  font-size: 13px;
  color: #888;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.unread-badge {
  min-width: 20px;
  height: 20px;
  padding: 0 6px;
  border-radius: 10px;
  background: #e74c3c;
  color: #fff;
  font-size: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
}
</style>
