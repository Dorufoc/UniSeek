import request from './index'
import type { ApiResponse } from './auth'

/** 上传图片 POST /api/upload/image */
export const uploadImage = async (file: File) => {
  const formData = new FormData()
  formData.append('file', file)
  const res = await request.post<ApiResponse<{ url: string }>>('/upload/image', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  })
  return res.data
}
