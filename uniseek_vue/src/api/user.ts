import request from './index'
import type { ApiResponse, UserInfo } from './auth'

/** 更新用户资料 PUT /api/user/profile */
export const updateProfile = async (params: {
  nickname?: string
  avatarUrl?: string
  phone?: string
  email?: string
}) => {
  const res = await request.put<ApiResponse<UserInfo>>('/user/profile', null, { params })
  return res
}

/** 获取用户统计数据 GET /api/user/stats */
export const getUserStats = async (): Promise<{
  applications?: number
  interviews?: number
  favorites?: number
  receivedResumes?: number
  hired?: number
}> => {
  const res: any = await request.get('/user/stats')
  return res
}
