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
  salaryUnit: number       // 0-日结, 1-时薪, 2-月结
  jobType: number          // 1-全职, 2-兼职, 3-实习
  totalQuota: number
  remainingQuota: number
  address: string
  tag: string[]
  status: number           // 0-待审, 1-招聘中, 2-已满员, 3-已过期, 4-已下架
  deadline: string | null
  createTime: string
  updateTime: string
  enterpriseName: string
  categoryName: string
  regionName: string
  hasApplied: boolean
  applicationCount: number
}

// 发布职位请求参数（匹配后端 TaskRequest）
export interface CreateTaskParams {
  categoryId: number
  regionId: number
  title: string
  description: string
  salaryMin: number
  salaryMax: number
  salaryUnit: number       // 0-月薪, 1-日薪, 2-时薪
  jobType: number          // 0-全职, 1-兼职, 2-实习
  totalQuota: number
  address: string
  tag: string[]
  deadline: string | null
}

/** 发布职位 POST /api/tasks */
export const createTask = async (params: CreateTaskParams) => {
  const res = await request.post<ApiResponse<TaskVO>>('/tasks', params)
  return res.data
}

/** 查询本企业职位列表 GET /api/enterprise/tasks */
export const getEnterpriseTasks = async () => {
  const res = await request.get<ApiResponse<PageResult<TaskVO>>>('/enterprise/tasks')
  return res.data
}

/** 修改职位状态 PUT /api/tasks/{id}/status */
export const updateTaskStatus = async (id: number, targetStatus: number) => {
  const res = await request.put<ApiResponse<void>>(`/tasks/${id}/status?targetStatus=${targetStatus}`)
  return res.data
}
