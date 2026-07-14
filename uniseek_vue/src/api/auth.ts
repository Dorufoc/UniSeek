import request from './index'

export interface LoginByPhoneParams {
  phone: string
  code: string
}

export interface LoginByPasswordParams {
  phone: string
  password: string
}

export interface RegisterParams {
  username: string
  email: string
  password: string
}

export interface SendCodeParams {
  phone: string
  type: 'login' | 'register'
}

export interface LoginResult {
  token: string
  userId: number
  nickname: string
  avatar: string
}

/** 短信验证码登录 */
export const loginByPhone = (params: LoginByPhoneParams) => {
  return request.post<LoginResult>('/auth/login/phone', params)
}

/** 密码登录 */
export const loginByPassword = (params: LoginByPasswordParams) => {
  return request.post<LoginResult>('/auth/login/password', params)
}

/** 注册 */
export const register = (params: RegisterParams) => {
  return request.post<LoginResult>('/auth/register', params)
}

/** 发送短信验证码 */
export const sendVerifyCode = (params: SendCodeParams) => {
  return request.post('/auth/send-code', params)
}
