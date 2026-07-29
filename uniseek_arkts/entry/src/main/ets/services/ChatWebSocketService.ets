// ChatWebSocketService.ets — WebSocket 实时推送服务
// 与 Vue 端 useChatWebSocket.ts 功能对齐
// 使用 @ohos.net.webSocket 实现 WebSocket 连接管理
// 功能：连接管理、PING 保活、断线重连、新消息推送

import webSocket from '@ohos.net.webSocket';
import { ApiClient } from './ApiClient';
import { ServerConfig } from './ServerConfig';
import { ChatService } from './ChatService';
import { WsNewMessageData } from './ChatTypes';
import { BusinessError } from '@kit.BasicServicesKit';

export { WsNewMessageData };

/** WebSocket 推送的 SEND_ACK 数据类型 */
export interface WsSendAckData {
  messageId: number;
  applicationId: number;
  sessionType?: string;
  messageType: number;
  content: string;
  sendTime: string;
}

/** 聊天详情页监听到的 NEW_MESSAGE 事件 */
export interface WsNewMessageEvent {
  type: 'NEW_MESSAGE';
  data: WsNewMessageData;
}

/** 聊天详情页监听到的 SEND_ACK 事件 */
export interface WsSendAckEvent {
  type: 'SEND_ACK';
  data: WsSendAckData;
}

/** 聊天详情页监听器可接收的事件联合类型 */
export type WsChatDetailEvent = WsNewMessageEvent | WsSendAckEvent;

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
  private sessionListeners: Map<string, ((data: WsNewMessageData) => void)> = new Map();
  private detailListeners: Map<string, ((event: WsChatDetailEvent) => void)> = new Map();
  private onUnreadCountChangedCallbacks: ((count: number) => void)[] = [];

  static getInstance(): ChatWebSocketService {
    if (ChatWebSocketService.instance === null) {
      ChatWebSocketService.instance = new ChatWebSocketService();
    }
    return ChatWebSocketService.instance;
  }

  /** 设置会话列表的新消息回调（兼容旧版，内部映射到 listenerId='legacy'）。 */
  setOnSessionMessageCallback(callback: ((data: WsNewMessageData) => void) | null): void {
    if (callback) {
      this.sessionListeners.set('legacy', callback);
    } else {
      this.sessionListeners.delete('legacy');
    }
  }

  /** 移除会话列表的新消息回调（兼容旧版）。 */
  removeOnSessionMessageCallback(): void {
    this.sessionListeners.delete('legacy');
  }

  /** 按 listenerId 注册会话列表的新消息回调。 */
  addSessionMessageListener(listenerId: string, callback: (data: WsNewMessageData) => void): void {
    this.sessionListeners.set(listenerId, callback);
  }

  /** 按 listenerId 移除会话列表的新消息回调。 */
  removeSessionMessageListener(listenerId: string): void {
    this.sessionListeners.delete(listenerId);
  }

  /** 设置聊天详情的新消息回调（兼容旧版，内部映射到 listenerId='legacy'，仅接收 NEW_MESSAGE）。 */
  setOnDetailMessageCallback(callback: ((data: WsNewMessageData) => void) | null): void {
    if (callback) {
      this.detailListeners.set('legacy', (event: WsChatDetailEvent) => {
        if (event.type === 'NEW_MESSAGE') {
          callback(event.data);
        }
      });
    } else {
      this.detailListeners.delete('legacy');
    }
  }

  /** 移除聊天详情的新消息回调（兼容旧版）。 */
  removeOnDetailMessageCallback(): void {
    this.detailListeners.delete('legacy');
  }

  /** 按 listenerId 注册聊天详情消息事件回调（可接收 NEW_MESSAGE / SEND_ACK）。 */
  addDetailMessageListener(listenerId: string, callback: (event: WsChatDetailEvent) => void): void {
    this.detailListeners.set(listenerId, callback);
  }

  /** 按 listenerId 移除聊天详情消息事件回调。 */
  removeDetailMessageListener(listenerId: string): void {
    this.detailListeners.delete(listenerId);
  }

  /**
   * 注册未读消息总数变化回调。
   * 回调参数为当前所有聊天会话 unreadCount 的总和（上限 99）。
   */
  addOnUnreadCountChanged(callback: (count: number) => void): void {
    this.onUnreadCountChangedCallbacks.push(callback);
  }

  /**
   * 移除未读消息总数变化回调。
   */
  removeOnUnreadCountChanged(callback: (count: number) => void): void {
    const index = this.onUnreadCountChangedCallbacks.indexOf(callback);
    if (index !== -1) {
      this.onUnreadCountChangedCallbacks.splice(index, 1);
    }
  }

  /** 检查 WebSocket 是否已连接 */
  isConnected(): boolean {
    return this.connected;
  }

  /** 建立 WebSocket 连接 */
  connect(): void {
    if (this.connected) {
      return;
    }

    // 连接状态异常时清理旧实例，避免旧连接阻塞后续重连。
    if (this.ws !== null) {
      try {
        this.ws.close().catch(() => {});
      } catch {
        // 旧连接关闭失败时继续创建新连接
      }
      this.ws = null;
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
        // 连接建立后立即同步一次未读消息总数
        this.refreshUnreadCount();
      });

      // 接收消息事件：解析 JSON 并分发
      socket.on('message', (err: BusinessError, value: Object) => {
        if (err) {
          return;
        }
        const dataStr: string = this.extractMessageText(value);
        if (dataStr.length > 0) {
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
    this.sessionListeners.clear();
    this.detailListeners.clear();
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

  /**
   * 主动拉取会话列表并计算未读消息总数，然后通知所有监听者。
   * 结果上限为 99（超过时显示 99+）。
   */
  async refreshUnreadCount(): Promise<void> {
    try {
      const sessions = await ChatService.getSessions();
      let total = 0;
      for (const session of sessions) {
        total += session.unreadCount || 0;
      }
      const displayCount = total > 99 ? 99 : total;
      this.notifyUnreadCountChanged(displayCount);
    } catch (e) {
      console.error('ChatWebSocket: 刷新未读数失败', e);
    }
  }

  /**
   * 通知未读数变化。
   */
  private notifyUnreadCountChanged(count: number): void {
    for (const callback of this.onUnreadCountChangedCallbacks) {
      callback(count);
    }
  }

  /** 发送 PING 保活消息 */
  sendPing(): void {
    if (this.ws && this.connected) {
      try {
        this.ws.send('{"type":"PING","data":{}}').catch(() => {
          this.handleConnectionFailure();
        });
      } catch {
        this.handleConnectionFailure();
      }
    }
  }

  /** 发送心跳失败时立即释放失效连接并启动重连。 */
  private handleConnectionFailure(): void {
    this.connected = false;
    this.stopPing();
    if (this.ws !== null) {
      try {
        this.ws.close().catch(() => {});
      } catch {
        // 失效连接关闭失败时仍需继续重连
      }
      this.ws = null;
    }
    this.scheduleReconnect();
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
      // 分发到所有会话列表监听器
      for (const callback of this.sessionListeners.values()) {
        callback(messageData);
      }
      const newMessageEvent: WsNewMessageEvent = { type: 'NEW_MESSAGE', data: messageData };
      // 分发到所有聊天详情监听器
      for (const callback of this.detailListeners.values()) {
        callback(newMessageEvent);
      }
      // 新消息会改变未读数，重新拉取会话列表计算总数
      this.refreshUnreadCount();
    } else if (msg.type === 'SEND_ACK') {
      const ackData: WsSendAckData = msg.data as WsSendAckData;
      const ackEvent: WsSendAckEvent = { type: 'SEND_ACK', data: ackData };
      // SEND_ACK 仅推送给发送方所在的详情页监听器，用于保证不重复追加
      for (const callback of this.detailListeners.values()) {
        callback(ackEvent);
      }
    } else if (msg.type === 'MESSAGE_READ') {
      // 对方已读回执也可能影响未读数
      this.refreshUnreadCount();
    }
    // ERROR 类型消息忽略处理
  }

  private extractMessageText(value: Object): string {
    if (typeof value === 'string') {
      return value;
    }
    const messageObject = value as Record<string, Object>;
    const rawData = messageObject['data'];
    if (typeof rawData === 'string') {
      return rawData;
    }
    return JSON.stringify(value);
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
