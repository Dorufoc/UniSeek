export interface JobData {
  id: string
  title: string
  company: string
  salary: string
  salaryMid: number
  popularity: number
  region: string
  type: string
  category: string
  description: string
}

export interface TaskVO {
  id: number
  title: string
  company: string
  salary: string
  salaryMid: number
  popularity: number
  region: string
  type: string
  category: string
  description: string
  enterpriseId: number
  enterpriseName: string
  hrName: string
  hrAvatar: string
}

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
}

export interface ApplicationResult {
  id: number
}

export interface ChatMessageVO {
  id: number
  senderId: number
  messageType: number
  content: string
  isRead: number
  sendTime: string
  senderName: string
  senderAvatar: string
}
