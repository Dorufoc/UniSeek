<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useUserStore } from '@/stores/user'
import { useChatStore } from '@/stores/chat'
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
import type { WsNewMessageData } from '@/composables/useChatWebSocket'
import { updateApplicationStatus, getApplicationById, type ResumeSnapshot } from '@/api/application'
import { parseSkills } from '@/utils/skillParser'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()
const chatStore = useChatStore()

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

const resumeDialogVisible = ref(false)
const resumeData = ref<ResumeSnapshot | null>(null)
const interviewDialogVisible = ref(false)
const interviewForm = ref({ interviewTime: '', interviewLocation: '' })
const rejectDialogVisible = ref(false)
const rejectForm = ref({ rejectReason: '', hrNote: '' })

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

const parseSnapshot = (json: string | null): ResumeSnapshot | null => {
  if (!json) return null
  try { return JSON.parse(json) as ResumeSnapshot } catch { return null }
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

const handleViewProfile = async () => {
  if (!applicationId || isNaN(applicationId)) return
  try {
    const app: any = await getApplicationById(applicationId)
    const snapshotJson = app?.resumeSnapshot
    if (!snapshotJson) { ElMessage.warning('暂无简历数据'); return }
    const parsed = parseSnapshot(snapshotJson)
    if (parsed) { resumeData.value = parsed; resumeDialogVisible.value = true }
    else { ElMessage.warning('简历数据无效') }
  } catch (e: any) { ElMessage.error(e?.message || '获取简历失败') }
}

const handleInviteInterview = async () => {
  if (!interviewForm.value.interviewTime || !interviewForm.value.interviewLocation.trim()) {
    ElMessage.warning('请填写面试时间和地点'); return
  }
  if (!applicationId || isNaN(applicationId)) return
  try {
    await updateApplicationStatus(applicationId, {
      status: 1, interviewTime: interviewForm.value.interviewTime,
      interviewLocation: interviewForm.value.interviewLocation.trim()
    })
    ElMessage.success('面试邀请已发送')
    interviewDialogVisible.value = false
    interviewForm.value = { interviewTime: '', interviewLocation: '' }
	    await refreshSession()
	    await loadMessages()
	    await nextTick(() => { scrollToBottom() })
	  } catch (e: any) { ElMessage.error(e?.message || '操作失败') }
	}

	const handleMarkPending = async () => {
  if (!applicationId || isNaN(applicationId)) return
  try { await ElMessageBox.confirm('确定要「待定」该候选人吗？', '提示', { type: 'warning' }) }
  catch { return }
  try {
    await updateApplicationStatus(applicationId, { status: 2 })
	    ElMessage.success('操作成功'); await refreshSession()
	    await loadMessages()
	    await nextTick(() => { scrollToBottom() })
	  } catch (e: any) { ElMessage.error(e?.message || '操作失败') }
	}

	const handleReject = async () => {
  if (!rejectForm.value.rejectReason.trim()) { ElMessage.warning('请填写淘汰原因'); return }
  if (!applicationId || isNaN(applicationId)) return
  try {
    await updateApplicationStatus(applicationId, {
      status: 4, rejectReason: rejectForm.value.rejectReason.trim(),
      hrNote: rejectForm.value.hrNote.trim() || undefined
    })
    ElMessage.success('已发送淘汰通知')
    rejectDialogVisible.value = false
    rejectForm.value = { rejectReason: '', hrNote: '' }
	    await refreshSession()
	    await loadMessages()
	    await nextTick(() => { scrollToBottom() })
	  } catch (e: any) { ElMessage.error(e?.message || '操作失败') }
	}

	const refreshSession = async () => {
  try {
    session.value = await getChatSession(applicationId)
  } catch {
    // 静默失败
  }
}

let unsubWs: (() => void) | null = null

const onWsMessage = (data: WsNewMessageData) => {
  if (data.applicationId !== applicationId) return
  if (data.senderId === currentUserId.value) return
  // 活跃会话：立即标记已读
  markSessionRead(applicationId)
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
  unsubWs = chatStore.subscribeWs(onWsMessage)
  chatStore.setActiveApplication(applicationId)
  await loadSession()
  await loadMessages()
  await markSessionRead(applicationId)
  loading.value = false
  scrollToBottom()
})

onUnmounted(() => {
  unsubWs?.()
  chatStore.setActiveApplication(null)
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
      <!-- HR 操作按钮栏 -->
      <div v-if="isHr" class="hr-action-bar">
        <el-button size="small" type="info" :disabled="!applicationId" @click="handleViewProfile">查看个人简介</el-button>
        <el-button size="small" type="primary"
          :disabled="!(applicationId && session && (session.applicationStatus === 0 || session.applicationStatus === 2))"
          @click="interviewDialogVisible = true">
          {{ session?.applicationStatus === 2 ? '安排面试' : '邀请面试' }}
        </el-button>
        <el-button size="small" type="warning"
          :disabled="!(applicationId && session && (session.applicationStatus === 0 || session.applicationStatus === 1))"
          @click="handleMarkPending">待定</el-button>
        <el-button size="small" type="danger"
          :disabled="!(applicationId && session && (session.applicationStatus === 0 || session.applicationStatus === 1 || session.applicationStatus === 2))"
          @click="rejectDialogVisible = true">淘汰</el-button>
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

    <el-dialog v-model="resumeDialogVisible" title="候选人简历" width="520px" align-center>
      <div class="resume-detail" v-if="resumeData">
        <div class="resume-field"><label>姓名</label><span>{{ resumeData.realName || '-' }}</span></div>
        <div class="resume-field"><label>性别</label><span>{{ resumeData.gender === 0 ? '男' : resumeData.gender === 1 ? '女' : '-' }}</span></div>
        <div class="resume-field"><label>出生日期</label><span>{{ resumeData.birthDate?.replace('T', ' ')?.substring(0, 10) || '-' }}</span></div>
        <div class="resume-field"><label>学历</label><span>{{ resumeData.education || '-' }}</span></div>
        <div class="resume-field"><label>学校</label><span>{{ resumeData.school || '-' }}</span></div>
        <div class="resume-field"><label>技能标签</label><div class="talent-tags" v-if="parseSkills(resumeData.skills).length"><el-tag v-for="skill in parseSkills(resumeData.skills)" :key="skill" size="small" type="info" class="talent-tag">{{ skill }}</el-tag></div><span v-else>-</span></div>
        <div class="resume-field"><label>工作经历</label><span v-html="resumeData.experience || '-'"></span></div>
      </div>
    </el-dialog>

    <el-dialog v-model="interviewDialogVisible" title="邀请面试" width="420px" align-center @open="interviewForm = { interviewTime: '', interviewLocation: '' }">
      <el-form label-position="top">
        <el-form-item label="面试时间">
          <el-date-picker v-model="interviewForm.interviewTime" type="datetime" placeholder="选择面试时间"
            value-format="YYYY-MM-DDTHH:mm:ss" style="width: 100%" />
        </el-form-item>
        <el-form-item label="面试地点">
          <el-input v-model="interviewForm.interviewLocation" placeholder="请输入面试地点" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="interviewDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleInviteInterview">发送邀请</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="rejectDialogVisible" title="淘汰候选人" width="420px" align-center @open="rejectForm = { rejectReason: '', hrNote: '' }">
      <el-form label-position="top">
        <el-form-item label="淘汰原因">
          <el-input v-model="rejectForm.rejectReason" type="textarea" :rows="3" placeholder="请输入淘汰原因" />
        </el-form-item>
        <el-form-item label="HR备注（可选）">
          <el-input v-model="rejectForm.hrNote" type="textarea" :rows="2" placeholder="内部备注，仅HR可见" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="rejectDialogVisible = false">取消</el-button>
        <el-button type="danger" @click="handleReject">确认淘汰</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
/* 聊天页面 - 世界一流聊天界面设计 */
.chat-page {
  height: calc(100vh - 60px);
  background: linear-gradient(135deg, #f5f7fa 0%, #e8ecf1 100%);
  padding: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-sizing: border-box;
  overflow: hidden;
}

.chat-container {
  max-width: 960px;
  width: 100%;
  margin: 0 auto;
  background: #ffffff;
  border-radius: 24px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.08), 0 0 0 1px rgba(0, 0, 0, 0.04);
  height: 100%;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  backdrop-filter: blur(10px);
}

/* 头部 - 精致简约 */
.chat-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 28px;
  background: linear-gradient(180deg, #ffffff 0%, #fafbfc 100%);
  border-bottom: 1px solid rgba(0, 0, 0, 0.04);
  position: relative;
}

.chat-header::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 28px;
  right: 28px;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(23, 98, 251, 0.1), transparent);
}

.back-btn {
  background: none;
  border: none;
  color: #1762FB;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  padding: 8px 12px;
  border-radius: 8px;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

.back-btn:hover {
  background: rgba(23, 98, 251, 0.06);
  transform: translateX(-2px);
}

.chat-title {
  text-align: center;
  flex: 1;
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
}

.subtitle {
  font-size: 13px;
  color: #8b95a7;
  margin-top: 2px;
  font-weight: 400;
}

.placeholder {
  width: 60px;
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
  background: linear-gradient(180deg, #fafbfc 0%, #f5f7fa 100%);
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

.loading-state,
.empty-state {
  text-align: center;
  color: #8b95a7;
  padding: 60px 0;
  font-size: 14px;
  font-weight: 400;
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
  box-shadow: 0 2px 8px rgba(23, 98, 251, 0.2);
  position: relative;
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

.input-row {
  display: flex;
  gap: 12px;
  align-items: flex-end;
}

.input-row .el-input {
  flex: 1;
}

.input-row .el-input :deep(.el-input__wrapper) {
  box-shadow: none !important;
  border: 1.5px solid #e8ecf1;
  border-radius: 14px;
  padding: 12px 16px;
  background: #fafbfc;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  min-height: 48px;
}

.input-row .el-input :deep(.el-input__wrapper:hover) {
  border-color: #c5d1e0;
  background: #ffffff;
}

.input-row .el-input :deep(.el-input__wrapper.is-focus) {
  border-color: #1762FB;
  background: #ffffff;
  box-shadow: 0 0 0 4px rgba(23, 98, 251, 0.08) !important;
}

.input-row .el-input :deep(.el-input__inner) {
  font-size: 14.5px;
  line-height: 1.5;
  color: #1a1a2e;
}

.input-row .el-input :deep(.el-input__inner::placeholder) {
  color: #a0aab8;
}

.input-row .el-button {
  height: 48px;
  padding: 0 28px;
  border-radius: 14px;
  font-size: 14.5px;
  font-weight: 600;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

.input-row .el-button[type="primary"] {
  background: linear-gradient(135deg, #1762FB 0%, #2d7bff 100%);
  border: none;
  box-shadow: 0 4px 12px rgba(23, 98, 251, 0.25);
}

.input-row .el-button[type="primary"]:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(23, 98, 251, 0.35);
}

.input-row .el-button[type="primary"]:active:not(:disabled) {
  transform: translateY(0);
}

.input-row .el-button + .el-button {
  margin-left: 0;
}

/* 简历气泡 */
.resume-bubble {
  padding: 10px !important;
  background: linear-gradient(135deg, #f5f5ff 0%, #eef2ff 100%) !important;
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
}

.resume-icon {
  font-size: 32px;
  filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.1));
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

.resume-preview-btn {
  font-size: 13px;
  font-weight: 500;
  white-space: nowrap;
  border-radius: 8px;
  padding: 6px 14px;
  height: 32px;
}

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

/* 公司名称标签 */
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

/* 发送者名称 */
.sender-name {
  font-size: 12.5px;
  color: #8b95a7;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  flex-wrap: wrap;
  font-weight: 500;
}

/* 加号按钮 */
.action-wrap {
  position: relative;
}

.bar-btn {
  height: 48px;
  padding: 0 20px;
  border-radius: 14px;
  flex-shrink: 0;
  border: 1.5px solid #e8ecf1;
  background: #fafbfc;
  color: #6b7585;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

.bar-plus-btn {
  width: 48px;
  height: 48px;
  padding: 0;
  font-size: 20px;
  align-self: flex-end;
}

.bar-plus-btn:hover {
  background: #ffffff;
  border-color: #1762FB;
  color: #1762FB;
  transform: rotate(90deg);
}

.bar-plus-btn.active {
  background: linear-gradient(135deg, #1762FB 0%, #2d7bff 100%);
  border-color: #1762FB;
  color: #fff;
  transform: rotate(45deg);
  box-shadow: 0 4px 12px rgba(23, 98, 251, 0.25);
}

/* 操作菜单 */
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
@media (max-width: 768px) {
  .chat-page {
    padding: 12px;
  }

  .chat-container {
    border-radius: 16px;
    height: calc(100vh - 84px);
  }

  .chat-header {
    padding: 16px 20px;
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

  .input-row .el-button {
    padding: 0 20px;
  }
}
.hr-action-bar {
  display: flex;
  gap: 8px;
  padding: 10px 28px;
  background: linear-gradient(180deg, #ffffff 0%, #fafbfc 100%);
  border-bottom: 1px solid rgba(0, 0, 0, 0.04);
  flex-shrink: 0;
  align-items: center;
  justify-content: center;
  flex-wrap: wrap;
}
.hr-action-bar .el-button {
  border-radius: 20px;
  font-weight: 500;
  padding: 8px 20px;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}
.hr-action-bar .el-button:not(:disabled):hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}
.resume-detail {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.resume-field {
  display: flex;
  gap: 12px;
  font-size: 14px;
}
.resume-field label {
  width: 80px;
  color: #8b95a7;
  flex-shrink: 0;
  font-weight: 500;
}
.resume-field span {
  flex: 1;
  color: #1a1a2e;
  word-break: break-word;
}
</style>
