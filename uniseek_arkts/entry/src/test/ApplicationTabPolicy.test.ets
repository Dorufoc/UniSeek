import { describe, expect, it } from '@ohos/hypium'
import { ApplicationTabPolicy } from '../main/ets/common/ApplicationTabPolicy'

export default function applicationTabPolicyTest(): void {
  describe('求职记录页签策略', (): void => {
    it('缺省页签展示投递记录', 0, (): void => {
      expect(ApplicationTabPolicy.resolve('')).assertEqual(0)
    })

    it('面试入口展示面试邀请', 0, (): void => {
      expect(ApplicationTabPolicy.resolve('interviews')).assertEqual(1)
    })

    it('未知页签回退至投递记录', 0, (): void => {
      expect(ApplicationTabPolicy.resolve('unknown')).assertEqual(0)
    })
  })
}
