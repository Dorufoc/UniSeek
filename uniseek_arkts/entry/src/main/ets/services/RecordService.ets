import { JobData } from './ChatTypes';

const viewedMap: Map<string, JobData> = new Map()
const chattedMap: Map<string, JobData> = new Map()

export class RecordService {
  static addViewedJob(job: JobData): void {
    viewedMap.set(job.id, job)
  }

  static addChattedJob(job: JobData): void {
    chattedMap.set(job.id, job)
  }

  static getViewedJobs(): JobData[] {
    const result: JobData[] = []
    viewedMap.forEach((value: JobData) => {
      result.push(value)
    })
    return result
  }

  static getChattedJobs(): JobData[] {
    const result: JobData[] = []
    chattedMap.forEach((value: JobData) => {
      result.push(value)
    })
    return result
  }
}
