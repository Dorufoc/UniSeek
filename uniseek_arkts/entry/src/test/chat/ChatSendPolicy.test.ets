import { describe, it, expect } from '@ohos/hypium';
import { ChatSendGuard } from '../../main/ets/common/BusinessPolicies';

export default function chatSendPolicyTest() {
  describe('ChatSendGuard', () => {
    it('同一时间只允许一个发送请求占用发送资格', 0, () => {
      const guard: ChatSendGuard = new ChatSendGuard()

      expect(guard.tryAcquire()).assertTrue()
      expect(guard.tryAcquire()).assertFalse()

      guard.release()

      expect(guard.tryAcquire()).assertTrue()
    })
  })
}
