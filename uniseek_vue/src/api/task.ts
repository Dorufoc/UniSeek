import request from './index'
import type { ApiResponse } from './auth'

// 分页结果结构
export interface PageResult<T> {
  records: T[]
  total: number
  page: number
  pageSize: number
  totalPages: number
}

// 职位搜索参数
export interface TaskSearchParams {
  keyword?: string
  categoryId?: number
  regionId?: number
  jobType?: number
  salaryMin?: number
  salaryMax?: number
  salaryUnit?: number
  address?: string
  tag?: string
  sortBy?: string
  sortOrder?: string
  page?: number
  pageSize?: number
}

// 职位视图（匹配后端 TaskVO）
export interface TaskVO {
  id: number
  enterpriseId: number
  categoryId: number
  regionId: number
  title: string
  description: string
  salaryMin: number
  salaryMax: number
  salaryUnit: number
  jobType: number
  totalQuota: number
  remainingQuota: number
  address: string
  tag: string[]
  longitude: number
  latitude: number
  status: number
  deadline: string | null
  createTime: string
  updateTime: string
  enterpriseName: string
  categoryName: string
  regionName: string
  hasApplied: boolean
  applicationCount: number
}

// 发布职位请求参数
export interface CreateTaskParams {
  categoryId: number
  regionId: number
  title: string
  description: string
  salaryMin: number
  salaryMax: number
  salaryUnit: number
  jobType: number
  totalQuota: number
  address: string
  tag: string[]
  deadline: string | null
}

/** GET /api/tasks 分页搜索职位 */
export const searchTasks = async (params: TaskSearchParams) => {
  const res = await request.get<ApiResponse<PageResult<TaskVO>>>('/tasks', { params })
  return res.data
}

/** GET /api/tasks/:id 获取职位详情 */
export const getTaskById = async (id: number) => {
  const res = await request.get<ApiResponse<TaskVO>>(`/tasks/${id}`)
  return res.data
}

/** POST /api/tasks 发布职位 */
export const createTask = async (params: CreateTaskParams) => {
  const res = await request.post<ApiResponse<TaskVO>>('/tasks', params)
  return res.data
}

/** PUT /api/tasks/:id 更新职位 */
export const updateTask = async (id: number, params: CreateTaskParams) => {
  const res = await request.put<ApiResponse<TaskVO>>(`/tasks/${id}`, params)
  return res.data
}

/** PUT /api/tasks/:id/status 修改职位状态 */
export const updateTaskStatus = async (id: number, targetStatus: number) => {
  const res = await request.put<ApiResponse<void>>(`/tasks/${id}/status?targetStatus=${targetStatus}`)
  return res.data
}

/** GET /api/enterprise/tasks 查询本企业职位列表 */
export const getEnterpriseTasks = async (page = 1, pageSize = 100) => {
  const res = await request.get<ApiResponse<PageResult<TaskVO>>>(`/enterprise/tasks?page=${page}&pageSize=${pageSize}`)
  return res.data
}
