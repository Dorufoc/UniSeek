// ChoiceChips — 分段单选胶囊组
// 职责：按等宽/等间距展示一组单选胶囊，常用于薪资单位、工作类型、排序方式

import { AppColors, AppFilter, AppRadius } from '../../common/AppStyles';

export interface ChoiceOption {
  value: number
  label: string
}

@Component
export struct ChoiceChips {
  @Prop options: ChoiceOption[] = []
  @Prop selected: number = 0
  onSelect?: (value: number) => void

  build() {
    Row({ space: AppFilter.CHOICE_CHIP_SPACE }) {
      ForEach(this.options, (option: ChoiceOption) => {
        Button(option.label, { type: ButtonType.Capsule })
          .height(AppFilter.CHOICE_CHIP_HEIGHT)
          .fontSize(AppFilter.CHOICE_CHIP_FONT_SIZE)
          .fontColor(this.selected === option.value ? '#FFFFFF' : AppFilter.INACTIVE_TEXT_COLOR)
          .backgroundColor(this.selected === option.value ? AppColors.PRIMARY : AppFilter.INACTIVE_BACKGROUND_COLOR)
          .layoutWeight(1)
          .onClick((): void => {
            // 始终触发选择回调，便于调用方实现重复点击切换（如排序升降序）
            this.onSelect?.(option.value)
          })
          .stateStyles({
            pressed: { .opacity(0.85) }
          })
          .animation({ duration: 180 })
      }, (option: ChoiceOption): string => String(option.value))
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }
}
