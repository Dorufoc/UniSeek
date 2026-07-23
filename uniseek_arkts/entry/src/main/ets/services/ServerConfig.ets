/** 后端服务地址配置与输入规范化。 */
export class ServerConfig {
  static readonly DEFAULT_BASE_URL: string = 'http://192.168.246.118:8080'

  static normalizeBaseUrl(value: string): string {
    let trimmed: string = value.trim()
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return ServerConfig.DEFAULT_BASE_URL
    }
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1)
    }
    return trimmed
  }

  /** 将服务端返回的相对路径解析为当前后端的完整 HTTP 地址。 */
  static toHttpUrl(baseUrl: string, value: string): string {
    const target: string = value.trim()
    if (target.startsWith('http://') || target.startsWith('https://')) {
      return target
    }
    const base: string = ServerConfig.normalizeBaseUrl(baseUrl)
    if (target.startsWith('/')) {
      return base + target
    }
    return base + '/' + target
  }

  /** 根据当前 HTTP 服务地址生成同源 WebSocket 地址。 */
  static toWebSocketUrl(baseUrl: string, token: string): string {
    const normalized: string = ServerConfig.normalizeBaseUrl(baseUrl)
    let socketBase: string = normalized
    if (normalized.startsWith('https://')) {
      socketBase = 'wss://' + normalized.substring(8)
    } else if (normalized.startsWith('http://')) {
      socketBase = 'ws://' + normalized.substring(7)
    }
    return socketBase + '/ws/chat?token=' + encodeURIComponent(token)
  }
}
