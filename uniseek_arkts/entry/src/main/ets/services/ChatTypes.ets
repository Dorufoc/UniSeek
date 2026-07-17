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

export function mapTaskToJobData(task: TaskVO): JobData {
  return {
    id: String(task.id),
    title: task.title || '',
    company: task.enterpriseName || '',
    salary: (task.salaryMin != null && task.salaryMax != null) ? Number(task.salaryMin) + '-' + Number(task.salaryMax) + '元' : '',
    salaryMid: (Number(task.salaryMin) + Number(task.salaryMax)) / 2 || 0,
    popularity: task.applicationCount || 0,
    region: task.regionName || '',
    type: task.categoryName || '',
    category: task.jobType === 1 ? '全职' : task.jobType === 2 ? '兼职' : task.jobType === 3 ? '实习' : '全职',
    description: task.description || '',
    enterpriseId: task.enterpriseId || 0,
    categoryId: task.categoryId || 0,
    regionId: task.regionId || 0,
    salaryMin: Number(task.salaryMin) || 0,
    salaryMax: Number(task.salaryMax) || 0,
    salaryUnit: task.salaryUnit ?? 0,
    jobType: task.jobType || 0,
    status: task.status ?? 1,
    hasApplied: !!task.hasApplied,
    applicationId: task.applicationId || 0,
    tag: task.tag || [],
    remainingQuota: task.remainingQuota || 0,
    hrName: task.hrName || '',
    hrAvatar: task.hrAvatar || ''
  } as JobData
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
