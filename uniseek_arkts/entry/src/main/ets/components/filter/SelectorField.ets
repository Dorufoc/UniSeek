// SelectorField — 表单选择行
// 职责：在表单中展示一个看起来像输入框的选择器触发区域，带右侧箭头

import { AppColors, AppFilter, AppFontSize, AppRadius, AppSpacing } from '../../common/AppStyles';

@Component
export struct SelectorField {
  @Prop label: string = '';
  @Prop value: string = '';
  @Prop placeholder: string = '请选择';
  onFieldClick?: () => void;

  build() {
    Column() {
      Text(this.label)
        .fontSize(AppFilter.SELECTOR_FIELD_LABEL_FONT_SIZE)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')

      Button({ type: ButtonType.Normal }) {
        Row() {
          Text(this.value || this.placeholder)
            .fontSize(AppFilter.SELECTOR_FIELD_FONT_SIZE)
            .fontColor(this.value ? AppColors.TEXT_PRIMARY : AppColors.TEXT_MUTED)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(AppFilter.SELECTOR_FIELD_CHEVRON_SIZE)
            .fontColor([AppColors.TEXT_MUTED])
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(AppFilter.SELECTOR_FIELD_HEIGHT)
      .backgroundColor(AppColors.INPUT_BG)
      .borderRadius(AppRadius.SM)
      .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
      .margin({ top: AppSpacing.XS })
      .onClick(() => {
        this.onFieldClick?.()
      })
      .stateStyles({
        pressed: { .backgroundColor(AppFilter.ACTIVE_BACKGROUND_COLOR) }
      })
    }
    .width('100%')
  }
}
