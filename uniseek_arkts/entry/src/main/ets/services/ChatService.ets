import { ApiClient, ApiEmpty } from './ApiClient';
import { ServerConfig } from './ServerConfig'
import { ChatSessionVO, ChatMessageVO } from './ChatTypes';
import { fileIo } from '@kit.CoreFileKit';
import { request } from '@kit.BasicServicesKit';
import { filePreview } from '@kit.PreviewKit';
import { FileTransferPolicy, UploadResponse } from './FileTransferPolicy';

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

  /** 通用文件上传：复制到应用缓存目录后使用系统 multipart 上传。 */
  private static async uploadToServer(uri: string, serverPath: string): Promise<string> {
    if (!uri || uri.trim().length === 0) {
      throw new Error('文件地址为空')
    }
    const context = getContext()
    const fallbackName: string = serverPath.endsWith('/image') ? 'upload.jpg' : 'upload.pdf'
    const fileName: string = FileTransferPolicy.extractFileName(uri, fallbackName)
    const cacheName: string = 'uniseek-' + new Date().getTime() + '-' + ChatService.safeCacheFileName(fileName)
    const cachePath: string = context.cacheDir + '/' + cacheName

    // 通过源 URI 与目标缓存文件的 fd 复制内容，避免将 Picker 返回的 URI 直接作为本地路径
    let sourceFile: fileIo.File | undefined = undefined
    try {
      sourceFile = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY)
      fileIo.copyFileSync(sourceFile.fd, cachePath)
    } catch {
      try {
        fileIo.unlinkSync(cachePath)
      } catch {
        // 复制失败且缓存文件不存在时无需清理
      }
      throw new Error('无法读取所选文件')
    } finally {
      if (sourceFile !== undefined) {
        fileIo.closeSync(sourceFile)
      }
    }

    if (serverPath === '/api/resume/upload-attachment') {
      const cacheStat = fileIo.statSync(cachePath)
      if (cacheStat.size > 10 * 1024 * 1024) {
        try {
          fileIo.unlinkSync(cachePath)
        } catch {
          // 超限文件清理失败不影响校验结果
        }
        throw new Error('文件大小不能超过 10MB')
      }
    }

    const uploadConfig: request.UploadConfig = {
      url: ApiClient.BASE_URL + serverPath,
      header: {
        'Authorization': 'Bearer ' + ApiClient.getToken()
      },
      method: 'POST',
      files: [{
        filename: fileName,
        name: 'file',
        uri: 'internal://cache/' + cacheName,
        type: FileTransferPolicy.getMimeType(fileName)
      }],
      data: []
    }

    const uploadTask = await request.uploadFile(context, uploadConfig)
    return new Promise<string>((resolve, reject) => {
      uploadTask.on('complete', (states: Array<request.TaskState>): void => {
        if (states.length === 0 || states[0].responseCode < 200 || states[0].responseCode >= 300) {
          reject(new Error('文件上传失败'))
          return
        }
        const raw: string = states[0].message
        try {
          const response: UploadResponse = JSON.parse(raw) as UploadResponse
          // 即使 HTTP responseCode 为 2xx，也按业务 code 判断，优先抛出服务端具体错误信息
          if (response.code !== 200) {
            reject(new Error(response.message || '文件上传失败'))
            return
          }
          const url: string = FileTransferPolicy.readUploadUrl(response)
          if (!url) {
            reject(new Error(response.message || '上传响应无文件地址'))
            return
          }
          resolve(url)
        } catch {
          reject(new Error('上传响应解析失败'))
        }
      })
      uploadTask.on('fail', (states: Array<request.TaskState>): void => {
        const message: string = states.length > 0 ? states[0].message : '文件上传失败'
        reject(new Error(message || '文件上传失败'))
      })
    }).finally(() => {
      try {
        fileIo.unlinkSync(cachePath)
      } catch (err) {
        // 缓存文件已清理或不存在时忽略，不影响业务结果
      }
    })
  }

  /** 下载并预览聊天中的简历附件。 */
  static async previewAttachment(url: string): Promise<void> {
    const hostContext = getContext()
    const localPath: string = await ChatService.downloadAttachment(url)
    const localUri: string = FileTransferPolicy.toFileUri(localPath)
    const previewable: boolean = await filePreview.canPreview(hostContext, localUri)
    if (!previewable) {
      throw new Error('当前设备不支持预览该附件')
    }
    const fileName: string = FileTransferPolicy.extractFileName(url, '简历附件.pdf')
    await filePreview.openPreview(hostContext, {
      uri: localUri,
      mimeType: FileTransferPolicy.getPreviewMimeType(fileName),
      title: '简历附件'
    })
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
