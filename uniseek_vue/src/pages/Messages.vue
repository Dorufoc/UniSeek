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
                  <div v-if="!isHr" class="action-menu-item" @click="showActionMenu = false; handleSendResume()">
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
/* 消息页面 - 世界一流聊天界面设计 */
.im-page {
  display: flex;
  width: calc(100% - 20px);
  max-width: 1400px;
  height: calc(100vh - 60px - 20px);
  margin: 10px auto;
  background: #ffffff;
  border-radius: 24px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.08), 0 0 0 1px rgba(0, 0, 0, 0.04);
  overflow: hidden;
  backdrop-filter: blur(10px);
  flex-shrink: 0;
  box-sizing: border-box;
}

/* ---- 侧边栏 - 会话列表 ---- */
.sidebar {
  width: 380px;
  min-width: 380px;
  height: 100%;
  background: linear-gradient(180deg, #fafbfc 0%, #f5f7fa 100%);
  border-right: 1px solid rgba(0, 0, 0, 0.04);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  position: relative;
}

.sidebar::after {
  content: '';
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  width: 1px;
  background: linear-gradient(180deg, transparent, rgba(23, 98, 251, 0.08), transparent);
}

.sidebar-header {
  padding: 28px 28px 20px;
  font-size: 24px;
  font-weight: 700;
  color: #1a1a2e;
  letter-spacing: -0.02em;
  background: linear-gradient(180deg, #ffffff 0%, #fafbfc 100%);
  border-bottom: 1px solid rgba(0, 0, 0, 0.04);
  position: relative;
}

.sidebar-header::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 28px;
  right: 28px;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(23, 98, 251, 0.1), transparent);
}

.session-list {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
  padding: 12px 0;
  scroll-behavior: smooth;
}

.session-list::-webkit-scrollbar {
  width: 6px;
}

.session-list::-webkit-scrollbar-track {
  background: transparent;
}

.session-list::-webkit-scrollbar-thumb {
  background: rgba(0, 0, 0, 0.1);
  border-radius: 3px;
}

.session-list::-webkit-scrollbar-thumb:hover {
  background: rgba(0, 0, 0, 0.15);
}

.loading-state,
.empty-state {
  text-align: center;
  padding: 80px 0;
  color: #8b95a7;
  font-size: 14px;
  font-weight: 400;
}

/* 会话项 - 精致设计 */
.session-item {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px 24px;
  cursor: pointer;
  transition: background 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  margin: 0 12px;
  border-radius: 14px;
}

.session-item:hover {
  background: rgba(23, 98, 251, 0.04);
}

.session-item.active {
  background: linear-gradient(135deg, rgba(23, 98, 251, 0.08) 0%, rgba(23, 98, 251, 0.04) 100%);
  box-shadow: 0 2px 8px rgba(23, 98, 251, 0.08);
}

.session-item.active::before {
  content: '';
  position: absolute;
  left: 0;
  top: 50%;
  transform: translateY(-50%);
  width: 3px;
  height: 24px;
  background: linear-gradient(180deg, #1762FB 0%, #2d7bff 100%);
  border-radius: 0 3px 3px 0;
}

.session-item.active:hover {
  background: linear-gradient(135deg, rgba(23, 98, 251, 0.1) 0%, rgba(23, 98, 251, 0.06) 100%);
}

.session-avatar {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: linear-gradient(135deg, #1762FB 0%, #5856d6 100%);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  font-weight: 600;
  flex-shrink: 0;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(23, 98, 251, 0.2);
  position: relative;
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
  gap: 6px;
}

.session-header {
  display: flex;
  align-items: flex-start;
  gap: 6px;
}

.session-name-wrap {
  flex: 1;
  min-width: 0;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  flex-wrap: wrap;
}

.session-name-wrap .counterpart-name {
  font-size: 15px;
  font-weight: 600;
  color: #1a1a2e;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 140px;
  letter-spacing: -0.01em;
}

.session-name-wrap .session-company-tag {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  min-width: 0;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
}

.session-name-wrap .session-company-tag .at-symbol {
  font-size: 11px;
  color: #a0aab8;
  font-weight: 400;
  flex-shrink: 0;
}

.session-name-wrap .session-company-tag .company-link {
  font-size: 12px;
  font-weight: 500;
  color: #1762FB;
  cursor: pointer;
  text-decoration: none;
  transition: all 0.2s;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.session-name-wrap .session-company-tag .company-link:hover {
  color: #0056b3;
  text-decoration: underline;
  text-underline-offset: 2px;
}

.session-time {
  font-size: 12px;
  color: #a0aab8;
  white-space: nowrap;
  flex-shrink: 0;
  font-weight: 500;
}

.session-body {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.session-preview {
  font-size: 13.5px;
  color: #6b7585;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  line-height: 1.4;
}

.unread-badge {
  min-width: 20px;
  height: 20px;
  padding: 0 6px;
  border-radius: 10px;
  background: linear-gradient(135deg, #ff4757 0%, #ff6b81 100%);
  color: #fff;
  font-size: 11px;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  box-shadow: 0 2px 6px rgba(255, 71, 87, 0.3);
  animation: badgePulse 2s ease-in-out infinite;
}

@keyframes badgePulse {
  0%, 100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.05);
  }
}

/* ---- 聊天面板 ---- */
.chat-panel {
  flex: 1;
  display: flex;
  flex-direction: column;
  background: linear-gradient(180deg, #fafbfc 0%, #f5f7fa 100%);
  overflow: hidden;
  position: relative;
}

.chat-header {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px 32px;
  background: linear-gradient(180deg, #ffffff 0%, #fafbfc 100%);
  border-bottom: 1px solid rgba(0, 0, 0, 0.04);
  position: relative;
}

.chat-header::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 32px;
  right: 32px;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(23, 98, 251, 0.1), transparent);
}

.chat-title {
  text-align: center;
}

.chat-title h3 {
  margin: 0;
  font-size: 17px;
  font-weight: 600;
  color: #1a1a2e;
  letter-spacing: -0.01em;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
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
  color: #a0aab8;
  font-weight: 400;
}

.company-link {
  color: #1762FB;
  font-weight: 500;
  cursor: pointer;
  text-decoration: none;
  transition: all 0.2s;
}

.company-link:hover {
  color: #0056b3;
  text-decoration: underline;
  text-underline-offset: 2px;
}

.subtitle {
  font-size: 13px;
  color: #8b95a7;
  margin-top: 2px;
  font-weight: 400;
}

.task-link {
  color: #1762FB;
  cursor: pointer;
  text-decoration: none;
  transition: all 0.2s;
}

.task-link:hover {
  color: #0056b3;
  text-decoration: underline;
  text-underline-offset: 2px;
}

/* 消息列表 - 沉浸式对话空间 */
.message-list {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
  padding: 28px 32px;
  display: flex;
  flex-direction: column;
  gap: 20px;
  scroll-behavior: smooth;
}

.message-list::-webkit-scrollbar {
  width: 6px;
}

.message-list::-webkit-scrollbar-track {
  background: transparent;
}

.message-list::-webkit-scrollbar-thumb {
  background: rgba(0, 0, 0, 0.1);
  border-radius: 3px;
}

.message-list::-webkit-scrollbar-thumb:hover {
  background: rgba(0, 0, 0, 0.15);
}

.load-more {
  text-align: center;
  padding: 12px 0;
}

.load-more button {
  background: none;
  border: none;
  color: #1762FB;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  padding: 8px 16px;
  border-radius: 8px;
  transition: all 0.2s;
}

.load-more button:hover {
  background: rgba(23, 98, 251, 0.06);
}

/* 消息项 - 精致气泡设计 */
.message-item {
  display: flex;
  gap: 12px;
  max-width: 70%;
  animation: messageSlideIn 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

@keyframes messageSlideIn {
  from {
    opacity: 0;
    transform: translateY(12px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.message-item.self {
  align-self: flex-end;
  flex-direction: row-reverse;
}

.message-item.other {
  align-self: flex-start;
}

.avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: linear-gradient(135deg, #1762FB 0%, #5856d6 100%);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 15px;
  font-weight: 600;
  flex-shrink: 0;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(23, 98, 251, 0.2);
  position: relative;
}

.avatar .avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.avatar::after {
  content: '';
  position: absolute;
  inset: -2px;
  border-radius: 50%;
  background: linear-gradient(135deg, rgba(23, 98, 251, 0.2), rgba(88, 86, 214, 0.2));
  opacity: 0;
  transition: opacity 0.3s;
}

.message-item:hover .avatar::after {
  opacity: 1;
}

.message-content {
  display: flex;
  flex-direction: column;
  gap: 6px;
  min-width: 0;
}

.self .message-content {
  align-items: flex-end;
}

.sender-name {
  font-size: 12.5px;
  color: #8b95a7;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  flex-wrap: wrap;
  font-weight: 500;
}

/* 气泡 - 核心视觉元素 */
.bubble {
  padding: 12px 16px;
  border-radius: 6px 18px 18px 18px;
  font-size: 14.5px;
  line-height: 1.6;
  word-break: break-word;
  background: #ffffff;
  color: #1a1a2e;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06), 0 0 0 1px rgba(0, 0, 0, 0.04);
  position: relative;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  max-width: 100%;
}

.bubble:hover {
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08), 0 0 0 1px rgba(0, 0, 0, 0.06);
  transform: translateY(-1px);
}

.self .bubble {
  background: linear-gradient(135deg, #1762FB 0%, #2d7bff 100%);
  color: #ffffff;
  box-shadow: 0 4px 16px rgba(23, 98, 251, 0.25), 0 0 0 1px rgba(23, 98, 251, 0.1);
  border-radius: 18px 6px 18px 18px;
}

.self .bubble:hover {
  box-shadow: 0 6px 20px rgba(23, 98, 251, 0.3), 0 0 0 1px rgba(23, 98, 251, 0.15);
}

.message-time {
  font-size: 11px;
  color: #a0aab8;
  font-weight: 400;
  padding: 0 4px;
  opacity: 0.8;
}

/* 未选择聊天状态 */
.no-chat-selected {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: #8b95a7;
  background: linear-gradient(180deg, #fafbfc 0%, #f5f7fa 100%);
}

.no-chat-icon {
  margin-bottom: 20px;
  opacity: 0.5;
  animation: floatIcon 3s ease-in-out infinite;
}

@keyframes floatIcon {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-8px);
  }
}

.no-chat-icon .el-icon {
  display: block;
}

.no-chat-selected p {
  font-size: 16px;
  margin: 0;
  font-weight: 500;
  color: #6b7585;
}

/* 输入区域 - 精致交互 */
.input-area {
  background: #ffffff;
  padding: 16px 28px 20px;
  border-top: 1px solid rgba(0, 0, 0, 0.04);
  position: relative;
}

.input-area::before {
  content: '';
  position: absolute;
  top: 0;
  left: 28px;
  right: 28px;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(0, 0, 0, 0.08), transparent);
}

.block-tip {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 14px;
  margin-bottom: 12px;
  background: linear-gradient(135deg, #fff7e6 0%, #ffedd5 100%);
  border: 1px solid rgba(255, 213, 145, 0.6);
  border-radius: 12px;
  color: #d46b08;
  font-size: 13px;
  font-weight: 500;
  box-shadow: 0 2px 8px rgba(212, 107, 8, 0.1);
}

.input-bar {
  display: flex;
  align-items: flex-end;
  gap: 12px;
}

/* 加号按钮 */
.bar-plus-btn {
  width: 48px;
  height: 48px;
  padding: 0;
  border-radius: 14px;
  flex-shrink: 0;
  border: 1.5px solid #e8ecf1;
  background: #fafbfc;
  color: #6b7585;
  font-size: 20px;
  transition: background 0.2s cubic-bezier(0.4, 0, 0.2, 1), border-color 0.2s cubic-bezier(0.4, 0, 0.2, 1), color 0.2s cubic-bezier(0.4, 0, 0.2, 1), border-radius 0.2s cubic-bezier(0.4, 0, 0.2, 1), transform 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

.bar-plus-btn:hover {
  background: #ffffff;
  border-color: #1762FB;
  color: #1762FB;
}

.bar-plus-btn:active {
  background: linear-gradient(135deg, #1762FB 0%, #2d7bff 100%);
  border-color: #1762FB;
  color: #fff;
  border-radius: 50%;
  transform: rotate(45deg);
  box-shadow: 0 4px 12px rgba(23, 98, 251, 0.25);
}

.bar-plus-btn.active {
  background: linear-gradient(135deg, #1762FB 0%, #2d7bff 100%);
  border-color: #1762FB;
  color: #fff;
  border-radius: 50%;
  transform: rotate(45deg);
  box-shadow: 0 4px 12px rgba(23, 98, 251, 0.25);
}

/* 操作菜单 */
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
  bottom: calc(100% + 12px);
  left: 0;
  z-index: 10;
  background: #ffffff;
  border-radius: 16px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.12), 0 0 0 1px rgba(0, 0, 0, 0.04);
  padding: 8px;
  display: flex;
  flex-direction: row;
  gap: 6px;
  animation: menuSlideUp 0.25s cubic-bezier(0.4, 0, 0.2, 1);
}

@keyframes menuSlideUp {
  from {
    opacity: 0;
    transform: translateY(8px) scale(0.96);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

.action-menu-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  padding: 12px 20px;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  white-space: nowrap;
}

.action-menu-item:hover {
  background: linear-gradient(135deg, #f0f4ff 0%, #e8f0ff 100%);
  transform: translateY(-2px);
}

.action-icon {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  background: linear-gradient(135deg, #f0f4ff 0%, #e8f0ff 100%);
  color: #1762FB;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.action-menu-item:hover .action-icon {
  background: linear-gradient(135deg, #1762FB 0%, #2d7bff 100%);
  color: #ffffff;
  transform: scale(1.05);
  box-shadow: 0 4px 12px rgba(23, 98, 251, 0.3);
}

.action-label {
  font-size: 12.5px;
  color: #1a1a2e;
  font-weight: 500;
}

/* 菜单动画 */
.action-fade-enter-active,
.action-fade-leave-active {
  transition: opacity 0.2s cubic-bezier(0.4, 0, 0.2, 1), transform 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

.action-fade-enter-from,
.action-fade-leave-to {
  opacity: 0;
  transform: translateY(8px) scale(0.96);
}

/* 输入框 */
.input-bar .el-input {
  flex: 1;
}

.input-bar .el-input :deep(.el-input__wrapper) {
  box-shadow: none !important;
  border: 1.5px solid #e8ecf1;
  border-radius: 14px;
  padding: 0 16px;
  background: #fafbfc;
  min-height: 48px;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

.input-bar .el-input :deep(.el-input__wrapper:hover) {
  border-color: #c5d1e0;
  background: #ffffff;
}

.input-bar .el-input :deep(.el-input__wrapper.is-focus) {
  border-color: #1762FB;
  background: #ffffff;
  box-shadow: 0 0 0 4px rgba(23, 98, 251, 0.08) !important;
}

.input-bar .el-input :deep(.el-input__inner) {
  font-size: 14.5px;
  height: 46px;
  line-height: 46px;
  background: transparent;
  border: none;
  padding: 0;
  color: #1a1a2e;
}

.input-bar .el-input :deep(.el-input__inner::placeholder) {
  color: #a0aab8;
}

.input-bar .el-input :deep(.el-input__count) {
  display: none;
}

/* 发送按钮 */
.bar-send-btn {
  height: 48px;
  min-width: 80px;
  padding: 0 24px;
  border-radius: 14px;
  font-size: 14.5px;
  font-weight: 600;
  flex-shrink: 0;
  border: none;
  background: linear-gradient(135deg, #1762FB 0%, #2d7bff 100%);
  box-shadow: 0 4px 12px rgba(23, 98, 251, 0.25);
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

.bar-send-btn:hover:not(:disabled):not(.is-disabled) {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(23, 98, 251, 0.35);
}

.bar-send-btn:active:not(:disabled):not(.is-disabled) {
  transform: translateY(0);
}

.bar-send-btn.is-disabled {
  background: #e8ecf1 !important;
  color: #a0aab8 !important;
  box-shadow: none !important;
}

/* 简历气泡 */
.resume-bubble {
  padding: 0 !important;
  background: linear-gradient(135deg, #f5f5ff 0%, #eef2ff 100%) !important;
  position: relative;
  overflow: hidden;
  border: 1px solid rgba(23, 98, 251, 0.1);
}

.self .resume-bubble {
  background: linear-gradient(135deg, #e0f0ff 0%, #d0e8ff 100%) !important;
  border-color: rgba(23, 98, 251, 0.15);
}

.resume-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 16px;
}

.resume-icon {
  flex-shrink: 0;
  color: #1762FB;
  filter: drop-shadow(0 2px 4px rgba(23, 98, 251, 0.2));
}

.self .resume-icon {
  color: #0056b3;
}

.resume-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
  gap: 2px;
}

.resume-name {
  font-size: 13.5px;
  font-weight: 600;
  color: #1a1a2e;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.resume-label {
  font-size: 12px;
  color: #8b95a7;
  font-weight: 400;
}

/* 简历操作按钮 */
.resume-actions {
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 0 12px;
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.25s ease;
}

.resume-bubble:hover .resume-actions {
  opacity: 1;
  pointer-events: auto;
}

.resume-actions::before {
  content: '';
  position: absolute;
  top: 0;
  bottom: 0;
  left: 0;
  right: 0;
  z-index: -1;
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.25s ease;
}

.resume-bubble:hover .resume-actions::before {
  opacity: 1;
}

.resume-bubble:not(.self) .resume-actions::before {
  background: rgba(245, 245, 255, 0.6);
  backdrop-filter: blur(4px);
}

.self .resume-actions::before {
  background: rgba(208, 232, 255, 0.6);
  backdrop-filter: blur(4px);
}

.resume-action-btn {
  position: relative;
  z-index: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
  width: 52px;
  padding: 6px 0;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  color: #6b7585;
  background: #ffffff;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.resume-action-btn:hover {
  background: #f0f4ff;
  color: #1762FB;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(23, 98, 251, 0.2);
}

.self .resume-action-btn {
  background: #ffffff;
}

.self .resume-action-btn:hover {
  background: #e0f0ff;
  color: #0056b3;
}

.resume-action-btn .action-label {
  font-size: 11px;
  font-weight: 600;
  white-space: nowrap;
}

/* 文件选择弹窗按钮 */
.file-action-buttons {
  display: flex;
  gap: 12px;
  justify-content: center;
  padding: 12px 0;
}

.file-action-btn {
  flex: 1;
  border-radius: 12px;
  font-weight: 500;
}

/* 图片消息气泡 */
.image-bubble {
  padding: 4px !important;
  background: transparent !important;
  box-shadow: none !important;
  max-width: 300px;
}

.chat-image {
  display: block;
  width: 100%;
  max-height: 320px;
  object-fit: cover;
  border-radius: 14px;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
}

.chat-image:hover {
  transform: scale(1.02);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
}

/* 图片预览弹窗 */
.lightbox-overlay {
  position: fixed;
  inset: 0;
  z-index: 2000;
  background: rgba(0, 0, 0, 0.92);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  backdrop-filter: blur(8px);
  animation: lightboxFadeIn 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

@keyframes lightboxFadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

.lightbox-image {
  max-width: 92vw;
  max-height: 88vh;
  object-fit: contain;
  border-radius: 8px;
  cursor: default;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
  animation: lightboxZoomIn 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

@keyframes lightboxZoomIn {
  from {
    opacity: 0;
    transform: scale(0.9);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

.lightbox-close {
  position: fixed;
  top: 24px;
  right: 24px;
  width: 44px;
  height: 44px;
  border-radius: 50%;
  border: none;
  background: rgba(255, 255, 255, 0.15);
  color: #fff;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  z-index: 2001;
  backdrop-filter: blur(8px);
}

.lightbox-close:hover {
  background: rgba(255, 255, 255, 0.25);
  transform: rotate(90deg) scale(1.1);
}

/* 预览弹窗过渡动画 */
.lightbox-fade-enter-active,
.lightbox-fade-leave-active {
  transition: opacity 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.lightbox-fade-enter-from,
.lightbox-fade-leave-to {
  opacity: 0;
}

/* 响应式优化 */
@media (max-width: 1200px) {
  .im-page {
    margin: 16px;
    height: calc(100vh - 92px);
  }

  .sidebar {
    width: 320px;
    min-width: 320px;
  }
}

@media (max-width: 900px) {
  .im-page {
    flex-direction: column;
    margin: 12px;
    height: calc(100vh - 84px);
  }

  .sidebar {
    width: 100%;
    min-width: 100%;
    height: 40%;
    border-right: none;
    border-bottom: 1px solid rgba(0, 0, 0, 0.04);
  }

  .chat-panel {
    height: 60%;
  }

  .message-list {
    padding: 20px 16px;
  }

  .message-item {
    max-width: 85%;
  }

  .input-area {
    padding: 12px 16px 16px;
  }
}
</style>
