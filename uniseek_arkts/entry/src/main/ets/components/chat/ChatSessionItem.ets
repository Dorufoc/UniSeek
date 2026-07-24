// 单个聊天会话项：头像、对端名称（带身份标签）、最后消息预览、时间、未读徽标、箭头

import { ChatSessionVO } from '../../services/ChatTypes';
import { AppColors, AppFontSize, AppRadius, AppSpacing, AppChat } from '../../common/AppStyles';
import { Avatar } from './Avatar';
import { UnreadBadge } from './UnreadBadge';
import { formatSessionTime } from './ChatMessageUtils';

@Component
export struct ChatSessionItem {
  @Prop session: ChatSessionVO
  @Prop isSelected: boolean = false
  @Prop showChevron: boolean = true
  @Prop tagText: string = ''
  onItemClick?: () => void

  build() {
    Stack() {
      // 选中态背景层，通过透明度切换并带动画
      Row()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.SELECTED_BG)
        .borderRadius(AppRadius.XL)
        .opacity(this.isSelected ? 1 : 0)
        .animation({ duration: AppChat.SESSION_SELECT_DURATION })

      Row() {
        Avatar({
          url: this.session.counterpartAvatar,
          name: this.session.counterpartName,
          avatarSize: AppChat.AVATAR_SESSION
        })

        Column() {
          // 第一行：对端名称 + 身份标签 + 时间
          Row() {
            Row() {
              Text(this.session.counterpartName)
                .fontSize(AppChat.SESSION_NAME_FONT)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppColors.TEXT_PRIMARY)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              if (this.tagText) {
                Text('[' + this.tagText + ']')
                  .fontSize(AppFontSize.XS)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(AppColors.PRIMARY)
                  .margin({ left: AppSpacing.XS })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
            }
            .layoutWeight(1)
            .alignItems(VerticalAlign.Center)

            Text(formatSessionTime(this.session.lastMessageTime))
              .fontSize(AppChat.SESSION_TIME_FONT)
              .fontColor(AppColors.TEXT_MUTED)
              .fontWeight(FontWeight.Medium)
              .flexShrink(0)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 第二行：最后消息预览 + 未读徽标
          Row() {
            Text(this.session.lastMessage)
              .fontSize(AppChat.SESSION_PREVIEW_FONT)
              .fontColor(AppColors.TEXT_SECONDARY)
              .lineHeight(AppChat.PREVIEW_LINE_HEIGHT)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)

            UnreadBadge({ count: this.session.unreadCount })
          }
          .width('100%')
          .margin({ top: AppSpacing.XS })
          .alignItems(VerticalAlign.Center)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        if (this.showChevron) {
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(AppFontSize.MD)
            .fontColor([AppColors.TEXT_MUTED])
            .margin({ left: AppSpacing.XS })
        }
      }
      .width('100%')
      .padding({
        left: AppSpacing.MD,
        right: AppSpacing.MD,
        top: AppChat.SESSION_ITEM_PADDING,
        bottom: AppChat.SESSION_ITEM_PADDING
      })
      .alignItems(VerticalAlign.Center)

      // 左侧选中态竖条提示
      Column() {
        Column()
          .width(AppChat.SELECTOR_WIDTH)
          .height(AppChat.SELECTOR_HEIGHT)
          .borderRadius({ topRight: AppChat.SELECTOR_RADIUS, bottomRight: AppChat.SELECTOR_RADIUS })
          .backgroundColor(AppColors.PRIMARY)
      }
      .width(AppChat.SELECTOR_WIDTH)
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .position({ x: 0 })
      .opacity(this.isSelected ? 1 : 0)
      .animation({ duration: AppChat.SESSION_SELECT_DURATION })
    }
    .width('100%')
    .height(AppChat.AVATAR_SESSION + AppChat.SESSION_ITEM_PADDING * 2)
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
