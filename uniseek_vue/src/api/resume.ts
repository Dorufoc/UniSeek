import request from './index'

export interface ResumeData {
  id?: number
  userId?: number
  gender?: number
  birthDate?: string
  education?: string
  school?: string
  skills?: string
  experience?: string
  attachmentUrl?: string
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
