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

/** 提交企业资质认证 POST /api/enterprise */
export const submitEnterprise = async (params: EnterpriseRequest) => {
  const res = await request.post<ApiResponse<EnterpriseInfo>>('/enterprise', params)
  return res.data
}

/** 查询我的企业资质信息 GET /api/enterprise/my */
export const getMyEnterprise = async () => {
  const res = await request.get<ApiResponse<EnterpriseInfo>>('/enterprise/my')
  return res.data
}

/** 更新企业资质 PUT /api/enterprise */
export const updateEnterprise = async (params: EnterpriseRequest) => {
  const res = await request.put<ApiResponse<EnterpriseInfo>>('/enterprise', params)
  return res.data
}
