import { ApiClient } from './ApiClient'
import { PageResult, ResumeData } from './ResumeService'
import { TaskVO } from './ChatTypes'
import { AppColors } from '../common/AppStyles'

export interface ApplicationData {
  id: number
  taskId: number
  applicantId: number
  resumeSnapshot: string
  attachmentUrl: string
  status: number
  interviewTime: string
  interviewLocation: string
  rejectReason: string
  hrNote: string
  createTime: string
  updateTime: string
}

export class ApplicationService {
  static async getMyApplications(page: number = 1, pageSize: number = 50): Promise<PageResult<ApplicationData>> {
    return ApiClient.get<PageResult<ApplicationData>>('/api/applications/my', [
      ['page', String(page)],
      ['pageSize', String(pageSize)]
    ])
  }

  static async getTask(taskId: number): Promise<TaskVO | null> {
    try {
      return await ApiClient.get<TaskVO>('/api/tasks/' + taskId)
    } catch {
      return null
    }
  }

  static formatTime(value: string): string {
    if (!value) {
      return ''
    }
    return value.replace('T', ' ').substring(0, 16)
  }

  static statusLabel(status: number): string {
    const labels: Record<number, string> = {
      0: '已投递',
      1: '待面试',
      2: '待定',
      3: '已录用',
      4: '已淘汰',
      5: '已完成'
    }
    return labels[status] || '未知状态'
  }

  static statusColor(status: number): ResourceColor {
    const colors: Record<number, ResourceColor> = {
      0: AppColors.PRIMARY,
      1: AppColors.WARNING,
      2: AppColors.TEXT_SECONDARY,
      3: AppColors.SUCCESS,
      4: AppColors.DANGER,
      5: AppColors.INFO
    }
    return colors[status] || AppColors.TEXT_SECONDARY
  }
}
