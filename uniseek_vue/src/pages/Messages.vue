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
import PdfPreview from '@/components/PdfPreview.vue'
import { View, Download, ChatDotRound, Plus, Picture, Document, Close } from '@element-plus/icons-vue'
import { useChatWebSocket, type WsNewMessageData } from '@/composables/useChatWebSocket'
import { uploadImage } from '@/api/upload'

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

const fileDialogVisible = ref(false)
const fileDialogUrl = ref('')
const pdfPreviewVisible = ref(false)
const imagePreviewVisible = ref(false)
const imagePreviewUrl = ref('')
const showActionMenu = ref(false)

const toggleActionMenu = () => {
  showActionMenu.value = !showActionMenu.value
}

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
      messages.value = [...list.reverse(), ...messages.value]
    } else {
      messages.value = list.reverse()
    }
  } catch {
    /* 错误已在拦截器处理 */
  }
}

const scrollToBottom = () => {
  nextTick(() => {
    const el = messageListRef.value
    if (el) {
      el.scrollTop = el.scrollHeight
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
    scrollToBottom()
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
    messages.value.push(msg)
    inputText.value = ''
    updateSessionInSidebar(msg)
    await refreshCurrentSession()
    scrollToBottom()
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
    messages.value.push(msg)
    updateSessionInSidebar(msg)
    await refreshCurrentSession()
    scrollToBottom()
    await loadSessions()
  } catch {
    /* 错误已在拦截器处理 */
  } finally {
    sendingResume.value = false
  }
}

const handleSendImage = async () => {
  if (isBlocked.value) {
    ElMessage.warning(blockedTip)
    return
  }
  if (!selectedAppId.value) return
  // 创建隐藏的文件输入框
  const input = document.createElement('input')
  input.type = 'file'
  input.accept = 'image/*'
  input.onchange = async () => {
    const file = input.files?.[0]
    if (!file) return
    try {
      const { url } = await uploadImage(file)
      if (!url) {
        ElMessage.error('图片上传失败')
        return
      }
      const msg = await sendMessage(selectedAppId.value, { messageType: 1, content: url })
      messages.value.push(msg)
      updateSessionInSidebar(msg)
      await refreshCurrentSession()
      scrollToBottom()
      await loadSessions()
    } catch {
      ElMessage.error('图片上传失败')
    }
  }
  input.click()
}

const getAttachmentName = (url: string) => {
  const name = url.substring(url.lastIndexOf('/') + 1) || '简历附件'
  return name.length > 30 ? name.substring(0, 27) + '...' : name
}

const openFileAction = (url: string) => {
  fileDialogUrl.value = url
  fileDialogVisible.value = true
}

const previewFile = () => {
  pdfPreviewVisible.value = true
  fileDialogVisible.value = false
}

const downloadFile = () => {
  const a = document.createElement('a')
  a.href = fileDialogUrl.value
  a.download = getAttachmentName(fileDialogUrl.value)
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  fileDialogVisible.value = false
}

const previewImage = (url: string) => {
  imagePreviewUrl.value = url
  imagePreviewVisible.value = true
}

const previewFileFromMsg = (url: string) => {
  fileDialogUrl.value = url
  pdfPreviewVisible.value = true
}

const downloadFileFromMsg = (url: string) => {
  const a = document.createElement('a')
  a.href = url
  a.download = getAttachmentName(url)
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
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
  const preview = msg.messageType === 2 ? '[简历附件]' : msg.messageType === 1 ? '[图片]' : msg.content
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
  messages.value.push(msg)
  refreshCurrentSession()
  scrollToBottom()
}

useChatWebSocket({
  onNewMessage: handleWsNewMessage,
  enabled: computed(() => !!currentUserId.value)
})

const handleLoadMore = async () => {
  if (!hasMore.value || messages.value.length === 0 || !selectedAppId.value) return
  const lastId = messages.value[0].id
  await loadMessages(selectedAppId.value, lastId)
}

const goToCompany = (enterpriseId?: number) => {
  if (enterpriseId) {
    router.push(`/company?id=${enterpriseId}`)
  }
}

const goToJobDetail = (taskId?: number) => {
  if (taskId) {
    router.push(`/jobs/${taskId}`)
  }
}

const ensureSessionInList = async (appId: number) => {
  const exists = sessions.value.some(s => s.applicationId === appId)
  if (!exists) {
    await loadSessions()
  }
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
      await ensureSessionInList(appId)
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
            <div class="session-avatar">
              <img v-if="sessionItem.counterpartAvatar" :src="sessionItem.counterpartAvatar" class="avatar-img" />
              <span v-else>{{ (sessionItem.counterpartName || '对')[0] }}</span>
            </div>
          <div class="session-info">
            <div class="session-header">
              <div class="session-name-wrap">
                <span class="counterpart-name">{{ sessionItem.counterpartName || '对方' }}</span>
                <span v-if="sessionItem.counterpartCompany" class="company-tag session-company-tag">
                  <span class="at-symbol">@</span>
                  <a class="company-link" @click.stop="goToCompany(sessionItem.enterpriseId)">
                    {{ sessionItem.counterpartCompany }}
                  </a>
                </span>
              </div>
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
            <h3>
              <span class="counterpart-name">{{ session?.counterpartName || selectedSession.counterpartName || '对方' }}</span>
              <span v-if="session?.counterpartCompany || selectedSession?.counterpartCompany" class="company-tag">
                <span class="at-symbol">@</span>
                <a class="company-link" @click="goToCompany(session?.enterpriseId || selectedSession?.enterpriseId)">
                  {{ session?.counterpartCompany || selectedSession?.counterpartCompany }}
                </a>
              </span>
            </h3>
            <span class="subtitle">
              <a v-if="session?.taskTitle || selectedSession?.taskTitle" class="task-link" @click="goToJobDetail(session?.taskId || selectedSession?.taskId)">
                {{ session?.taskTitle || selectedSession?.taskTitle }}
              </a>
            </span>
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
              <div class="avatar">
                <img v-if="msg.senderAvatar" :src="msg.senderAvatar" class="avatar-img" />
                <span v-else>{{ (msg.senderName || '用')[0] }}</span>
              </div>
              <div class="message-content">
                <div class="sender-name">
                  <span>{{ msg.senderName }}</span>
                  <span v-if="msg.senderId !== currentUserId && (session?.counterpartCompany || selectedSession?.counterpartCompany)" class="company-tag">
                    <span class="at-symbol">@</span>
                    <a class="company-link" @click="goToCompany(session?.enterpriseId || selectedSession?.enterpriseId)">
                      {{ session?.counterpartCompany || selectedSession?.counterpartCompany }}
                    </a>
                  </span>
                </div>
                <div v-if="msg.messageType === 2" class="bubble resume-bubble">
                  <div class="resume-card">
                    <el-icon :size="28" class="resume-icon"><Document /></el-icon>
                    <div class="resume-info">
                      <span class="resume-name">{{ getAttachmentName(msg.content) }}</span>
                      <span class="resume-label">简历附件</span>
                    </div>
                  </div>
                  <div class="resume-actions">
                    <div class="resume-action-btn" @click="previewFileFromMsg(msg.content)" title="预览">
                      <el-icon :size="20"><View /></el-icon>
                      <span class="action-label">预览</span>
                    </div>
                    <div class="resume-action-btn" @click="downloadFileFromMsg(msg.content)" title="下载">
                      <el-icon :size="20"><Download /></el-icon>
                      <span class="action-label">下载</span>
                    </div>
                  </div>
                </div>
                <div v-else-if="msg.messageType === 1" class="bubble image-bubble">
                  <img class="chat-image" :src="msg.content" alt="图片消息" @click="previewImage(msg.content)" />
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
          <div class="input-bar">
            <div class="action-wrap">
              <el-button
                v-if="!isHr"
                class="bar-btn bar-plus-btn"
                :class="{ active: showActionMenu }"
                :disabled="isBlocked"
                @click="toggleActionMenu"
                title="更多"
              >
                <el-icon :size="20"><Plus /></el-icon>
              </el-button>
              <Transition name="action-fade">
                <div v-if="showActionMenu" class="action-menu-backdrop" @click="showActionMenu = false"></div>
              </Transition>
              <Transition name="action-fade">
                <div v-if="showActionMenu" class="action-menu">
                  <div class="action-menu-item" @click="showActionMenu = false; handleSendImage()">
                    <div class="action-icon"><el-icon :size="22"><Picture /></el-icon></div>
                    <span class="action-label">上传图片</span>
                  </div>
                  <div class="action-menu-item" @click="showActionMenu = false; handleSendResume()">
                    <div class="action-icon"><el-icon :size="22"><Document /></el-icon></div>
                    <span class="action-label">发送简历</span>
                  </div>
                </div>
              </Transition>
            </div>
            <el-input
              v-model="inputText"
              :disabled="isBlocked || sending"
              placeholder="请输入消息..."
              maxlength="2000"
              @keydown.enter.prevent="handleSend"
            />
            <el-button
              class="bar-btn bar-send-btn"
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
          <div class="no-chat-icon"><el-icon :size="56"><ChatDotRound /></el-icon></div>
          <p>选择一个会话开始聊天</p>
        </div>
      </template>
    </div>

    <el-dialog v-model="fileDialogVisible" title="附件简历" width="300px" align-center>
      <div class="file-action-buttons">
        <el-button type="primary" size="large" @click="previewFile" class="file-action-btn">
          <el-icon><View /></el-icon>预览
        </el-button>
        <el-button type="primary" size="large" @click="downloadFile" class="file-action-btn">
          <el-icon><Download /></el-icon>下载
        </el-button>
      </div>
    </el-dialog>

    <!-- 图片预览轻量弹窗 -->
    <Transition name="lightbox-fade">
      <div v-if="imagePreviewVisible" class="lightbox-overlay" @click.self="imagePreviewVisible = false">
        <img :src="imagePreviewUrl" class="lightbox-image" alt="图片预览" />
        <button class="lightbox-close" @click="imagePreviewVisible = false">
          <el-icon :size="24"><Close /></el-icon>
        </button>
      </div>
    </Transition>

    <PdfPreview v-model:visible="pdfPreviewVisible" :url="fileDialogUrl" />
  </div>
</template>

<style scoped>
.im-page {
  display: flex;
  height: calc(100vh - 60px);
  max-width: 1200px;
  margin: 0 auto;
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
  overflow: hidden;
}
.session-avatar .avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
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
  align-items: flex-start;
  gap: 4px;
}
.session-name-wrap {
  flex: 1;
  min-width: 0;
  display: inline-flex;
  align-items: center;
  gap: 2px;
  flex-wrap: wrap;
}
.session-name-wrap .counterpart-name {
  font-size: 15px;
  font-weight: 600;
  color: #1a1a2e;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 120px;
}
.session-name-wrap .session-company-tag {
  display: inline-flex;
  align-items: center;
  gap: 1px;
  min-width: 0;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
}
.session-name-wrap .session-company-tag .at-symbol {
  font-size: 11px;
  color: #999;
  font-weight: 400;
  flex-shrink: 0;
}
.session-name-wrap .session-company-tag .company-link {
  font-size: 12px;
  font-weight: 400;
  color: #1762FB;
  cursor: pointer;
  text-decoration: none;
  transition: opacity 0.2s;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.session-name-wrap .session-company-tag .company-link:hover {
  opacity: 0.75;
  text-decoration: underline;
}

.session-time {
  font-size: 12px;
  color: #999;
  white-space: nowrap;
  flex-shrink: 0;
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
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  flex-wrap: wrap;
}

.counterpart-name {
  white-space: nowrap;
}

.company-tag {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  white-space: nowrap;
}

.at-symbol {
  color: #999;
  font-weight: 400;
}

.company-link {
  color: #1762FB;
  font-weight: 500;
  cursor: pointer;
  text-decoration: none;
  transition: opacity 0.2s;
}

.company-link:hover {
  opacity: 0.75;
  text-decoration: underline;
}

.subtitle {
  font-size: 12px;
  color: #999;
}

.task-link {
  color: #1762FB;
  cursor: pointer;
  text-decoration: none;
  transition: opacity 0.2s;
}

.task-link:hover {
  opacity: 0.75;
  text-decoration: underline;
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
  overflow: hidden;
}
.avatar .avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
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
  display: inline-flex;
  align-items: center;
  gap: 2px;
  flex-wrap: wrap;
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
  margin-bottom: 16px;
  opacity: 0.6;
}
.no-chat-icon .el-icon {
  display: block;
}

.no-chat-selected p {
  font-size: 15px;
  margin: 0;
}

.input-area {
  background: #fff;
  padding: 6px 16px 12px;
  border-top: 1px solid #e8e8e8;
}

.block-tip {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 12px;
  margin-bottom: 8px;
  background: #fff7e6;
  border: 1px solid #ffd591;
  border-radius: 8px;
  color: #d46b08;
  font-size: 13px;
}

.input-bar {
  display: flex;
  align-items: flex-end;
  gap: 8px;
}

/* ── 加号按钮 ── */
.bar-plus-btn {
  width: 40px;
  height: 40px;
  padding: 0;
  border-radius: 10px;
  flex-shrink: 0;
  border: 1px solid #e8e8e8;
  background: #f7f8fa;
  color: #666;
  font-size: 20px;
  transition: all 0.2s;
}
.bar-plus-btn:hover {
  background: #eff0f2;
  border-color: #1762FB;
  color: #1762FB;
}
.bar-plus-btn.active {
  background: #1762FB;
  border-color: #1762FB;
  color: #fff;
}

/* ── 操作菜单 ── */
.action-wrap {
  position: relative;
}
.action-menu-backdrop {
  position: fixed;
  inset: 0;
  z-index: 9;
}
.action-menu {
  position: absolute;
  bottom: calc(100% + 8px);
  left: 0;
  z-index: 10;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.12);
  padding: 8px;
  display: flex;
  flex-direction: row;
  gap: 4px;
}
.action-menu-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  padding: 10px 16px;
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.15s;
  white-space: nowrap;
}
.action-menu-item:hover {
  background: #f0f4ff;
}
.action-icon {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: #f0f4ff;
  color: #1762FB;
  display: flex;
  align-items: center;
  justify-content: center;
}
.action-menu-item:hover .action-icon {
  background: #dde6ff;
}
.action-label {
  font-size: 12px;
  color: #333;
  font-weight: 500;
}

/* ── 菜单动画 ── */
.action-fade-enter-active,
.action-fade-leave-active {
  transition: opacity 0.2s, transform 0.2s;
}
.action-fade-enter-from,
.action-fade-leave-to {
  opacity: 0;
  transform: translateY(4px);
}

/* ── 输入框 ── */
.input-bar .el-input {
  flex: 1;
}
.input-bar .el-input :deep(.el-input__wrapper) {
  box-shadow: none !important;
  border: 1px solid #e8e8e8;
  border-radius: 10px;
  padding: 0 12px;
  background: #f7f8fa;
  min-height: 40px;
  transition: border-color 0.2s, box-shadow 0.2s;
}
.input-bar .el-input :deep(.el-input__wrapper:hover) {
  border-color: #1762FB;
}
.input-bar .el-input :deep(.el-input__wrapper.is-focus) {
  border-color: #1762FB;
  box-shadow: 0 0 0 2px rgba(23, 98, 251, 0.1) !important;
}
.input-bar .el-input :deep(.el-input__inner) {
  font-size: 14px;
  height: 38px;
  line-height: 38px;
  background: transparent;
  border: none;
  padding: 0;
}
.input-bar .el-input :deep(.el-input__count) {
  display: none;
}

/* ── 发送按钮 ── */
.bar-send-btn {
  height: 40px;
  min-width: 68px;
  padding: 0 18px;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 500;
  flex-shrink: 0;
  border: none;
}
.bar-send-btn.is-disabled {
  background: #e8e8e8 !important;
  color: #bbb !important;
}

.resume-bubble {
  padding: 0 !important;
  background: #f5f5ff !important;
  position: relative;
  overflow: hidden;
}
.self .resume-bubble {
  background: #d0f0c0 !important;
}
.resume-card {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 14px;
}
.resume-icon {
  flex-shrink: 0;
  color: #1762FB;
}
.self .resume-icon {
  color: #389e0d;
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

/* ── 简历操作按钮：浮层模式，hover 时从右侧滑入 ── */
.resume-actions {
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 0 10px;
  pointer-events: none;
  transform: translateX(100%);
  transition: transform 0.25s ease;
}
.resume-bubble:hover .resume-actions {
  transform: translateX(0);
  pointer-events: auto;
}

/* 渐变遮罩 — 跟随气泡背景色，hover 时从右侧滑入覆盖整个气泡 */
.resume-actions::before {
  content: '';
  position: absolute;
  top: 0;
  bottom: 0;
  left: -500px;
  width: calc(100% + 500px);
  z-index: -1;
  pointer-events: none;
  transform: translateX(100%);
  transition: transform 0.25s ease;
}
.resume-bubble:hover .resume-actions::before {
  transform: translateX(0);
}
.resume-bubble:not(.self) .resume-actions::before {
  background: rgba(245, 245, 255, 0.5);
}
.self .resume-actions::before {
  background: rgba(208, 240, 192, 0.5);
}

.resume-action-btn {
  position: relative;
  z-index: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  width: 48px;
  padding: 4px 0;
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.15s;
  color: #666;
  background: #fff;
}
.resume-action-btn:hover {
  background: #e8ecf7;
  color: #1762FB;
}
.self .resume-action-btn {
  background: #fff;
}
.self .resume-action-btn:hover {
  background: #c8e8b0;
  color: #389e0d;
}
.resume-action-btn .action-label {
  font-size: 11px;
  font-weight: 500;
  white-space: nowrap;
}

/* ── 文件选择弹窗按钮 ── */
.file-action-buttons {
  display: flex;
  gap: 16px;
  justify-content: center;
  padding: 8px 0;
}
.file-action-btn {
  flex: 1;
}

/* ── 图片消息气泡 ── */
.image-bubble {
  padding: 4px !important;
  background: transparent !important;
  box-shadow: none !important;
  max-width: 280px;
}
.chat-image {
  display: block;
  width: 100%;
  max-height: 300px;
  object-fit: cover;
  border-radius: 8px;
  cursor: pointer;
  transition: opacity 0.2s;
}
.chat-image:hover {
  opacity: 0.9;
}

/* ── 图片预览轻量弹窗 ── */
.lightbox-overlay {
  position: fixed;
  inset: 0;
  z-index: 2000;
  background: rgba(0, 0, 0, 0.85);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
.lightbox-image {
  max-width: 92vw;
  max-height: 88vh;
  object-fit: contain;
  border-radius: 6px;
  cursor: default;
  box-shadow: 0 8px 40px rgba(0, 0, 0, 0.5);
}
.lightbox-close {
  position: fixed;
  top: 20px;
  right: 20px;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: none;
  background: rgba(255, 255, 255, 0.15);
  color: #fff;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s;
  z-index: 2001;
}
.lightbox-close:hover {
  background: rgba(255, 255, 255, 0.3);
}

/* ── 预览弹窗过渡动画 ── */
.lightbox-fade-enter-active,
.lightbox-fade-leave-active {
  transition: opacity 0.25s ease;
}
.lightbox-fade-enter-from,
.lightbox-fade-leave-to {
  opacity: 0;
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
