export class ApplicationTabPolicy {
  static resolve(tab: string): number {
    if (tab === 'interviews') {
      return 1
    }
    if (tab === 'hired') {
      return 2
    }
    return 0
  }
}
