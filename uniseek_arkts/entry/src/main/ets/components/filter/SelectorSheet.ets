// SelectorSheet — 通用单选底部面板
// 职责：配合页面 bindSheet 使用，呈现标题 + 单选列表 + 空状态

import { AppColors, AppFilter } from '../../common/AppStyles';
import { EmptyView } from '../EmptyView';
import { FilterSheetHeader } from './FilterSheetHeader';
import { SelectorOptionItem } from './SelectorOptionItem';

export interface SelectorOption {
  id: string | number
  label: string
}

@Component
export struct SelectorSheet {
  @Prop title: string = '';
  @Prop options: SelectorOption[] = [];
  @Prop selectedId?: string | number;
  @Prop emptyMessage: string = '暂无选项';
  @Prop emptyActionText?: string;
  onSelect?: (option: SelectorOption) => void
  onClose?: () => void
  onEmptyAction?: () => void

  build() {
    Column() {
      FilterSheetHeader({
        title: this.title,
        showReset: false
      })

      if (this.options.length === 0) {
        EmptyView({
          message: this.emptyMessage,
          actionText: this.emptyActionText,
          onAction: (): void => {
            this.onEmptyAction?.()
          }
        })
          .layoutWeight(1)
      } else {
        List() {
          ForEach(this.options, (option: SelectorOption) => {
            ListItem() {
              SelectorOptionItem({
                label: option.label,
                selected: option.id === this.selectedId,
                onItemClick: (): void => {
                  this.onSelect?.(option)
                  this.onClose?.()
                }
              })
            }
          }, (option: SelectorOption): string => String(option.id))
        }
        .layoutWeight(1)
        .width('100%')
        .divider({
          strokeWidth: AppFilter.DIVIDER_HEIGHT,
          color: AppFilter.DIVIDER_COLOR,
          startMargin: AppFilter.DIVIDER_INSETS,
          endMargin: AppFilter.DIVIDER_INSETS
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_CARD)
  }
}
