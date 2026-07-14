import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

// 用户状态管理 - 管理登录态、Token、用户信息
export const useUserStore = defineStore('user', () => {
  // Token 持久化存储在 localStorage，文件读取恢复登录态
  const token = ref(localStorage.getItem('uniseek_token') || '')
  // 用户信息从 localStorage 恢复（含 role、nickname 等）
  const userInfo = ref<any>(JSON.parse(localStorage.getItem('uniseek_user') || 'null'))
  // 登录态根据 Token 是否存在判断
  const isLoggedIn = ref(!!token.value)
  // 角色计算属性：0=求职者, 1=企业HR, -1=未登录
  const role = computed(() => userInfo.value?.role ?? -1)

  // 设置 Token 并持久化到 localStorage
  const setToken = (val: string) => {
    token.value = val
    localStorage.setItem('uniseek_token', val)
    isLoggedIn.value = true
  }

  // 设置用户信息并持久化到 localStorage
  const setUserInfo = (info: any) => {
    userInfo.value = info
    localStorage.setItem('uniseek_user', JSON.stringify(info))
  }

  // 退出登录：清除 Token、用户信息、登录态
  const logout = () => {
    token.value = ''
    userInfo.value = null
    isLoggedIn.value = false
    localStorage.removeItem('uniseek_token')
    localStorage.removeItem('uniseek_user')
  }

  return { token, userInfo, isLoggedIn, role, setToken, setUserInfo, logout }
})
