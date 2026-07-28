// FilterSheet — 求职者首页统一职位筛选下拉伸缩抽屉
// 职责：封装结算周期/薪资范围/面议/工作区域/职位类型/标签的临时状态，
//       抽屉关闭或重置时通过 onApply/onReset 回调将结果传回父组件。

import { DataService, Province, City, District, Field, Occupation } from '../../services/DataService';
import { TaskService } from '../../services/TaskService';
import { AppColors, AppFilter, AppFontSize, AppRadius, AppSpacing } from '../../common/AppStyles';
import { WindowBreakpoint } from '../../common/Responsive';

// 筛选结果数据对象
export interface FilterSelection {
  salaryMin: number
  salaryMax: number
  salaryUnit: number
  includeNegotiable: boolean
  region: string[]
  type: string[]
  tags: string[]
}

// 结算周期选项：时薪 / 日薪 / 月薪（对应后端 salaryUnit 1 / 0 / 2）
interface SalaryUnitOption {
  value: number
  label: string
}

const SALARY_UNIT_OPTIONS: SalaryUnitOption[] = [
  { value: 1, label: '时薪' },
  { value: 0, label: '日薪' },
  { value: 2, label: '月薪' }
]

// ==================== 主筛选抽屉组件 ====================
@Component
export struct FilterSheet {
  // 当前已应用的筛选条件（作为抽屉初始值）
  @Prop salaryMin: number = 0
  @Prop salaryMax: number = 0
  @Prop selectedSalaryUnit: number = -1
  @Prop includeNegotiable: boolean = true
  @Prop selectedRegion: string[] = []
  @Prop selectedType: string[] = []
  @Prop selectedTags: string[] = []
  @Prop breakpoint: WindowBreakpoint = WindowBreakpoint.COMPACT

  // 抽屉临时状态
  @State filterSalaryMin: number = 0
  @State filterSalaryMax: number = 0
  @State filterSalaryUnit: number = -1
  @State filterIncludeNeg: boolean = true
  @State filterRegion: string[] = []
  @State filterType: string[] = []
  @State filterTags: string[] = []
  @State tagInput: string = ''

  // 标签推荐
  @State allTags: string[] = []

  // 防止重置与关闭抽屉双重触发搜索
  @State hasApplied: boolean = false

  aboutToAppear(): void {
    this.copyFromProps()
    this.loadAllTags()
  }

  aboutToDisappear(): void {
    // 抽屉收回或关闭时立即生效：将当前临时条件回传父组件
    if (!this.hasApplied) {
      this.applyFilters()
    }
  }

  private copyFromProps(): void {
    this.filterSalaryMin = this.salaryMin
    this.filterSalaryMax = this.salaryMax
    this.filterSalaryUnit = this.selectedSalaryUnit
    this.filterIncludeNeg = this.includeNegotiable
    this.filterRegion = [...this.selectedRegion]
    this.filterType = [...this.selectedType]
    this.filterTags = [...this.selectedTags]
    this.tagInput = ''
    this.hasApplied = false
  }

  private async loadAllTags(): Promise<void> {
    const list = await TaskService.getAllTags()
    this.allTags = list
  }

  // ==================== 回调 ====================
  onApply?: (selection: FilterSelection) => void
  onReset?: () => void

  private applyFilters(): void {
    this.hasApplied = true
    this.onApply?.({
      salaryMin: this.filterSalaryMin,
      salaryMax: this.filterSalaryMax,
      salaryUnit: this.filterSalaryUnit,
      includeNegotiable: this.filterIncludeNeg,
      region: [...this.filterRegion],
      type: [...this.filterType],
      tags: [...this.filterTags]
    })
  }

  private resetFilters(): void {
    this.filterSalaryMin = 0
    this.filterSalaryMax = 0
    this.filterSalaryUnit = -1
    this.filterIncludeNeg = true
    this.filterRegion = []
    this.filterType = []
    this.filterTags = []
    this.tagInput = ''
    this.onReset?.()
    // 重置后立即生效
    this.applyFilters()
  }

  private confirmReset(): void {
    AlertDialog.show({
      message: '确定要清空所有筛选条件吗？',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '确定',
        action: (): void => {
          this.resetFilters()
        }
      }
    })
  }

  // ==================== 标签处理 ====================
  private addTag(): void {
    const value = this.tagInput.trim()
    if (value.length === 0) {
      return
    }
    if (this.filterTags.indexOf(value) >= 0) {
      this.tagInput = ''
      return
    }
    this.filterTags = [...this.filterTags, value]
    this.tagInput = ''
    this.hasApplied = false
  }

  private addSuggestedTag(tag: string): void {
    if (this.filterTags.indexOf(tag) >= 0) {
      return
    }
    this.filterTags = [...this.filterTags, tag]
    this.hasApplied = false
  }

  private removeTag(tag: string): void {
    this.filterTags = this.filterTags.filter((t: string) => t !== tag)
    this.hasApplied = false
  }

  private computeSuggestedTags(): string[] {
    const input = this.tagInput.trim()
    let list = this.allTags.filter((t: string) => this.filterTags.indexOf(t) < 0)
    if (input.length > 0) {
      list = list.filter((t: string) => t.indexOf(input) >= 0)
    }
    return list.slice(0, 8)
  }

  // ==================== 地区选择器逻辑（原生级联 TextPickerDialog） ====================
  private openRegionPicker(): void {
    this.getUIContext().showTextPickerDialog({
      range: this.buildRegionRange(),
      selected: [0, 0, 0],
      onAccept: (value: TextPickerResult): void => {
        const selectedValues = value.value as string[]
        if (selectedValues && selectedValues.length > 0) {
          // 规范化路径：去掉"全部"，保留父级路径
          const normalizedPath = this.normalizeSelectionPath(selectedValues)
          if (normalizedPath.length === 0) {
            return
          }
          const path = normalizedPath.join('-')
          if (this.filterRegion.indexOf(path) < 0) {
            this.filterRegion = [...this.filterRegion, path]
            this.applyFilters()
          }
        }
      }
    })
  }

  /**
   * 规范化选择路径：去掉"全部"，保留有效的父级路径。
   * 例如：["吉林省", "全部"] → ["吉林省"]
   *       ["吉林省", "长春市", "全部"] → ["吉林省", "长春市"]
   *       ["吉林省", "长春市", "朝阳区"] → ["吉林省", "长春市", "朝阳区"]
   */
  private normalizeSelectionPath(values: string[]): string[] {
    const result: string[] = []
    for (const v of values) {
      if (v === '全部') {
        break
      }
      result.push(v)
    }
    return result
  }

  private buildRegionRange(): TextCascadePickerRangeContent[] {
    return DataService.getProvinces().map((province: Province): TextCascadePickerRangeContent => {
      if (province.isMunicipality) {
        // 直辖市：省 -> 区县两级
        const city = province.cities[0]
        // 为直辖市添加"全部"选项，表示选择该直辖市所有区县
        const districts: TextCascadePickerRangeContent[] = [this.cascadeItem('全部')]
        if (city) {
          for (const d of city.districts) {
            districts.push(this.cascadeItem(d.name))
          }
        }
        return this.cascadeItem(province.name, districts)
      }
      // 普通省份：省 -> 市 -> 区县三级
      const cities: TextCascadePickerRangeContent[] = [this.cascadeItem('全部')]
      for (const city of province.cities) {
        // 为每个市添加"全部"选项，表示选择该市所有区县
        const districts: TextCascadePickerRangeContent[] = [this.cascadeItem('全部')]
        for (const d of city.districts) {
          districts.push(this.cascadeItem(d.name))
        }
        cities.push(this.cascadeItem(city.name, districts))
      }
      return this.cascadeItem(province.name, cities)
    })
  }

  private removeRegion(path: string): void {
    this.filterRegion = this.filterRegion.filter((r: string) => r !== path)
    this.applyFilters()
  }

  private buildRegionButtonLabel(): string {
    return this.formatSelectionLabel(this.filterRegion)
  }

  // ==================== 职位类型选择器逻辑（原生级联 TextPickerDialog） ====================
  private openCategoryPicker(): void {
    this.getUIContext().showTextPickerDialog({
      range: this.buildCategoryRange(),
      selected: [0, 0],
      onAccept: (value: TextPickerResult): void => {
        const selectedValues = value.value as string[]
        if (selectedValues && selectedValues.length > 0) {
          // 规范化路径：去掉"全部"，保留父级路径
          const normalizedPath = this.normalizeSelectionPath(selectedValues)
          if (normalizedPath.length === 0) {
            return
          }
          const path = normalizedPath.join('-')
          if (this.filterType.indexOf(path) < 0) {
            this.filterType = [...this.filterType, path]
            this.applyFilters()
          }
        }
      }
    })
  }

  private buildCategoryRange(): TextCascadePickerRangeContent[] {
    return DataService.getFields().map((field: Field): TextCascadePickerRangeContent => {
      // 为每个大类添加"全部"选项，表示选择该大类所有子类
      const children: TextCascadePickerRangeContent[] = [this.cascadeItem('全部')]
      if (field.occupations.length > 0) {
        for (const o of field.occupations) {
          children.push(this.cascadeItem(o.name))
        }
      }
      return this.cascadeItem(field.name, children)
    })
  }

  private removeCategory(path: string): void {
    this.filterType = this.filterType.filter((t: string) => t !== path)
    this.applyFilters()
  }

  private buildCategoryButtonLabel(): string {
    return this.formatSelectionLabel(this.filterType)
  }

  private formatSelectionLabel(items: string[]): string {
    if (items.length === 0) {
      return ''
    }
    // 取第一条路径的末级名称，避免按钮过长
    const first = items[0].split('-').pop() || items[0]
    if (items.length === 1) {
      return first
    }
    return `${first} +${items.length - 1}`
  }

  // 将字符串包装为符合 TextPickerDialog range 要求的级联项，避免 ArkTS 的匿名对象字面量类型检查报错
  private cascadeItem(text: string, children?: TextCascadePickerRangeContent[]): TextCascadePickerRangeContent {
    return { text, children }
  }

  // ==================== UI 构建器 ====================
  @Builder
  SectionHeader(title: string) {
    Text(title)
      .fontSize(AppFilter.SECTION_TITLE_FONT_SIZE)
      .fontWeight(AppFilter.SECTION_TITLE_FONT_WEIGHT)
      .fontColor(AppColors.TEXT_PRIMARY)
      .margin({ top: AppFilter.SECTION_TITLE_MARGIN, bottom: AppFilter.SECTION_TITLE_MARGIN })
  }

  @Builder
  SectionHint(text: string) {
    Text(text)
      .fontSize(AppFontSize.XS)
      .fontColor(AppColors.TEXT_MUTED)
      .margin({ top: AppSpacing.XS })
      .width('100%')
  }

  @Builder
  SelectedChips(list: string[], onRemove: (item: string) => void) {
    if (list.length > 0) {
      Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row, justifyContent: FlexAlign.Start }) {
        ForEach(list, (item: string) => {
          Row() {
            Text(item)
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.PRIMARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text('×')
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.TEXT_MUTED)
              .margin({ left: AppSpacing.XS })
              .onClick(() => {
                onRemove(item)
              })
          }
          .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
          .backgroundColor(AppColors.SELECTED_BG)
          .borderRadius(AppRadius.MD)
          .margin({ right: AppSpacing.SM, bottom: AppSpacing.SM })
        }, (item: string): string => item)
      }
      .width('100%')
      .margin({ top: AppSpacing.SM })
    }
  }

  @Builder
  SelectedTagChips() {
    if (this.filterTags.length > 0) {
      Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row, justifyContent: FlexAlign.Start }) {
        ForEach(this.filterTags, (item: string) => {
          Row() {
            Text(item)
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.PRIMARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text('×')
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.TEXT_MUTED)
              .margin({ left: AppSpacing.XS })
              .onClick(() => {
                this.removeTag(item)
              })
          }
          .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
          .backgroundColor(AppColors.SELECTED_BG)
          .borderRadius(AppRadius.MD)
          .margin({ right: AppSpacing.SM, bottom: AppSpacing.SM })
        }, (item: string): string => item)
      }
      .width('100%')
      .margin({ top: AppSpacing.SM })
    }
  }

  @Builder
  SalaryUnitChips() {
    Row({ space: AppFilter.CHOICE_CHIP_SPACE }) {
      ForEach(SALARY_UNIT_OPTIONS, (option: SalaryUnitOption) => {
        Button(option.label, { type: ButtonType.Capsule })
          .height(AppFilter.CHOICE_CHIP_HEIGHT)
          .fontSize(AppFilter.CHOICE_CHIP_FONT_SIZE)
          .fontColor(this.filterSalaryUnit === option.value ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
          .backgroundColor(this.filterSalaryUnit === option.value ? AppColors.PRIMARY : AppColors.INPUT_BG)
          .layoutWeight(1)
          .onClick((): void => {
            // 单选可取消：再次点击同一项则清空
            this.filterSalaryUnit = this.filterSalaryUnit === option.value ? -1 : option.value
            this.applyFilters()
          })
          .stateStyles({
            pressed: { .opacity(0.85) }
          })
          .animation({ duration: 180 })
      }, (option: SalaryUnitOption): string => String(option.value))
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  SelectorButton(label: string, placeholder: string, onClick: () => void) {
    Button(label || placeholder, { type: ButtonType.Capsule })
      .height(AppFilter.CHOICE_CHIP_HEIGHT)
      .fontSize(AppFilter.CHOICE_CHIP_FONT_SIZE)
      .fontColor(label ? AppColors.PRIMARY : AppColors.TEXT_MUTED)
      .backgroundColor(label ? AppColors.SELECTED_BG : AppColors.INPUT_BG)
      .layoutWeight(1)
      .onClick(onClick)
      .stateStyles({
        pressed: { .opacity(0.85) }
      })
      .animation({ duration: 180 })
  }

  @Builder
  RegionSelectorRow() {
    Row({ space: AppFilter.CHOICE_CHIP_SPACE }) {
      this.SelectorButton(
        this.buildRegionButtonLabel(),
        '选择地区',
        () => { this.openRegionPicker() }
      )
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  CategorySelectorRow() {
    Row({ space: AppFilter.CHOICE_CHIP_SPACE }) {
      this.SelectorButton(
        this.buildCategoryButtonLabel(),
        '选择职位类型',
        () => { this.openCategoryPicker() }
      )
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  TagInputRow() {
    Row({ space: AppSpacing.SM }) {
      TextInput({ placeholder: '输入标签后添加', text: this.tagInput })
        .height(AppSpacing.BUTTON_HEIGHT_MD)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.MD)
        .fontSize(AppFontSize.SM)
        .placeholderColor(AppColors.TEXT_MUTED)
        .layoutWeight(1)
        .onChange((value: string) => {
          this.tagInput = value
        })
        .onSubmit(() => {
          this.addTag()
        })

      Button('+', { type: ButtonType.Capsule })
        .width(AppSpacing.BUTTON_HEIGHT_MD)
        .height(AppSpacing.BUTTON_HEIGHT_MD)
        .backgroundColor(this.tagInput.trim().length > 0 ? AppColors.PRIMARY : AppColors.INPUT_BG)
        .fontColor(this.tagInput.trim().length > 0 ? '#FFFFFF' : AppColors.TEXT_MUTED)
        .fontSize(AppFontSize.MD)
        .enabled(this.tagInput.trim().length > 0)
        .onClick(() => {
          this.addTag()
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  TagSuggestions() {
    if (this.computeSuggestedTags().length > 0) {
      Column() {
        Text('推荐标签')
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.TEXT_MUTED)
          .width('100%')
          .margin({ bottom: AppSpacing.XS })

        Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row, justifyContent: FlexAlign.Start }) {
          ForEach(this.computeSuggestedTags(), (tag: string) => {
            Text(tag)
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.TEXT_SECONDARY)
              .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
              .backgroundColor(AppColors.INPUT_BG)
              .borderRadius(AppRadius.MD)
              .margin({ right: AppSpacing.SM, bottom: AppSpacing.SM })
              .onClick(() => {
                this.addSuggestedTag(tag)
              })
          }, (tag: string): string => tag)
        }
        .width('100%')
      }
      .width('100%')
      .margin({ top: AppSpacing.SM })
    }
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          // ===== 结算周期 =====
          this.SectionHeader('结算周期')
          this.SalaryUnitChips()

          // ===== 薪资范围 =====
          this.SectionHeader('薪资范围')
          Column() {
            Row() {
              TextInput({ placeholder: '最低薪资', text: this.filterSalaryMin > 0 ? String(this.filterSalaryMin) : '' })
                .onChange((v: string) => {
                  this.filterSalaryMin = parseInt(v) || 0
                  this.hasApplied = false
                })
                .height(AppSpacing.BUTTON_HEIGHT_MD)
                .backgroundColor(AppColors.INPUT_BG)
                .borderRadius(AppRadius.MD)
                .layoutWeight(1)
                .type(InputType.Number)
              Text(' — ')
                .fontColor(AppColors.TEXT_MUTED)
                .margin({ left: AppSpacing.SM, right: AppSpacing.SM })
              TextInput({ placeholder: '最高薪资', text: this.filterSalaryMax > 0 ? String(this.filterSalaryMax) : '' })
                .onChange((v: string) => {
                  this.filterSalaryMax = parseInt(v) || 0
                  this.hasApplied = false
                })
                .height(AppSpacing.BUTTON_HEIGHT_MD)
                .backgroundColor(AppColors.INPUT_BG)
                .borderRadius(AppRadius.MD)
                .layoutWeight(1)
                .type(InputType.Number)
            }
            .width('100%')

            if (this.filterSalaryUnit < 0) {
              this.SectionHint('* 未选择结算周期时，日结/时薪岗位将按 22天/8小时 统一折算为预估月薪进行匹配')
            }

            Row() {
              Checkbox({ name: 'includeNegotiable' })
                .select(this.filterIncludeNeg)
                .selectedColor(AppColors.PRIMARY)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
                .onChange((value: boolean) => {
                  this.filterIncludeNeg = value
                  this.applyFilters()
                })
              Text('包含面议')
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.TEXT_SECONDARY)
                .margin({ left: AppSpacing.SM })
              Blank()
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .margin({ top: AppSpacing.SM })
          }
          .padding({ left: AppSpacing.SM })

          Divider()
            .height(AppFilter.DIVIDER_HEIGHT)
            .color(AppFilter.DIVIDER_COLOR)
            .margin({ top: AppSpacing.SM_PLUS, bottom: AppSpacing.SM_PLUS })

          // ===== 工作区域 =====
          this.SectionHeader('工作区域')
          Column() {
            this.RegionSelectorRow()
            this.SelectedChips(this.filterRegion, (item: string) => {
              this.removeRegion(item)
            })
          }

          Divider()
            .height(AppFilter.DIVIDER_HEIGHT)
            .color(AppFilter.DIVIDER_COLOR)
            .margin({ top: AppSpacing.SM_PLUS, bottom: AppSpacing.SM_PLUS })

          // ===== 职位类型 =====
          this.SectionHeader('职位类型')
          Column() {
            this.CategorySelectorRow()
            this.SelectedChips(this.filterType, (item: string) => {
              this.removeCategory(item)
            })
          }

          Divider()
            .height(AppFilter.DIVIDER_HEIGHT)
            .color(AppFilter.DIVIDER_COLOR)
            .margin({ top: AppSpacing.SM_PLUS, bottom: AppSpacing.SM_PLUS })

          // ===== 职位标签 =====
          this.SectionHeader('职位标签')
          Column() {
            this.TagInputRow()
            this.TagSuggestions()
            this.SelectedTagChips()
          }
        }
        .width('100%')
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM_PLUS, bottom: AppSpacing.MD })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)

      // ===== 底部重置 =====
      Button('重置筛选')
        .width('100%')
        .height(AppSpacing.INPUT_HEIGHT)
        .backgroundColor(AppColors.DANGER)
        .fontColor('#FFFFFF')
        .fontSize(AppFontSize.MD)
        .fontWeight(FontWeight.Medium)
        .borderRadius(AppRadius.LG)
        .margin({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.MD })
        .onClick(() => {
          this.confirmReset()
        })
    }
    .width('100%')
    .height('100%')
    .constraintSize({ maxWidth: this.breakpoint === WindowBreakpoint.COMPACT ? '100%' : 560 })
    .backgroundColor(AppColors.BG_PAGE)
  }
}
