import { JobData } from './ChatTypes';

const viewedMap: Map<string, JobData> = new Map()
const chattedMap: Map<string, JobData> = new Map()
const favoriteMap: Map<string, JobData> = new Map()

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

  static addFavoriteJob(job: JobData): void {
    favoriteMap.set(job.id, job)
  }

  static removeFavoriteJob(jobId: string): void {
    favoriteMap.delete(jobId)
  }

  static isFavorited(jobId: string): boolean {
    return favoriteMap.has(jobId)
  }

  static getFavoriteJobs(): JobData[] {
    const result: JobData[] = []
    favoriteMap.forEach((value: JobData) => {
      result.push(value)
    })
    return result
  }
}
