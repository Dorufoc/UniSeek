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
  enterpriseId: number
  categoryId: number
  regionId: number
  salaryMin: number
  salaryMax: number
  salaryUnit: number
  jobType: number
  status: number
  hasApplied: boolean
  applicationId: number
  tag: string[]
  remainingQuota: number
  hrName: string
  hrAvatar: string
}

export interface TaskVO {
  id: number
  title: string
  enterpriseName: string
  salaryMin: number
  salaryMax: number
  salaryUnit: number
  jobType: number
  totalQuota: number
  remainingQuota: number
  address: string
  tag: string[]
  status: number
  rejectReason: string
  description: string
  enterpriseId: number
  categoryId: number
  regionId: number
  categoryName: string
  regionName: string
  hasApplied: boolean
  applicationId: number
  applicationCount: number
  hasFavorited: boolean
  deadline: string
  createTime: string
  updateTime: string
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
