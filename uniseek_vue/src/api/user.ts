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
