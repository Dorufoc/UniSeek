import request from './index'
import type { ApiResponse } from './auth'

export interface RegionVO {
  id: number
  name: string
  level: number
  children: RegionVO[]
}

/** 获取完整省/市/区三级树形结构 GET /api/region/tree */
export const getRegionTree = async () => {
  const res = await request.get<ApiResponse<RegionVO[]>>('/region/tree')
  return res.data
}
