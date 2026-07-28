import { ApplicationActionConfig } from '../services/RecruiterTypes'

/** 企业认证资料的提交方式。 */
export class EnterpriseSubmissionPolicy {
  static resolveMethod(hasEnterprise: boolean): string {
    return hasEnterprise ? 'PUT' : 'POST'
  }
}

/** 简历完整度与发布前置条件。 */
export class ResumeCompletionPolicy {
  static calculate(realName: string, gender: number, birthDate: string, education: string,
    school: string, graduationDate: string, skills: string, experience: string): number {
    let completed: number = 0
    if (realName.trim().length > 0) completed++
    if (gender === 0 || gender === 1) completed++
    if (birthDate.trim().length > 0) completed++
    if (education.trim().length > 0) completed++
    if (school.trim().length > 0) completed++
    if (graduationDate.trim().length > 0) completed++
    if (skills.trim().length > 0) completed++
    if (experience.trim().length > 0) completed++
    return Math.round(completed * 100 / 8)
  }

  static canPublish(realName: string, gender: number, birthDate: string, education: string,
    school: string, graduationDate: string): boolean {
    const hasGender: boolean = gender === 0 || gender === 1
    return realName.trim().length > 0 && hasGender && birthDate.trim().length > 0 &&
      education.trim().length > 0 && school.trim().length > 0 && graduationDate.trim().length > 0
  }
}

/** 人才市场支持的后端筛选值。 */
export class TalentFilterPolicy {
  static normalize(value: string): string {
    if (value === '有附件简历' || value === '在校生' || value === '有工作经验') {
      return value
    }
    return '全部'
  }
}

/** 招聘方处理投递时的必填说明规则。 */
export class ApplicationNotePolicy {
  static isValid(value: string): boolean {
    return value.trim().length > 0
  }
}

/** 招聘方处理投递时的可选操作（与 Vue ResumePool 对齐）。 */
export class ApplicationActionPolicy {
  /**
   * 根据当前状态返回可执行操作。
   * 0 已投递 -> 邀请面试 / 待定 / 淘汰
   * 1 待面试 -> 录用 / 待定 / 淘汰
   * 2 待定   -> 安排面试 / 录用 / 淘汰
   * 3 已录用 -> 终态，不再继续流转
   */
  static getActions(status: number): ApplicationActionConfig[] {
    switch (status) {
      case 0:
        return [
          { targetStatus: 1, label: '邀请面试', variant: 'primary', requiresDialog: 'interview' },
          { targetStatus: 2, label: '待定', variant: 'warning' },
          { targetStatus: 4, label: '淘汰', variant: 'danger', requiresDialog: 'reject' }
        ]
      case 1:
        return [
          { targetStatus: 3, label: '录用', variant: 'success' },
          { targetStatus: 2, label: '待定', variant: 'warning' },
          { targetStatus: 4, label: '淘汰', variant: 'danger', requiresDialog: 'reject' }
        ]
      case 2:
        return [
          { targetStatus: 1, label: '安排面试', variant: 'primary', requiresDialog: 'interview' },
          { targetStatus: 3, label: '录用', variant: 'success' },
          { targetStatus: 4, label: '淘汰', variant: 'danger', requiresDialog: 'reject' }
        ]
      default:
        return []
    }
  }
}

/** 通用分页继续加载判断。 */
export class PageLoadPolicy {
  static hasNext(page: number, totalPages: number): boolean {
    return totalPages > 0 && page < totalPages
  }
}

/** WebSocket 新消息追加策略，仅按服务端消息 ID 去重。 */
export class ChatMessagePolicy {
  static shouldAppend(messageId: number, senderId: number, currentUserId: number, existingIds: number[]): boolean {
    return !existingIds.includes(messageId)
  }
}
