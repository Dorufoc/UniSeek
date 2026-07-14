import type { AxiosInstance } from 'axios'
import MockAdapter from 'axios-mock-adapter'

// 开发模式下设置 Mock 拦截器，模拟后端 API 响应
export function setupMock(request: AxiosInstance) {
  // 仅开发环境启用 Mock，生产构建时不执行
  if (!import.meta.env.DEV) return

  const mock = new MockAdapter(request, { delayResponse: 500 })

  // 模拟密码登录接口 POST /auth/login
  mock.onPost('/auth/login').reply((config) => {
    const { phone, password } = JSON.parse(config.data)
    if (phone && password) {
      return [
        200,
        {
          code: 200,
          msg: '登录成功',
          token: 'mock_token_' + Date.now(),
          userInfo: {
            userId: 1,
            nickname: '测试用户',
            avatarUrl: '',
            role: 0,          // 默认求职者角色
            phone: phone
          }
        }
      ]
    }
    return [400, { code: 400, msg: '请填写完整信息' }]
  })

  // 模拟注册接口 POST /auth/register
  mock.onPost('/auth/register').reply((config) => {
    const { phone, password, confirmPassword, nickname } = JSON.parse(config.data)
    if (phone && password && confirmPassword && nickname) {
      return [
        200,
        {
          code: 200,
          msg: '注册成功',
          token: 'mock_token_' + Date.now(),
          userInfo: {
            userId: 2,
            nickname: nickname,
            avatarUrl: '',
            role: phone === '19900000001' ? 1 : 0,  // 特定手机号模拟招聘者角色
            phone: phone
          }
        }
      ]
    }
    return [400, { code: 400, msg: '请填写完整信息' }]
  })
}
