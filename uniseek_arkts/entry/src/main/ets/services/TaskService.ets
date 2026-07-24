import { ApiClient } from './ApiClient';

/**
 * 职位相关接口封装。
 */
export class TaskService {
  /**
   * 获取所有可用职位标签（包含热门推荐）。
   * 接口：GET /api/tasks/tags/all
   */
  static async getAllTags(): Promise<string[]> {
    try {
      return await ApiClient.get<string[]>('/api/tasks/tags/all')
    } catch {
      return []
    }
  }
}
