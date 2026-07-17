import axios from 'axios'
import { ElMessage } from 'element-plus'
// import { setupMock } from './mock'

// 创建 axios 实例，配置基础 URL 和超时时间
const request = axios.create({
  baseURL: '/api',
  timeout: 15000
})

// 开发模式下启用 Mock 数据，拦截 API 请求返回模拟数据
// 如需连接真实后端，请取消下面这行注释
// setupMock(request)

// 请求拦截器：自动从 localStorage 读取 Token 并附加到请求头
request.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('uniseek_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => Promise.reject(error)
)

// 响应拦截器：解包 response.data，并在业务错误时弹出提示
request.interceptors.response.use(
  (response) => {
    const data = response.data
    // 后端统一用 HTTP 200 + code 字段区分成功/失败
    // code !== 200 时视为业务错误，弹出提示并拒绝 Promise
    if (data.code && data.code !== 200) {
      if (!(response.config as any)._silent) {
        ElMessage.error(data.message || '请求失败')
      }
      return Promise.reject(data)
    }
    return data.data
  },
  (error) => {
    // 401：未授权，清除本地登录态并跳转登录页
    if (error.response?.status === 401) {
      localStorage.removeItem('uniseek_token')
      localStorage.removeItem('uniseek_user')
      localStorage.removeItem('uniseek_role')
      ElMessage.error('认证令牌无效或已过期，请重新登录')
      setTimeout(() => { window.location.href = '/login' }, 1500)
      return Promise.reject(error)
    }
    // 5xx 服务端错误：统一跳转到错误页（避免在错误页自身内再触发跳转）
    const status = error.response?.status
    if (status && status >= 500 && status < 600 && !window.location.pathname.startsWith('/error')) {
      window.location.href = `/error/${status}`
      return Promise.reject(error)
    }
    // 其余情况按原逻辑提示
    if (!error.config?._silent) {
      const msg = error.response?.data?.message || '网络异常，请稍后重试'
      ElMessage.error(msg)
    }
    return Promise.reject(error)
  }
)

export default request
