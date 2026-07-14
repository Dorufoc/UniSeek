import axios from 'axios'
import { ElMessage } from 'element-plus'
import { setupMock } from './mock'

const request = axios.create({
  baseURL: '/api',
  timeout: 15000
})

setupMock(request)

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

request.interceptors.response.use(
  (response) => response.data,
  (error) => {
    const msg = error.response?.data?.message || '网络异常，请稍后重试'
    ElMessage.error(msg)
    return Promise.reject(error)
  }
)

export default request
