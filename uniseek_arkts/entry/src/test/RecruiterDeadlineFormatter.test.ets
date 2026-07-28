import { describe, it, expect } from '@ohos/hypium'
import { formatDeadlineForApi } from '../main/ets/services/RecruiterTypes'

/**
 * HR 职位表单 deadline 提交边界转换单元测试
 * 覆盖：空格分隔格式、ISO 分隔符缺少秒、已有秒数、前后空白、空字符串。
 */
export default function recruiterDeadlineFormatterTest(): void {
  describe('职位截止时间提交边界转换', (): void => {
    it('空格分隔的日期时间转换为 ISO-8601 带秒', 0, (): void => {
      expect(formatDeadlineForApi('2026-07-28 18:00')).assertEqual('2026-07-28T18:00:00')
    })

    it('ISO 分隔符缺少秒时补秒', 0, (): void => {
      expect(formatDeadlineForApi('2026-07-28T18:00')).assertEqual('2026-07-28T18:00:00')
    })

    it('已带秒数的 ISO 时间保持不变', 0, (): void => {
      expect(formatDeadlineForApi('2026-07-28T18:00:00')).assertEqual('2026-07-28T18:00:00')
    })

    it('前后空白字符会被去除', 0, (): void => {
      expect(formatDeadlineForApi(' 2026-07-28 18:00 ')).assertEqual('2026-07-28T18:00:00')
    })

    it('空字符串返回空字符串', 0, (): void => {
      expect(formatDeadlineForApi('')).assertEqual('')
    })
  })
}
