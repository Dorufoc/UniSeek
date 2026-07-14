import request from './index'

export interface ApplyParams {
  taskId: number
}

export interface UpdateStatusParams {
  status: number
  interviewTime?: string
  interviewLocation?: string
  rejectReason?: string
  hrNote?: string
}

export interface CompleteParams {
  settlementAmount?: number
  hrNote?: string
}

export interface TaskApplication {
  id: number
  taskId: number
  applicantId: number
  resumeSnapshot: any
  attachmentUrl: string
  status: number
  hrId: number
  interviewTime: string
  interviewLocation: string
  rejectReason: string
  hrNote: string
  version: number
  createTime: string
  updateTime: string
}

export interface PageResult<T> {
  records: T[]
  total: number
  page: number
  pageSize: number
  totalPages: number
}

/** POST /applications 投递职位 */
export const apply = (params: ApplyParams) =>
  request.post<any, TaskApplication>('/applications', params)

/** GET /applications/my 我的投递列表 */
export const getMyApplications = (page?: number, pageSize?: number) =>
  request.get<any, PageResult<TaskApplication>>('/applications/my', { params: { page, pageSize } })

/** GET /applications/:id 投递详情 */
export const getApplicationById = (id: number) =>
  request.get<any, TaskApplication>(`/applications/${id}`)

/** GET /tasks/:taskId/applications 职位投递列表（HR视角） */
export const getTaskApplications = (taskId: number, page?: number, pageSize?: number) =>
  request.get<any, PageResult<TaskApplication>>(`/tasks/${taskId}/applications`, { params: { page, pageSize } })

/** PUT /applications/:id/status 更新投递状态 */
export const updateApplicationStatus = (id: number, params: UpdateStatusParams) =>
  request.put<any, void>(`/applications/${id}/status`, params)

/** PUT /applications/:id/complete 完成结算 */
export const completeApplication = (id: number, params: CompleteParams) =>
  request.put<any, void>(`/applications/${id}/complete`, params)
