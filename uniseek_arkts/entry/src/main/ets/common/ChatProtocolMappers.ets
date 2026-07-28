// ChatProtocolMappers.ets — WebSocket 聊天消息协议到业务 VO 的纯映射
// 抽离为独立纯函数，方便单元测试并避免测试依赖 @ohos.net.webSocket 系统 API。

import { ChatMessageVO, WsNewMessageData } from '../services/ChatTypes';

/**
 * 将 WebSocket 推送的 NEW_MESSAGE 数据映射为 ChatMessageVO。
 * 本函数是协议映射的唯一收口：服务端字段 messageId 统一映射为 ChatMessageVO.id。
 */
export function mapWsNewMessageToChatMessageVO(data: WsNewMessageData): ChatMessageVO {
  return {
    id: data.messageId,
    senderId: data.senderId,
    messageType: data.messageType,
    content: data.content,
    isRead: data.isRead,
    sendTime: data.sendTime,
    senderName: data.senderName,
    senderAvatar: data.senderAvatar
  }
}
