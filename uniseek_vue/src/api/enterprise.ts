import request from './index'

export interface EnterpriseParams {
  companyName: string
  creditCode: string
  licenseImgUrl?: string
  industry: string
  regionId?: number
  description?: string
}

export interface EnterpriseData {
  id: number
  userId: number
  companyName: string
  creditCode: string
  licenseImgUrl: string
  industry: string
  regionId: number
  description: string
  auditStatus: number
  createTime: string
  updateTime: string
}

/** POST /enterprise 提交企业认证 */
export const submitEnterprise = (params: EnterpriseParams) =>
  request.post<any, EnterpriseData>('/enterprise', params)

/** GET /enterprise/my 获取本企业信息 */
export const getMyEnterprise = () =>
  request.get<any, EnterpriseData>('/enterprise/my')

/** PUT /enterprise 更新企业信息 */
export const updateEnterprise = (params: EnterpriseParams) =>
  request.put<any, EnterpriseData>('/enterprise', params)
