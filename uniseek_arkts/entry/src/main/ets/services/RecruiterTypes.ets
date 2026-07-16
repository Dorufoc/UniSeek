export interface RecruiterJobVO {
  id: number
  title: string
  salaryMin: number
  salaryMax: number
  salaryUnit: number
  jobType: number
  address: string
  status: number
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
  salaryMin: number
  salaryMax: number
  salaryUnit: number
  jobType: number
  totalQuota: number
  address: string
  tag: string
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
  interviewTime: string
  interviewLocation: string
  rejectReason: string
  hrNote: string
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
  4: '已淘汰',
  5: '已完成'
}

export const AUDIT_STATUS_LABELS: Record<number, string> = {
  0: '审核中',
  1: '已审核',
  2: '已驳回'
}

export const SALARY_UNIT_LABELS: Record<number, string> = {
  0: '日结',
  1: '时薪',
  2: '月结'
}

export const JOB_TYPE_LABELS: Record<number, string> = {
  1: '全职',
  2: '兼职',
  3: '实习'
}
