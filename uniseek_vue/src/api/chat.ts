import request from './index'

export interface ChatSessionVO {
  applicationId: number
  taskId: number
  taskTitle: string
  taskStatus: number
  applicationStatus: number
  counterpartId: number
  counterpartName: string
  counterpartAvatar: string
  lastMessage: string
  lastMessageTime: string
  unreadCount: number
  canSend?: boolean
}

export interface ChatMessageVO {
  id: number
  senderId: number
  senderName: string
  senderAvatar: string
  messageType: number
  content: string
  isRead: number
  sendTime: string
}

export interface SendMessageParams {
  messageType?: number
  content: string
}

/** GET /chat/sessions 获取聊天会话列表 */
export const getChatSessions = () =>
  request.get<any, ChatSessionVO[]>('/chat/sessions')

/** GET /chat/sessions/:applicationId 获取聊天会话 */
export const getChatSession = (applicationId: number) =>
  request.get<any, ChatSessionVO>(`/chat/sessions/${applicationId}`)

/** GET /chat/sessions/:applicationId/messages 获取聊天消息 */
export const getChatMessages = (applicationId: number, beforeId?: number, pageSize?: number) =>
  request.get<any, ChatMessageVO[]>(`/chat/sessions/${applicationId}/messages`, {
    params: { beforeId, pageSize }
  })

/** POST /chat/sessions/:applicationId/messages 发送消息 */
export const sendMessage = (applicationId: number, params: SendMessageParams) =>
  request.post<any, ChatMessageVO>(`/chat/sessions/${applicationId}/messages`, params)

/** PUT /chat/sessions/:applicationId/read 标记会话已读 */
export const markSessionRead = (applicationId: number) =>
  request.put<any, void>(`/chat/sessions/${applicationId}/read`)

/** POST /chat/sessions/direct 创建直接会话（人才库联系求职者） */
export const createDirectSession = (targetUserId: number) =>
  request.post<any, number>('/chat/sessions/direct', null, { params: { targetUserId } })
