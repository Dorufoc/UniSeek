<script setup lang="ts">
import { ref, onMounted, computed, nextTick, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/stores/user'
import {
  getChatSessions,
  getChatSession,
  getChatMessages,
  sendMessage,
  markSessionRead,
  type ChatSessionVO,
  type ChatMessageVO
} from '@/api/chat'
import { getResume } from '@/api/resume'
import { useChatWebSocket, type WsNewMessageData } from '@/composables/useChatWebSocket'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const sessions = ref<ChatSessionVO[]>([])
const sessionsLoading = ref(true)
const selectedAppId = ref<number | null>(null)
const session = ref<ChatSessionVO | null>(null)
const messages = ref<ChatMessageVO[]>([])
const chatLoading = ref(false)
const sending = ref(false)
const sendingResume = ref(false)
const inputText = ref('')
const hasMore = ref(true)
const messageListRef = ref<HTMLElement | null>(null)

const currentUserId = computed(() => userStore.userInfo?.id)
const isHr = computed(() => userStore.userInfo?.role === 1)

const selectedSession = computed(() =>
  sessions.value.find(s => s.applicationId === selectedAppId.value) || null
)

const isBlocked = computed(() => {
  if (isHr.value) return false
  return session.value?.canSend === false
})

const blockedTip = 'HR 未回复前，您只能发送一条消息'

const formatTime = (dateStr: string): string => {
  if (!dateStr) return ''
  return dateStr.replace('T', ' ').substring(0, 16)
}

const formatSessionTime = (dateStr: string): string => {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  const now = new Date()
  const diff = now.getTime() - d.getTime()
  const oneDay = 86400000
  if (diff < oneDay) {
    return dateStr.substring(11, 16)
  }
  if (diff < 2 * oneDay) {
    return '昨天'
  }
  return dateStr.substring(5, 10)
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
    sessionsLoading.value = false
  }
}

const loadSession = async (appId: number) => {
  try {
    session.value = await getChatSession(appId)
  } catch {
    session.value = null
  }
}

const loadMessages = async (appId: number, beforeId?: number) => {
  try {
    const list = await getChatMessages(appId, beforeId)
    if (list.length < 20) {
      hasMore.value = false
    }
    if (beforeId) {
      messages.value.push(...list)
    } else {
      messages.value = list
    }
  } catch {
    /* 错误已在拦截器处理 */
  }
}

const scrollToTop = () => {
  nextTick(() => {
    const el = messageListRef.value
    if (el) {
      el.scrollTop = 0
    }
  })
}

const selectSession = async (appId: number) => {
  if (selectedAppId.value === appId) return
  selectedAppId.value = appId
  chatLoading.value = true
  messages.value = []
  hasMore.value = true
  try {
    await Promise.all([
      loadSession(appId),
      loadMessages(appId),
      markSessionRead(appId)
    ])
    const s = sessions.value.find(s => s.applicationId === appId)
    if (s) s.unreadCount = 0
  } catch {
    /* 错误已在拦截器处理 */
  } finally {
    chatLoading.value = false
    scrollToTop()
  }
}

const handleSend = async () => {
  const text = inputText.value.trim()
  if (!text) {
    ElMessage.warning('请输入消息内容')
    return
  }
  if (isBlocked.value) {
    ElMessage.warning(blockedTip)
    return
  }
  if (!selectedAppId.value) return
  sending.value = true
  try {
    const msg = await sendMessage(selectedAppId.value, { content: text })
    messages.value.unshift(msg)
    inputText.value = ''
    updateSessionInSidebar(msg)
    await refreshCurrentSession()
    scrollToTop()
    await loadSessions()
  } catch {
    /* 错误已在拦截器处理 */
  } finally {
    sending.value = false
  }
}

const handleSendResume = async () => {
  if (isBlocked.value) {
    ElMessage.warning(blockedTip)
    return
  }
  if (!selectedAppId.value) return
  sendingResume.value = true
  try {
    const resume = await getResume()
    if (!resume || !resume.attachmentUrl) {
      ElMessage.warning('请先上传简历附件')
      router.push('/resume')
      return
    }
    const msg = await sendMessage(selectedAppId.value, { messageType: 2, content: resume.attachmentUrl })
    messages.value.unshift(msg)
    updateSessionInSidebar(msg)
    await refreshCurrentSession()
    scrollToTop()
    await loadSessions()
  } catch {
    /* 错误已在拦截器处理 */
  } finally {
    sendingResume.value = false
  }
}

const getAttachmentName = (url: string) => {
  const name = url.substring(url.lastIndexOf('/') + 1) || '简历附件'
  return name.length > 30 ? name.substring(0, 27) + '...' : name
}

const refreshCurrentSession = async () => {
  if (!selectedAppId.value) return
  try {
    session.value = await getChatSession(selectedAppId.value)
  } catch {
    /* 静默失败 */
  }
}

/**
 * 发送消息后立即更新左侧会话列表：
 * - 若会话已存在，则更新最后一条消息预览并置顶；
 * - 若会话不在列表中（如直接会话），则根据当前会话详情构造一条插入顶部。
 */
const updateSessionInSidebar = (msg: ChatMessageVO) => {
  if (!selectedAppId.value) return
  const appId = selectedAppId.value
  const idx = sessions.value.findIndex(s => s.applicationId === appId)
  const preview = msg.messageType === 2 ? '[简历附件]' : msg.content
  if (idx !== -1) {
    const item = sessions.value[idx]
    item.lastMessage = preview
    item.lastMessageTime = msg.sendTime
    item.unreadCount = 0
    sessions.value.splice(idx, 1)
    sessions.value.unshift(item)
  } else if (session.value) {
    sessions.value.unshift({
      applicationId: appId,
      taskId: session.value.taskId,
      taskTitle: session.value.taskTitle,
      taskStatus: session.value.taskStatus,
      applicationStatus: session.value.applicationStatus,
      counterpartId: session.value.counterpartId,
      counterpartName: session.value.counterpartName,
      counterpartAvatar: session.value.counterpartAvatar,
      lastMessage: preview,
      lastMessageTime: msg.sendTime,
      unreadCount: 0,
      canSend: session.value.canSend
    })
  }
}

const handleWsNewMessage = (data: WsNewMessageData) => {
  loadSessions()
  if (data.applicationId !== selectedAppId.value) return
  if (data.senderId === currentUserId.value) return
  const msg: ChatMessageVO = {
    id: data.messageId,
    senderId: data.senderId,
    senderName: data.senderName,
    senderAvatar: data.senderAvatar || '',
    messageType: data.messageType,
    content: data.content,
    isRead: data.isRead ?? 1,
    sendTime: data.sendTime
  }
  messages.value.unshift(msg)
  refreshCurrentSession()
  scrollToTop()
}

useChatWebSocket({
  onNewMessage: handleWsNewMessage,
  enabled: computed(() => !!currentUserId.value)
})

const handleLoadMore = async () => {
  if (!hasMore.value || messages.value.length === 0 || !selectedAppId.value) return
  const lastId = messages.value[messages.value.length - 1].id
  await loadMessages(selectedAppId.value, lastId)
}

onMounted(async () => {
  await loadSessions()
  const chatParam = route.query.chat
  if (chatParam) {
    const appId = Number(chatParam)
    if (!isNaN(appId)) {
      await selectSession(appId)
    }
  }
})

watch(() => route.query.chat, async (newVal) => {
  if (newVal) {
    const appId = Number(newVal)
    if (!isNaN(appId)) {
      await selectSession(appId)
    }
  }
})
</script>

<template>
  <div class="im-page">
    <div class="sidebar">
      <div class="sidebar-header">消息</div>
      <div class="session-list">
        <div v-if="sessionsLoading" class="loading-state">加载中...</div>
        <div v-else-if="sessions.length === 0" class="empty-state">暂无会话</div>
        <div
          v-for="sessionItem in sessions"
          :key="sessionItem.applicationId"
          :class="['session-item', { active: selectedAppId === sessionItem.applicationId }]"
          @click="selectSession(sessionItem.applicationId)"
        >
          <div class="session-avatar">{{ (sessionItem.counterpartName || '对')[0] }}</div>
          <div class="session-info">
            <div class="session-header">
              <span class="counterpart-name">{{ sessionItem.counterpartName || '对方' }}</span>
              <span class="session-time">{{ formatSessionTime(sessionItem.lastMessageTime) }}</span>
            </div>
            <div class="session-body">
              <span class="session-preview">{{ truncate(sessionItem.lastMessage) }}</span>
            </div>
          </div>
          <div v-if="sessionItem.unreadCount > 0" class="unread-badge">
            {{ sessionItem.unreadCount > 99 ? '99+' : sessionItem.unreadCount }}
          </div>
        </div>
      </div>
    </div>

    <div class="chat-panel">
      <template v-if="selectedAppId && selectedSession">
        <div class="chat-header">
          <div class="chat-title">
            <h3>{{ session?.counterpartName || selectedSession.counterpartName || '对方' }}</h3>
            <span class="subtitle">{{ session?.taskTitle || selectedSession.taskTitle || '' }}</span>
          </div>
        </div>

        <div class="message-list" ref="messageListRef">
          <div v-if="chatLoading" class="loading-state">加载中...</div>
          <template v-else>
            <div
              v-for="msg in messages"
              :key="msg.id"
              :class="['message-item', msg.senderId === currentUserId ? 'self' : 'other']"
            >
              <div class="avatar">{{ (msg.senderName || '用')[0] }}</div>
              <div class="message-content">
                <div class="sender-name">{{ msg.senderName }}</div>
                <div v-if="msg.messageType === 2" class="bubble resume-bubble">
                  <div class="resume-card">
                    <span class="resume-icon">📄</span>
                    <div class="resume-info">
                      <span class="resume-name">{{ getAttachmentName(msg.content) }}</span>
                      <span class="resume-label">简历附件</span>
                    </div>
                    <a class="resume-download" :href="msg.content" target="_blank" title="下载简历">下载</a>
                  </div>
                </div>
                <div v-else class="bubble">{{ msg.content }}</div>
                <div class="message-time">{{ formatTime(msg.sendTime) }}</div>
              </div>
            </div>
            <div v-if="hasMore && messages.length > 0" class="load-more">
              <button @click="handleLoadMore">加载更多</button>
            </div>
            <div v-if="messages.length === 0" class="empty-state">暂无消息，开始沟通吧</div>
          </template>
        </div>

        <div class="input-area">
          <div v-if="isBlocked" class="block-tip">
            <span>{{ blockedTip }}</span>
          </div>
          <div class="input-row">
            <el-input
              v-model="inputText"
              type="textarea"
              :rows="2"
              :disabled="isBlocked || sending"
              placeholder="请输入消息..."
              maxlength="2000"
              show-word-limit
              @keydown.enter.prevent="handleSend"
            />
            <el-button
              v-if="!isHr"
              type="warning"
              :disabled="isBlocked || sendingResume"
              :loading="sendingResume"
              @click="handleSendResume"
            >
              发送简历
            </el-button>
            <el-button
              type="primary"
              :disabled="isBlocked || sending || !inputText.trim()"
              :loading="sending"
              @click="handleSend"
            >
              发送
            </el-button>
          </div>
        </div>
      </template>

      <template v-else>
        <div class="no-chat-selected">
          <div class="no-chat-icon">💬</div>
          <p>选择一个会话开始聊天</p>
        </div>
      </template>
    </div>
  </div>
</template>

<style scoped>
.im-page {
  display: flex;
  height: calc(100vh - 60px);
  background: #f5f7fa;
  overflow: hidden;
}

/* ---- Sidebar ---- */
.sidebar {
  width: 360px;
  min-width: 360px;
  background: #fff;
  border-right: 1px solid #e8e8e8;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.sidebar-header {
  padding: 20px 24px 16px;
  font-size: 20px;
  font-weight: 700;
  color: #1a1a2e;
  border-bottom: 1px solid #f0f0f5;
}

.session-list {
  flex: 1;
  overflow-y: auto;
  padding: 8px 0;
}

.loading-state,
.empty-state {
  text-align: center;
  padding: 60px 0;
  color: #999;
  font-size: 14px;
}

.session-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 24px;
  cursor: pointer;
  transition: background 0.15s;
  position: relative;
}

.session-item:hover {
  background: #f5f5f8;
}

.session-item.active {
  background: #e8f0fe;
}

.session-item.active:hover {
  background: #dde8fb;
}

.session-avatar {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  background: linear-gradient(135deg, #1762FB, #5856d6);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 17px;
  flex-shrink: 0;
}

.session-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 4px;
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
  white-space: nowrap;
}

.session-body {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.session-preview {
  font-size: 13px;
  color: #888;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.unread-badge {
  min-width: 18px;
  height: 18px;
  padding: 0 5px;
  border-radius: 9px;
  background: #e74c3c;
  color: #fff;
  font-size: 11px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

/* ---- Chat Panel ---- */
.chat-panel {
  flex: 1;
  display: flex;
  flex-direction: column;
  background: #f5f7fa;
  overflow: hidden;
}

.chat-header {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 16px 24px;
  background: #fff;
  border-bottom: 1px solid #f0f0f5;
}

.chat-title {
  text-align: center;
}

.chat-title h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #1a1a2e;
}

.subtitle {
  font-size: 12px;
  color: #999;
}

.message-list {
  flex: 1;
  overflow-y: auto;
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.load-more {
  text-align: center;
  padding: 8px 0;
}

.load-more button {
  background: none;
  border: none;
  color: #1762FB;
  font-size: 13px;
  cursor: pointer;
}

.message-item {
  display: flex;
  gap: 10px;
  max-width: 75%;
}

.message-item.self {
  align-self: flex-end;
  flex-direction: row-reverse;
}

.message-item.other {
  align-self: flex-start;
}

.avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: linear-gradient(135deg, #1762FB, #5856d6);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  flex-shrink: 0;
}

.message-content {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.self .message-content {
  align-items: flex-end;
}

.sender-name {
  font-size: 12px;
  color: #999;
}

.bubble {
  padding: 10px 14px;
  border-radius: 12px;
  font-size: 14px;
  line-height: 1.5;
  word-break: break-word;
  background: #fff;
  color: #1a1a2e;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06);
}

.self .bubble {
  background: #95ec69;
  color: #1a1a2e;
}

.message-time {
  font-size: 11px;
  color: #bbb;
}

.no-chat-selected {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: #999;
  background: #f5f7fa;
}

.no-chat-icon {
  font-size: 56px;
  margin-bottom: 16px;
  opacity: 0.6;
}

.no-chat-selected p {
  font-size: 15px;
  margin: 0;
}

.input-area {
  background: #fff;
  border-top: 1px solid #f0f0f5;
  padding: 12px 24px 16px;
}

.block-tip {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 12px;
  margin-bottom: 10px;
  background: #fff7e6;
  border: 1px solid #ffd591;
  border-radius: 8px;
  color: #d46b08;
  font-size: 13px;
}

.input-row {
  display: flex;
  gap: 12px;
  align-items: flex-end;
}

.input-row .el-input {
  flex: 1;
}

.input-row .el-button {
  height: 52px;
  padding: 0 24px;
}

.input-row .el-button + .el-button {
  margin-left: 8px;
}

.resume-bubble {
  padding: 8px !important;
  background: #f5f5ff !important;
}
.self .resume-bubble {
  background: #d0f0c0 !important;
}
.resume-card {
  display: flex;
  align-items: center;
  gap: 10px;
}
.resume-icon {
  font-size: 28px;
}
.resume-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
}
.resume-name {
  font-size: 13px;
  font-weight: 500;
  color: #1a1a2e;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.resume-label {
  font-size: 11px;
  color: #999;
}
.resume-download {
  font-size: 13px;
  color: #1762FB;
  text-decoration: none;
  white-space: nowrap;
  padding: 4px 10px;
  border: 1px solid #1762FB;
  border-radius: 6px;
}
.resume-download:hover {
  background: #1762FB;
  color: #fff;
}

/* ---- Scrollbar ---- */
.session-list::-webkit-scrollbar,
.message-list::-webkit-scrollbar {
  width: 4px;
}

.session-list::-webkit-scrollbar-thumb,
.message-list::-webkit-scrollbar-thumb {
  background: #ddd;
  border-radius: 2px;
}

.session-list::-webkit-scrollbar-track,
.message-list::-webkit-scrollbar-track {
  background: transparent;
}
</style>
