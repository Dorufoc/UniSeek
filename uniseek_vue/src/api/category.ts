import request from './index'

export interface CategoryVO {
  id: number
  parentId: number | null
  name: string
  sortOrder: number
  children?: CategoryVO[]
}

/** GET /categories 获取职位分类树 */
export const getCategories = () =>
  request.get<any, CategoryVO[]>('/categories')
