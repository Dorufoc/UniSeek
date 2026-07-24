// MessageBubble.ets — 文本消息气泡组件

import { AppColors, AppFontSize, AppRadius, AppSpacing, AppChat } from '../../common/AppStyles';

@Component
export struct MessageBubble {
  @Prop content: string = '';
  @Prop isSelf: boolean = false;

  build() {
    Text(this.content)
      .fontSize(AppChat.BUBBLE_FONT)
      .fontColor(this.isSelf ? AppColors.BG_CARD : AppColors.TEXT_PRIMARY)
      .padding({
        left: AppSpacing.MD,
        right: AppSpacing.MD,
        top: AppSpacing.SM_PLUS,
        bottom: AppSpacing.SM_PLUS
      })
      .borderRadius({
        topLeft: this.isSelf ? AppRadius.BUBBLE : AppChat.BUBBLE_OTHER_SHARP_CORNER,
        topRight: this.isSelf ? AppChat.BUBBLE_SELF_SHARP_CORNER : AppRadius.BUBBLE,
        bottomLeft: AppRadius.BUBBLE,
        bottomRight: AppRadius.BUBBLE
      })
      .maxLines(100)
      .lineHeight(AppChat.BUBBLE_LINE_HEIGHT)
      .backgroundColor(this.isSelf ? AppColors.PRIMARY : AppColors.BG_CARD)
      .borderWidth(this.isSelf ? 0 : 1)
      .borderColor(this.isSelf ? AppColors.PRIMARY : AppColors.BORDER)
  }
}
