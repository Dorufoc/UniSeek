import request from './index'

export interface UploadResult {
  url: string
}

/** POST /upload/image 上传图片 */
export const uploadImage = (file: File) => {
  const formData = new FormData()
  formData.append('file', file)
  return request.post<any, UploadResult>('/upload/image', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  })
}

/** POST /upload/file 上传文件 */
export const uploadFile = (file: File) => {
  const formData = new FormData()
  formData.append('file', file)
  return request.post<any, UploadResult>('/upload/file', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  })
}
