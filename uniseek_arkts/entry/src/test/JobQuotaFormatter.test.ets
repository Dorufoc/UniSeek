import { describe, expect, it } from '@ohos/hypium'
import { formatRemainingText } from '../main/ets/utils/JobQuotaFormatter'

export default function jobQuotaFormatterTest(): void {
  describe('职位名额状态文案', (): void => {
    it('有有效总名额时显示剩余名额和总名额', 0, (): void => {
      expect(formatRemainingText(5, 10)).assertEqual('剩 5 / 10 人')
    })

    it('总名额缺失时不应显示无效分母', 0, (): void => {
      expect(formatRemainingText(5, 0)).assertEqual('剩 5 人')
    })

    it('剩余名额为零时显示已招满', 0, (): void => {
      expect(formatRemainingText(0, 10)).assertEqual('已招满')
    })

    it('剩余名额异常为负数时仍显示已招满', 0, (): void => {
      expect(formatRemainingText(-1, 10)).assertEqual('已招满')
    })
  })
}
