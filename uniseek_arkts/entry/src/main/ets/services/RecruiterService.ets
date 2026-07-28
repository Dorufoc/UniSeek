import { ApiClient, ApiEmpty } from './ApiClient';
import { PageResult } from './ResumeService';
import { TaskVO } from './ChatTypes';
import {
  RecruiterJobVO,
  RecruiterApplicationVO,
  RecruiterEnterpriseVO,
  RecruiterJobRequest,
  RecruiterEnterpriseRequest,
  RecruiterUpdateStatusRequest,
  RecruiterRequestVO,
  APPLICATION_STATUS_LABELS
} from './RecruiterTypes';
import { EnterpriseSubmissionPolicy } from '../common/BusinessPolicies'

const KEY_CACHE_ENTERPRISE_INFO = 'cached_enterprise_info'

interface ResumeSnapshot {
  realName?: string
  birthDate?: string
  education?: string
  school?: string
  skills?: string
  experience?: string
}

export class RecruiterService {
  /** 将企业认证信息持久化到本地，供离线时展示招聘者个人中心。 */
  static saveCachedEnterpriseInfo(info: RecruiterEnterpriseVO): void {
    const pref = ApiClient.getPreferenceStore()
    if (!pref) {
      return
    }
    pref.putSync(KEY_CACHE_ENTERPRISE_INFO, JSON.stringify(info))
    pref.flushSync()
  }

  /** 读取本地缓存的企业认证信息。 */
  static getCachedEnterpriseInfo(): RecruiterEnterpriseVO | null {
    const pref = ApiClient.getPreferenceStore()
    if (!pref) {
      return null
    }
    try {
      const raw: string = pref.getSync(KEY_CACHE_ENTERPRISE_INFO, '') as string
      if (!raw) {
        return null
      }
      return JSON.parse(raw) as RecruiterEnterpriseVO
    } catch {
      return null
    }
  }

  static async getMyJobs(): Promise<RecruiterJobVO[]> {
    const records: RecruiterJobVO[] = []
    let page: number = 1
    let totalPages: number = 1
    do {
      const result = await ApiClient.get<PageResult<RecruiterJobVO>>('/api/enterprise/tasks', [['page', String(page)], ['pageSize', '20']])
      const pageRecords = result?.records ?? []
      records.push(...pageRecords)
      totalPages = result?.totalPages ?? 0
      page++
    } while (page <= totalPages)
    return records
  }

  /**
   * 发布职位。失败时直接抛出 ApiClient 原始 Error，由调用方回显后端业务/鉴权/网络错误。
   */
  static async createJob(data: RecruiterJobRequest): Promise<void> {
    await ApiClient.post<ApiEmpty>('/api/tasks', data)
  }

  /**
   * 更新职位。失败时直接抛出 ApiClient 原始 Error，由调用方回显后端业务/鉴权/网络错误。
   */
  static async updateJob(jobId: number, data: RecruiterJobRequest): Promise<void> {
    await ApiClient.put<ApiEmpty>('/api/tasks/' + jobId, data)
  }

  static async updateJobStatus(jobId: number, targetStatus: number): Promise<boolean> {
    try {
      await ApiClient.put<ApiEmpty>('/api/tasks/' + jobId + '/status?targetStatus=' + targetStatus)
      return true
    } catch {
      return false
    }
  }

  static async resubmitJob(jobId: number): Promise<boolean> {
    try {
      await ApiClient.put<ApiEmpty>('/api/tasks/' + jobId + '/resubmit')
      return true
    } catch {
      return false
    }
  }
  static async getJobDetail(jobId: number): Promise<TaskVO | null> {
    try {
      return await ApiClient.get<TaskVO>('/api/tasks/' + jobId)
    } catch {
      return null
    }
  }

  static async getJobApplications(taskId: number): Promise<RecruiterApplicationVO[]> {
    const records: RecruiterApplicationVO[] = []
    let page: number = 1
    let totalPages: number = 1
    do {
      const result = await ApiClient.get<PageResult<RecruiterApplicationVO>>('/api/tasks/' + taskId + '/applications', [['page', String(page)], ['pageSize', '20']])
      const pageRecords = (result?.records ?? []).map((app: RecruiterApplicationVO) => {
        if (!app.applicantName && app.resumeSnapshot) {
          try {
            const snapshot = JSON.parse(app.resumeSnapshot) as ResumeSnapshot
            if (snapshot.realName) {
              app.applicantName = snapshot.realName
            }
          } catch {
            // JSON 解析失败则跳过
          }
        }
        return app
      })
      records.push(...pageRecords)
      totalPages = result?.totalPages ?? 0
      page++
    } while (page <= totalPages)
    return records
  }

  /** 通过投递记录 ID 查询详情，用于通知铃铛跳转定位。 */
  static async getApplicationById(applicationId: number): Promise<RecruiterApplicationVO | null> {
    try {
      return await ApiClient.get<RecruiterApplicationVO>('/api/applications/' + applicationId)
    } catch {
      return null
    }
  }

  static async updateApplicationStatus(applicationId: number, data: RecruiterUpdateStatusRequest): Promise<boolean> {
    try {
      await ApiClient.put<ApiEmpty>('/api/applications/' + applicationId + '/status', data)
      return true
    } catch {
      return false
    }
  }

  static async getEnterpriseInfo(): Promise<RecruiterEnterpriseVO | null> {
    try {
      const info = await ApiClient.get<RecruiterEnterpriseVO>('/api/enterprise/my')
      if (info) {
        RecruiterService.saveCachedEnterpriseInfo(info)
      }
      return info
    } catch {
      return null
    }
  }

  static async saveEnterpriseInfo(data: RecruiterEnterpriseRequest, hasEnterprise: boolean): Promise<boolean> {
    try {
      if (EnterpriseSubmissionPolicy.resolveMethod(hasEnterprise) === 'PUT') {
        await ApiClient.put<ApiEmpty>('/api/enterprise', data)
      } else {
        await ApiClient.post<ApiEmpty>('/api/enterprise', data)
      }
      return true
    } catch {
      return false
    }
  }

  static async deleteJob(jobId: number): Promise<boolean> {
    return RecruiterService.updateJobStatus(jobId, 4)
  }

  static async getIncomingRequests(): Promise<RecruiterRequestVO[]> {
    const jobs = await RecruiterService.getMyJobs()
    const allRequests: RecruiterRequestVO[] = []

    for (const job of jobs) {
      let apps: RecruiterApplicationVO[] = []
      try {
        apps = await RecruiterService.getJobApplications(job.id)
      } catch {
        continue
      }
      for (const app of apps) {
        const resume = RecruiterService.parseResumeSnapshot(app.resumeSnapshot)
        allRequests.push({
          id: app.id,
          applicantId: app.applicantId,
          applicantName: app.applicantName || resume.realName || '求职者',
          applicantAvatar: app.applicantAvatar,
          applicantAge: RecruiterService.getAge(resume.birthDate),
          applicantSchool: resume.school || '',
          applicantMajor: '',
          applicantEducation: resume.education || '',
          applicantExperience: resume.experience || '',
          applicantSkills: resume.skills || '',
          applicantRegion: '',
          applicantType: '',
          applicantSalary: '',
          jobTitle: job.title,
          status: app.status,
          interviewTime: app.interviewTime,
          interviewLocation: app.interviewLocation,
          rejectReason: app.rejectReason,
          createTime: app.createTime,
          attachmentUrl: app.attachmentUrl || ''
        })
      }
    }

    return allRequests
  }

  static async processRequest(requestId: number, data: RecruiterUpdateStatusRequest): Promise<boolean> {
    return RecruiterService.updateApplicationStatus(requestId, data)
  }

  private static parseResumeSnapshot(snapshot?: string): ResumeSnapshot {
    if (!snapshot) {
      return {}
    }
    try {
      return JSON.parse(snapshot) as ResumeSnapshot
    } catch {
      return {}
    }
  }

  private static getAge(birthDate?: string): number {
    if (!birthDate || birthDate.length < 4) {
      return 0
    }
    const birthYear = Number(birthDate.substring(0, 4))
    const currentYear = new Date().getFullYear()
    if (birthYear < 1900 || birthYear > currentYear) {
      return 0
    }
    return currentYear - birthYear
  }
}
