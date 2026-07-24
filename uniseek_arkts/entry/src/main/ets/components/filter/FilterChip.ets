// FilterChip — 统一筛选胶囊芯片
// 职责：在筛选栏/表单中展示单条可点击/可关闭的药丸标签

import { AppColors, AppFilter, AppRadius, AppSpacing } from '../../common/AppStyles';

@Component
export struct FilterChip {
  @Prop label: string = '';
  @Prop isActive: boolean = false;
  @Prop icon?: Resource;
  onChipClick?: () => void;
  onClose?: () => void;

  @Builder
  ChipContent() {
    Row({ space: AppFilter.CHIP_ICON_TEXT_GAP }) {
      if (this.icon !== undefined) {
        SymbolGlyph(this.icon)
          .fontSize(AppFilter.CHIP_ICON_SIZE)
          .fontColor([this.isActive ? AppFilter.ACTIVE_TEXT_COLOR : AppFilter.INACTIVE_TEXT_COLOR])
      }

      Text(this.label)
        .fontSize(AppFilter.CHIP_FONT_SIZE)
        .fontColor(this.isActive ? AppFilter.ACTIVE_TEXT_COLOR : AppFilter.INACTIVE_TEXT_COLOR)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(VerticalAlign.Center)
  }

  build() {
    if (this.onClose !== undefined) {
      // 可关闭芯片：主区域与关闭图标为同级可点击区，避免事件嵌套冲突
      Row({ space: AppSpacing.XS }) {
        Row() {
          this.ChipContent()
        }
        .height('100%')
        .padding({ left: AppFilter.CHIP_PADDING_HORIZONTAL, right: AppSpacing.XS })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.onChipClick?.()
        })

        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(AppFilter.CHIP_CLOSE_ICON_SIZE)
          .fontColor([this.isActive ? AppFilter.ACTIVE_TEXT_COLOR : AppFilter.INACTIVE_TEXT_COLOR])
          .margin({ right: AppFilter.CHIP_PADDING_HORIZONTAL })
          .onClick(() => {
            this.onClose?.()
          })
      }
      .height(AppFilter.CHIP_HEIGHT)
      .backgroundColor(this.isActive ? AppFilter.ACTIVE_BACKGROUND_COLOR : AppFilter.INACTIVE_BACKGROUND_COLOR)
      .borderRadius(AppRadius.FULL)
      .alignItems(VerticalAlign.Center)
      .stateStyles({
        pressed: { .opacity(0.8) }
      })
      .animation({ duration: 180 })
    } else {
      Button({ type: ButtonType.Capsule }) {
        this.ChipContent()
      }
      .height(AppFilter.CHIP_HEIGHT)
      .backgroundColor(this.isActive ? AppFilter.ACTIVE_BACKGROUND_COLOR : AppFilter.INACTIVE_BACKGROUND_COLOR)
      .borderRadius(AppRadius.FULL)
      .padding({ left: AppFilter.CHIP_PADDING_HORIZONTAL, right: AppFilter.CHIP_PADDING_HORIZONTAL })
      .onClick(() => {
        this.onChipClick?.()
      })
      .stateStyles({
        pressed: { .opacity(0.8) }
      })
      .animation({ duration: 180 })
    }
  }
}
