import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useAppStore = defineStore('app', () => {
  const city = ref('全国')
  const searchKeyword = ref('')

  const setCity = (val: string) => { city.value = val }
  const setSearchKeyword = (val: string) => { searchKeyword.value = val }

  return { city, searchKeyword, setCity, setSearchKeyword }
})
