import { ref } from 'vue'
import { defineStore } from 'pinia'
import { getChatUnreadCount } from '@/api/chat'
import type { WsNewMessageData } from '@/composables/useChatWebSocket'

/**
 * 全局聊天状态管理
 * - DefaultLayout 维护唯一 WebSocket 连接
 * - Store 管理未读计数和活跃会话消息分发
 * - Messages/Chat 页面通过 subscribeWs 订阅实时消息
 */
export const useChatStore = defineStore('chat', () => {
  const totalUnreadCount = ref(0)
  const activeApplicationId = ref<number | null>(null)
  const sessionUnreadMap = ref<Record<number, number>>({})
  const currentUserId = ref<number | null>(null)

  // ---- WS 消息订阅机制 ----
  const wsListeners = new Set<(data: WsNewMessageData) => void>()

  function setCurrentUserId(id: number | null) {
    currentUserId.value = id
  }

  async function fetchUnreadCount() {
    try {
      const count = await getChatUnreadCount()
      totalUnreadCount.value = count ?? 0
    } catch {
      // 静默失败
    }
  }

  function setActiveApplication(id: number | null) {
    activeApplicationId.value = id
  }

  /** WS 收到消息的总入口（由 DefaultLayout 调用） */
  function handleWsMessage(data: WsNewMessageData) {
    // 1. 分发给订阅者（Messages/Chat 页面实时显示）
    wsListeners.forEach(cb => cb(data))
    // 2. 更新未读计数
    if (data.senderId === currentUserId.value) return
    if (data.applicationId === activeApplicationId.value) return
    sessionUnreadMap.value = {
      ...sessionUnreadMap.value,
      [data.applicationId]: (sessionUnreadMap.value[data.applicationId] || 0) + 1
    }
    totalUnreadCount.value = Object.values(sessionUnreadMap.value).reduce((a, b) => a + b, 0)
  }

  /** 页面订阅 WS 消息（用于活跃会话实时显示） */
  function subscribeWs(cb: (data: WsNewMessageData) => void): () => void {
    wsListeners.add(cb)
    return () => { wsListeners.delete(cb) }
  }

  function clearSessionUnread(appId: number) {
    const count = sessionUnreadMap.value[appId] || 0
    if (count > 0) {
      totalUnreadCount.value = Math.max(0, totalUnreadCount.value - count)
      sessionUnreadMap.value = { ...sessionUnreadMap.value, [appId]: 0 }
    }
  }

  function getSessionUnread(appId: number): number {
    return sessionUnreadMap.value[appId] || 0
  }

  /** loadSessions 后同步后端会话未读数到 Store */
  function syncUnreadMap(sessions: Array<{ applicationId: number, unreadCount: number }>) {
    const map: Record<number, number> = {}
    for (const s of sessions) {
      if (s.unreadCount > 0) {
        map[s.applicationId] = s.unreadCount
      }
    }
    sessionUnreadMap.value = map
    totalUnreadCount.value = Object.values(map).reduce((a, b) => a + b, 0)
  }

  return {
    totalUnreadCount,
    activeApplicationId,
    sessionUnreadMap,
    fetchUnreadCount,
    setActiveApplication,
    setCurrentUserId,
    handleWsMessage,
    subscribeWs,
    clearSessionUnread,
    getSessionUnread,
    syncUnreadMap
  }
})
