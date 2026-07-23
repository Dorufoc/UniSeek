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

/** 通用分页继续加载判断。 */
export class PageLoadPolicy {
  static hasNext(page: number, totalPages: number): boolean {
    return totalPages > 0 && page < totalPages
  }
}

/** WebSocket 新消息追加策略，防止自己发送的消息和重复推送。 */
export class ChatMessagePolicy {
  static shouldAppend(messageId: number, senderId: number, currentUserId: number, existingIds: number[]): boolean {
    if (senderId === currentUserId) {
      return false
    }
    return !existingIds.includes(messageId)
  }
}
