import request from './index'
import type { ApiResponse } from './auth'

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
  const res = await request.post<ApiResponse<any>>('/tasks', params)
  return res.data
}
