// ChatWebSocketService.ets — WebSocket 实时推送服务
// 与 Vue 端 useChatWebSocket.ts 功能对齐
// 使用 @ohos.net.webSocket 实现 WebSocket 连接管理
// 功能：连接管理、PING 保活、断线重连、新消息推送

import webSocket from '@ohos.net.webSocket';
import { ApiClient } from './ApiClient';
import { ServerConfig } from './ServerConfig';
import { BusinessError } from '@kit.BasicServicesKit';

/** WebSocket 推送的新消息数据类型 */
export interface WsNewMessageData {
  messageId: number;
  applicationId: number;
  senderId: number;
  senderName: string;
  senderAvatar: string;
  content: string;
  messageType: number;
  sendTime: string;
  isRead: number;
}

/** WebSocket 协议消息（内部使用） */
interface WsProtocolMessage {
  type: string;
  data: Object;
}

/**
 * WebSocket 实时推送服务（单例模式）
 * - 自动连接 ws://host/ws/chat?token=xxx
 * - 处理 NEW_MESSAGE 推送
 * - 30 秒 PING 保活
 * - 断线 5 秒自动重连（最多 5 次）
 */
export class ChatWebSocketService {
  private static instance: ChatWebSocketService | null = null;
  private ws: webSocket.WebSocket | null = null;
  private pingTimerId: number = -1;
  private reconnectTimerId: number = -1;
  private reconnectCount: number = 0;
  private readonly maxReconnectCount: number = 5;
  private readonly reconnectDelay: number = 5000;
  private readonly pingInterval: number = 30000;
  private connected: boolean = false;
  private onSessionMessageCallback: ((data: WsNewMessageData) => void) | null = null;
  private onDetailMessageCallback: ((data: WsNewMessageData) => void) | null = null;

  static getInstance(): ChatWebSocketService {
    if (ChatWebSocketService.instance === null) {
      ChatWebSocketService.instance = new ChatWebSocketService();
    }
    return ChatWebSocketService.instance;
  }

  /** 设置会话列表的新消息回调。 */
  setOnSessionMessageCallback(callback: ((data: WsNewMessageData) => void) | null): void {
    this.onSessionMessageCallback = callback;
  }

  /** 移除会话列表的新消息回调。 */
  removeOnSessionMessageCallback(): void {
    this.onSessionMessageCallback = null;
  }

  /** 设置聊天详情的新消息回调。 */
  setOnDetailMessageCallback(callback: ((data: WsNewMessageData) => void) | null): void {
    this.onDetailMessageCallback = callback;
  }

  /** 移除聊天详情的新消息回调。 */
  removeOnDetailMessageCallback(): void {
    this.onDetailMessageCallback = null;
  }

  /** 检查 WebSocket 是否已连接 */
  isConnected(): boolean {
    return this.connected;
  }

  /** 建立 WebSocket 连接 */
  connect(): void {
    if (this.connected || this.ws !== null) {
      return;
    }

    const token: string = ApiClient.getToken();
    if (!token) {
      return;
    }

    const url: string = ServerConfig.toWebSocketUrl(ApiClient.BASE_URL, token);

    try {
      const socket: webSocket.WebSocket = webSocket.createWebSocket();
      this.ws = socket;

      // 连接成功事件：启动 PING 保活
      socket.on('open', () => {
        this.connected = true;
        this.reconnectCount = 0;
        this.startPing();
      });

      // 接收消息事件：解析 JSON 并分发
      socket.on('message', (err: BusinessError, value: Object) => {
        if (err) {
          return;
        }
        const msgObj = value as Record<string, Object>;
        const rawData = msgObj['data'];
        const dataStr: string = typeof rawData === 'string' ? rawData : '';
        if (dataStr) {
          this.handleMessage(dataStr);
        }
      });

      // 连接关闭事件：清理资源并安排重连
      socket.on('close', () => {
        this.connected = false;
        this.stopPing();
        this.ws = null;
        this.scheduleReconnect();
      });

      // 连接错误事件：close 事件会在 error 后自动触发
      socket.on('error', () => {
        // 重连逻辑在 close 事件中处理
      });

      // 发起连接（失败由 error/close 事件处理重连）
      socket.connect(url);
    } catch {
      this.ws = null;
      this.scheduleReconnect();
    }
  }

  /** 断开 WebSocket 连接 */
  disconnect(): void {
    this.cancelReconnect();
    this.stopPing();
    this.onSessionMessageCallback = null;
    this.onDetailMessageCallback = null;
    if (this.ws) {
      try {
        this.ws.close().catch(() => {});
      } catch {
        // 忽略关闭异常
      }
      this.ws = null;
    }
    this.connected = false;
  }

  /** 发送 PING 保活消息 */
  sendPing(): void {
    if (this.ws && this.connected) {
      try {
        this.ws.send('{"type":"PING","data":{}}').catch(() => {});
      } catch {
        // 忽略发送异常
      }
    }
  }

  /** 处理接收到的 WebSocket 消息 */
  private handleMessage(data: string): void {
    let msg: WsProtocolMessage;
    try {
      msg = JSON.parse(data) as WsProtocolMessage;
    } catch {
      return;
    }

    if (msg.type === 'NEW_MESSAGE') {
      const messageData: WsNewMessageData = msg.data as WsNewMessageData;
      if (this.onSessionMessageCallback) {
        this.onSessionMessageCallback(messageData);
      }
      if (this.onDetailMessageCallback) {
        this.onDetailMessageCallback(messageData);
      }
    }
    // ERROR 类型消息忽略处理
  }

  /** 启动 30 秒 PING 保活定时器 */
  private startPing(): void {
    this.stopPing();
    this.pingTimerId = setInterval(() => {
      this.sendPing();
    }, this.pingInterval);
  }

  /** 停止 PING 保活定时器 */
  private stopPing(): void {
    if (this.pingTimerId !== -1) {
      clearInterval(this.pingTimerId);
      this.pingTimerId = -1;
    }
  }

  /** 安排断线重连（5 秒后重试，最多 5 次） */
  private scheduleReconnect(): void {
    if (this.reconnectCount >= this.maxReconnectCount) {
      return;
    }
    this.cancelReconnect();
    this.reconnectTimerId = setTimeout(() => {
      this.reconnectCount++;
      this.connect();
    }, this.reconnectDelay);
  }

  /** 取消重连定时器 */
  private cancelReconnect(): void {
    if (this.reconnectTimerId !== -1) {
      clearTimeout(this.reconnectTimerId);
      this.reconnectTimerId = -1;
    }
  }
}
