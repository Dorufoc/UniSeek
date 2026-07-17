import { ApiClient, ApiEmpty } from './ApiClient';
import { ChatSessionVO, ChatMessageVO } from './ChatTypes';

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
