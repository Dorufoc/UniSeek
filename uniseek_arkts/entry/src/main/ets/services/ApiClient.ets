import { http } from '@kit.NetworkKit';
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

const PREF_NAME = 'uniseek_token_db';
const KEY_TOKEN = 'jwt_token';

export interface ApiEmpty {}

export class ApiClient {
  static BASE_URL: string = 'http://192.168.246.118:8080'

  static saveToken(token: string): void {
    const pref = preferences.getPreferencesSync(getContext(), { name: PREF_NAME })
    pref.putSync(KEY_TOKEN, token)
    pref.flushSync()
  }

  static getToken(): string {
    const pref = preferences.getPreferencesSync(getContext(), { name: PREF_NAME })
    return pref.getSync(KEY_TOKEN, '') as string
  }

  static clearToken(): void {
    const pref = preferences.getPreferencesSync(getContext(), { name: PREF_NAME })
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

  static async patch<T>(path: string, body?: object): Promise<T> {
    return request<T>('PATCH', path, undefined, body)
  }

  static async delete<T>(path: string): Promise<T> {
    return request<T>('DELETE', path)
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
        ApiClient.clearToken()
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