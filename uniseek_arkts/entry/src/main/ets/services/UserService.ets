import { ApiClient } from './ApiClient';
import { UserVO } from './AuthService';
import { UserSession } from './UserSession';

const KEY_CACHE_USER_STATS = 'cached_user_stats'

/** 用户资料更新请求参数。 */
export interface UserProfileUpdate {
  nickname?: string
  avatarUrl?: string
  phone?: string
  email?: string
}

/** 用户资料与统计接口。 */
export class UserService {
  private static statsCacheKey(userId: number): string {
    return KEY_CACHE_USER_STATS + '_' + userId
  }

  private static saveCachedStats(userId: number, stats: UserStats): void {
    const pref = ApiClient.getPreferenceStore()
    if (!pref) {
      return
    }
    pref.putSync(UserService.statsCacheKey(userId), JSON.stringify(stats))
    pref.flushSync()
  }

  private static getCachedStats(userId: number): UserStats | null {
    const pref = ApiClient.getPreferenceStore()
    if (!pref) {
      return null
    }
    try {
      const raw: string = pref.getSync(UserService.statsCacheKey(userId), '') as string
      if (!raw) {
        return null
      }
      return JSON.parse(raw) as UserStats
    } catch {
      return null
    }
  }

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
    const userId = UserSession.userId
    try {
      const stats = await ApiClient.get<UserStats>('/api/user/stats')
      const normalized: UserStats = {
        applications: UserService.parseStatValue(stats.applications),
        interviews: UserService.parseStatValue(stats.interviews),
        favorites: UserService.parseStatValue(stats.favorites),
        receivedResumes: UserService.parseStatValue(stats.receivedResumes),
        hired: UserService.parseStatValue(stats.hired)
      }
      UserService.saveCachedStats(userId, normalized)
      return normalized
    } catch {
      return UserService.getCachedStats(userId) || {
        applications: 0,
        interviews: 0,
        favorites: 0,
        receivedResumes: 0,
        hired: 0
      }
    }
  }

  /**
   * 将后端返回的统计字段统一解析为非负整数，兼容 number / string / null / undefined。
   * 网络成功时该解析结果会覆盖本地缓存，确保显示真实数据。
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
}
