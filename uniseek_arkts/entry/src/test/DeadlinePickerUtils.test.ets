import { describe, expect, it } from '@ohos/hypium'
import { applyDatePickerResult, applyTimePickerResult } from '../main/ets/utils/DeadlinePickerUtils'

export default function deadlinePickerUtilsTest(): void {
  describe('截止时间选择结果转换', (): void => {
    it('日期列滚动时应保留DatePicker返回的三月', 0, (): void => {
      const selected: Date = new Date(2026, 2, 31, 14, 30)
      const result: Date = applyDatePickerResult(selected, { year: 2026, month: 2, day: 30 })
      expect(result.getFullYear()).assertEqual(2026)
      expect(result.getMonth()).assertEqual(2)
      expect(result.getDate()).assertEqual(30)
      expect(result.getHours()).assertEqual(14)
      expect(result.getMinutes()).assertEqual(30)
    })

    it('一月的零基月份不应被解析为上一年十二月', 0, (): void => {
      const selected: Date = new Date(2026, 0, 15, 10, 0)
      const result: Date = applyDatePickerResult(selected, { year: 2026, month: 0, day: 15 })
      expect(result.getFullYear()).assertEqual(2026)
      expect(result.getMonth()).assertEqual(0)
    })

    it('时间列调整时应保留日期并更新时间', 0, (): void => {
      const selected: Date = new Date(2026, 2, 31, 14, 30)
      const result: Date = applyTimePickerResult(selected, { hour: 23, minute: 59, second: 0 })
      expect(result.getFullYear()).assertEqual(2026)
      expect(result.getMonth()).assertEqual(2)
      expect(result.getDate()).assertEqual(31)
      expect(result.getHours()).assertEqual(23)
      expect(result.getMinutes()).assertEqual(59)
    })
  })
}
