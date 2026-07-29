import { ApiClient, ApiEmpty } from './ApiClient';
import { ServerConfig } from './ServerConfig'
import { ChatSessionVO, ChatMessageVO } from './ChatTypes';
import { fileIo } from '@kit.CoreFileKit';
import { http } from '@kit.NetworkKit';
import { request } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { FileTransferPolicy, UploadResponse } from './FileTransferPolicy';
import { MediaUriResolver, CacheFileInfo } from './MediaUriResolver';
import { UploadPolicy } from '../common/FormValidators';

export interface SendMessageRequest {
  messageType: number
  content: string
}

export interface ApplicationResponse {
  id: number
}

export interface CreateApplicationRequest {
  taskId: number
}

/** 上传响应中的 data 字段 */
interface UploadData {
  url: string
}

export class ChatService {
  static async getSessions(): Promise<ChatSessionVO[]> {
    return ApiClient.get<ChatSessionVO[]>('/api/chat/sessions')
  }

  static async getSessionDetail(applicationId: number, sessionType?: string): Promise<ChatSessionVO> {
    const path = ChatService.buildSessionPath('/api/chat/sessions/' + applicationId, sessionType)
    return ApiClient.get<ChatSessionVO>(path)
  }

  static async getMessages(applicationId: number, beforeId?: number, pageSize: number = 20, sessionType?: string): Promise<ChatMessageVO[]> {
    const params: Array<[string, string]> = [['pageSize', pageSize.toString()]]
    if (beforeId !== undefined) {
      params.push(['beforeId', beforeId.toString()])
    }
    if (sessionType !== undefined && sessionType.trim().length > 0) {
      params.push(['sessionType', sessionType])
    }
    return ApiClient.get<ChatMessageVO[]>('/api/chat/sessions/' + applicationId + '/messages', params)
  }

  static async sendMessage(applicationId: number, content: string, sessionType?: string): Promise<ChatMessageVO> {
    const path = ChatService.buildSessionPath('/api/chat/sessions/' + applicationId + '/messages', sessionType)
    return ApiClient.post<ChatMessageVO>(path, {
      messageType: 0,
      content: content
    } as SendMessageRequest)
  }

  static async sendMessageWithType(applicationId: number, messageType: number, content: string, sessionType?: string): Promise<ChatMessageVO> {
    const path = ChatService.buildSessionPath('/api/chat/sessions/' + applicationId + '/messages', sessionType)
    return ApiClient.post<ChatMessageVO>(path, {
      messageType: messageType,
      content: content
    } as SendMessageRequest)
  }

  /** 上传图片文件到服务器，返回图片 URL */
  static async uploadImage(uri: string): Promise<string> {
    return ChatService.uploadToServer(uri, '/api/upload/image')
  }

  /** 上传普通文件（简历附件等）到服务器，返回文件 URL */
  static async uploadFile(uri: string): Promise<string> {
    return ChatService.uploadToServer(uri, '/api/upload/file')
  }

  /** 上传简历附件到简历专用接口，返回文件 URL。 */
  static async uploadResumeAttachment(uri: string): Promise<string> {
    return ChatService.uploadToServer(uri, '/api/resume/upload-attachment')
  }

  /** 通用文件上传：手动构造 multipart/form-data 并通过 http.request 发送。 */
  private static async uploadToServer(uri: string, serverPath: string): Promise<string> {
    if (!uri || uri.trim().length === 0) {
      throw new Error('文件地址为空')
    }
    const context = getContext()
    const fallbackName: string = serverPath.endsWith('/image') ? 'upload.jpg' : 'upload.pdf'
    let fileName: string = FileTransferPolicy.extractFileName(uri, fallbackName)
    let cachePath: string = ''
    let uploadUri: string = ''

    if (FileTransferPolicy.isMediaUri(uri)) {
      const mediaFile: CacheFileInfo = await MediaUriResolver.copyMediaUriToCache(uri)
      fileName = mediaFile.fileName
      cachePath = mediaFile.cachePath
      uploadUri = mediaFile.uploadUri
    } else {
      const cacheName: string = 'uniseek-' + new Date().getTime().toString() + '-' + ChatService.safeCacheFileName(fileName)
      cachePath = context.cacheDir + '/' + cacheName
      let sourceFile: fileIo.File | undefined = undefined
      try {
        sourceFile = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY)
        fileIo.copyFileSync(sourceFile.fd, cachePath)
      } catch {
        try {
          fileIo.unlinkSync(cachePath)
        } catch {
        }
        throw new Error('无法读取所选文件')
      } finally {
        if (sourceFile !== undefined) {
          fileIo.closeSync(sourceFile)
        }
      }
      }
      uploadUri = 'internal://cache/' + cacheName
    }

    if (serverPath === '/api/resume/upload-attachment') {
      const cacheStat = fileIo.statSync(cachePath)
      if (cacheStat.size > 10 * 1024 * 1024) {
        try {
          fileIo.unlinkSync(cachePath)
        } catch {
        }
        throw new Error('文件大小不能超过 10MB')
      }
    } else if (serverPath === '/api/upload/image') {
      const cacheStat = fileIo.statSync(cachePath)
      const validationMessage: string = UploadPolicy.validateAvatar(fileName, cacheStat.size)
      if (validationMessage) {
        try {
          fileIo.unlinkSync(cachePath)
        } catch {
          // 校验失败后的缓存清理失败不改变用户可见的校验结果
        }
        throw new Error(validationMessage)
      }
    }

    // 读取文件内容到 ArrayBuffer
    const file = fileIo.openSync(cachePath, fileIo.OpenMode.READ_ONLY)
    const stat = fileIo.statSync(cachePath)
    const fileBuffer = new ArrayBuffer(stat.size)
    fileIo.readSync(file.fd, fileBuffer)
    fileIo.closeSync(file)

    // 清理缓存文件
    try {
      fileIo.unlinkSync(cachePath)
    } catch {
    }

    // 手动构造 multipart/form-data 请求体
    const boundary: string = '----UniSeekBoundary' + new Date().getTime()
    const encoder: util.TextEncoder = new util.TextEncoder()
    const headerPart: string = '--' + boundary + '\r\n' +
      'Content-Disposition: form-data; name="file"; filename="' + fileName + '"\r\n' +
      'Content-Type: ' + FileTransferPolicy.getMimeType(fileName) + '\r\n\r\n'
    const footerPart: string = '\r\n--' + boundary + '--\r\n'
    const headerBytes: Uint8Array = encoder.encodeInto(headerPart)
    const footerBytes: Uint8Array = encoder.encodeInto(footerPart)

    const totalLength: number = headerBytes.byteLength + fileBuffer.byteLength + footerBytes.byteLength
    const requestBody: ArrayBuffer = new ArrayBuffer(totalLength)
    const bodyView: Uint8Array = new Uint8Array(requestBody)
    bodyView.set(headerBytes, 0)
    bodyView.set(new Uint8Array(fileBuffer), headerBytes.byteLength)
    bodyView.set(footerBytes, headerBytes.byteLength + fileBuffer.byteLength)

    // 通过 http.request 发送
    const httpRequest = http.createHttp()
    try {
      const resp: http.HttpResponse = await httpRequest.request(
        ApiClient.BASE_URL + serverPath,
        {
          method: http.RequestMethod.POST,
          header: {
            'Authorization': 'Bearer ' + ApiClient.getToken(),
            'Content-Type': 'multipart/form-data; boundary=' + boundary
          },
          extraData: requestBody,
          connectTimeout: 10000,
          readTimeout: 30000
        }
      )
      const raw: string = resp.result as string
      const response: UploadResponse = JSON.parse(raw) as UploadResponse
      if (response.code !== 200) {
        throw new Error(response.message || '文件上传失败')
      }
      const url: string = FileTransferPolicy.readUploadUrl(response)
      if (!url) {
        throw new Error(response.message || '上传响应无文件地址')
      }
      return url
    } finally {
      httpRequest.destroy()
    }
  }

  /** 将附件下载到应用私有目录并返回本地路径。 */
  static async downloadAttachment(url: string): Promise<string> {
    const hostContext = getContext()
    const resolvedUrl: string = ServerConfig.toHttpUrl(ApiClient.BASE_URL, url)
    const fileName: string = FileTransferPolicy.extractFileName(resolvedUrl, 'resume-' + new Date().getTime() + '.pdf')
    const filePath = hostContext.filesDir + '/' + fileName
    const task = await request.downloadFile(hostContext, {
      url: resolvedUrl,
      filePath: filePath,
      title: fileName,
      header: { Authorization: 'Bearer ' + ApiClient.getToken() },
      background: false
    })
    return new Promise<string>((resolve, reject) => {
      task.on('complete', () => {
        try {
          const stat = fileIo.statSync(filePath)
          if (stat.size <= 0) {
            reject(new Error('附件下载内容为空'))
            return
          }
           resolve(filePath)
        } catch {
          reject(new Error('附件下载文件不存在'))
        }
      })
      task.on('fail', (code: number) => {
        reject(new Error('附件下载失败：' + code))
      })
    })
  }

  private static safeCacheFileName(fileName: string): string {
    const extensionIndex: number = fileName.lastIndexOf('.')
    const extension: string = extensionIndex >= 0 ? fileName.substring(extensionIndex) : ''
    return 'attachment' + extension.toLowerCase()
  }
  static async createDirectSession(targetUserId: number): Promise<number> {
    return ApiClient.post<number>('/api/chat/sessions/direct?targetUserId=' + targetUserId)
  }

  static async markSessionRead(applicationId: number, sessionType?: string): Promise<void> {
    const path = ChatService.buildSessionPath('/api/chat/sessions/' + applicationId + '/read', sessionType)
    await ApiClient.put<ApiEmpty>(path)
  }

  static async createApplication(taskId: number): Promise<ApplicationResponse> {
    return ApiClient.post<ApplicationResponse>('/api/applications', { taskId } as CreateApplicationRequest)
  }

  /** 在路径后追加 sessionType 查询参数，仅用于区分直聊与投递会话。 */
  private static buildSessionPath(path: string, sessionType?: string): string {
    if (sessionType === undefined || sessionType.trim().length === 0) {
      return path
    }
    return path + '?sessionType=' + sessionType
  }
}
