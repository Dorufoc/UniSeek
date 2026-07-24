// 单个聊天会话项
// 参考微信/QQ/钉钉等即时通讯应用：左侧头像叠加未读红点，右侧上下两行信息，
// 整体采用 cards-on-page 风格，搭配 HMOS List 分割线，提供清晰按压反馈。

import { ChatSessionVO } from '../../services/ChatTypes';
import { AppColors, AppFontSize, AppRadius, AppSpacing, AppChat } from '../../common/AppStyles';
import { Avatar } from './Avatar';
import { UnreadBadge } from './UnreadBadge';
import { formatSessionTime, formatSessionPreview } from './ChatMessageUtils';

@Component
export struct ChatSessionItem {
  @Prop session: ChatSessionVO
  @Prop isSelected: boolean = false
  @Prop showChevron: boolean = false
  @Prop tagText: string = ''
  onItemClick?: () => void

  private getPreview(): string {
    return formatSessionPreview(this.session.lastMessage)
  }

  build() {
    Row() {
      // 头像区：右上角叠加未读徽标
      Stack({ alignContent: Alignment.Center }) {
        Avatar({
          url: this.session.counterpartAvatar,
          name: this.session.counterpartName,
          avatarSize: AppChat.AVATAR_SESSION
        })

        if (this.session.unreadCount > 0) {
          UnreadBadge({ count: this.session.unreadCount })
            .align(Alignment.TopEnd)
            .margin({ top: -AppSpacing.XXS, right: -AppSpacing.XXS })
        }
      }
      .width(AppChat.AVATAR_SESSION)
      .height(AppChat.AVATAR_SESSION)

      // 名称、时间、最后消息
      Column() {
        // 第一行：对方昵称 + 身份标签（左侧），最后消息时间（右侧）
        Row() {
          Row() {
            Text(this.session.counterpartName)
              .fontSize(AppChat.SESSION_NAME_FONT)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.isSelected ? AppColors.PRIMARY : AppColors.TEXT_PRIMARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            if (this.tagText) {
              Text(this.tagText)
                .fontSize(AppFontSize.XXS)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppColors.PRIMARY)
                .padding({ left: AppSpacing.XS, right: AppSpacing.XS })
                .margin({ left: AppSpacing.XS })
                .backgroundColor(AppColors.PRIMARY_ALPHA_8)
                .borderRadius(AppRadius.SM)
            }
          }
          .layoutWeight(1)
          .alignItems(VerticalAlign.Center)

          Text(formatSessionTime(this.session.lastMessageTime))
            .fontSize(AppChat.SESSION_TIME_FONT)
            .fontColor(this.session.unreadCount > 0 ? AppColors.TEXT_PRIMARY : AppColors.TEXT_MUTED)
            .fontWeight(FontWeight.Regular)
            .flexShrink(0)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 第二行：最后一条消息预览
        Row() {
          Text(this.getPreview())
            .fontSize(AppChat.SESSION_PREVIEW_FONT)
            .fontColor(this.session.lastMessage ? AppColors.TEXT_SECONDARY : AppColors.TEXT_MUTED)
            .lineHeight(AppChat.PREVIEW_LINE_HEIGHT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (this.showChevron) {
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(AppFontSize.SM)
              .fontColor([AppColors.TEXT_MUTED])
              .margin({ left: AppSpacing.XS })
          }
        }
        .width('100%')
        .margin({ top: AppSpacing.XS })
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: AppSpacing.SM_PLUS })
    }
    .width('100%')
    .height(AppChat.SESSION_ITEM_HEIGHT)
    .padding({
      left: AppSpacing.MD,
      right: AppSpacing.MD,
      top: AppSpacing.SM_PLUS,
      bottom: AppSpacing.SM_PLUS
    })
    .backgroundColor(this.isSelected ? AppColors.SELECTED_BG : AppColors.BG_CARD)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onItemClick?.()
    })
    .stateStyles({
      pressed: {
        .backgroundColor(AppColors.SELECTED_BG)
      }
    })
  }
}
