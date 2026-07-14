import request from './index'

export interface RegionVO {
  id: number
  name: string
  level: number
  children?: RegionVO[]
}

/** GET /region/provinces 获取省级列表 */
export const getProvinces = () =>
  request.get<any, RegionVO[]>('/region/provinces')

/** GET /region/children/:parentId 获取子级区划 */
export const getRegionChildren = (parentId: number) =>
  request.get<any, RegionVO[]>(`/region/children/${parentId}`)

/** GET /region/tree 获取完整省市区树 */
export const getRegionTree = () =>
  request.get<any, RegionVO[]>('/region/tree')
