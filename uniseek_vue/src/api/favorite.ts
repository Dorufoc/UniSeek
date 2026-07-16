import request from './index'

export interface FavoriteRecord {
  id: number
  userId: number
  taskId: number
  createTime: string
}

export interface PageResult<T> {
  records: T[]
  total: number
  page: number
  pageSize: number
}

export async function addFavorite(taskId: number): Promise<any> {
  return request.post(`/favorites/${taskId}`)
}

export async function removeFavorite(taskId: number): Promise<any> {
  return request.delete(`/favorites/${taskId}`)
}

export async function checkFavorited(taskId: number): Promise<{ favorited: boolean }> {
  const res: any = await request.get(`/favorites/check/${taskId}`)
  return res
}

export async function listFavorites(page = 1, pageSize = 10): Promise<PageResult<any>> {
  const res: any = await request.get('/favorites', { params: { page, pageSize } })
  return res
}

export async function countFavorites(): Promise<{ count: number }> {
  const res: any = await request.get('/favorites/count')
  return res
}
