export function formatRemainingText(remainingQuota: number, totalQuota: number): string {
  if (remainingQuota <= 0) {
    return '已招满'
  }
  if (totalQuota > 0) {
    return '剩 ' + String(remainingQuota) + ' / ' + String(totalQuota) + ' 人'
  }
  return '剩 ' + String(remainingQuota) + ' 人'
}
