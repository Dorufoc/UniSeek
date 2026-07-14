import type { AxiosInstance } from 'axios'
import MockAdapter from 'axios-mock-adapter'

export function setupMock(request: AxiosInstance) {
  if (!import.meta.env.DEV) return

  const mock = new MockAdapter(request, { delayResponse: 500 })

  mock.onPost('/auth/login/password').reply((config) => {
    const { phone, password } = JSON.parse(config.data)
    if (phone && password) {
      return [
        200,
        {
          token: 'mock_token_' + Date.now(),
          userId: 1,
          nickname: '测试用户',
          avatar: ''
        }
      ]
    }
    return [400, { message: '请填写完整信息' }]
  })

  mock.onPost('/auth/register').reply((config) => {
    const { username, email, password } = JSON.parse(config.data)
    if (username && email && password) {
      return [
        200,
        {
          token: 'mock_token_' + Date.now(),
          userId: 2,
          nickname: username,
          avatar: ''
        }
      ]
    }
    return [400, { message: '请填写完整信息' }]
  })
}
