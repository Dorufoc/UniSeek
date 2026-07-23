import { ApiClient } from './ApiClient';
import { UserVO } from './AuthService';

/** 用户资料更新请求参数。 */
export interface UserProfileUpdate {
  nickname?: string
  avatarUrl?: string
  phone?: string
  email?: string
}

/** 用户资料与统计接口。 */
export class UserService {
  static async updateProfile(update: UserProfileUpdate): Promise<UserVO> {
    const params: Array<[string, string]> = []
    if (update.nickname !== undefined && update.nickname.trim().length > 0) {
      params.push(['nickname', update.nickname.trim()])
    }
    if (update.avatarUrl !== undefined && update.avatarUrl.trim().length > 0) {
      params.push(['avatarUrl', update.avatarUrl.trim()])
    }
    if (update.phone !== undefined && update.phone.trim().length > 0) {
      params.push(['phone', update.phone.trim()])
    }
    if (update.email !== undefined && update.email.trim().length > 0) {
      params.push(['email', update.email.trim()])
    }
    if (params.length === 0) {
      throw new Error('没有需要更新的资料')
    }
    return ApiClient.putWithParams<UserVO>('/api/user/profile', params)
  }

  static async getStats(): Promise<UserStats> {
    return ApiClient.get<UserStats>('/api/user/stats')
  }
}

/** 用户中心统计数据。 */
export interface UserStats {
  applications?: number
  interviews?: number
  favorites?: number
  receivedResumes?: number
  hired?: number
}