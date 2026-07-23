import { describe, expect, it } from '@ohos/hypium'
import { ResumeCardData } from '../main/ets/services/RecruiterTypes'
import { RecruiterResumeFilter } from '../main/ets/common/RecruiterResumeFilter'

function createResume(id: string, region: string, type: string): ResumeCardData {
  return {
    id: id,
    name: '候选人',
    age: 0,
    avatar: '',
    education: '',
    school: '',
    major: '',
    experience: '',
    skills: '',
    region: region,
    type: type,
    category: '',
    expectedSalary: '',
    description: ''
  }
}

export default function recruiterResumeFilterTest(): void {
  describe('招聘者人才筛选策略', (): void => {
    it('接口未提供地区字段时不将候选人全部过滤', 0, (): void => {
      const resumes: ResumeCardData[] = [createResume('1', '', '')]
      const result: ResumeCardData[] = RecruiterResumeFilter.filter(resumes, ['浙江'], [])
      expect(result.length).assertEqual(1)
    })

    it('存在地区和类型字段时按选择条件筛选', 0, (): void => {
      const resumes: ResumeCardData[] = [
        createResume('1', '浙江-杭州', '技术-前端'),
        createResume('2', '上海', '运营')
      ]
      const result: ResumeCardData[] = RecruiterResumeFilter.filter(resumes, ['浙江'], ['技术'])
      expect(result.length).assertEqual(1)
      expect(result[0].id).assertEqual('1')
    })
  })
}
