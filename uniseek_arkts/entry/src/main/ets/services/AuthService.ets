import { ApiClient, ApiEmpty } from './ApiClient';
import { UserSession } from './UserSession';
import { ChatWebSocketService } from './ChatWebSocketService';
import { preferences } from '@kit.ArkData';
import { Router } from '@kit.ArkUI';

const KEY_CACHE_CURRENT_USER = 'cached_current_user'
const KEY_CACHE_REAL_NAME_STATUS_PREFIX = 'cached_real_name_status'
const KEY_CACHE_REAL_NAME_INFO_PREFIX = 'cached_real_name_info'
// 兼容旧版本全局缓存键，用于清理兜底
const KEY_CACHE_REAL_NAME_STATUS = 'cached_real_name_status'
const KEY_CACHE_REAL_NAME_INFO = 'cached_real_name_info'

// 请求体接口
export interface LoginRequest {
  account: string
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
  isAuth: boolean
  realName: string | null
  idCard: string | null
  birthDate: string | null
  gender: number
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

  /** 获取当前登录用户ID，内存会话优先，无内存时回退到持久化会话。 */
  private static currentUserId(): number {
    if (UserSession.userId > 0) {
      return UserSession.userId
    }
    const stored = ApiClient.getStoredSession()
    if (stored && stored.userId > 0) {
      return stored.userId
    }
    return 0
  }

  private static realNameStatusKey(): string {
    return KEY_CACHE_REAL_NAME_STATUS_PREFIX + '_' + AuthService.currentUserId().toString()
  }

  private static realNameInfoKey(): string {
    return KEY_CACHE_REAL_NAME_INFO_PREFIX + '_' + AuthService.currentUserId().toString()
  }

  /** 将实名认证状态持久化到本地，按当前账号隔离存储。 */
  static saveCachedRealNameStatus(status: RealNameStatus): void {
    const pref = ApiClient.getPreferenceStore()
    if (!pref) {
      return
    }
    pref.putSync(AuthService.realNameStatusKey(), JSON.stringify(status))
    pref.flushSync()
  }

  /** 读取本地缓存的实名认证状态，仅返回当前账号的缓存。 */
  static getCachedRealNameStatus(): RealNameStatus | null {
    const pref = ApiClient.getPreferenceStore()
    if (!pref) {
      return null
    }
    try {
      const raw: string = pref.getSync(AuthService.realNameStatusKey(), '') as string
      if (!raw) {
        return null
      }
      return JSON.parse(raw) as RealNameStatus
    } catch {
      return null
    }
  }

  /** 将完整实名信息持久化到本地，按当前账号隔离存储。 */
  static saveCachedRealNameInfo(info: RealNameInfo): void {
    const pref = ApiClient.getPreferenceStore()
    if (!pref) {
      return
    }
    pref.putSync(AuthService.realNameInfoKey(), JSON.stringify(info))
    pref.flushSync()
  }

  /** 读取本地缓存的完整实名信息，仅返回当前账号的缓存。 */
  static getCachedRealNameInfo(): RealNameInfo | null {
    const pref = ApiClient.getPreferenceStore()
    if (!pref) {
      return null
    }
    try {
      const raw: string = pref.getSync(AuthService.realNameInfoKey(), '') as string
      if (!raw) {
        return null
      }
      return JSON.parse(raw) as RealNameInfo
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

  static async login(account: string, password: string): Promise<LoginResult> {
    const result = await ApiClient.post<LoginResult>('/api/auth/login', { account, password } as LoginRequest)
    ApiClient.saveToken(result.token)
    AuthService.clearCachedRealNameStatus()
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
    // 先按当前账号清理实名缓存，再清空会话，避免会话清空后无法定位账号导致缓存残留
    AuthService.clearCachedRealNameStatus()
    ApiClient.clearSession()
    UserSession.clear()
    ChatWebSocketService.getInstance().disconnect()
  }

  /**
   * 统一退出登录并跳转登录页。
   * 无论网络是否可用，都立即清空本地角色状态与缓存，然后清空页面栈并跳转登录页；
   * 远程退出接口仅在联网时尽力通知服务端，不会阻塞界面返回。
   */
  static logoutAndRedirect(router: Router): void {
    // 1. 先按当前账号清理实名缓存，再立即清空本地会话、角色缓存与 WebSocket 连接
    AuthService.clearCachedRealNameStatus()
    ApiClient.clearSession()
    UserSession.clear()
    ChatWebSocketService.getInstance().disconnect()

    // 2. 清空搜索历史等本地业务缓存
    try {
      const pref = preferences.getPreferencesSync(getContext(), { name: 'search_history_db' })
      pref.clearSync()
      pref.flushSync()
    } catch {
      // 即使清空缓存失败，也不影响继续跳转登录页
    }

    // 3. 尽力通知服务端退出，不阻塞页面跳转
    void AuthService.logout()

    // 4. 清空页面历史栈并跳转登录页，确保登录页按返回键不会再回到登录态页面
    router.clear()
    router.replaceUrl({ url: 'pages/LoginPage' })
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

  static clearCachedRealNameStatus(): void {
    const pref = ApiClient.getPreferenceStore()
    if (!pref) {
      return
    }
    const userId = AuthService.currentUserId()
    if (userId > 0) {
      pref.deleteSync(KEY_CACHE_REAL_NAME_STATUS_PREFIX + '_' + userId.toString())
      pref.deleteSync(KEY_CACHE_REAL_NAME_INFO_PREFIX + '_' + userId.toString())
    }
    // 兼容旧版本全局缓存键，兜底清理避免切换账号后旧数据残留
    pref.deleteSync(KEY_CACHE_REAL_NAME_STATUS)
    pref.deleteSync(KEY_CACHE_REAL_NAME_INFO)
    pref.flushSync()
  }

  static async getRealNameStatus(): Promise<RealNameStatus> {
    const status = await ApiClient.get<RealNameStatus>('/api/auth/real-name/status')
    if (status.isAuth) {
      AuthService.saveCachedRealNameStatus(status)
    } else {
      AuthService.clearCachedRealNameStatus()
    }
    return status
  }

  static async updatePhone(newPhone: string, password: string): Promise<void> {
    await ApiClient.put<ApiEmpty>('/api/auth/phone', { newPhone, password } as UpdatePhoneRequest)
  }

  static async updateEmail(newEmail: string, password: string): Promise<void> {
    await ApiClient.put<ApiEmpty>('/api/auth/email', { newEmail, password } as UpdateEmailRequest)
  }
}
