import request from './index'

// 密码登录请求参数
export interface LoginByPasswordParams {
  phone: string       // 手机号（11位数字）
  password: string    // 密码（明文，后端用 MD5+盐校验）
}

// 注册请求参数
export interface RegisterParams {
  phone: string           // 手机号
  password: string        // 密码
  confirmPassword: string // 确认密码
  nickname: string        // 昵称
}

// 用户信息（后端返回）
export interface UserInfo {
  userId: number      // 用户ID
  nickname: string    // 昵称
  avatarUrl: string   // 头像URL
  role: number        // 角色：0=求职者, 1=企业HR, 9=管理员
  phone: string       // 手机号
}

// 登录/注册接口统一响应结构
export interface LoginResult {
  code: number        // 业务状态码
  msg: string         // 提示消息
  token: string       // JWT Token
  userInfo: UserInfo  // 用户信息
}

/** 密码登录 POST /auth/login */
export const loginByPassword = (params: LoginByPasswordParams) => {
  return request.post<LoginResult>('/auth/login', params)
}

/** 用户注册 POST /auth/register */
export const register = (params: RegisterParams) => {
  return request.post<LoginResult>('/auth/register', params)
}
