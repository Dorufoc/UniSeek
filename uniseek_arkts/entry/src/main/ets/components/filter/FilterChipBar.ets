// FilterChipBar — 横向可滚动筛选芯片栏
// 职责：接收一组芯片数据，统一渲染为水平滚动条

import { AppFilter } from '../../common/AppStyles';
import { FilterChip } from './FilterChip';

export interface FilterChipData {
  label: string
  active?: boolean
  icon?: Resource
  hasClose?: boolean
}

@Component
export struct FilterChipBar {
  @Prop chips: FilterChipData[] = []
  onChipClick?: (index: number) => void
  onClose?: (index: number) => void

  build() {
    Scroll() {
      Row({ space: AppFilter.CHIP_BAR_SPACE }) {
        ForEach(this.chips, (chip: FilterChipData, index: number) => {
          FilterChip({
            label: chip.label,
            isActive: chip.active === true,
            icon: chip.icon,
            onChipClick: (): void => {
              this.onChipClick?.(index)
            },
            onClose: chip.hasClose === true ? (): void => {
              this.onClose?.(index)
            } : undefined
          })
        }, (chip: FilterChipData, index: number): string => chip.label + '_' + index)
      }
      .padding({
        left: AppFilter.CHIP_BAR_SPACE,
        right: AppFilter.CHIP_BAR_SPACE,
        top: AppFilter.CHIP_BAR_PADDING_VERTICAL,
        bottom: AppFilter.CHIP_BAR_PADDING_VERTICAL
      })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
  }
}
