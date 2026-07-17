export class UserSession {
  static userId: number = 0
  static role: number = 0
  static nickname: string = ''
  static avatarUrl: string = ''

  static clear(): void {
    UserSession.userId = 0
    UserSession.role = 0
    UserSession.nickname = ''
    UserSession.avatarUrl = ''
  }
}
