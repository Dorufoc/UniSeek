<script setup lang="ts">
import { ref, onMounted, computed, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/stores/user'
import {
  getChatSession,
  getChatMessages,
  sendMessage,
  markSessionRead,
  type ChatSessionVO,
  type ChatMessageVO
} from '@/api/chat'
import { getResume } from '@/api/resume'
import PdfPreview from '@/components/PdfPreview.vue'
import { View, Download } from '@element-plus/icons-vue'
import { useChatWebSocket, type WsNewMessageData } from '@/composables/useChatWebSocket'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const applicationId = Number(route.params.applicationId)
const session = ref<ChatSessionVO | null>(null)
const messages = ref<ChatMessageVO[]>([])
const loading = ref(true)
const sending = ref(false)
const sendingResume = ref(false)
const inputText = ref('')
const hasMore = ref(true)
const messageListRef = ref<HTMLElement | null>(null)

const fileDialogVisible = ref(false)
const fileDialogUrl = ref('')
const pdfPreviewVisible = ref(false)

const currentUserId = computed(() => userStore.userInfo?.id)
const isHr = computed(() => userStore.userInfo?.role === 1)
const isBlocked = computed(() => {
  // 仅求职者可能受限制
  if (isHr.value) return false
  return session.value?.canSend === false
})

const blockedTip = computed(() => {
  if (isBlocked.value) {
    return 'HR 未回复前，您只能发送一条消息'
  }
  return ''
})

const formatTime = (dateStr: string): string => {
  if (!dateStr) return ''
  return dateStr.replace('T', ' ').substring(0, 16)
}

const loadSession = async () => {
  try {
    session.value = await getChatSession(applicationId)
  } catch {
    session.value = null
  }
}

const loadMessages = async (beforeId?: number) => {
  try {
    const list = await getChatMessages(applicationId, beforeId)
    if (list.length < 20) {
      hasMore.value = false
    }
    if (beforeId) {
      messages.value.unshift(...list.reverse())
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

const handleSend = async () => {
  const text = inputText.value.trim()
  if (!text) {
    ElMessage.warning('请输入消息内容')
    return
  }
  if (isBlocked.value) {
    ElMessage.warning(blockedTip.value)
    return
  }
  sending.value = true
  try {
    const message = await sendMessage(applicationId, { content: text })
    messages.value.push(message)
    inputText.value = ''
    refreshSession()
    scrollToBottom()
  } catch {
        /* 错误已在拦截器处理 */
    } finally {
        sending.value = false;
    }
}

const handleSendResume = async () => {
  if (isBlocked.value) {
    ElMessage.warning(blockedTip.value)
    return
  }
  sendingResume.value = true
  try {
    const resume = await getResume()
    if (!resume || !resume.attachmentUrl) {
      ElMessage.warning('请先上传简历附件')
      router.push('/resume')
      return
    }
    const message = await sendMessage(applicationId, { messageType: 2, content: resume.attachmentUrl })
    messages.value.push(message)
    refreshSession()
    scrollToBottom()
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

const refreshSession = async () => {
  try {
    session.value = await getChatSession(applicationId)
  } catch {
    // 静默失败
  }
}

const handleWsNewMessage = (data: WsNewMessageData) => {
  if (data.applicationId !== applicationId) return
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
  refreshSession()
  scrollToBottom()
}

useChatWebSocket({
  onNewMessage: handleWsNewMessage,
  enabled: computed(() => !!currentUserId.value)
})

const handleLoadMore = async () => {
  if (!hasMore.value || messages.value.length === 0) return
  const firstId = messages.value[0].id
  const oldScrollHeight = messageListRef.value?.scrollHeight || 0
  await loadMessages(firstId)
  nextTick(() => {
    const el = messageListRef.value
    if (el) {
      el.scrollTop = el.scrollHeight - oldScrollHeight
    }
  })
}

onMounted(async () => {
  if (!applicationId || isNaN(applicationId)) {
    ElMessage.error('无效的会话 ID')
    router.back()
    return
  }
  await loadSession()
  await loadMessages()
  await markSessionRead(applicationId)
  loading.value = false
  scrollToBottom()
})
</script>

<template>
  <div class="chat-page">
    <div class="chat-container">
      <!-- 头部 -->
      <div class="chat-header">
        <button class="back-btn" @click="router.back()">&larr; 返回</button>
        <div class="chat-title">
          <h3>{{ session?.counterpartName || '对方' }}</h3>
          <span class="subtitle">{{ session?.taskTitle || '' }}</span>
        </div>
        <span class="placeholder"></span>
      </div>

      <!-- 消息列表 -->
      <div class="message-list" ref="messageListRef">
        <div v-if="loading" class="loading-state">加载中...</div>
        <template v-else>
          <div v-if="hasMore && messages.length > 0" class="load-more">
            <button @click="handleLoadMore">加载更多</button>
          </div>
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
                  <el-button class="resume-preview-btn" size="small" @click="openFileAction(msg.content)">操作</el-button>
                </div>
              </div>
              <div v-else class="bubble">{{ msg.content }}</div>
              <div class="message-time">{{ formatTime(msg.sendTime) }}</div>
            </div>
          </div>
          <div v-if="messages.length === 0" class="empty-state">暂无消息，开始沟通吧</div>
        </template>
      </div>

      <!-- 输入区 -->
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

    <PdfPreview v-model:visible="pdfPreviewVisible" :url="fileDialogUrl" />
  </div>
</template>

<style scoped>
.chat-page {
  min-height: calc(100vh - 60px);
  background: #f5f7fa;
  padding: 16px;
}

.chat-container {
  max-width: 900px;
  margin: 0 auto;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  height: calc(100vh - 92px);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.chat-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid #f0f0f5;
}

.back-btn {
  background: none;
  border: none;
  color: #1762FB;
  font-size: 14px;
  cursor: pointer;
  padding: 0;
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

.placeholder {
  width: 60px;
}

.message-list {
  flex: 1;
  overflow-y: auto;
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.loading-state,
.empty-state {
  text-align: center;
  color: #999;
  padding: 40px 0;
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
  background: #f0f0f5;
  color: #1a1a2e;
}

.self .bubble {
  background: #1762FB;
  color: #fff;
}

.message-time {
  font-size: 11px;
  color: #bbb;
}

.input-area {
  border-top: 1px solid #f0f0f5;
  padding: 12px 20px 16px;
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
  background: #e8f0ff !important;
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
.resume-preview-btn {
  font-size: 13px;
  white-space: nowrap;
}
.file-action-buttons {
  display: flex;
  gap: 16px;
  justify-content: center;
  padding: 8px 0;
}
.file-action-btn {
  flex: 1;
}
</style>
