// ChatComponents.test.ets — 聊天组件导入编译与存在性验证
// 由于本地单元测试未集成本地 UI 渲染框架，本文件先验证组件可被测试包导入并编译通过。

import { describe, it, expect } from '@ohos/hypium';
import { Avatar } from '../../main/ets/components/chat/Avatar';
import { UnreadBadge } from '../../main/ets/components/chat/UnreadBadge';
import { MessageBubble } from '../../main/ets/components/chat/MessageBubble';
import { ChatImageMessage } from '../../main/ets/components/chat/ChatImageMessage';
import { AttachmentCard } from '../../main/ets/components/chat/AttachmentCard';
import { MessageInputBar } from '../../main/ets/components/chat/MessageInputBar';
import { MessageTimeLabel } from '../../main/ets/components/chat/MessageTimeLabel';
import { MessageDateSeparator } from '../../main/ets/components/chat/MessageDateSeparator';

export default function chatComponentsTest() {
  describe('ChatComponents import smoke', () => {
    it('all chat components are importable', 0, () => {
      expect(Avatar !== undefined).assertTrue()
      expect(UnreadBadge !== undefined).assertTrue()
      expect(MessageBubble !== undefined).assertTrue()
      expect(ChatImageMessage !== undefined).assertTrue()
      expect(AttachmentCard !== undefined).assertTrue()
      expect(MessageInputBar !== undefined).assertTrue()
      expect(MessageTimeLabel !== undefined).assertTrue()
      expect(MessageDateSeparator !== undefined).assertTrue()
    })
  })
}
