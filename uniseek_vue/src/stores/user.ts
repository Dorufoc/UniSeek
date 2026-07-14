import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { getCurrentUser } from '@/api/auth'

export const useUserStore = defineStore('user', () => {
  const token = ref(localStorage.getItem('uniseek_token') || '')
  const userInfo = ref<any>(JSON.parse(localStorage.getItem('uniseek_user') || 'null'))
  const isLoggedIn = ref(!!token.value)
  const role = computed(() => userInfo.value?.role ?? -1)

  const setToken = (val: string) => {
    token.value = val
    localStorage.setItem('uniseek_token', val)
    isLoggedIn.value = true
  }

  const setUserInfo = (info: any) => {
    userInfo.value = info
    localStorage.setItem('uniseek_user', JSON.stringify(info))
  }

  /** 从后端刷新当前用户信息并更新 store + localStorage */
  const fetchUserInfo = async () => {
    try {
      const info = await getCurrentUser()
      userInfo.value = info
      localStorage.setItem('uniseek_user', JSON.stringify(info))
    } catch {
      // 静默失败，保持旧数据
    }
  }

  const logout = () => {
    token.value = ''
    userInfo.value = null
    isLoggedIn.value = false
    localStorage.removeItem('uniseek_token')
    localStorage.removeItem('uniseek_user')
  }

  return { token, userInfo, isLoggedIn, role, setToken, setUserInfo, fetchUserInfo, logout }
})