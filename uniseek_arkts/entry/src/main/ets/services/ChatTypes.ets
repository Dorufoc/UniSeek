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
  enterpriseName: string
  totalQuota: number
  address: string
  deadline: string
  applicationCount: number
  hasFavorited: boolean
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
  counterpartCompany?: string
  enterpriseId?: number
  lastMessage: string
  lastMessageTime: string
  unreadCount: number
}

export interface ApplicationResult {
  id: number
}

// 薪资格式化：数字缩写
function formatSalaryValue(val: number): string {
  if (val >= 10000) {
    const wan = (val / 10000)
    return wan % 1 === 0 ? wan + '万' : wan.toFixed(1) + '万'
  }
  if (val >= 1000) {
    const k = (val / 1000)
    return k % 1 === 0 ? k + 'K' : k.toFixed(1) + 'K'
  }
  return String(val)
}

const SALARY_UNIT_SUFFIX: Record<number, string> = {
  0: '/日',
  1: '/时',
  2: '/月'
}

// 薪资格式化：范围 + 单位
function formatSalary(min: number, max: number, unit: number): string {
  // 薪资范围为 0-0 时显示为"面议"
  if (min === 0 && max === 0) {
    return '面议'
  }
  const suffix = SALARY_UNIT_SUFFIX[unit] ?? '/月'
  if (min > 0 && max > 0) {
    return formatSalaryValue(min) + '-' + formatSalaryValue(max) + suffix
  }
  if (min > 0) {
    return '≥' + formatSalaryValue(min) + suffix
  }
  if (max > 0) {
    return '≤' + formatSalaryValue(max) + suffix
  }
  return ''
}

export function mapTaskToJobData(task: TaskVO): JobData {
  return {
    id: String(task.id),
    title: task.title || '',
    company: task.enterpriseName || '',
    salary: (task.salaryMin != null || task.salaryMax != null) ? formatSalary(Number(task.salaryMin) || 0, Number(task.salaryMax) || 0, task.salaryUnit ?? 2) : '',
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
    hrAvatar: task.hrAvatar || '',
    enterpriseName: task.enterpriseName || '',
    totalQuota: task.totalQuota || 0,
    address: task.address || '',
    deadline: task.deadline || '',
    applicationCount: task.applicationCount || 0,
    hasFavorited: task.hasFavorited === true
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

export interface TaskSearchParams {
  keyword?: string
  categoryId?: number
  categoryIds?: string    // 新增：逗号分隔的分类ID列表
  regionId?: number
  regionIds?: string      // 新增：逗号分隔的地区ID列表
  jobType?: number
  salaryMin?: number
  salaryMax?: number
  salaryUnit?: number
  includeNegotiable?: boolean
  sortBy?: string
  page?: number
  pageSize?: number
}

export interface PageResult<T> {
  records: T[]
  total: number
  page: number
  pageSize: number
  totalPages: number
}
