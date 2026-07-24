import { ApiClient, ApiEmpty } from './ApiClient';
import { UserSession } from './UserSession';
import { ChatWebSocketService } from './ChatWebSocketService';

const KEY_CACHE_CURRENT_USER = 'cached_current_user'
const KEY_CACHE_REAL_NAME_STATUS = 'cached_real_name_status'

// 请求体接口
export interface LoginRequest {
  phone: string
  password: string
}

export interface RegisterRequest {
  phone: string
  email: string
  password: string
  confirmPassword: string
  nickname: string
  role: number
}

export interface ChangePasswordRequest {
  oldPassword: string
  newPassword: string
  confirmPassword: string
}

export interface UpdatePhoneRequest {
  newPhone: string
  password: string
}

export interface UpdateEmailRequest {
  newEmail: string
  password: string
}

// 响应体接口
export interface UserInfo {
  id: number
  phone: string
  email: string
  nickname: string
  avatarUrl: string
  role: number
  status: number
  creditScore: number
  lastLoginTime: string
  createTime: string
}

export interface LoginResult {
  token: string
  userInfo: UserInfo
}

export interface RealNameInfo {
  realName: string
  idCard: string
  authTime: string
}

export interface RealNameStatus {
  status: number
  realName: string
}

export interface UserVO {
  id: number
  phone: string
  email: string
  nickname: string
  avatarUrl: string
  role: number
  status: number
  creditScore: number
  lastLoginTime: string
  createTime: string
}

export class AuthService {
  static applyUserInfo(userId: number, role: number, nickname: string, avatarUrl: string): void {
    const safeNickname: string = nickname || ''
    const safeAvatarUrl: string = avatarUrl || ''
    UserSession.restore(userId, role, safeNickname, safeAvatarUrl)
    ApiClient.saveSession(userId, role, safeNickname, safeAvatarUrl)
  }

  /** 将完整用户信息持久化到本地，供离线时展示个人中心。 */
  static saveCachedCurrentUser(user: UserVO): void {
    const pref = ApiClient.getPreferenceStore()
    if (!pref) {
      return
    }
    pref.putSync(KEY_CACHE_CURRENT_USER, JSON.stringify(user))
    pref.flushSync()
  }

  /** 读取本地缓存的完整用户信息。 */
  static getCachedCurrentUser(): UserVO | null {
    const pref = ApiClient.getPreferenceStore()
    if (!pref) {
      return null
    }
    try {
      const raw: string = pref.getSync(KEY_CACHE_CURRENT_USER, '') as string
      if (!raw) {
        return null
      }
      return JSON.parse(raw) as UserVO
    } catch {
      return null
    }
  }

  /** 将实名认证状态持久化到本地。 */
  static saveCachedRealNameStatus(status: RealNameStatus): void {
    const pref = ApiClient.getPreferenceStore()
    if (!pref) {
      return
    }
    pref.putSync(KEY_CACHE_REAL_NAME_STATUS, JSON.stringify(status))
    pref.flushSync()
  }

  /** 读取本地缓存的实名认证状态。 */
  static getCachedRealNameStatus(): RealNameStatus | null {
    const pref = ApiClient.getPreferenceStore()
    if (!pref) {
      return null
    }
    try {
      const raw: string = pref.getSync(KEY_CACHE_REAL_NAME_STATUS, '') as string
      if (!raw) {
        return null
      }
      return JSON.parse(raw) as RealNameStatus
    } catch {
      return null
    }
  }

  static restoreCachedSession(): boolean {
    ApiClient.restoreConfiguration()
    if (!ApiClient.hasToken()) {
      UserSession.clear()
      return false
    }
    const session = ApiClient.getStoredSession()
    if (!session) {
      ApiClient.clearSession()
      UserSession.clear()
      return false
    }
    UserSession.restore(session.userId, session.role, session.nickname, session.avatarUrl)
    return true
  }

  static async login(phone: string, password: string): Promise<LoginResult> {
    const result = await ApiClient.post<LoginResult>('/api/auth/login', { phone, password } as LoginRequest)
    ApiClient.saveToken(result.token)
    AuthService.applyUserInfo(result.userInfo.id, result.userInfo.role, result.userInfo.nickname, result.userInfo.avatarUrl)
    return result
  }

  static async register(phone: string, email: string, password: string, confirmPassword: string, nickname: string, role: number): Promise<void> {
    await ApiClient.post<ApiEmpty>('/api/auth/register', { phone, email, password, confirmPassword, nickname, role } as RegisterRequest)
  }

  static async logout(): Promise<void> {
    try {
      await ApiClient.post<ApiEmpty>('/api/auth/logout')
    } catch {
    }
    ApiClient.clearSession()
    UserSession.clear()
    ChatWebSocketService.getInstance().disconnect()
  }

  static async getCurrentUser(): Promise<UserVO> {
    const user = await ApiClient.get<UserVO>('/api/auth/current-user')
    AuthService.applyUserInfo(user.id, user.role, user.nickname, user.avatarUrl)
    AuthService.saveCachedCurrentUser(user)
    return user
  }

  static async changePassword(oldPassword: string, newPassword: string, confirmPassword: string): Promise<void> {
    await ApiClient.put<ApiEmpty>('/api/auth/password', { oldPassword, newPassword, confirmPassword } as ChangePasswordRequest)
  }

  static async realNameAuth(realName: string, idCard: string): Promise<RealNameInfo> {
    return ApiClient.post<RealNameInfo>('/api/auth/real-name', { realName, idCard } as RealNameInfo)
  }

  static async getRealNameStatus(): Promise<RealNameStatus> {
    const status = await ApiClient.get<RealNameStatus>('/api/auth/real-name/status')
    AuthService.saveCachedRealNameStatus(status)
    return status
  }

  static async updatePhone(newPhone: string, password: string): Promise<void> {
    await ApiClient.put<ApiEmpty>('/api/auth/phone', { newPhone, password } as UpdatePhoneRequest)
  }

  static async updateEmail(newEmail: string, password: string): Promise<void> {
    await ApiClient.put<ApiEmpty>('/api/auth/email', { newEmail, password } as UpdateEmailRequest)
  }
}
