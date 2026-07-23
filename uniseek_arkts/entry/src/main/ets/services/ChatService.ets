import { ApiClient, ApiEmpty } from './ApiClient';
import { ServerConfig } from './ServerConfig'
import { ChatSessionVO, ChatMessageVO } from './ChatTypes';
import { http } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { BusinessError, request } from '@kit.BasicServicesKit';
import { filePreview } from '@kit.PreviewKit';

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
    return ChatService.uploadToServer(uri, '/upload/image')
  }

  /** 上传普通文件（简历附件等）到服务器，返回文件 URL */
  static async uploadFile(uri: string): Promise<string> {
    return ChatService.uploadToServer(uri, '/upload/file')
  }

  /** 通用文件上传：读取本地文件，以 multipart/form-data 形式上传 */
  private static async uploadToServer(uri: string, serverPath: string): Promise<string> {
    // 读取文件内容
    const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY)
    const stat = fileIo.statSync(uri)
    const fileBuf = new ArrayBuffer(stat.size)
    fileIo.readSync(file.fd, fileBuf)
    fileIo.closeSync(file)

    // 解析文件名和 Content-Type
    const fileName = uri.substring(uri.lastIndexOf('/') + 1)
    const ext = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase()
    let contentType: string = 'application/octet-stream'
    if (ext === 'jpg' || ext === 'jpeg') {
      contentType = 'image/jpeg'
    } else if (ext === 'png') {
      contentType = 'image/png'
    } else if (ext === 'gif') {
      contentType = 'image/gif'
    } else if (ext === 'webp') {
      contentType = 'image/webp'
    } else if (ext === 'pdf') {
      contentType = 'application/pdf'
    }

    // 构造 multipart/form-data 的 header 和 footer
    const boundary = '----UniSeekBoundary' + new Date().getTime()
    const headerStr = '--' + boundary + '\r\n' +
      'Content-Disposition: form-data; name="file"; filename="' + fileName + '"\r\n' +
      'Content-Type: ' + contentType + '\r\n\r\n'
    const footerStr = '\r\n--' + boundary + '--\r\n'

    // 将字符串转为 Uint8Array
    const encoder = new util.TextEncoder()
    const headerBytes = encoder.encodeInto(headerStr)
    const footerBytes = encoder.encodeInto(footerStr)

    // 拼接完整请求体
    const totalSize = headerBytes.byteLength + fileBuf.byteLength + footerBytes.byteLength
    const fullBody = new ArrayBuffer(totalSize)
    const fullView = new Uint8Array(fullBody)
    fullView.set(new Uint8Array(headerBytes.buffer), 0)
    fullView.set(new Uint8Array(fileBuf), headerBytes.byteLength)
    fullView.set(new Uint8Array(footerBytes.buffer), headerBytes.byteLength + fileBuf.byteLength)

    return new Promise<string>((resolve: Function, reject: Function) => {
      const httpRequest = http.createHttp()
      httpRequest.request(ApiClient.BASE_URL + serverPath, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'multipart/form-data; boundary=' + boundary,
          'Authorization': 'Bearer ' + ApiClient.getToken()
        },
        extraData: fullBody,
        connectTimeout: 30000,
        readTimeout: 60000
      }).then((resp: http.HttpResponse) => {
        httpRequest.destroy()
        const raw = resp.result as string
        if (!raw) {
          reject(new Error('上传响应为空'))
          return
        }
        let json: Record<string, Object>
        try {
          json = JSON.parse(raw) as Record<string, Object>
        } catch {
          reject(new Error('上传响应解析失败'))
          return
        }
        if (Number(json['code']) === 200) {
          const data = json['data'] as Record<string, Object>
          resolve(data['url'] as string)
        } else {
          reject(new Error(String(json['message'] || '上传失败')))
        }
      }).catch((err: BusinessError) => {
        httpRequest.destroy()
        reject(new Error('上传失败: ' + err.message))
      })
    })
  }

  /** 下载并预览聊天中的简历附件。 */
  static async previewAttachment(url: string): Promise<void> {
    const hostContext = getContext()
    const localPath = await ChatService.downloadAttachment(url)
    await filePreview.openPreview(hostContext, {
      uri: localPath,
      mimeType: 'application/pdf',
      title: '简历附件'
    })
  }

  /** 将附件下载到应用私有目录并返回本地路径。 */
  static async downloadAttachment(url: string): Promise<string> {
    const hostContext = getContext()
    const resolvedUrl: string = ServerConfig.toHttpUrl(ApiClient.BASE_URL, url)
    const namePart = resolvedUrl.substring(resolvedUrl.lastIndexOf('/') + 1).split('?')[0]
    const fileName = namePart || ('resume-' + new Date().getTime() + '.pdf')
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
        resolve(filePath)
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
