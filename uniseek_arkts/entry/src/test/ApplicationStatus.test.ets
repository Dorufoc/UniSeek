import { describe, expect, it } from '@ohos/hypium'
import { ApplicationService } from '../main/ets/services/ApplicationService'

export default function applicationStatusTest(): void {
  describe('求职投递与职位状态映射', (): void => {
    it('已完成投递应显示已完成', 0, (): void => {
      expect(ApplicationService.statusLabel(5)).assertEqual('已完成')
    })

    it('职位状态应区分满员、过期、下架和驳回', 0, (): void => {
      expect(ApplicationService.taskStatusLabel(2)).assertEqual('已满员')
      expect(ApplicationService.taskStatusLabel(3)).assertEqual('已过期')
      expect(ApplicationService.taskStatusLabel(4)).assertEqual('已下架')
      expect(ApplicationService.taskStatusLabel(5)).assertEqual('已驳回')
    })
  })
}
