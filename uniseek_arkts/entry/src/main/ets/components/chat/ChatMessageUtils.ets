// ChatMessageUtils.ets — 聊天模块通用工具函数
// 纯函数，供会话列表与聊天详情页复用

const ONE_MINUTE: number = 60000;
const FIVE_MINUTES: number = 5 * ONE_MINUTE;
const ONE_DAY_MS: number = 86400000;
const ATTACHMENT_NAME_MAX_LENGTH: number = 30;
const ATTACHMENT_TRUNCATE_KEEP: number = 27;

// 格式化会话时间：当天显示 HH:mm，昨天显示 "昨天"，更早显示 MM-DD
export function formatSessionTime(dateStr: string): string {
  if (!dateStr || dateStr.length === 0) {
    return '';
  }
  const d: Date = new Date(dateStr);
  const now: Date = new Date();
  const diff: number = now.getTime() - d.getTime();
  if (diff < ONE_DAY_MS && diff >= 0) {
    return dateStr.substring(11, 16);
  }
  if (diff < 2 * ONE_DAY_MS && diff >= 0) {
    return '昨天';
  }
  return dateStr.substring(5, 10);
}

// 判断相邻两条消息之间是否需要显示时间标签，默认间隔超过 5 分钟即显示
export function shouldShowTimeLabel(prevTime: string, currTime: string): boolean {
  if (!prevTime || prevTime.length === 0) {
    return true;
  }
  if (!currTime || currTime.length === 0) {
    return false;
  }
  const prev: Date = new Date(prevTime);
  const curr: Date = new Date(currTime);
  if (Number.isNaN(prev.getTime()) || Number.isNaN(curr.getTime())) {
    return true;
  }
  return Math.abs(curr.getTime() - prev.getTime()) > FIVE_MINUTES;
}

// 格式化消息时间：HH:mm（用于聊天详情页消息间时间标签）
export function formatMessageTime(dateStr: string): string {
  if (!dateStr || dateStr.length === 0) {
    return '';
  }
  return dateStr.substring(11, 16);
}

// 根据日期字符串返回分隔线文案：今天 / 昨天 / MM-DD
export function getDateSeparatorLabel(dateStr: string): string {
  if (!dateStr || dateStr.length === 0) {
    return '';
  }
  const d: Date = new Date(dateStr);
  if (Number.isNaN(d.getTime())) {
    return '';
  }
  const now: Date = new Date();
  const today: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const target: Date = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  const diff: number = today.getTime() - target.getTime();
  if (diff === 0) {
    return '今天';
  }
  if (diff === ONE_DAY_MS) {
    return '昨天';
  }
  const month: number = target.getMonth() + 1;
  const day: number = target.getDate();
  const monthStr: string = month < 10 ? '0' + month : '' + month;
  const dayStr: string = day < 10 ? '0' + day : '' + day;
  return monthStr + '-' + dayStr;
}

// 从 URL 中提取文件名，超过 30 字符时截断
export function getAttachmentName(url: string, defaultName: string = '简历附件'): string {
  if (!url || url.length === 0) {
    return defaultName;
  }
  const lastSlash: number = url.lastIndexOf('/');
  const name: string = lastSlash >= 0 ? url.substring(lastSlash + 1) : url;
  const cleanName: string = name.length > 0 ? name : defaultName;
  if (cleanName.length > ATTACHMENT_NAME_MAX_LENGTH) {
    return cleanName.substring(0, ATTACHMENT_TRUNCATE_KEEP) + '...';
  }
  return cleanName;
}
