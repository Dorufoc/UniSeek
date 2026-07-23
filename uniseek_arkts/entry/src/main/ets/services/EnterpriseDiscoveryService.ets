import { ApiClient } from './ApiClient'
import { PageResult, TaskVO } from './ChatTypes'

export interface EnterpriseListItem {
  id: number
  companyName: string
  industry: string
  regionId: number | null
  description: string
}

export interface EnterpriseSearchParams {
  page: number
  pageSize: number
  keyword?: string
  industry?: string
  regionId?: number
  sortBy?: string
  sortOrder?: string
}

export class EnterpriseDiscoveryService {
  static getEnterprises(params: EnterpriseSearchParams): Promise<PageResult<EnterpriseListItem>> {
    const query: Array<[string, string]> = [
      ['page', String(params.page)],
      ['pageSize', String(params.pageSize)]
    ]
    if (params.keyword) {
      query.push(['keyword', params.keyword])
    }
    if (params.industry) {
      query.push(['industry', params.industry])
    }
    if (params.regionId) {
      query.push(['regionId', String(params.regionId)])
    }
    if (params.sortBy) {
      query.push(['sortBy', params.sortBy])
      query.push(['sortOrder', params.sortOrder || 'desc'])
    }
    return ApiClient.get<PageResult<EnterpriseListItem>>('/api/enterprise/list', query)
  }

  static getEnterprise(id: number): Promise<EnterpriseListItem> {
    return ApiClient.get<EnterpriseListItem>('/api/enterprise/' + id)
  }

  static getPublishedJobs(enterpriseId: number): Promise<TaskVO[]> {
    return ApiClient.get<TaskVO[]>('/api/enterprise/' + enterpriseId + '/tasks')
  }
}
