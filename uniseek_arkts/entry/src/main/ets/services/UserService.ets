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
    const stats = await ApiClient.get<UserStats>('/api/user/stats')
    return {
      applications: UserService.parseStatValue(stats.applications),
      interviews: UserService.parseStatValue(stats.interviews),
      favorites: UserService.parseStatValue(stats.favorites),
      receivedResumes: UserService.parseStatValue(stats.receivedResumes),
      hired: UserService.parseStatValue(stats.hired),
      pending: UserService.parseStatValue(stats.pending),
      activeJobs: UserService.parseStatValue(stats.activeJobs)
    }
  }

  /**
   * 将后端返回的统计字段统一解析为非负整数，兼容 number / string / null / undefined。
   */
  private static parseStatValue(value: number | string | null | undefined): number {
    if (value === null || value === undefined) {
      return 0
    }
    if (typeof value === 'number') {
      return Number.isFinite(value) ? Math.max(0, Math.floor(value)) : 0
    }
    if (typeof value === 'string') {
      const parsed: number = Number.parseInt(value, 10)
      return Number.isNaN(parsed) ? 0 : Math.max(0, parsed)
    }
    return 0
  }
}

/** 用户中心统计数据。 */
export interface UserStats {
  applications?: number
  interviews?: number
  favorites?: number
  receivedResumes?: number
  hired?: number
  /** 招聘者待定投递数（status=2）。 */
  pending?: number
  /** 招聘者在招职位数（status=1）。 */
  activeJobs?: number
}
