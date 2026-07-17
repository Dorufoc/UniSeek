import request from './index'
import type { ApiResponse } from './auth'
import type { PageResult } from './task'

// 企业资质认证请求参数（匹配后端 EnterpriseRequest）
export interface EnterpriseRequest {
  companyName: string
  creditCode: string
  licenseImgUrl: string
  industry: string
  regionId: number | null
  description: string
}

// 企业信息（匹配后端 Enterprise 实体）
export interface EnterpriseInfo {
  id: number
  userId: number
  companyName: string
  creditCode: string
  licenseImgUrl: string
  industry: string
  regionId: number | null
  description: string
  auditStatus: number
  auditTime: string | null
  createTime: string
  updateTime: string
}

/** POST /api/enterprise 提交企业资质认证 */
export const submitEnterprise = async (params: EnterpriseRequest) => {
  const res = await request.post<ApiResponse<EnterpriseInfo>>('/enterprise', params)
  return res
}

/** GET /api/enterprise/my 查询我的企业资质信息 */
export const getMyEnterprise = async () => {
  const res = await request.get<ApiResponse<EnterpriseInfo>>('/enterprise/my')
  return res
}

/** PUT /api/enterprise 更新企业资质 */
export const updateEnterprise = async (params: EnterpriseRequest) => {
  const res = await request.put<ApiResponse<EnterpriseInfo>>('/enterprise', params)
  return res
}

/** GET /api/enterprise/list 分页获取已认证的企业列表 */
export interface EnterpriseListParams {
  page?: number
  pageSize?: number
  keyword?: string
  industry?: string
  regionId?: number
  sortBy?: string
  sortOrder?: string
}
export const getEnterpriseList = (params: EnterpriseListParams = {}) =>
  request.get<any, PageResult<EnterpriseInfo>>('/enterprise/list', { params })

// 热门企业信息
export interface HotEnterprise {
  id: number
  companyName: string
  industry: string
  regionId: number | null
  regionName: string
  description: string
  heatScore: number
  activeJobCount: number
}

/** GET /api/enterprise/hot 获取热门企业列表 */
export const getHotEnterprises = (limit = 12) =>
  request.get<any, HotEnterprise[]>('/enterprise/hot', { params: { limit } })

/** GET /api/enterprise/{id} 根据ID获取企业详情 */
export const getEnterpriseById = (id: number) =>
  request.get<any, EnterpriseInfo>(`/enterprise/${id}`)
