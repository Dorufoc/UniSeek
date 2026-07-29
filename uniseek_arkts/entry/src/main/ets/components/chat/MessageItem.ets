// MessageItem.ets — 单条完整消息行：头像、昵称、内容气泡、时间标签、日期分隔线

import { ChatMessageVO } from '../../services/ChatTypes';
import { AppColors, AppFontSize, AppSpacing, AppChat } from '../../common/AppStyles';
import { Avatar } from './Avatar';
import { MessageBubble } from './MessageBubble';
import { ChatImageMessage } from './ChatImageMessage';
import { AttachmentCard } from './AttachmentCard';
import { MessageTimeLabel } from './MessageTimeLabel';
import { MessageDateSeparator } from './MessageDateSeparator';
import { formatMessageTime } from './ChatMessageUtils';

@Component
export struct MessageItem {
  @Prop msg: ChatMessageVO;
  @Prop isSelf: boolean = false;
  @Prop counterpartName: string = '';
  @Prop counterpartAvatar: string = '';
  @Prop showTime: boolean = false;
  @Prop showDateSeparator: boolean = false;
  @Prop dateLabel: string = '';
  @Prop isAttachmentHandling: boolean = false;
  onImageClick?: () => void;
  onResumeDownload?: () => void;

  private getDisplayName(): string {
    // 自己发送的消息优先使用 senderName，缺失时回退到对方昵称（当前会话上下文兜底）
    const fallbackName: string = this.counterpartName || '我'
    if (this.isSelf) {
      return this.msg.senderName || fallbackName;
    }
    return this.msg.senderName || this.counterpartName;
  }

  private getAvatarUrl(): string {
    // 优先使用当前消息发送者的自定义头像，缺失时回退到会话头像
    return this.msg.senderAvatar || this.counterpartAvatar;
  }

  build() {
    Column() {
      // 日期分隔线
      if (this.showDateSeparator && this.dateLabel.length > 0) {
        MessageDateSeparator({ label: this.dateLabel })
      }

      // 时间标签
      if (this.showTime) {
        Row() {
          MessageTimeLabel({ time: formatMessageTime(this.msg.sendTime) })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: AppChat.MESSAGE_TIME_GAP, bottom: AppChat.MESSAGE_TIME_GAP })
      }

      // 消息行：头像 + 气泡（发送方头像在右，接收方在左）
      Row() {
        if (this.isSelf) {
          Blank().layoutWeight(1)
        }

        Row({ space: AppChat.MESSAGE_ROW_SPACE }) {
          if (!this.isSelf) {
            Avatar({
              url: this.getAvatarUrl(),
              name: this.getDisplayName(),
              avatarSize: AppChat.AVATAR_MESSAGE
            })
          }

          Column() {
            Text(this.getDisplayName())
              .fontSize(AppFontSize.CAPTION)
              .fontColor(AppColors.TEXT_MUTED)
              .fontWeight(500)
              .margin({ bottom: AppSpacing.XS_GAP })

            if (this.msg.messageType === 1) {
              ChatImageMessage({ url: this.msg.content, onImageClick: () => { this.onImageClick?.() } })
            } else if (this.msg.messageType === 2) {
              AttachmentCard({
                url: this.msg.content,
                isSelf: this.isSelf,
                isHandling: this.isAttachmentHandling,
                onDownload: () => { this.onResumeDownload?.() }
              })
            } else {
              MessageBubble({ content: this.msg.content, isSelf: this.isSelf })
            }
          }
          .alignItems(this.isSelf ? HorizontalAlign.End : HorizontalAlign.Start)
          .width(AppChat.BUBBLE_MAX_WIDTH)

          if (this.isSelf) {
            Avatar({
              url: this.getAvatarUrl(),
              name: this.getDisplayName(),
              avatarSize: AppChat.AVATAR_MESSAGE
            })
          }
        }
        .alignItems(VerticalAlign.Top)

        if (!this.isSelf) {
          Blank().layoutWeight(1)
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .margin({ bottom: AppSpacing.SM })
    .transition({ opacity: 0, translate: { y: AppSpacing.SM_PLUS } })
  }
}
