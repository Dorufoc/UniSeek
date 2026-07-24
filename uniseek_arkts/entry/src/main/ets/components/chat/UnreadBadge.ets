// UnreadBadge.ets — 聊天未读消息徽标
// 未读数 <= 0 时隐藏；>= 100 时显示 "99+"

import { AppColors, AppChat } from '../../common/AppStyles';

@Component
export struct UnreadBadge {
  @Prop count: number = 0;

  private getDisplayText(): string {
    if (this.count >= AppChat.BADGE_OVERFLOW_THRESHOLD) {
      return AppChat.BADGE_MAX_TEXT;
    }
    return this.count.toString();
  }

  build() {
    if (this.count > 0) {
      Text(this.getDisplayText())
        .fontSize(AppChat.BADGE_FONT)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .padding({ left: AppChat.BADGE_HORIZONTAL_PADDING, right: AppChat.BADGE_HORIZONTAL_PADDING })
        .height(AppChat.BADGE_HEIGHT)
        .constraintSize({ minWidth: AppChat.BADGE_MIN_WIDTH })
        .borderRadius(AppChat.BADGE_RADIUS)
        .backgroundColor(AppColors.DANGER)
    }
  }
}
