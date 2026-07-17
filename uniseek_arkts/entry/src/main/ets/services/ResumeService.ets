import { ApiClient, ApiEmpty } from './ApiClient';

export interface ResumeData {
  id: number
  userId: number
  gender: number
  birthDate: string
  education: string
  school: string
  skills: string
  experience: string
  attachmentUrl: string
  isPublished: number
  realName: string
}

export interface ResumeRequest {
  gender?: number
  birthDate?: string
  education?: string
  school?: string
  skills?: string
  experience?: string
  attachmentUrl?: string
}

export class ResumeService {
  static async getMyResume(): Promise<ResumeData | null> {
    try {
      return await ApiClient.get<ResumeData>('/api/resume')
    } catch {
      return null
    }
  }

  static async saveResume(data: ResumeRequest): Promise<void> {
    await ApiClient.put<ApiEmpty>('/api/resume', data)
  }

  static async publishResume(): Promise<void> {
    await ApiClient.patch<ApiEmpty>('/api/resume/publish')
  }

  static async unpublishResume(): Promise<void> {
    await ApiClient.patch<ApiEmpty>('/api/resume/unpublish')
  }

  static async searchPublishedResumes(keyword?: string, page: number = 1, pageSize: number = 20): Promise<PageResult<ResumeData>> {
    const params: Array<[string, string]> = [['page', page.toString()], ['pageSize', pageSize.toString()]]
    if (keyword) {
      params.push(['keyword', keyword])
    }
    return ApiClient.get<PageResult<ResumeData>>('/api/resume/search', params)
  }

  static async getPublishedResume(userId: number): Promise<ResumeData | null> {
    try {
      return await ApiClient.get<ResumeData>('/api/resume/user/' + userId)
    } catch {
      return null
    }
  }
}

export interface PageResult<T> {
  records: T[]
  total: number
  page: number
  pageSize: number
  totalPages: number
}
