import request from './index'

// 密码登录请求参数
export interface LoginByPasswordParams {
  phone: string       // 手机号（11位数字）
  password: string    // 密码（明文，后端用 MD5+盐校验）
}

// 注册请求参数
export interface RegisterParams {
  phone: string           // 手机号
  email: string           // 邮箱
  password: string        // 密码
  confirmPassword: string // 确认密码
  nickname: string        // 昵称
  role: number            // 角色：0=求职者, 1=企业HR
}

// 用户信息（匹配后端 UserVO 返回结构）
export interface UserInfo {
  id: number          // 用户ID
  nickname: string    // 昵称
  avatarUrl: string   // 头像URL
  role: number        // 角色：0=求职者, 1=企业HR, 9=管理员
  phone: string       // 手机号（脱敏）
  email: string       // 邮箱（脱敏）
  status: number      // 状态：0=禁用, 1=正常
  creditScore: number // 信用分
}

// 后端统一响应包装结构
export interface ApiResponse<T> {
  code: number
  message: string
  data: T
}

// 登录/注册接口 data 字段的数据结构
export interface LoginData {
  token: string
  userInfo: UserInfo
}

/** 密码登录 POST /api/auth/login */
export const loginByPassword = (params: LoginByPasswordParams) =>
  request.post<any, LoginData>('/auth/login', params)

/** 用户注册 POST /api/auth/register */
export const register = (params: RegisterParams) =>
  request.post<any, LoginData>('/auth/register', params)

// 实名认证请求参数
export interface RealNameAuthParams {
  realName: string
  idCard: string
}

// 实名认证返回数据
export interface RealNameAuthVO {
  realName: string
  idCard: string
  authTime: string
}

// 实名认证状态返回数据
export interface RealNameAuthStatus {
  isAuth: boolean
  realName: string | null
  idCard: string | null
  birthDate: string | null
  gender: number
}

// 修改密码请求参数
export interface ChangePasswordParams {
  oldPassword: string
  newPassword: string
  confirmPassword: string
}

/** 提交实名认证 POST /api/auth/real-name */
export const submitRealNameAuth = (params: RealNameAuthParams) =>
  request.post<any, RealNameAuthVO>('/auth/real-name', params)

/** 查询实名认证状态 GET /api/auth/real-name/status */
export const getRealNameAuthStatus = async () => {
  const res = await request.get<ApiResponse<RealNameAuthStatus>>('/auth/real-name/status')
  return res
}

/** 修改密码 PUT /api/auth/password */
export const changePassword = async (params: ChangePasswordParams) => {
  const res = await request.put<ApiResponse<void>>('/auth/password', params)
  return res
}

/** PUT /api/auth/phone 修改手机号 */
export const updatePhone = async (params: { newPhone: string; password: string }) => {
  const res = await request.put<ApiResponse<void>>('/auth/phone', params)
  return res
}

/** PUT /api/auth/email 修改邮箱 */
export const updateEmail = async (params: { newEmail: string; password: string }) => {
  const res = await request.put<ApiResponse<void>>('/auth/email', params)
  return res
}

/** GET /api/auth/current-user 获取当前用户信息 */
export const getCurrentUser = async () => {
  const res = await request.get<ApiResponse<UserInfo>>('/auth/current-user')
  return res
}
