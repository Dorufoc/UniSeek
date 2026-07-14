import request from './index'
import type { ApiResponse } from './auth'
import type { PageResult } from './task'

// 简历快照（JSON 解析后结构）
export interface ResumeSnapshot {
  realName?: string
  gender?: number
  birthDate?: string
  education?: string
  school?: string
  skills?: string
  experience?: string
  attachmentUrl?: string
}

// 投递申请记录
export interface TaskApplication {
  id: number
  taskId: number
  applicantId: number
  resumeSnapshot: string | null
  attachmentUrl: string | null
  status: number
  hrId: number | null
  interviewTime: string | null
  interviewLocation: string | null
  rejectReason: string | null
  hrNote: string | null
  version: number
  createTime: string
  updateTime: string
}

// 投递请求参数
export interface ApplyParams {
  taskId: number
}

// 更新投递状态请求参数
export interface UpdateApplicationStatusParams {
  status: number
  interviewTime?: string | null
  interviewLocation?: string | null
  rejectReason?: string | null
  hrNote?: string | null
}

// 结算确认请求参数
export interface CompleteApplicationParams {
  hrNote?: string | null
  settlementAmount?: number
}

/** POST /api/applications 投递职位 */
export const apply = async (params: ApplyParams) => {
  const res = await request.post<ApiResponse<TaskApplication>>('/applications', params)
  return res
}

/** GET /api/applications/my 我的投递列表 */
export const getMyApplications = async (page = 1, pageSize = 10) => {
  const res = await request.get<ApiResponse<PageResult<TaskApplication>>>(`/applications/my?page=${page}&pageSize=${pageSize}`)
  return res
}

/** GET /api/applications/:id 投递详情 */
export const getApplicationById = async (id: number) => {
  const res = await request.get<ApiResponse<TaskApplication>>(`/applications/${id}`)
  return res
}

/** GET /api/tasks/{taskId}/applications 查询某个职位的投递列表（HR视角） */
export const getTaskApplications = async (taskId: number, page = 1, pageSize = 100) => {
  const res = await request.get<ApiResponse<PageResult<TaskApplication>>>(
    `/tasks/${taskId}/applications?page=${page}&pageSize=${pageSize}`
  )
  return res
}

/** PUT /api/applications/{id}/status 更新投递状态 */
export const updateApplicationStatus = async (id: number, params: UpdateApplicationStatusParams) => {
  const res = await request.put<ApiResponse<void>>(`/applications/${id}/status`, params)
  return res
}

/** PUT /api/applications/{id}/complete 结算确认 */
export const completeApplication = async (id: number, params: CompleteApplicationParams = {}) => {
  const res = await request.put<ApiResponse<void>>(`/applications/${id}/complete`, params)
  return res
}
