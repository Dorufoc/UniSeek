import { defineStore } from 'pinia'
import { ref } from 'vue'

// 应用全局状态管理 - 当前城市、搜索关键词等
export const useAppStore = defineStore('app', () => {
  // 当前选中城市，默认为"全国"
  const city = ref('全国')
  // 搜索关键词
  const searchKeyword = ref('')

  const setCity = (val: string) => { city.value = val }
  const setSearchKeyword = (val: string) => { searchKeyword.value = val }

  return { city, searchKeyword, setCity, setSearchKeyword }
})
