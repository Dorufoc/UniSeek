// FilterSheetHeader — 筛选 Sheet 统一头部
// 职责：展示标题与可选的重置按钮

import { AppColors, AppFilter, AppSpacing } from '../../common/AppStyles';

@Component
export struct FilterSheetHeader {
  @Prop title: string = '';
  @Prop showReset: boolean = true;
  onReset?: () => void;

  build() {
    Row() {
      Text(this.title)
        .fontSize(AppFilter.SHEET_TITLE_FONT_SIZE)
        .fontWeight(AppFilter.SHEET_TITLE_FONT_WEIGHT)
        .fontColor(AppColors.TEXT_PRIMARY)

      Blank()

      if (this.showReset) {
        Button('重置', { type: ButtonType.Capsule })
          .height(AppFilter.SHEET_HEADER_HEIGHT)
          .fontSize(AppFilter.SHEET_RESET_FONT_SIZE)
          .fontColor(AppColors.TEXT_MUTED)
          .backgroundColor(AppFilter.INACTIVE_BACKGROUND_COLOR)
          .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
          .onClick(() => {
            this.onReset?.()
          })
      }
    }
    .width('100%')
    .padding({
      left: AppFilter.SHEET_HEADER_PADDING,
      right: AppFilter.SHEET_HEADER_PADDING,
      top: AppFilter.SHEET_HEADER_PADDING,
      bottom: AppSpacing.SM
    })
    .alignItems(VerticalAlign.Center)
  }
}
