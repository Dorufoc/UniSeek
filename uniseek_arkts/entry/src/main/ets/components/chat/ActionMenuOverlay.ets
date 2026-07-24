// ActionMenuOverlay.ets — 聊天更多操作菜单（发送图片 / 发送简历）

import { AppColors, AppFontSize, AppRadius, AppSpacing, AppShadow } from '../../common/AppStyles';

@Component
export struct ActionMenuOverlay {
  onSendImage?: () => void;
  onSendResume?: () => void;
  onClose?: () => void;

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      // 半透明遮罩：点击关闭菜单
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.OVERLAY)
        .onClick(() => {
          this.onClose?.();
        })
        .transition({ opacity: 0 })

      // 操作菜单面板
      Column({ space: AppSpacing.XS }) {
        // 发送图片
        Row() {
          SymbolGlyph($r('sys.symbol.picture'))
            .fontSize(AppFontSize.XL)
            .fontColor([AppColors.PRIMARY])
            .margin({ right: AppSpacing.SM_PLUS })
          Text('发送图片')
            .fontSize(AppFontSize.SUBHEAD)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .width('100%')
        .height(AppSpacing.INPUT_HEIGHT)
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
        .alignItems(VerticalAlign.Center)
        .borderRadius(AppRadius.PANEL)
        .accessibilityText('选择图片')
        .onClick(() => {
          this.onSendImage?.();
        })
        .stateStyles({
          pressed: {
            .backgroundColor(AppColors.INPUT_BG)
          }
        })

        // 发送简历
        Row() {
          SymbolGlyph($r('sys.symbol.doc_text'))
            .fontSize(AppFontSize.XL)
            .fontColor([AppColors.PRIMARY])
            .margin({ right: AppSpacing.SM_PLUS })
          Text('发送简历')
            .fontSize(AppFontSize.SUBHEAD)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .width('100%')
        .height(AppSpacing.INPUT_HEIGHT)
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
        .alignItems(VerticalAlign.Center)
        .borderRadius(AppRadius.PANEL)
        .accessibilityText('选择文件')
        .onClick(() => {
          this.onSendResume?.();
        })
        .stateStyles({
          pressed: {
            .backgroundColor(AppColors.INPUT_BG)
          }
        })
      }
      .width(AppSpacing.MENU_PANEL_WIDTH)
      .padding(AppSpacing.SM)
      .backgroundColor(AppColors.BG_CARD)
      .borderRadius(AppRadius.LG)
      .shadow(AppShadow.MENU)
      // 与原 Vue 端 menuSlideUp 对齐：从下方 8px + scale 0.96 淡入
      .transition({ opacity: 0, translate: { y: 8 }, scale: { x: 0.96, y: 0.96 } })
      .margin({ left: 28, bottom: 100 })
    }
    .width('100%')
    .height('100%')
  }
}
