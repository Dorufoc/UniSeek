/**
 * 应用启动页决策策略。
 * 将纯业务判断从 UIAbility 生命周期中分离，便于测试和复用。
 */
export class AppBootstrapPolicy {
  static resolveInitialPage(hasToken: boolean, role: number): string {
    if (!hasToken) {
      return 'pages/LoginPage'
    }
    if (role === 1) {
      return 'pages/RecruiterHomePage'
    }
    return 'pages/MainPage'
  }
}
