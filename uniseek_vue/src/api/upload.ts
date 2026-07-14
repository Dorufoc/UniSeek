import request from './index'
import type { ApiResponse } from './auth'

export interface UploadResult {
  url: string
}

/** POST /api/upload/image 上传图片 */
export const uploadImage = async (file: File) => {
  const formData = new FormData()
  formData.append('file', file)
  const res = await request.post<ApiResponse<{ url: string }>>('/upload/image', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  })
  return res.data
}

/** POST /api/upload/file 上传文件 */
export const uploadFile = async (file: File) => {
  const formData = new FormData()
  formData.append('file', file)
  const res = await request.post<ApiResponse<UploadResult>>('/upload/file', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  })
  return res.data
}
