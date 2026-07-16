import request from './index'

// ==================== 类型定义 ====================

export interface PageResult<T> {
  records: T[]
  total: number
  page: number
  pageSize: number
}

export interface StatisticsSummary {
  totalUsers: number
  totalEnterprises: number
  totalTasks: number
  totalApplications: number
  pendingEnterprises: number
  pendingTasks: number
  pendingComplaints: number
}

export interface DailyStatItem {
  statDate: string
  newUserCount: number
  newEnterpriseCount: number
  newTaskCount: number
  newResumeCount: number
  newDeliveryCount: number
  newInterviewCount: number
  newEntryCount: number
}

export interface EnterpriseRecord {
  id: number
  userId: number
  companyName: string
  creditCode: string
  licenseImgUrl: string
  industry: string
  regionId: number
  description: string
  auditStatus: number
  auditTime: string
  createTime: string
  updateTime: string
}

export interface TaskRecord {
  id: number
  enterpriseId: number
  enterpriseName: string
  categoryId: number
  categoryName: string
  title: string
  description: string
  salaryMin: number
  salaryMax: number
  salaryUnit: number
  jobType: number
  totalQuota: number
  remainingQuota: number
  address: string
  status: number
  deadline: string
  createTime: string
  updateTime: string
}

export interface UserRecord {
  id: number
  phone: string
  email: string
  nickname: string
  avatarUrl: string
  role: number
  creditScore: number
  status: number
  realNameAuth: boolean
  lastLoginTime: string
  createTime: string
}

export interface ComplaintRecord {
  id: number
  complainantId: number
  complainantName: string
  complainantPhone: string
  targetType: number
  targetId: number
  targetName: string
  type: number
  content: string
  status: number
  handlerId: number
  handlerName: string
  handleResult: string
  createTime: string
  updateTime: string
}

export interface OperationLogRecord {
  id: number
  operatorId: number
  operatorName: string
  operationType: string
  targetType: string
  targetId: number
  detail: string
  ipAddress: string
  createTime: string
}

// ==================== 统计 API ====================

export async function getStatistics(startDate?: string, endDate?: string): Promise<{
  summary: Record<string, number>
  dailyList: Array<Record<string, unknown>>
}> {
  const res: any = await request.get('/admin/statistics', { params: { startDate, endDate } })
  return res
}

// ==================== 企业审核 API ====================

export async function listEnterprises(params: {
  page: number; pageSize: number; auditStatus?: number; keyword?: string
}): Promise<PageResult<EnterpriseRecord>> {
  const res: any = await request.get('/admin/enterprises', { params })
  return res
}

export function auditEnterprise(id: number, data: { approved: boolean; rejectReason?: string }): Promise<any> {
  return request.put(`/admin/enterprises/${id}/audit`, null, {
    params: { approved: data.approved, rejectReason: data.rejectReason }
  })
}

// ==================== 职位审核 API ====================

export async function listTasks(params: {
  page: number; pageSize: number; status?: number; keyword?: string
}): Promise<PageResult<TaskRecord>> {
  const res: any = await request.get('/admin/tasks', { params })
  return res
}

export async function listPendingTasks(params: {
  page: number; pageSize: number; status?: number; keyword?: string
}): Promise<PageResult<TaskRecord>> {
  const res: any = await request.get('/admin/tasks/pending', { params })
  return res
}

export function auditTask(id: number, data: { approved: boolean; rejectReason?: string }): Promise<any> {
  return request.put(`/admin/tasks/${id}/audit`, null, {
    params: { approved: data.approved, rejectReason: data.rejectReason }
  })
}

// ==================== 用户管理 API ====================

export async function listUsers(params: {
  page: number; pageSize: number; keyword?: string; role?: number; status?: number
}): Promise<PageResult<UserRecord>> {
  const res: any = await request.get('/admin/users', { params })
  return res
}

export function updateUserStatus(id: number, status: number): Promise<any> {
  return request.put(`/admin/users/${id}/status`, null, { params: { status } })
}

export function updateUserRole(id: number, role: number): Promise<any> {
  return request.put(`/admin/users/${id}/role`, null, { params: { role } })
}

// ==================== 投诉处理 API ====================

export async function listComplaints(params: {
  page: number; pageSize: number; status?: number; targetType?: number
}): Promise<PageResult<ComplaintRecord>> {
  const res: any = await request.get('/admin/complaints', { params })
  return res
}

export async function getComplaintDetail(id: number): Promise<ComplaintRecord> {
  const res: any = await request.get(`/admin/complaints/${id}`)
  return res
}

export function handleComplaint(id: number, data: { status: number; handleResult: string }): Promise<any> {
  return request.put(`/admin/complaints/${id}/handle`, null, {
    params: { status: data.status, handleResult: data.handleResult }
  })
}

// ==================== 操作日志 API ====================

export async function listOperationLogs(params: {
  page: number; pageSize: number; operatorId?: number; operationType?: string; startTime?: string; endTime?: string
}): Promise<PageResult<OperationLogRecord>> {
  const res: any = await request.get('/admin/operation-logs', { params })
  return res
}

// ==================== 大屏统计 API ====================

/** 大屏公开 KPI 汇总（无需管理员权限） */
export async function getScreenSummary(range = '7d'): Promise<{
  summary: { totalUsers: number; totalEnterprises: number; totalTasks: number; publishedTasks: number; totalApplications: number }
  latestDeliveries: number
  dailyList: Array<{ date: string; newUsers: number; newEnterprises: number; newTasks: number; newApplications: number; newInterviews: number; newEntries: number }>
}> {
  const res: any = await request.get('/admin/statistics/summary', { params: { range } })
  return res
}

export async function getIndustryDistribution(): Promise<Array<{ industry: string; count: number }>> {
  const res: any = await request.get('/admin/statistics/industries')
  return res
}

export async function getHotTasks(): Promise<Array<{ id: number; title: string; companyName: string; applicationCount: number }>> {
  const res: any = await request.get('/admin/statistics/hot-tasks')
  return res
}

export async function getLatestActivity(): Promise<Array<{ id: number; message: string; time: string }>> {
  const res: any = await request.get('/admin/statistics/latest-activity')
  return res
}

export async function getTalentFlow(): Promise<Array<{ fromCode: string; toCode: number; flowCount: number }>> {
  const res: any = await request.get('/admin/statistics/talent-flow')
  return res
}

export async function getApplicationFunnel(): Promise<{
  total: number
  todayNew: number
  statusList: Array<{ status: number; name: string; count: number }>
}> {
  const res: any = await request.get('/admin/statistics/application-funnel')
  return res
}

export async function getEnterpriseSummary(): Promise<{
  totalEnterprise: number
  auditList: Array<{ status: number; name: string; count: number }>
  totalUser: number
  authedCount: number
  unauthedCount: number
}> {
  const res: any = await request.get('/admin/statistics/enterprise-summary')
  return res
}
