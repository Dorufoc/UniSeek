// LightboxOverlay.ets — 全屏图片预览浮层

import { AppColors, AppFontSize, AppRadius, AppSpacing } from '../../common/AppStyles';

@Component
export struct LightboxOverlay {
  @Prop imageUrl: string = '';
  onClose?: () => void;

  build() {
    Stack() {
      // 深色背景遮罩：点击关闭
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.OVERLAY_DARK)
        .onClick(() => {
          this.onClose?.();
        })
        .transition({ opacity: 0 })

      // 预览图片
      Image(this.imageUrl)
        .objectFit(ImageFit.Contain)
        .constraintSize({ maxWidth: '90%', maxHeight: '90%' })
        .borderRadius(AppRadius.MD)
        .hitTestBehavior(HitTestMode.Block)
        .transition({ opacity: 0, scale: { x: 0.9, y: 0.9 } })

      // 关闭按钮
      Button({ type: ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(AppFontSize.ICON_LG)
          .fontColor([AppColors.BG_CARD])
      }
      .width(AppSpacing.ICON_XL)
      .height(AppSpacing.ICON_XL)
      .backgroundColor(AppColors.OVERLAY)
      .position({ x: '86%', y: 32 })
      .accessibilityText('关闭图片预览')
      .onClick(() => {
        this.onClose?.();
      })
      .transition({ opacity: 0 })
    }
    .width('100%')
    .height('100%')
  }
}
