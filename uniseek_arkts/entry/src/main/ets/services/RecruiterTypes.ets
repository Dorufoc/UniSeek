export interface RecruiterJobVO {
  id: number
  title: string
  salaryMin: number
  salaryMax: number
  salaryUnit: number
  jobType: number
  address: string
  status: number
  rejectReason: string
  applicationCount: number
  remainingQuota: number
  totalQuota: number
  deadline: string
  createTime: string
}

export interface RecruiterApplicationVO {
  id: number
  taskId: number
  applicantId: number
  applicantName: string
  applicantAvatar: string
  status: number
  interviewTime: string
  interviewLocation: string
  rejectReason: string
  createTime: string
  resumeSnapshot?: string
  attachmentUrl?: string
}

export interface RecruiterEnterpriseVO {
  id: number
  companyName: string
  creditCode: string
  licenseImgUrl: string
  industry: string
  regionId: number
  regionName: string
  description: string
  auditStatus: number
}

export interface RecruiterJobRequest {
  title: string
  categoryId: number
  regionId: number
  description: string
  salaryMin: number
  salaryMax: number
  salaryUnit: number
  jobType: number
  totalQuota: number
  address: string
  tag: string[]
  deadline: string
}

export interface RecruiterEnterpriseRequest {
  companyName: string
  creditCode: string
  licenseImgUrl: string
  industry: string
  regionId: number
  description: string
}

export interface RecruiterUpdateStatusRequest {
  status: number
  interviewTime?: string
  interviewLocation?: string
  rejectReason?: string
  hrNote?: string
}

export interface ResumeCardData {
  id: string
  name: string
  age: number
  avatar: string
  education: string
  school: string
  major: string
  experience: string
  skills: string
  region: string
  type: string
  category: string
  expectedSalary: string
  description: string
  attachmentUrl?: string
  graduationDate?: string
  // 以下字段用于 HR 端求职者详情页，按需补充原生简历中不存在的信息
  gender?: number
  birthDate?: string
  applicationId?: number
  applicationStatus?: number
  jobTitle?: string
  createTime?: string
}

export interface RecruiterRequestVO {
  id: number
  applicantId: number
  applicantName: string
  applicantAvatar: string
  applicantAge: number
  applicantSchool: string
  applicantMajor: string
  applicantEducation: string
  applicantExperience: string
  applicantSkills: string
  applicantRegion: string
  applicantType: string
  applicantSalary: string
  jobTitle: string
  status: number
  interviewTime: string
  interviewLocation: string
  rejectReason: string
  createTime: string
  attachmentUrl: string
}

// 系统通知消息（与后端 notification 表对齐）
export interface NotificationVO {
  id: number
  receiverId: number
  senderId: number
  senderName?: string
  title: string
  content: string
  type: number
  isRead: number
  bizId: number
  createTime: string
}

// 通知未读数汇总
export interface UnreadCountVO {
  totalUnread?: number
  total?: number
}

// 投递记录可操作按钮配置
export interface ApplicationActionConfig {
  targetStatus: number
  label: string
  variant: 'primary' | 'success' | 'warning' | 'danger'
  requiresDialog?: 'interview' | 'reject'
}

export const JOB_STATUS_MAP: number[] = [0, 1, 2, 3, 4]
export const JOB_STATUS_LABELS: Record<number, string> = {
  0: '待审核',
  1: '招聘中',
  2: '已满员',
  3: '已过期',
  4: '已下架'
}

export const APPLICATION_STATUS_LABELS: Record<number, string> = {
  0: '已投递',
  1: '待面试',
  2: '待定',
  3: '已录用',
  4: '已淘汰'
}

export const AUDIT_STATUS_LABELS: Record<number, string> = {
  0: '审核中',
  1: '已认证',
  2: '已驳回'
}

export const SALARY_UNIT_LABELS: Record<number, string> = {
  0: '日薪',
  1: '时薪',
  2: '月薪'
}

export const JOB_TYPE_LABELS: Record<number, string> = {
  1: '全职',
  2: '兼职',
  3: '实习'
}

/**
 * 将页面展示的报名截止时间（YYYY-MM-DD HH:mm）转换为后端 LocalDateTime 可解析的 ISO-8601 格式。
 * 仅补充秒数，不改变日期与时间值。
 *
 * @param displayDeadline 用户界面上的截止时间字符串
 * @returns ISO-8601 格式字符串，例如 2026-07-28T18:00:00；空值返回空字符串
 */
export function formatDeadlineForApi(displayDeadline: string): string {
  const trimmed: string = displayDeadline.trim()
  if (trimmed.length === 0) {
    return ''
  }

  let iso: string = trimmed
  if (iso.indexOf('T') < 0) {
    const spaceIndex: number = iso.indexOf(' ')
    if (spaceIndex >= 0 && spaceIndex < iso.length) {
      iso = iso.substring(0, spaceIndex) + 'T' + iso.substring(spaceIndex + 1)
    }
  }

  const timePartStart: number = iso.indexOf('T')
  if (timePartStart >= 0 && timePartStart < iso.length) {
    const timePart: string = iso.substring(timePartStart + 1)
    let colonCount: number = 0
    for (let i = 0; i < timePart.length; i++) {
      if (timePart.charAt(i) === ':') {
        colonCount++
      }
    }
    if (colonCount === 1) {
      iso = iso + ':00'
    }
  }

  return iso
}
