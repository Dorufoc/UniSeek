import { ApiClient, ApiEmpty } from './ApiClient';
import { PageResult } from './ResumeService';
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

export class RecruiterService {
  static async getMyJobs(): Promise<RecruiterJobVO[]> {
    const result = await ApiClient.get<PageResult<RecruiterJobVO>>('/api/enterprise/tasks', [['page', '1'], ['pageSize', '100']])
    return result.records
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

  static async getJobApplications(taskId: number): Promise<RecruiterApplicationVO[]> {
    const result = await ApiClient.get<PageResult<RecruiterApplicationVO>>('/api/tasks/' + taskId + '/applications', [['page', '1'], ['pageSize', '100']])
    return result.records
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

  static async saveEnterpriseInfo(data: RecruiterEnterpriseRequest): Promise<boolean> {
    try {
      await ApiClient.post<ApiEmpty>('/api/enterprise', data)
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
          allRequests.push({
            id: app.id,
            applicantId: app.applicantId,
            applicantName: app.applicantName,
            applicantAvatar: app.applicantAvatar,
            applicantAge: 0,
            applicantSchool: '',
            applicantMajor: '',
            applicantEducation: '',
            applicantExperience: '',
            applicantSkills: '',
            applicantRegion: '',
            applicantType: '',
            applicantSalary: '',
            jobTitle: job.title,
            status: app.status,
            interviewTime: app.interviewTime,
            interviewLocation: app.interviewLocation,
            rejectReason: app.rejectReason,
            createTime: app.createTime
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
}
