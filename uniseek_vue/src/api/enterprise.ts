import request from './index'
import type { ApiResponse } from './auth'

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
  return res.data
}

/** GET /api/enterprise/my 查询我的企业资质信息 */
export const getMyEnterprise = async () => {
  const res = await request.get<ApiResponse<EnterpriseInfo>>('/enterprise/my')
  return res.data
}

/** PUT /api/enterprise 更新企业资质 */
export const updateEnterprise = async (params: EnterpriseRequest) => {
  const res = await request.put<ApiResponse<EnterpriseInfo>>('/enterprise', params)
  return res.data
}
