// 通知消息服务：与 Java 后端 notification 模块对接
// 主要供招聘方「新投递通知铃铛」使用

import { ApiClient, ApiEmpty } from './ApiClient';
import { PageResult } from './ResumeService';
import { NotificationVO, UnreadCountVO } from './RecruiterTypes';

export class NotificationService {
  /**
   * 拉取新投递通知列表。
   * 后端 type=0 表示系统通知（平台自动在投递成功时向 HR 推送）。
   */
  static async getNewDeliveries(page: number = 1, pageSize: number = 50): Promise<NotificationVO[]> {
    try {
      const result = await ApiClient.get<PageResult<NotificationVO>>('/api/messages', [
        ['type', '0'],
        ['page', String(page)],
        ['pageSize', String(pageSize)]
      ])
      return result?.records ?? []
    } catch {
      return []
    }
  }

  /** 获取未读通知总数。 */
  static async getUnreadCount(): Promise<number> {
    try {
      const result = await ApiClient.get<UnreadCountVO>('/api/messages/unread-count')
      return result?.totalUnread ?? result?.total ?? 0
    } catch {
      return 0
    }
  }

  /** 单条标记已读。 */
  static async markRead(id: number): Promise<boolean> {
    try {
      await ApiClient.put<ApiEmpty>('/api/messages/' + id + '/read')
      return true
    } catch {
      return false
    }
  }

  /** 全部标记已读。 */
  static async markAllRead(): Promise<boolean> {
    try {
      await ApiClient.put<ApiEmpty>('/api/messages/read-all')
      return true
    } catch {
      return false
    }
  }
}
