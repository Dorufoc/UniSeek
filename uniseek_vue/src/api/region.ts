import request from './index'
import type { ApiResponse } from './auth'

export interface RegionVO {
  id: number
  name: string
  level: number
  children?: RegionVO[]
}

/** GET /region/provinces 获取省级列表 */
export const getProvinces = async () => {
  const res = await request.get<ApiResponse<RegionVO[]>>('/region/provinces')
  return res
}

/** GET /region/children/:parentId 获取子级区划 */
export const getRegionChildren = async (parentId: number) => {
  const res = await request.get<ApiResponse<RegionVO[]>>(`/region/children/${parentId}`)
  return res
}

/** GET /region/tree 获取完整省市区树 */
export const getRegionTree = async () => {
  const res = await request.get<ApiResponse<RegionVO[]>>('/region/tree')
  return res
}
