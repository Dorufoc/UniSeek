import { describe, expect, it } from '@ohos/hypium'
import { ApplicationNotePolicy, ChatMessagePolicy, EnterpriseSubmissionPolicy, PageLoadPolicy, ResumeCompletionPolicy, TalentFilterPolicy } from '../main/ets/common/BusinessPolicies'
import { InputValidator, UploadPolicy } from '../main/ets/common/FormValidators'
import { ServerConfig } from '../main/ets/services/ServerConfig'

export default function auditPoliciesTest(): void {
  describe('审计问题修复策略', (): void => {
    it('后端地址转换为同主机的WebSocket地址', 0, (): void => {
      expect(ServerConfig.toWebSocketUrl('http://127.0.0.1:8080/', 'abc')).assertEqual('ws://127.0.0.1:8080/ws/chat?token=abc')
      expect(ServerConfig.toWebSocketUrl('https://api.example.com', 'a b')).assertEqual('wss://api.example.com/ws/chat?token=a%20b')
    })

    it('附件地址会解析为当前后端的完整地址', 0, (): void => {
      expect(ServerConfig.toHttpUrl('https://api.example.com/', '/uploads/resume.pdf')).assertEqual('https://api.example.com/uploads/resume.pdf')
      expect(ServerConfig.toHttpUrl('http://127.0.0.1:8080', 'https://cdn.example.com/resume.pdf')).assertEqual('https://cdn.example.com/resume.pdf')
    })

    it('企业资料存在时使用更新接口', 0, (): void => {
      expect(EnterpriseSubmissionPolicy.resolveMethod(false)).assertEqual('POST')
      expect(EnterpriseSubmissionPolicy.resolveMethod(true)).assertEqual('PUT')
    })

    it('注册字段执行完整格式校验', 0, (): void => {
      expect(InputValidator.isPhone('13800138000')).assertTrue()
      expect(InputValidator.isPhone('1380013800')).assertFalse()
      expect(InputValidator.isEmail('user@example.com')).assertTrue()
      expect(InputValidator.isEmail('user@')).assertFalse()
      expect(InputValidator.isStrongPassword('Abc12345')).assertTrue()
      expect(InputValidator.isStrongPassword('12345678')).assertFalse()
      expect(InputValidator.isNickname('求职者小林')).assertTrue()
      expect(InputValidator.isNickname(' ')).assertFalse()
    })

    it('身份证校验包含日期与校验码', 0, (): void => {
      expect(InputValidator.isValidIdCard('11010519491231002X')).assertTrue()
      expect(InputValidator.isValidIdCard('11010519490231002X')).assertFalse()
      expect(InputValidator.isValidIdCard('110105194912310021')).assertFalse()
    })

    it('附件与营业执照执行类型和大小限制', 0, (): void => {
      expect(UploadPolicy.validateResume('个人简历.pdf', 10 * 1024 * 1024)).assertEqual('')
      expect(UploadPolicy.validateResume('个人简历.doc', 1024)).assertEqual('仅支持 PDF 格式')
      expect(UploadPolicy.validateResume('个人简历.pdf', 10 * 1024 * 1024 + 1)).assertEqual('文件大小不能超过 10MB')
      expect(UploadPolicy.validateLicense('营业执照.png', 5 * 1024 * 1024)).assertEqual('')
      expect(UploadPolicy.validateLicense('营业执照.pdf', 1024)).assertEqual('请选择 JPG、PNG、GIF 或 WebP 图片')
      expect(UploadPolicy.validateLicense('营业执照.jpg', 5 * 1024 * 1024 + 1)).assertEqual('图片大小不能超过 5MB')
    })

    it('简历完整度与发布条件保持一致', 0, (): void => {
      expect(ResumeCompletionPolicy.calculate('张三', 1, '2000-01-01', '本科', '某大学', '2024-06-30', 'ArkTS', '项目经验')).assertEqual(100)
      expect(ResumeCompletionPolicy.canPublish('张三', 1, '2000-01-01', '本科', '某大学', '2024-06-30')).assertTrue()
      expect(ResumeCompletionPolicy.canPublish('', 1, '2000-01-01', '本科', '某大学', '2024-06-30')).assertFalse()
    })

    it('人才市场筛选值与后端契约一致', 0, (): void => {
      expect(TalentFilterPolicy.normalize('有附件简历')).assertEqual('有附件简历')
      expect(TalentFilterPolicy.normalize('在校生')).assertEqual('在校生')
      expect(TalentFilterPolicy.normalize('有工作经验')).assertEqual('有工作经验')
      expect(TalentFilterPolicy.normalize('未知')).assertEqual('全部')
    })

    it('淘汰和结算说明不接受空白内容', 0, (): void => {
      expect(ApplicationNotePolicy.isValid('候选人经验与岗位要求不匹配')).assertTrue()
      expect(ApplicationNotePolicy.isValid('  ')).assertFalse()
    })

    it('分页加载只在还有下一页时继续请求', 0, (): void => {
      expect(PageLoadPolicy.hasNext(1, 3)).assertTrue()
      expect(PageLoadPolicy.hasNext(3, 3)).assertFalse()
      expect(PageLoadPolicy.hasNext(1, 0)).assertFalse()
    })

    it('WebSocket忽略自己发送和已经存在的消息', 0, (): void => {
      const existingIds: number[] = [11, 12]
      expect(ChatMessagePolicy.shouldAppend(13, 8, 9, existingIds)).assertTrue()
      expect(ChatMessagePolicy.shouldAppend(13, 9, 9, existingIds)).assertFalse()
      expect(ChatMessagePolicy.shouldAppend(12, 8, 9, existingIds)).assertFalse()
    })
  })
}
