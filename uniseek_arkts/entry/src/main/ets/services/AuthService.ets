import { ApiClient, ApiEmpty } from './ApiClient';
import { UserSession } from './UserSession';

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
  static async login(phone: string, password: string): Promise<LoginResult> {
    const result = await ApiClient.post<LoginResult>('/api/auth/login', { phone, password } as LoginRequest)
    ApiClient.saveToken(result.token)
    UserSession.userId = result.userInfo.id
    UserSession.role = result.userInfo.role
    UserSession.nickname = result.userInfo.nickname
    UserSession.avatarUrl = result.userInfo.avatarUrl
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
    ApiClient.clearToken()
    UserSession.clear()
  }

  static async getCurrentUser(): Promise<UserVO> {
    const user = await ApiClient.get<UserVO>('/api/auth/current-user')
    UserSession.userId = user.id
    UserSession.role = user.role
    UserSession.nickname = user.nickname
    UserSession.avatarUrl = user.avatarUrl
    return user
  }

  static async changePassword(oldPassword: string, newPassword: string, confirmPassword: string): Promise<void> {
    await ApiClient.put<ApiEmpty>('/api/auth/password', { oldPassword, newPassword, confirmPassword } as ChangePasswordRequest)
  }

  static async realNameAuth(realName: string, idCard: string): Promise<RealNameInfo> {
    return ApiClient.post<RealNameInfo>('/api/auth/real-name', { realName, idCard } as RealNameInfo)
  }

  static async getRealNameStatus(): Promise<RealNameStatus> {
    return ApiClient.get<RealNameStatus>('/api/auth/real-name/status')
  }

  static async updatePhone(newPhone: string, password: string): Promise<void> {
    await ApiClient.put<ApiEmpty>('/api/auth/phone', { newPhone, password } as UpdatePhoneRequest)
  }

  static async updateEmail(newEmail: string, password: string): Promise<void> {
    await ApiClient.put<ApiEmpty>('/api/auth/email', { newEmail, password } as UpdateEmailRequest)
  }
}
