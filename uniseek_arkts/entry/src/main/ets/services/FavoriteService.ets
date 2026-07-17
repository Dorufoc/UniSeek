import { ApiClient } from './ApiClient';
import { JobData, TaskVO, mapTaskToJobData } from './ChatTypes';
import { PageResult } from './ResumeService';

interface FavoriteTaskItem {
  id: number
  enterpriseId: number
  categoryId: number
  regionId: number
  title: string
  salaryMin: number
  salaryMax: number
  salaryUnit: number
  jobType: number
  totalQuota: number
  remainingQuota: number
  address: string
  tag: string
  status: number
  description: string
  createTime: string
}

interface FavoriteCheckResult {
  favorited: boolean
}

export class FavoriteService {
  static async addFavorite(taskId: number): Promise<void> {
    await ApiClient.post<object>('/api/favorites/' + taskId)
  }

  static async removeFavorite(taskId: number): Promise<void> {
    await ApiClient.delete<object>('/api/favorites/' + taskId)
  }

  static async checkFavorited(taskId: number): Promise<boolean> {
    const result = await ApiClient.get<FavoriteCheckResult>('/api/favorites/check/' + taskId)
    return result.favorited
  }

  static async getFavorites(page: number = 1, pageSize: number = 100): Promise<JobData[]> {
    const favResult = await ApiClient.get<PageResult<FavoriteTaskItem>>('/api/favorites', [
      ['page', String(page)],
      ['pageSize', String(pageSize)]
    ])

    if (favResult.records.length === 0) {
      return []
    }

    const taskResult = await ApiClient.get<PageResult<TaskVO>>('/api/tasks', [
      ['page', '1'],
      ['pageSize', '500']
    ])

    const taskMap = new Map<number, TaskVO>()
    for (const t of taskResult.records) {
      taskMap.set(t.id, t)
    }

    const favIds = new Set(favResult.records.map(r => r.id))
    const matched: JobData[] = []

    for (const fav of favResult.records) {
      const full = taskMap.get(fav.id)
      if (full) {
        matched.push(mapTaskToJobData(full))
      } else {
        matched.push({
          id: String(fav.id),
          title: fav.title || '',
          company: '',
          salary: (fav.salaryMin != null && fav.salaryMax != null) ? Number(fav.salaryMin) + '-' + Number(fav.salaryMax) + '元' : '',
          salaryMid: (Number(fav.salaryMin) + Number(fav.salaryMax)) / 2 || 0,
          popularity: 0,
          region: '',
          type: '',
          category: fav.jobType === 1 ? '全职' : fav.jobType === 2 ? '兼职' : fav.jobType === 3 ? '实习' : '全职',
          description: fav.description || '',
          enterpriseId: fav.enterpriseId || 0,
          categoryId: fav.categoryId || 0,
          regionId: fav.regionId || 0,
          salaryMin: Number(fav.salaryMin) || 0,
          salaryMax: Number(fav.salaryMax) || 0,
          salaryUnit: fav.salaryUnit ?? 0,
          jobType: fav.jobType || 0,
          status: fav.status ?? 1,
          hasApplied: false,
          applicationId: 0,
          tag: [],
          remainingQuota: fav.remainingQuota || 0,
          hrName: '',
          hrAvatar: ''
        })
      }
    }

    return matched
  }
}