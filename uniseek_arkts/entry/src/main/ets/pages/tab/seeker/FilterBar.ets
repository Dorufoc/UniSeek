// FilterBar.ets - 筛选芯片栏组件
// 位于 Tabs 结构上方，含三颗筛选胶囊芯片：薪资、区域、类型
// 芯片选中时品牌色高亮 + 更新文字摘要，未选中时灰色背景

import { AppColors, AppFilter } from '../../../common/AppStyles';
import { SALARY_UNIT_LABELS } from '../../../services/RecruiterTypes';
import { FilterChipBar, FilterChipData } from '../../../components/filter/FilterChipBar';

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

  private buildChips(): FilterChipData[] {
    const salaryActive: boolean = this.salaryMin > 0 || this.salaryMax > 0 || this.selectedSalaryUnit >= 0 || this.includeNegotiable;
    const regionActive: boolean = this.selectedRegion.length > 0;
    const typeActive: boolean = this.selectedType.length > 0;
    return [
      {
        icon: $r('sys.symbol.creditcard'),
        label: this.salaryLabel(),
        active: salaryActive,
        hasClose: salaryActive && this.onClearSalary !== undefined
      },
      {
        icon: $r('sys.symbol.map'),
        label: this.selectedRegion.length > 0 ? this.compactLabel(this.selectedRegion) : '区域',
        active: regionActive,
        hasClose: regionActive && this.onClearRegion !== undefined
      },
      {
        icon: $r('sys.symbol.line_3_horizontal'),
        label: this.selectedType.length > 0 ? this.compactLabel(this.selectedType) : '类型',
        active: typeActive,
        hasClose: typeActive && this.onClearType !== undefined
      }
    ];
  }

  build() {
    FilterChipBar({
      chips: this.buildChips(),
      onChipClick: (index: number): void => {
        this.onShowSheet?.();
      },
      onClose: (index: number): void => {
        if (index === 0) {
          this.onClearSalary?.();
        } else if (index === 1) {
          this.onClearRegion?.();
        } else if (index === 2) {
          this.onClearType?.();
        }
      }
    })
      .width('100%')
      .padding({ left: AppFilter.CHIP_BAR_SPACE, right: AppFilter.CHIP_BAR_SPACE })
      .backgroundColor(AppColors.BG_PAGE)
  }
}
