// ErrorView — 统一错误状态视图
// 职责：在数据加载失败时提供图标、文案与重试按钮

import { AppColors, AppFontSize, AppSpacing } from '../common/AppStyles';

@Component
export struct ErrorView {
  @Prop message: string = '加载失败，请稍后重试';
  @Prop retryText: string = '重新加载';
  onRetry?: () => void;

  build() {
    Column({ space: AppSpacing.SM }) {
      SymbolGlyph($r('sys.symbol.xmark'))
        .fontSize(48)
        .fontColor([AppColors.DANGER])
      Text(this.message)
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)

      if (this.onRetry) {
        Button(this.retryText, { type: ButtonType.Capsule })
          .height(AppSpacing.BUTTON_HEIGHT_SM)
          .fontSize(AppFontSize.SM)
          .fontColor('#FFFFFF')
          .backgroundColor(AppColors.PRIMARY)
          .padding({ left: AppSpacing.LG, right: AppSpacing.LG })
          .margin({ top: AppSpacing.SM })
          .onClick(() => { this.onRetry?.() })
      }
    }
    .width('100%')
    .padding(AppSpacing.XL)
    .alignItems(HorizontalAlign.Center)
    .accessibilityGroup(true)
    .accessibilityText(this.message + '，' + this.retryText)
  }
}
