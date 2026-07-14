import request from './index'

export interface NotificationItem {
  id: number
  receiverId: number
  senderId: number
  title: string
  content: string
  type: number
  isRead: number
  bizId: number
  createTime: string
}

export interface PageResult<T> {
  records: T[]
  total: number
  page: number
  pageSize: number
  totalPages: number
}

/** GET /messages 获取消息列表 */
export const getMessages = (params?: {
  type?: number
  isRead?: number
  page?: number
  pageSize?: number
}) =>
  request.get<any, PageResult<NotificationItem>>('/messages', { params })

/** GET /messages/unread-count 获取未读消息数 */
export const getUnreadCount = () =>
  request.get<any, { count: number }>('/messages/unread-count')

/** PUT /messages/:id/read 标记消息已读 */
export const markMessageRead = (id: number) =>
  request.put<any, void>(`/messages/${id}/read`)

/** PUT /messages/read-all 全部标记已读 */
export const markAllRead = () =>
  request.put<any, void>('/messages/read-all')
