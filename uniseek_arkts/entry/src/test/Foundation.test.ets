import { describe, it, expect } from '@ohos/hypium'
import { AppBootstrapPolicy } from '../main/ets/common/AppBootstrapPolicy'
import { BreakpointResolver, WindowBreakpoint } from '../main/ets/common/Responsive'
import { ServerConfig } from '../main/ets/services/ServerConfig'

export default function foundationTest(): void {
  describe('UniSeek基础策略', (): void => {
    it('未登录时进入登录页', 0, (): void => {
      expect(AppBootstrapPolicy.resolveInitialPage(false, 0)).assertEqual('pages/LoginPage')
    })

    it('求职者恢复会话后进入求职者首页', 0, (): void => {
      expect(AppBootstrapPolicy.resolveInitialPage(true, 0)).assertEqual('pages/MainPage')
    })

    it('招聘者恢复会话后进入招聘者首页', 0, (): void => {
      expect(AppBootstrapPolicy.resolveInitialPage(true, 1)).assertEqual('pages/RecruiterHomePage')
    })

    it('服务器地址自动移除末尾斜杠', 0, (): void => {
      expect(ServerConfig.normalizeBaseUrl('http://192.168.1.2:8080/'))
        .assertEqual('http://192.168.1.2:8080')
    })

    it('非法服务器地址回退到默认地址', 0, (): void => {
      expect(ServerConfig.normalizeBaseUrl('192.168.1.2:8080'))
        .assertEqual(ServerConfig.DEFAULT_BASE_URL)
    })

    it('窗口宽度映射到原生响应式断点', 0, (): void => {
      expect(BreakpointResolver.resolve(359)).assertEqual(WindowBreakpoint.COMPACT)
      expect(BreakpointResolver.resolve(600)).assertEqual(WindowBreakpoint.MEDIUM)
      expect(BreakpointResolver.resolve(840)).assertEqual(WindowBreakpoint.EXPANDED)
    })
  })
}
