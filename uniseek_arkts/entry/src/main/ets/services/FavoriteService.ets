import { ApiClient } from './ApiClient';
import { JobData } from './ChatTypes';
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

  static async getFavorites(page: number = 1, pageSize: number = 20): Promise<JobData[]> {
    const records: FavoriteTaskItem[] = []
    let currentPage: number = page
    let totalPages: number = page
    do {
      const result = await ApiClient.get<PageResult<FavoriteTaskItem>>('/api/favorites', [
        ['page', String(currentPage)],
        ['pageSize', String(pageSize)]
      ])
      records.push(...result.records)
      totalPages = result.totalPages
      currentPage++
    } while (currentPage <= totalPages)

    return records.map((fav: FavoriteTaskItem): JobData => {
      return {
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
          hrAvatar: '',
          enterpriseName: '', totalQuota: 0, address: '', deadline: '',
          applicationCount: 0, hasFavorited: false
      }
    })
  }
}
