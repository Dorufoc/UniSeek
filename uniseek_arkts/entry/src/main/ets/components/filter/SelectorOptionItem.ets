// SelectorOptionItem — 单选列表行
// 职责：在底部选择器 Sheet 中展示一条可单选的选项

import { AppColors, AppFilter, AppSpacing } from '../../common/AppStyles';

@Component
export struct SelectorOptionItem {
  @Prop label: string = '';
  @Prop selected: boolean = false;
  @Prop showDivider: boolean = false;
  onItemClick?: () => void;

  build() {
    Row() {
      Text(this.label)
        .fontSize(AppFilter.OPTION_FONT_SIZE)
        .fontColor(this.selected ? AppFilter.ACTIVE_TEXT_COLOR : AppColors.TEXT_PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)

      if (this.selected) {
        SymbolGlyph($r('sys.symbol.checkmark'))
          .fontSize(AppFilter.OPTION_CHECK_ICON_SIZE)
          .fontColor([AppFilter.ACTIVE_TEXT_COLOR])
      }
    }
    .width('100%')
    .height(AppFilter.OPTION_ROW_HEIGHT)
    .padding({ left: AppFilter.OPTION_HORIZONTAL_PADDING, right: AppFilter.OPTION_HORIZONTAL_PADDING })
    .backgroundColor(this.selected ? AppFilter.ACTIVE_BACKGROUND_COLOR : AppColors.BG_CARD)
    .onClick(() => {
      this.onItemClick?.()
    })
    .stateStyles({
      pressed: { .opacity(0.8) }
    })
  }
}
