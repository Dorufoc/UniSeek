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

  static async getSessionDetail(applicationId: number): Promise<ChatSessionVO> {
    return ApiClient.get<ChatSessionVO>('/api/chat/sessions/' + applicationId)
  }

  static async getMessages(applicationId: number, beforeId?: number, pageSize: number = 20): Promise<ChatMessageVO[]> {
    const params: Array<[string, string]> = [['pageSize', pageSize.toString()]]
    if (beforeId !== undefined) {
      params.push(['beforeId', beforeId.toString()])
    }
    return ApiClient.get<ChatMessageVO[]>('/api/chat/sessions/' + applicationId + '/messages', params)
  }

  static async sendMessage(applicationId: number, content: string): Promise<ChatMessageVO> {
    return ApiClient.post<ChatMessageVO>('/api/chat/sessions/' + applicationId + '/messages', {
      messageType: 0,
      content: content
    } as SendMessageRequest)
  }

  static async sendMessageWithType(applicationId: number, messageType: number, content: string): Promise<ChatMessageVO> {
    return ApiClient.post<ChatMessageVO>('/api/chat/sessions/' + applicationId + '/messages', {
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
    const sourceFile = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY)
    fileIo.closeSync(sourceFile)
    const cachePath: string = context.cacheDir + '/uniseek-' + new Date().getTime() + '-' + fileName
    fileIo.copyFileSync(uri, cachePath)

    const uploadConfig: request.UploadConfig = {
      url: ApiClient.BASE_URL + serverPath,
      header: {
        'Authorization': 'Bearer ' + ApiClient.getToken()
      },
      method: 'POST',
      files: [{
        filename: fileName,
        name: 'file',
        uri: cachePath,
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
      } catch {
      }
    })
  }

  /** 下载并预览聊天中的简历附件。 */
  static async previewAttachment(url: string): Promise<void> {
    const hostContext = getContext()
    const localPath = await ChatService.downloadAttachment(url)
    const previewable: boolean = await filePreview.canPreview(hostContext, localPath)
    if (!previewable) {
      throw new Error('当前设备不支持预览该附件')
    }
    const fileName: string = FileTransferPolicy.extractFileName(url, '简历附件.pdf')
    await filePreview.openPreview(hostContext, {
      uri: localPath,
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
  static async createDirectSession(targetUserId: number): Promise<number> {
    return ApiClient.post<number>('/api/chat/sessions/direct?targetUserId=' + targetUserId)
  }

  static async markSessionRead(applicationId: number): Promise<void> {
    await ApiClient.put<ApiEmpty>('/api/chat/sessions/' + applicationId + '/read')
  }

  static async createApplication(taskId: number): Promise<ApplicationResponse> {
    return ApiClient.post<ApplicationResponse>('/api/applications', { taskId } as CreateApplicationRequest)
  }
}
