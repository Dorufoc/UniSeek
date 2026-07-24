// FilterCheckOption — 筛选多选行
// 职责：在复杂筛选面板中展示标签 + 原生 Checkbox，支持点击整行切换

import { AppColors, AppFilter, AppRadius, AppSpacing } from '../../common/AppStyles';

@Component
export struct FilterCheckOption {
  @Prop label: string = '';
  @Prop checked: boolean = false;
  onChange?: (checked: boolean) => void;

  build() {
    Row({ space: AppSpacing.SM }) {
      Checkbox({ name: this.label })
        .select(this.checked)
        .selectedColor(AppColors.PRIMARY)
        .shape(CheckBoxShape.ROUNDED_SQUARE)
        .width(AppSpacing.ICON_SM)
        .height(AppSpacing.ICON_SM)

      Text(this.label)
        .fontSize(AppFilter.CHECK_OPTION_FONT_SIZE)
        .fontColor(AppColors.TEXT_PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')
    .height(AppFilter.CHECK_OPTION_HEIGHT)
    .padding({
      left: AppFilter.CHECK_OPTION_HORIZONTAL_PADDING,
      right: AppFilter.CHECK_OPTION_HORIZONTAL_PADDING
    })
    .backgroundColor(this.checked ? AppFilter.ACTIVE_BACKGROUND_COLOR : 'transparent')
    .borderRadius(AppRadius.MD)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onChange?.(!this.checked)
    })
    .stateStyles({
      pressed: { .opacity(0.8) }
    })
    .animation({ duration: 180 })
  }
}
