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

interface CompleteApplicationRequest {
  hrNote: string
}

interface ResumeSnapshot {
  realName?: string
  birthDate?: string
  education?: string
  school?: string
  skills?: string
  experience?: string
}

export class RecruiterService {
  static async getMyJobs(): Promise<RecruiterJobVO[]> {
    const records: RecruiterJobVO[] = []
    let page: number = 1
    let totalPages: number = 1
    do {
      const result = await ApiClient.get<PageResult<RecruiterJobVO>>('/api/enterprise/tasks', [['page', String(page)], ['pageSize', '20']])
      records.push(...result.records)
      totalPages = result.totalPages
      page++
    } while (page <= totalPages)
    return records
  }

  static async createJob(data: RecruiterJobRequest): Promise<boolean> {
    try {
      await ApiClient.post<ApiEmpty>('/api/tasks', data)
      return true
    } catch {
      return false
    }
  }

  static async updateJob(jobId: number, data: RecruiterJobRequest): Promise<boolean> {
    try {
      await ApiClient.put<ApiEmpty>('/api/tasks/' + jobId, data)
      return true
    } catch {
      return false
    }
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
      records.push(...result.records)
      totalPages = result.totalPages
      page++
    } while (page <= totalPages)
    return records
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
      return await ApiClient.get<RecruiterEnterpriseVO>('/api/enterprise/my')
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
      try {
        const apps = await RecruiterService.getJobApplications(job.id)
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
      } catch {
      }
    }

    return allRequests
  }

  static async processRequest(requestId: number, data: RecruiterUpdateStatusRequest): Promise<boolean> {
    return RecruiterService.updateApplicationStatus(requestId, data)
  }

  static async completeApplication(applicationId: number, hrNote: string = ''): Promise<boolean> {
    try {
      const data: CompleteApplicationRequest = { hrNote: hrNote }
      await ApiClient.put<ApiEmpty>('/api/applications/' + applicationId + '/complete', data)
      return true
    } catch {
      return false
    }
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
