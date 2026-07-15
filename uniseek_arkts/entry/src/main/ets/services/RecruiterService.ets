import {
  RecruiterJobVO,
  RecruiterApplicationVO,
  RecruiterEnterpriseVO,
  RecruiterJobRequest,
  RecruiterEnterpriseRequest,
  RecruiterUpdateStatusRequest
} from './RecruiterTypes';

export class RecruiterService {
  static getMyJobs(): Promise<RecruiterJobVO[]> {
    return new Promise((resolve) => { resolve([]) })
  }

  static createJob(data: RecruiterJobRequest): Promise<boolean> {
    return new Promise((resolve) => { resolve(false) })
  }

  static updateJob(jobId: number, data: RecruiterJobRequest): Promise<boolean> {
    return new Promise((resolve) => { resolve(false) })
  }

  static updateJobStatus(jobId: number, targetStatus: number): Promise<boolean> {
    return new Promise((resolve) => { resolve(false) })
  }

  static getJobApplications(taskId: number): Promise<RecruiterApplicationVO[]> {
    return new Promise((resolve) => { resolve([]) })
  }

  static updateApplicationStatus(applicationId: number, data: RecruiterUpdateStatusRequest): Promise<boolean> {
    return new Promise((resolve) => { resolve(false) })
  }

  static getEnterpriseInfo(): Promise<RecruiterEnterpriseVO | null> {
    return new Promise((resolve) => { resolve(null) })
  }

  static saveEnterpriseInfo(data: RecruiterEnterpriseRequest): Promise<boolean> {
    return new Promise((resolve) => { resolve(false) })
  }

  static deleteJob(jobId: number): Promise<boolean> {
    return new Promise((resolve) => { resolve(false) })
  }
}
