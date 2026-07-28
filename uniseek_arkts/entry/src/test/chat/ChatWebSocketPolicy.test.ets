// ChatWebSocketPolicy.test.ets — WebSocket 消息策略与协议映射回归测试

import { describe, it, expect } from '@ohos/hypium';
import { ChatMessagePolicy } from '../../main/ets/common/BusinessPolicies';
import { mapWsNewMessageToChatMessageVO } from '../../main/ets/common/ChatProtocolMappers';
import { WsNewMessageData } from '../../main/ets/services/ChatTypes';

export default function chatWebSocketPolicyTest() {
  describe('ChatMessagePolicy', () => {
    // 按 messageId 去重，重复 ID 不应追加
    it('shouldAppend rejects duplicate messageId', 0, () => {
      const existingIds: number[] = [1, 2, 3]
      expect(ChatMessagePolicy.shouldAppend(2, 100, 200, existingIds)).assertFalse()
    })

    // 新消息 ID 来自 HR 时应接受，策略不应对发送方做过滤
    it('shouldAppend accepts new messageId from HR', 0, () => {
      const existingIds: number[] = [1, 2]
      expect(ChatMessagePolicy.shouldAppend(3, 100, 200, existingIds)).assertTrue()
    })

    // 发送方为自己的消息不应追加，避免自己发送的消息通过 WebSocket 再次入库
    it('shouldAppend rejects new messageId from self', 0, () => {
      const existingIds: number[] = [1]
      expect(ChatMessagePolicy.shouldAppend(2, 200, 200, existingIds)).assertFalse()
    })
  })

  describe('ChatProtocolMappers', () => {
    // 协议映射核心：服务端 messageId 必须映射为 ChatMessageVO.id
    it('mapWsNewMessageToChatMessageVO maps messageId to id', 0, () => {
      const data: WsNewMessageData = {
        messageId: 42,
        applicationId: 10,
        senderId: 100,
        senderName: 'HR',
        senderAvatar: 'https://example.com/avatar.png',
        content: '你好',
        messageType: 0,
        sendTime: '2026-07-28T10:00:00',
        isRead: 0
      }
      const vo = mapWsNewMessageToChatMessageVO(data)
      expect(vo.id).assertEqual(42)
      expect(vo.senderId).assertEqual(100)
      expect(vo.messageType).assertEqual(0)
      expect(vo.content).assertEqual('你好')
      expect(vo.isRead).assertEqual(0)
      expect(vo.sendTime).assertEqual('2026-07-28T10:00:00')
      expect(vo.senderName).assertEqual('HR')
      expect(vo.senderAvatar).assertEqual('https://example.com/avatar.png')
    })
  })
}
