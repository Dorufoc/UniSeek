// ChatMessageList.ets — 聊天消息 List + LazyForEach 容器

import { ChatMessageVO } from '../../services/ChatTypes';
import { UserSession } from '../../services/UserSession';
import { AppColors, AppFontSize, AppRadius, AppSpacing, AppChat } from '../../common/AppStyles';
import { ChatMessageDataSource } from './ChatMessageDataSource';
import { MessageItem } from './MessageItem';
import { shouldShowTimeLabel, getDateSeparatorLabel } from './ChatMessageUtils';

// 外部控制器：允许页面主动调用列表滚动方法
export class ChatMessageListController {
  scrollToBottom: () => void = () => {};
}

@Component
export struct ChatMessageList {
  @Link @Watch('onMessagesChange') messages: ChatMessageVO[];
  @Prop counterpartName: string = '';
  @Prop counterpartAvatar: string = '';
  @Prop isLoadingMore: boolean = false;
  @Prop hasMore: boolean = true;
  @Prop isAttachmentHandling: boolean = false;
  @Prop controller: ChatMessageListController = new ChatMessageListController();
  onLoadMore?: () => void;
  onImageClick?: (url: string) => void;
  onResumeDownload?: (url: string) => void;

  private scroller: ListScroller = new ListScroller();
  private dataSource: ChatMessageDataSource = new ChatMessageDataSource(this.messages);
  // 记录上一次可见的最后一条消息 ID，用于区分追加与预加载历史消息
  private lastBottomMessageId: number = -1;

  aboutToAppear(): void {
    if (this.controller) {
      this.controller.scrollToBottom = (): void => {
        this.scrollToBottom();
      };
    }
    if (this.messages.length > 0) {
      this.lastBottomMessageId = this.messages[this.messages.length - 1].id;
    }
    this.dataSource.setMessages(this.messages);
  }

  onMessagesChange(): void {
    this.dataSource.setMessages(this.messages);
    const count = this.messages.length;
    if (count === 0) {
      this.lastBottomMessageId = -1;
      return;
    }
    const newLastId = this.messages[count - 1].id;
    // 只有在列表末尾追加新消息（ID 发生变化）时才自动滚动到底部；
    // 预加载历史消息不会改变最后一条 ID，避免把用户拉回底部。
    if (newLastId !== this.lastBottomMessageId) {
      this.lastBottomMessageId = newLastId;
      this.scrollToBottom();
    }
  }

  private scrollToBottom(): void {
    // 延迟到 LazyForEach 完成布局后再滚动，否则新项尚未测量，滚动目标会失效。
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 80);
  }

  private isSelfMessage(msg: ChatMessageVO): boolean {
    return msg.senderId === UserSession.userId;
  }

  private shouldShowTimeLabel(index: number): boolean {
    if (index <= 0 || this.messages.length <= 1) {
      return true;
    }
    const prev = this.messages[index - 1];
    const curr = this.messages[index];
    return shouldShowTimeLabel(prev.sendTime, curr.sendTime);
  }

  private shouldShowDateSeparator(index: number): boolean {
    if (index <= 0 || this.messages.length <= 1) {
      return true;
    }
    const prev = this.messages[index - 1];
    const curr = this.messages[index];
    return getDateSeparatorLabel(prev.sendTime) !== getDateSeparatorLabel(curr.sendTime);
  }

  build() {
    List({ scroller: this.scroller }) {
      // 顶部加载更多按钮（位于最早消息上方）
      if (this.hasMore && this.messages.length > 0) {
        ListItem() {
          Button() {
            if (this.isLoadingMore) {
              LoadingProgress()
                .width(AppSpacing.ICON_XS)
                .height(AppSpacing.ICON_XS)
                .color(AppColors.PRIMARY)
            } else {
              Text('加载更多')
                .fontSize(AppFontSize.META)
                .fontColor(AppColors.PRIMARY)
                .fontWeight(FontWeight.Medium)
            }
          }
          .width('100%')
          .height(AppSpacing.BUTTON_HEIGHT_MD)
          .backgroundColor('transparent')
          .borderRadius(AppRadius.MD)
          .enabled(!this.isLoadingMore)
          .onClick(() => {
            if (!this.isLoadingMore) {
              this.onLoadMore?.();
            }
          })
          .stateStyles({
            pressed: {
              .backgroundColor(AppColors.PRIMARY_ALPHA_6)
            }
          })
          .animation({ duration: 200 })
        }
      }

      LazyForEach(this.dataSource, (msg: ChatMessageVO, index: number) => {
        ListItem() {
          MessageItem({
            msg: msg,
            isSelf: this.isSelfMessage(msg),
            counterpartName: this.counterpartName,
            counterpartAvatar: this.counterpartAvatar,
            showTime: this.shouldShowTimeLabel(index),
            showDateSeparator: this.shouldShowDateSeparator(index),
            dateLabel: getDateSeparatorLabel(msg.sendTime),
            isAttachmentHandling: this.isAttachmentHandling,
            onImageClick: () => {
              this.onImageClick?.(msg.content);
            },
            onResumeDownload: () => {
              this.onResumeDownload?.(msg.content);
            }
          })
        }
      }, (msg: ChatMessageVO) => msg.id.toString())
    }
    .stackFromEnd(true)
    .layoutWeight(1)
    .width('100%')
    .padding({
      left: AppSpacing.MD,
      right: AppSpacing.MD
    })
    .onReachStart(() => {
      if (this.hasMore && !this.isLoadingMore && this.messages.length > 0) {
        this.onLoadMore?.();
      }
    })
  }
}
