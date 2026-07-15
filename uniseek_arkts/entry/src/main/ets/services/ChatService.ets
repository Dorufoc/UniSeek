import { ChatSessionVO, ChatMessageVO, ApplicationResult } from './ChatTypes'

export class ChatService {
  static getSessions(): Promise<ChatSessionVO[]> {
    return Promise.resolve([])
  }

  static getMessages(applicationId: number): Promise<ChatMessageVO[]> {
    return Promise.resolve([])
  }

  static sendMessage(applicationId: number, content: string): Promise<ChatMessageVO | null> {
    return Promise.resolve(null)
  }

  static createApplication(taskId: number): Promise<ApplicationResult | null> {
    return Promise.resolve(null)
  }
}
