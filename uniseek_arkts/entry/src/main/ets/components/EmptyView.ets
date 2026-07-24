// EmptyView — 统一空状态视图
// 职责：在列表/搜索无结果时使用一致的图标、文案与操作按钮

import { AppColors, AppFontSize, AppSpacing, AppRadius } from '../common/AppStyles';

@Component
export struct EmptyView {
  @Prop message: string = '暂无数据';
  @Prop icon?: Resource = undefined;
  @Prop actionText?: string = '';
  onAction?: () => void;

  build() {
    Column({ space: AppSpacing.SM }) {
      if (this.icon) {
        SymbolGlyph(this.icon)
          .fontSize(48)
          .fontColor([AppColors.TEXT_MUTED])
      }
      Text(this.message)
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)

      if (this.actionText && this.onAction) {
        Button(this.actionText, { type: ButtonType.Capsule })
          .height(AppSpacing.BUTTON_HEIGHT_SM)
          .fontSize(AppFontSize.SM)
          .fontColor('#FFFFFF')
          .backgroundColor(AppColors.PRIMARY)
          .padding({ left: AppSpacing.LG, right: AppSpacing.LG })
          .margin({ top: AppSpacing.SM })
          .onClick(() => { this.onAction?.() })
      }
    }
    .width('100%')
    .padding(AppSpacing.XL)
    .alignItems(HorizontalAlign.Center)
    .accessibilityGroup(true)
    .accessibilityText(this.message)
  }
}
