// FilterBar.ets - 求职者首页顶部标题与操作栏
// 职责：将标题、筛选入口、搜索入口整合到同一行，不单独占用一行药丸按钮或搜索框。

import { AppColors, AppFontSize, AppRadius, AppSpacing } from '../../../common/AppStyles';

@Component
export struct FilterBar {
  @Prop title: string = '发现职位'
  @Prop filterActive: boolean = false
  onFilterClick?: () => void
  onSearch?: () => void

  build() {
    Row() {
      Text(this.title)
        .fontSize(AppFontSize.XXL)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)

      Blank()

      // 筛选入口按钮（位于搜索按钮左侧）
      Button({ type: ButtonType.Capsule }) {
        SymbolGlyph($r('sys.symbol.line_3_horizontal'))
          .fontSize(AppFontSize.ICON_MD)
          .fontColor([AppColors.TEXT_PRIMARY])
      }
      .width(AppSpacing.BUTTON_HEIGHT)
      .height(AppSpacing.BUTTON_HEIGHT)
      .backgroundColor(AppColors.INPUT_BG)
      .margin({ right: AppSpacing.SM })
      .onClick(() => {
        this.onFilterClick?.()
      })

      // 搜索入口按钮（点击进入独立搜索页）
      Button({ type: ButtonType.Capsule }) {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(AppFontSize.ICON_MD)
          .fontColor([AppColors.TEXT_PRIMARY])
      }
      .width(AppSpacing.BUTTON_HEIGHT)
      .height(AppSpacing.BUTTON_HEIGHT)
      .backgroundColor(AppColors.INPUT_BG)
      .onClick(() => {
        this.onSearch?.()
      })
    }
    .width('100%')
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.SM })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(AppColors.BG_PAGE)
  }
}
