import { ref, watch, onUnmounted, type Ref } from 'vue'
import { useUserStore } from '@/stores/user'

export interface WsNewMessageData {
  messageId: number
  applicationId: number
  senderId: number
  senderName: string
  senderAvatar?: string
  content: string
  messageType: number
  sendTime: string
  isRead?: number
}

export function useChatWebSocket(options: {
  onNewMessage: (data: WsNewMessageData) => void
  enabled: Ref<boolean>
}) {
  const ws = ref<WebSocket | null>(null)
  const connected = ref(false)
  let reconnectTimer: ReturnType<typeof setTimeout> | null = null
  let pingTimer: ReturnType<typeof setInterval> | null = null

  const connect = () => {
    const userStore = useUserStore()
    const token = userStore.token
    if (!token) return

    const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:'
    const url = `${protocol}//${location.host}/ws/chat?token=${token}`

    const socket = new WebSocket(url)
    ws.value = socket

    socket.onopen = () => {
      connected.value = true
      pingTimer = setInterval(() => {
        if (socket.readyState === WebSocket.OPEN) {
          socket.send(JSON.stringify({ type: 'PING', data: {} }))
        }
      }, 30000)
    }

    socket.onmessage = (event) => {
      try {
        const msg = JSON.parse(event.data)
        switch (msg.type) {
          case 'NEW_MESSAGE':
            options.onNewMessage(msg.data)
            break
          case 'ERROR':
            console.warn('[WS ERROR]', msg.data.message)
            break
        }
      } catch {
        // ignore parse errors
      }
    }

    socket.onclose = () => {
      connected.value = false
      clearInterval(pingTimer!)
      ws.value = null
      reconnectTimer = setTimeout(connect, 5000)
    }

    socket.onerror = () => {
      socket.close()
    }
  }

  const disconnect = () => {
    clearTimeout(reconnectTimer!)
    clearInterval(pingTimer!)
    if (ws.value) {
      ws.value.close()
      ws.value = null
    }
    connected.value = false
  }

  watch(
    () => options.enabled.value,
    (val) => {
      if (val) {
        connect()
      } else {
        disconnect()
      }
    },
    { immediate: true }
  )

  onUnmounted(() => {
    disconnect()
  })

  return { connected, disconnect }
}
