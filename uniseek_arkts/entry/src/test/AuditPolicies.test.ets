import { describe, expect, it } from '@ohos/hypium'
import { ApplicationNotePolicy, ChatMessagePolicy, EnterpriseSubmissionPolicy, PageLoadPolicy, ResumeCompletionPolicy, TalentFilterPolicy } from '../main/ets/common/BusinessPolicies'
import { InputValidator, UploadPolicy } from '../main/ets/common/FormValidators'
import { ServerConfig } from '../main/ets/services/ServerConfig'
import { FileTransferPolicy, UploadResponse } from '../main/ets/services/FileTransferPolicy'
import { ResumeEditPolicy, ResumeEditState } from '../main/ets/common/ResumeEditPolicy'

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

    it('文件传输链路解析Picker文件名和PDF类型', 0, (): void => {
      expect(FileTransferPolicy.extractFileName('file://docs/%E7%AE%80%E5%8E%86.pdf?open=true', '简历.pdf'))
        .assertEqual('简历.pdf')
      expect(FileTransferPolicy.extractFileName('datashare://document/12345', '简历.pdf'))
        .assertEqual('简历.pdf')
      expect(FileTransferPolicy.getMimeType('resume.PDF')).assertEqual('application/pdf')
    })

    it('文件传输链路严格解析上传响应和相对地址', 0, (): void => {
      const response: UploadResponse = {
        code: 200,
        message: '上传成功',
        data: { url: '/api/files/files/resume.pdf' }
      }
      expect(FileTransferPolicy.readUploadUrl(response)).assertEqual('/api/files/files/resume.pdf')
      expect(FileTransferPolicy.readUploadUrl({
        code: 200,
        message: '上传成功',
        data: { url: '' }
      })).assertEqual('')
      expect(FileTransferPolicy.resolveUrl('http://127.0.0.1:8080', '/api/files/files/resume.pdf'))
        .assertEqual('http://127.0.0.1:8080/api/files/files/resume.pdf')
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
      expect(InputValidator.isStrongPassword('密码123456')).assertFalse()
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
      expect(UploadPolicy.validateLicense('营业执照.gif', 1024)).assertEqual('请选择 JPG、JPEG、PNG 或 WebP 图片')
      expect(UploadPolicy.validateLicense('营业执照.pdf', 1024)).assertEqual('请选择 JPG、JPEG、PNG 或 WebP 图片')
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

    it('淘汰说明不接受空白内容', 0, (): void => {
      expect(ApplicationNotePolicy.isValid('候选人经验与岗位要求不匹配')).assertTrue()
      expect(ApplicationNotePolicy.isValid('  ')).assertFalse()
    })

    it('实名认证信息覆盖姓名、性别和出生日期', 0, (): void => {
      const state: ResumeEditState = {
        name: '', gender: -1, birthDate: '', education: '本科', school: '某大学',
        graduationDate: '2024-06-30', skills: 'ArkTS', experience: '项目经验', attachmentUrl: ''
      }
      const merged = ResumeEditPolicy.mergeAuthData(state, {
        isAuth: true, realName: '张三', gender: 0, birthDate: '20000101'
      })
      expect(merged.name).assertEqual('张三')
      expect(merged.gender).assertEqual(0)
      expect(merged.birthDate).assertEqual('2000-01-01')
    })

    it('保存请求包含完整简历字段且不包含实名姓名', 0, (): void => {
      const request = ResumeEditPolicy.buildRequest({
        name: '张三', gender: 1, birthDate: '2000-01-01', education: '硕士', school: '某大学',
        graduationDate: '2025-06-30', skills: 'ArkTS', experience: '项目经验', attachmentUrl: '/files/a.pdf'
      })
      expect(request.gender).assertEqual(1)
      expect(request.birthDate).assertEqual('2000-01-01')
      expect(request.education).assertEqual('硕士')
      expect(request.school).assertEqual('某大学')
      expect(request.graduationDate).assertEqual('2025-06-30')
      expect(request.skills).assertEqual('ArkTS')
      expect(request.experience).assertEqual('项目经验')
      expect(request.attachmentUrl).assertEqual('/files/a.pdf')
    })

    it('初始化或保存中不触发自动保存', 0, (): void => {
      expect(ResumeEditPolicy.canAutoSave(true, false)).assertFalse()
      expect(ResumeEditPolicy.canAutoSave(false, true)).assertFalse()
      expect(ResumeEditPolicy.canAutoSave(false, false)).assertTrue()
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
