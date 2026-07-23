export class ApplicationTabPolicy {
  static resolve(tab: string): number {
    if (tab === 'interviews') {
      return 1
    }
    return 0
  }
}
