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
import { View, Download, Picture, Plus, Close } from '@element-plus/icons-vue'
import { uploadImage } from '@/api/upload'
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
const imagePreviewVisible = ref(false)
const imagePreviewUrl = ref('')
const showActionMenu = ref(false)
const sendingImage = ref(false)

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

const toggleActionMenu = () => {
  showActionMenu.value = !showActionMenu.value
}

const handleSendImage = async () => {
  if (isBlocked.value) {
    ElMessage.warning(blockedTip.value)
    return
  }
  // 创建隐藏的文件输入框
  const input = document.createElement('input')
  input.type = 'file'
  input.accept = 'image/*'
  input.onchange = async () => {
    const file = input.files?.[0]
    if (!file) return
    sendingImage.value = true
    try {
      const { url } = await uploadImage(file)
      if (!url) {
        ElMessage.error('图片上传失败')
        return
      }
      const msg = await sendMessage(applicationId, { messageType: 1, content: url })
      messages.value.push(msg)
      refreshSession()
      scrollToBottom()
    } catch {
      ElMessage.error('图片上传失败')
    } finally {
      sendingImage.value = false
    }
  }
  input.click()
}

const previewImage = (url: string) => {
  imagePreviewUrl.value = url
  imagePreviewVisible.value = true
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
          <h3>
            <span class="counterpart-name">{{ session?.counterpartName || '对方' }}</span>
            <span v-if="session?.counterpartCompany" class="company-tag">
              <span class="at-symbol">@</span>
              <span class="company-link">{{ session.counterpartCompany }}</span>
            </span>
          </h3>
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
              <div class="sender-name">
                <span>{{ msg.senderName }}</span>
                <span v-if="msg.senderId !== currentUserId && session?.counterpartCompany" class="company-tag">
                  <span class="at-symbol">@</span>
                  <span class="company-link">{{ session.counterpartCompany }}</span>
                </span>
              </div>
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
              <div v-else-if="msg.messageType === 1" class="bubble image-bubble">
                <img class="chat-image" :src="msg.content" alt="图片消息" @click="previewImage(msg.content)" />
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
          <div class="action-wrap">
            <el-button
              class="bar-btn bar-plus-btn"
              :class="{ active: showActionMenu }"
              :disabled="isBlocked || sendingImage"
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
              </div>
            </Transition>
          </div>
          <el-input
            v-model="inputText"
            type="textarea"
            :rows="2"
            :disabled="isBlocked || sending || sendingImage"
            placeholder="请输入消息..."
            maxlength="2000"
            show-word-limit
            @keydown.enter.prevent="handleSend"
          />
          <el-button
            v-if="!isHr"
            type="warning"
            :disabled="isBlocked || sendingResume || sendingImage"
            :loading="sendingResume"
            @click="handleSendResume"
          >
            发送简历
          </el-button>
          <el-button
            type="primary"
            :disabled="isBlocked || sending || sendingImage || !inputText.trim()"
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

    <!-- 图片预览轻量弹窗 -->
    <Transition name="lightbox-fade">
      <div v-if="imagePreviewVisible" class="lightbox-overlay" @click.self="imagePreviewVisible = false">
        <img :src="imagePreviewUrl" class="lightbox-image" alt="图片预览" />
        <button class="lightbox-close" @click="imagePreviewVisible = false">
          <el-icon :size="24"><Close /></el-icon>
        </button>
      </div>
    </Transition>
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

/* ── @公司名称 ── */
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

/* ── 发送者名称行支持公司标签 ── */
.sender-name {
  font-size: 12px;
  color: #999;
  display: inline-flex;
  align-items: center;
  gap: 2px;
  flex-wrap: wrap;
}

/* ── 加号按钮 ── */
.action-wrap {
  position: relative;
}
.bar-btn {
  height: 52px;
  padding: 0 24px;
  border-radius: 10px;
  flex-shrink: 0;
  border: 1px solid #e8e8e8;
  background: #f7f8fa;
  color: #666;
  transition: all 0.2s;
}
.bar-plus-btn {
  width: 40px;
  height: 40px;
  padding: 0;
  font-size: 20px;
  align-self: flex-end;
  margin-bottom: 2px;
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
</style>
