import request from './index'

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

export interface TaskCreateParams {
  categoryId: number
  regionId?: number
  title: string
  description?: string
  salaryMin: number
  salaryMax: number
  salaryUnit: number
  jobType: number
  totalQuota: number
  address?: string
  tag?: string[]
  longitude?: number
  latitude?: number
  deadline?: string
}

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
  deadline: string
  createTime: string
  updateTime: string
  enterpriseName: string
  categoryName: string
  regionName: string
  hasApplied: boolean
  applicationCount: number
}

export interface PageResult<T> {
  records: T[]
  total: number
  page: number
  pageSize: number
  totalPages: number
}

/** GET /tasks 分页搜索职位 */
export const searchTasks = (params: TaskSearchParams) =>
  request.get<any, PageResult<TaskVO>>('/tasks', { params })

/** GET /tasks/:id 获取职位详情 */
export const getTaskById = (id: number) =>
  request.get<any, TaskVO>(`/tasks/${id}`)

/** POST /tasks 发布职位 */
export const createTask = (params: TaskCreateParams) =>
  request.post<any, TaskVO>('/tasks', params)

/** PUT /tasks/:id 更新职位 */
export const updateTask = (id: number, params: TaskCreateParams) =>
  request.put<any, TaskVO>(`/tasks/${id}`, params)

/** PUT /tasks/:id/status 更新职位状态 */
export const updateTaskStatus = (id: number, targetStatus: number) =>
  request.put<any, void>(`/tasks/${id}/status`, null, { params: { targetStatus } })

/** GET /enterprise/tasks 获取本企业职位 */
export const getEnterpriseTasks = (page?: number, pageSize?: number) =>
  request.get<any, PageResult<TaskVO>>('/enterprise/tasks', { params: { page, pageSize } })
