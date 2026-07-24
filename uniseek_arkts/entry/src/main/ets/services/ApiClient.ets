import { http } from '@kit.NetworkKit';
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { Context } from '@kit.AbilityKit';
import { TaskSearchParams, TaskVO, PageResult } from './ChatTypes';
import { ServerConfig } from './ServerConfig';

const PREF_NAME = 'uniseek_token_db';
const KEY_TOKEN = 'jwt_token';
const KEY_BASE_URL = 'base_url';
const KEY_SESSION_USER_ID = 'session_user_id';
const KEY_SESSION_ROLE = 'session_role';
const KEY_SESSION_NICKNAME = 'session_nickname';
const KEY_SESSION_AVATAR = 'session_avatar';

export interface StoredSession {
  userId: number
  role: number
  nickname: string
  avatarUrl: string
}

export interface ApiEmpty {}

export class ApiClient {
  static BASE_URL: string = 'http://192.168.246.118:8080'

  private static appContext: Context | null = null

  /** 由 UIAbility 在应用创建时注入，用于在页面创建前恢复配置。 */
  static initialize(context: Context): void {
    ApiClient.appContext = context
  }

  static getPreferenceStore(): preferences.Preferences | null {
    if (!ApiClient.appContext) {
      return null
    }
    try {
      return preferences.getPreferencesSync(ApiClient.appContext, { name: PREF_NAME })
    } catch {
      return null
    }
  }

  private static configurationRestored: boolean = false

  /** 从本地偏好设置恢复后端地址。 */
  static restoreConfiguration(): void {
    if (ApiClient.configurationRestored) {
      return
    }
    ApiClient.configurationRestored = true
    try {
      const pref = ApiClient.getPreferenceStore()
      if (!pref) {
        return
      }
      const savedUrl: string = pref.getSync(KEY_BASE_URL, '') as string
      if (savedUrl.trim().length > 0) {
        ApiClient.BASE_URL = ServerConfig.normalizeBaseUrl(savedUrl)
      }
    } catch {
      ApiClient.BASE_URL = ServerConfig.DEFAULT_BASE_URL
    }
  }

  /** 更新并持久化后端地址。 */
  static setBaseUrl(value: string): string {
    const normalized: string = ServerConfig.normalizeBaseUrl(value)
    ApiClient.BASE_URL = normalized
    ApiClient.configurationRestored = true
    const pref = ApiClient.getPreferenceStore()
    if (!pref) {
      return normalized
    }
    pref.putSync(KEY_BASE_URL, normalized)
    pref.flushSync()
    return normalized
  }

  /** 持久化当前登录用户快照，供应用重启时恢复角色和展示信息。 */
  static saveSession(userId: number, role: number, nickname: string, avatarUrl: string): void {
    const pref = ApiClient.getPreferenceStore()
    if (!pref) {
      return
    }
    pref.putSync(KEY_SESSION_USER_ID, userId)
    pref.putSync(KEY_SESSION_ROLE, role)
    pref.putSync(KEY_SESSION_NICKNAME, nickname)
    pref.putSync(KEY_SESSION_AVATAR, avatarUrl)
    pref.flushSync()
  }

  static getStoredSession(): StoredSession | null {
    ApiClient.restoreConfiguration()
    const token: string = ApiClient.getToken()
    if (!token) {
      return null
    }
    const pref = ApiClient.getPreferenceStore()
    if (!pref) {
      return null
    }
    const userId: number = pref.getSync(KEY_SESSION_USER_ID, 0) as number
    if (userId <= 0) {
      return null
    }
    const stored: StoredSession = {
      userId: userId,
      role: pref.getSync(KEY_SESSION_ROLE, 0) as number,
      nickname: pref.getSync(KEY_SESSION_NICKNAME, '') as string,
      avatarUrl: pref.getSync(KEY_SESSION_AVATAR, '') as string
    }
    return stored
  }

  /** 清除令牌和用户快照，但保留后端地址配置。 */
  static clearSession(): void {
    const pref = ApiClient.getPreferenceStore()
    if (!pref) {
      return
    }
    pref.putSync(KEY_TOKEN, '')
    pref.putSync(KEY_SESSION_USER_ID, 0)
    pref.putSync(KEY_SESSION_ROLE, 0)
    pref.putSync(KEY_SESSION_NICKNAME, '')
    pref.putSync(KEY_SESSION_AVATAR, '')
    pref.flushSync()
  }

  static saveToken(token: string): void {
    ApiClient.restoreConfiguration()
    const pref = ApiClient.getPreferenceStore()
    if (!pref) {
      return
    }
    pref.putSync(KEY_TOKEN, token)
    pref.flushSync()
  }

  static getToken(): string {
    ApiClient.restoreConfiguration()
    const pref = ApiClient.getPreferenceStore()
    if (!pref) {
      return ''
    }
    return pref.getSync(KEY_TOKEN, '') as string
  }

  static clearToken(): void {
    const pref = ApiClient.getPreferenceStore()
    if (!pref) {
      return
    }
    pref.putSync(KEY_TOKEN, '')
    pref.flushSync()
  }

  static hasToken(): boolean {
    return ApiClient.getToken().length > 0
  }

  static async get<T>(path: string, params?: Array<[string, string]>): Promise<T> {
    return request<T>('GET', path, params)
  }

  static async post<T>(path: string, body?: object): Promise<T> {
    return request<T>('POST', path, undefined, body)
  }

  static async put<T>(path: string, body?: object): Promise<T> {
    return request<T>('PUT', path, undefined, body)
  }

  /** 使用查询参数发起 PUT 请求，适配后端 @RequestParam 接口。 */
  static async putWithParams<T>(path: string, params: Array<[string, string]>, body?: object): Promise<T> {
    return request<T>('PUT', path, params, body)
  }

  static async patch<T>(path: string, body?: object): Promise<T> {
    return request<T>('PATCH', path, undefined, body)
  }

  static async delete<T>(path: string): Promise<T> {
    return request<T>('DELETE', path)
  }

  static async searchTasks(params: TaskSearchParams): Promise<PageResult<TaskVO>> {
    const queryParams: Array<[string, string]> = []
    if (params.keyword !== undefined && params.keyword !== null) {
      queryParams.push(['keyword', params.keyword])
    }
    if (params.categoryId !== undefined && params.categoryId !== null) {
      queryParams.push(['categoryId', String(params.categoryId)])
    }
    if (params.regionId !== undefined && params.regionId !== null) {
      queryParams.push(['regionId', String(params.regionId)])
    }
    if (params.regionIds !== undefined && params.regionIds !== null) {
      queryParams.push(['regionIds', params.regionIds])
    }
    if (params.categoryIds !== undefined && params.categoryIds !== null) {
      queryParams.push(['categoryIds', params.categoryIds])
    }
    if (params.jobType !== undefined && params.jobType !== null) {
      queryParams.push(['jobType', String(params.jobType)])
    }
    if (params.salaryMin !== undefined && params.salaryMin !== null) {
      queryParams.push(['salaryMin', String(params.salaryMin)])
    }
    if (params.salaryMax !== undefined && params.salaryMax !== null) {
      queryParams.push(['salaryMax', String(params.salaryMax)])
    }
    if (params.salaryUnit !== undefined && params.salaryUnit !== null) {
      queryParams.push(['salaryUnit', String(params.salaryUnit)])
    }
    if (params.includeNegotiable !== undefined && params.includeNegotiable !== null) {
      queryParams.push(['includeNegotiable', String(params.includeNegotiable)])
    }
    if (params.tags !== undefined && params.tags !== null) {
      queryParams.push(['tags', params.tags])
    }
    if (params.sortBy !== undefined && params.sortBy !== null) {
      queryParams.push(['sortBy', params.sortBy])
    }
    if (params.sortOrder !== undefined && params.sortOrder !== null) {
      queryParams.push(['sortOrder', params.sortOrder])
    }
    if (params.page !== undefined && params.page !== null) {
      queryParams.push(['page', String(params.page)])
    }
    if (params.pageSize !== undefined && params.pageSize !== null) {
      queryParams.push(['pageSize', String(params.pageSize)])
    }
    return ApiClient.get<PageResult<TaskVO>>('/api/tasks', queryParams)
  }

  static async getTaskById(taskId: number): Promise<TaskVO> {
    return ApiClient.get<TaskVO>('/api/tasks/' + taskId)
  }
}

interface ApiResult {
  code: number
  message: string
  data: object | undefined
}

function request<T>(method: string, path: string, params?: Array<[string, string]>, body?: object): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    const url = buildUrl(path, params)
    const httpRequest = http.createHttp()

    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    }

    const token = ApiClient.getToken()
    if (token) {
      headers['Authorization'] = 'Bearer ' + token
    }

    httpRequest.request(url, {
      method: method as http.RequestMethod,
      header: headers,
      extraData: body ? JSON.stringify(body) : undefined,
      connectTimeout: 10000,
      readTimeout: 15000
    }).then((resp: http.HttpResponse) => {
      httpRequest.destroy()
      const raw = resp.result as string
      if (!raw) {
        reject(new Error('响应为空'))
        return
      }

      let json: ApiResult
      try {
        json = JSON.parse(raw) as ApiResult
      } catch {
        reject(new Error('响应解析失败'))
        return
      }

      if (json.code === 200) {
        resolve(json.data as T)
      } else if (json.code === 401) {
        ApiClient.clearSession()
        const LoginPage = '@bundle:com.example.uniseek/EntryAbility/'
        try {
          const ctx = getContext()
          const uiAbility = (ctx as object) as Record<string, object>
          const ability = uiAbility['ability'] as Record<string, Function>
          if (ability && ability['terminateSelf']) {
            ability['terminateSelf']()
          }
        } catch {
        }
        reject(new Error(json.message || '登录已过期，请重新登录'))
      } else {
        reject(new Error(json.message || '请求失败'))
      }
    }).catch((err: BusinessError) => {
      httpRequest.destroy()
      reject(new Error('网络请求失败: ' + err.message))
    })
  })
}

function buildUrl(path: string, params?: Array<[string, string]>): string {
  let url = ApiClient.BASE_URL + path
  if (params && params.length > 0) {
    const parts: string[] = []
    for (const param of params) {
      const key = param[0]
      const val = param[1]
      if (val !== undefined && val !== null && val !== '') {
        parts.push(encodeURIComponent(key) + '=' + encodeURIComponent(val))
      }
    }
    if (parts.length > 0) {
      url += '?' + parts.join('&')
    }
  }
  return url
}
