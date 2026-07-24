// ChatMessageDataSource.ets — 聊天消息 LazyForEach 数据源

import { ChatMessageVO } from '../../services/ChatTypes';

export class ChatMessageDataSource implements IDataSource {
  private messages: ChatMessageVO[] = [];
  private listeners: DataChangeListener[] = [];

  constructor(messages: ChatMessageVO[]) {
    this.messages = messages;
  }

  totalCount(): number {
    return this.messages.length;
  }

  getData(index: number): ChatMessageVO {
    return this.messages[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const position = this.listeners.indexOf(listener);
    if (position >= 0) {
      this.listeners.splice(position, 1);
    }
  }

  setMessages(messages: ChatMessageVO[]): void {
    this.messages = messages;
    this.notifyDataReload();
  }

  /** 在列表末尾追加一条消息并通知 LazyForEach */
  appendMessage(message: ChatMessageVO): void {
    this.messages.push(message);
    this.notifyDataAdd(this.messages.length - 1);
  }

  /** 在列表头部插入历史消息并通知 LazyForEach 重新加载 */
  prependMessages(messages: ChatMessageVO[]): void {
    this.messages = [...messages, ...this.messages];
    this.notifyDataReload();
  }

  notifyDataAdd(index: number): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataAdd(index);
    });
  }

  notifyDataReload(): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataReloaded();
    });
  }
}
