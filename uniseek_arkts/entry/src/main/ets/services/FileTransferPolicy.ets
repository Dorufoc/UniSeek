/** 文件上传、下载与预览共用的纯策略。 */
export interface UploadResponseData {
  url: string
}

export interface UploadResponse {
  code: number
  message: string
  data: UploadResponseData
}

export class FileTransferPolicy {
  static extractFileName(uri: string, fallback: string): string {
    const cleanUri: string = uri.split('?')[0]
    const rawName: string = cleanUri.substring(cleanUri.lastIndexOf('/') + 1)
    if (!rawName) {
      return fallback
    }
    try {
      const decodedName: string = decodeURIComponent(rawName)
      return decodedName.includes('.') ? decodedName : fallback
    } catch {
      return rawName.includes('.') ? rawName : fallback
    }
  }

  static getMimeType(fileName: string): string {
    const lowerName: string = fileName.trim().toLowerCase()
    if (lowerName.endsWith('.pdf')) {
      return 'application/pdf'
    }
    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
      return 'image/jpeg'
    }
    if (lowerName.endsWith('.png')) {
      return 'image/png'
    }
    if (lowerName.endsWith('.gif')) {
      return 'image/gif'
    }
    if (lowerName.endsWith('.webp')) {
      return 'image/webp'
    }
    return 'application/octet-stream'
  }

  static readUploadUrl(response: UploadResponse): string {
    if (response.code !== 200 || !response.data || !response.data.url) {
      return ''
    }
    return response.data.url.trim()
  }

  static resolveUrl(baseUrl: string, value: string): string {
    const target: string = value.trim()
    if (target.startsWith('http://') || target.startsWith('https://')) {
      return target
    }
    let base: string = baseUrl.trim()
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1)
    }
    return target.startsWith('/') ? base + target : base + '/' + target
  }

  /** 将应用沙箱路径转换为 PreviewKit 可识别的文件 URI。 */
  static toFileUri(path: string): string {
    const target: string = path.trim()
    if (!target) {
      return ''
    }
    if (target.startsWith('file://')) {
      return target
    }
    return target.startsWith('/') ? 'file://' + target : 'file:///' + target
  }

  static getPreviewMimeType(fileName: string): string {
    return FileTransferPolicy.getMimeType(fileName)
  }
}
