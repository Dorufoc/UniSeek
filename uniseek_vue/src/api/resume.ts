import request from './index'

export interface ResumeData {
  id?: number
  userId?: number
  realName?: string
  gender?: number
  birthDate?: string
  education?: string
  school?: string
  skills?: string
  experience?: string
  attachmentUrl?: string
  isPublished?: number
  createTime?: string
  updateTime?: string
}

export interface ResumeSaveParams {
  gender?: number
  birthDate?: string
  education?: string
  school?: string
  skills?: string
  experience?: string
  attachmentUrl?: string
}

/** GET /resume 获取我的简历 */
export const getResume = () =>
  request.get<any, ResumeData>('/resume')

/** PUT /resume 保存简历 */
export const saveResume = (params: ResumeSaveParams) =>
  request.put<any, void>('/resume', params)

/** POST /resume/upload-attachment 上传简历附件 */
export const uploadAttachment = (file: File) => {
  const formData = new FormData()
  formData.append('file', file)
  return request.post<any, { url: string }>('/resume/upload-attachment', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  })
}

/** PATCH /resume/publish 发布简历到人才市场 */
export const publishResume = () =>
  request.patch<any, void>('/resume/publish')

/** PATCH /resume/unpublish 从人才市场下架简历 */
export const unpublishResume = () =>
  request.patch<any, void>('/resume/unpublish')

/** GET /resume/search 搜索已发布的简历 */
export const searchPublishedResumes = (keyword?: string) =>
  request.get<any, ResumeData[]>('/resume/search', { params: { keyword } })
