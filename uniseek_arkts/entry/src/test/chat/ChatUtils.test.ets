// ChatUtils.test.ets — 聊天通用工具函数单测

import { describe, it, expect } from '@ohos/hypium';
import {
  formatSessionTime,
  formatMessageTime,
  shouldShowTimeLabel,
  getDateSeparatorLabel,
  getAttachmentName,
  getResumeAttachmentContent
} from '../../main/ets/components/chat/ChatMessageUtils';
import { ResumeData } from '../../main/ets/services/ResumeService';

export default function chatUtilsTest() {
  describe('ChatMessageUtils', () => {
    // 格式化会话时间：空串、当天、昨天、更早
    it('formatSessionTime empty', 0, () => {
      expect(formatSessionTime('')).assertEqual('')
    })

    it('formatSessionTime today', 0, () => {
      const now: Date = new Date()
      const dateStr: string = buildIsoString(now)
      expect(formatSessionTime(dateStr)).assertEqual(dateStr.substring(11, 16))
    })

    it('formatSessionTime yesterday', 0, () => {
      const d: Date = new Date(new Date().getTime() - 25 * 60 * 60 * 1000)
      expect(formatSessionTime(buildIsoString(d))).assertEqual('昨天')
    })

    it('formatSessionTime older', 0, () => {
      const d: Date = new Date(new Date().getTime() - 3 * 24 * 60 * 60 * 1000)
      expect(formatSessionTime(buildIsoString(d))).assertEqual(buildIsoString(d).substring(5, 10))
    })

    // 消息时间标签间隔判断
    it('shouldShowTimeLabel empty previous', 0, () => {
      expect(shouldShowTimeLabel('', buildIsoString(new Date()))).assertTrue()
    })

    it('shouldShowTimeLabel empty current', 0, () => {
      expect(shouldShowTimeLabel(buildIsoString(new Date()), '')).assertFalse()
    })

    it('shouldShowTimeLabel within five minutes', 0, () => {
      const t1: Date = new Date(2026, 0, 1, 10, 0, 0)
      const t2: Date = new Date(2026, 0, 1, 10, 4, 0)
      expect(shouldShowTimeLabel(buildIsoString(t1), buildIsoString(t2))).assertFalse()
    })

    it('shouldShowTimeLabel over five minutes', 0, () => {
      const t1: Date = new Date(2026, 0, 1, 10, 0, 0)
      const t2: Date = new Date(2026, 0, 1, 10, 6, 0)
      expect(shouldShowTimeLabel(buildIsoString(t1), buildIsoString(t2))).assertTrue()
    })

    it('shouldShowTimeLabel invalid previous', 0, () => {
      expect(shouldShowTimeLabel('invalid', buildIsoString(new Date()))).assertTrue()
    })

    // 消息内时间格式化
    it('formatMessageTime valid', 0, () => {
      const dateStr: string = '2026-07-24T14:30:00.000Z'
      expect(formatMessageTime(dateStr)).assertEqual('14:30')
    })

    it('formatMessageTime empty', 0, () => {
      expect(formatMessageTime('')).assertEqual('')
    })

    // 日期分隔线文案
    it('getDateSeparatorLabel empty', 0, () => {
      expect(getDateSeparatorLabel('')).assertEqual('')
    })

    it('getDateSeparatorLabel today', 0, () => {
      expect(getDateSeparatorLabel(buildIsoString(new Date()))).assertEqual('今天')
    })

    it('getDateSeparatorLabel yesterday', 0, () => {
      const d: Date = new Date(new Date().getTime() - 25 * 60 * 60 * 1000)
      expect(getDateSeparatorLabel(buildIsoString(d))).assertEqual('昨天')
    })

    it('getDateSeparatorLabel older', 0, () => {
      const d: Date = new Date(2026, 4, 20, 10, 0, 0)
      expect(getDateSeparatorLabel(buildIsoString(d))).assertEqual('05-20')
    })

    // 附件名称提取
    it('getAttachmentName empty uses default', 0, () => {
      expect(getAttachmentName('')).assertEqual('简历附件')
    })

    it('getAttachmentName empty with custom default', 0, () => {
      expect(getAttachmentName('', '默认文件')).assertEqual('默认文件')
    })

    it('getAttachmentName normal', 0, () => {
      expect(getAttachmentName('https://example.com/files/resume.pdf')).assertEqual('resume.pdf')
    })

    it('getAttachmentName long', 0, () => {
      const longName: string = 'thisisaverylongresumefilenameforexample.pdf'
      const url: string = 'https://example.com/files/' + longName
      const result: string = getAttachmentName(url)
      expect(result.length <= 30).assertTrue()
      expect(result.indexOf('...') > -1).assertTrue()
    })

    // 简历附件消息内容提取：确保已保存附件的 URL 作为 messageType=2 的 content 发送
    it('getResumeAttachmentContent keeps saved attachment url', 0, () => {
      const url: string = '/api/files/resume.pdf'
      const resume: ResumeData = buildResumeData(url)
      expect(getResumeAttachmentContent(resume)).assertEqual(url)
    })

    it('getResumeAttachmentContent trims whitespace', 0, () => {
      const url: string = '/api/files/resume.pdf'
      const resume: ResumeData = buildResumeData('  ' + url + '  ')
      expect(getResumeAttachmentContent(resume)).assertEqual(url)
    })

    it('getResumeAttachmentContent returns empty when resume is null', 0, () => {
      expect(getResumeAttachmentContent(null)).assertEqual('')
    })

    it('getResumeAttachmentContent returns empty when attachmentUrl is missing', 0, () => {
      const resume: ResumeData = buildResumeData('')
      expect(getResumeAttachmentContent(resume)).assertEqual('')
    })
  })
}

// 辅助：构造测试用的简历数据，仅 attachmentUrl 可变
function buildResumeData(attachmentUrl: string): ResumeData {
  const resume: ResumeData = {
    id: 1,
    userId: 1,
    gender: 0,
    birthDate: '2000-01-01',
    education: '本科',
    school: '测试大学',
    graduationDate: '2024-06-01',
    skills: '测试',
    experience: '测试经历',
    attachmentUrl: attachmentUrl,
    isPublished: 1,
    realName: '测试'
  }
  return resume
}

// 辅助：构造与 Date 绝对时间一致的 ISO 字符串，避免时区偏差导致测试不稳定
function buildIsoString(d: Date): string {
  return d.toISOString()
}
