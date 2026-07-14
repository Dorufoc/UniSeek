import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useUserStore = defineStore('user', () => {
  const token = ref(localStorage.getItem('uniseek_token') || '')
  const userInfo = ref<any>(JSON.parse(localStorage.getItem('uniseek_user') || 'null'))
  const isLoggedIn = ref(!!token.value)
  const role = computed(() => userInfo.value?.role || '')

  const setToken = (val: string) => {
    token.value = val
    localStorage.setItem('uniseek_token', val)
    isLoggedIn.value = true
  }

  const setUserInfo = (info: any) => {
    userInfo.value = info
    localStorage.setItem('uniseek_user', JSON.stringify(info))
  }

  const logout = () => {
    token.value = ''
    userInfo.value = null
    isLoggedIn.value = false
    localStorage.removeItem('uniseek_token')
    localStorage.removeItem('uniseek_user')
  }

  return { token, userInfo, isLoggedIn, role, setToken, setUserInfo, logout }
})
