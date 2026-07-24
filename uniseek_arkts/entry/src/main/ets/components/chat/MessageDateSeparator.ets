// 消息日期分隔线：按天聚合显示"今天""昨天"或 MM-DD

import { AppColors, AppFontSize, AppSpacing } from '../../common/AppStyles';

@Component
export struct MessageDateSeparator {
  @Prop label: string = ''

  build() {
    Row() {
      Row()
        .height(AppSpacing.DIVIDER_THICKNESS)
        .layoutWeight(1)
        .backgroundColor(AppColors.BORDER)

      Text(this.label)
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_MUTED)
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD })

      Row()
        .height(AppSpacing.DIVIDER_THICKNESS)
        .layoutWeight(1)
        .backgroundColor(AppColors.BORDER)
    }
    .width('100%')
    .padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })
    .alignItems(VerticalAlign.Center)
  }
}
