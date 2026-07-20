// FilterBar.ets - 筛选芯片栏组件
// 位于 Tabs 结构上方，含三颗筛选胶囊芯片：薪资、区域、类型
// 芯片选中时品牌色高亮 + 更新文字摘要，未选中时灰色背景

import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../../../common/AppStyles';
import { SALARY_UNIT_LABELS } from '../../../services/RecruiterTypes';

// ==================== 内部芯片子组件 ====================

@Component
struct FilterChip {
  icon?: Resource;
  label: string = '';
  isActive: boolean = false;
  hasClear: boolean = false;
  chipOnClick?: () => void;
  onClear?: () => void;

  build() {
    Row() {
      if (this.icon !== undefined) {
        SymbolGlyph(this.icon!)
          .fontSize(AppFontSize.XS)
          .fontColor([this.isActive ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY]);
      }
      Text(this.label)
        .fontSize(AppFontSize.XS)
        .fontColor(this.isActive ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
        .margin({ left: AppSpacing.XS });
      if (this.hasClear) {
        Blank();
        Text('✕')
          .fontSize(10)
          .fontColor(AppColors.TEXT_MUTED)
          .margin({ left: AppSpacing.XS })
          .onClick(() => {
            this.onClear?.();
          });
      }
    }
    .height(32)
    .backgroundColor(this.isActive ? AppColors.SELECTED_BG : AppColors.INPUT_BG)
    .borderRadius(AppRadius.FULL)
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
    .onClick(() => {
      this.chipOnClick?.();
    })
    .animation({
      duration: 200,
      curve: 'cubic-bezier(0.2, 0, 0, 1.0)'
    });
  }
}

// ==================== 导出筛选栏组件 ====================

@Component
export struct FilterBar {
  @Prop salaryMin: number = 0;
  @Prop salaryMax: number = 0;
  @Prop selectedSalaryUnit: number = -1;
  @Prop includeNegotiable: boolean = true;
  @Prop selectedRegion: string[] = [];
  @Prop selectedType: string[] = [];

  onShowSheet?: () => void;
  onClearSalary?: () => void;
  onClearRegion?: () => void;
  onClearType?: () => void;

  build() {
    Row({ space: AppSpacing.SM }) {
      FilterChip({
        icon: $r('sys.symbol.creditcard'),
        label: this.salaryLabel(),
        isActive: this.salaryMin > 0 || this.salaryMax > 0 || this.selectedSalaryUnit >= 0 || this.includeNegotiable,
        hasClear: this.salaryMin > 0 || this.salaryMax > 0 || this.selectedSalaryUnit >= 0,
        chipOnClick: () => {
          this.onShowSheet?.();
        },
        onClear: () => {
          this.onClearSalary?.();
        }
      });
      FilterChip({
        icon: $r('sys.symbol.map'),
        label: this.selectedRegion.length > 0 ? this.compactLabel(this.selectedRegion) : '区域',
        isActive: this.selectedRegion.length > 0,
        hasClear: this.selectedRegion.length > 0,
        chipOnClick: () => {
          this.onShowSheet?.();
        },
        onClear: () => {
          this.onClearRegion?.();
        }
      });
      FilterChip({
        icon: $r('sys.symbol.line_3_horizontal'),
        label: this.selectedType.length > 0 ? this.compactLabel(this.selectedType) : '类型',
        isActive: this.selectedType.length > 0,
        hasClear: this.selectedType.length > 0,
        chipOnClick: () => {
          this.onShowSheet?.();
        },
        onClear: () => {
          this.onClearType?.();
        }
      });
    }
    .width('100%')
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.XS })
    .justifyContent(FlexAlign.Start)
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#D9FFFFFF')
    .backgroundBlurStyle(BlurStyle.Thin);
  }

  // 生成薪资芯片标签文字
  private salaryLabel(): string {
    let parts: string[] = [];
    if (this.salaryMin > 0 && this.salaryMax > 0) {
      parts.push(this.salaryMin + '-' + this.salaryMax + '元');
    } else if (this.salaryMin > 0) {
      parts.push('≥' + this.salaryMin + '元');
    } else if (this.salaryMax > 0) {
      parts.push('≤' + this.salaryMax + '元');
    }
    if (this.selectedSalaryUnit >= 0) {
      parts.push(SALARY_UNIT_LABELS[this.selectedSalaryUnit]);
    }
    // 未设具体薪资但勾选了"包含面议"时显示"面议"
    if (parts.length === 0 && this.includeNegotiable) {
      return '面议';
    }
    return parts.join('/');
  }

  // 生成多选列表的紧凑摘要文字
  private compactLabel(list: string[]): string {
    if (list.length === 0) {
      return '';
    }
    if (list.length === 1) {
      let parts: string[] = list[0].split('-');
      return parts[parts.length - 1];
    }
    return list[0] + '等' + list.length + '项';
  }
}
