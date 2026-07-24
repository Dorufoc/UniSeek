// FilterSheet — 统一职位筛选半模态面板
// 职责：封装薪资/地区/职位类型筛选 UI 与临时状态，通过 onApply 回调将筛选结果传回父组件

import { DataService, Province, City, District, Field, Occupation } from '../../services/DataService';
import { AppColors, AppFilter, AppFontSize, AppRadius, AppSpacing } from '../../common/AppStyles';
import { WindowBreakpoint } from '../../common/Responsive';
import { FilterSheetHeader } from './FilterSheetHeader';
import { ChoiceChips, ChoiceOption } from './ChoiceChips';
import { FilterCheckOption } from './FilterCheckOption';

// 筛选结果数据对象
export interface FilterSelection {
  salaryMin: number
  salaryMax: number
  salaryUnit: number
  includeNegotiable: boolean
  region: string[]
  type: string[]
}

const SALARY_UNIT_OPTIONS: ChoiceOption[] = [
  { value: 0, label: '日结' },
  { value: 1, label: '时薪' },
  { value: 2, label: '月结' }
]

@Component
export struct FilterSheet {
  // 当前已应用的筛选条件（作为面板初始值）
  @Prop salaryMin: number = 0
  @Prop salaryMax: number = 0
  @Prop selectedSalaryUnit: number = -1
  @Prop includeNegotiable: boolean = true
  @Prop selectedRegion: string[] = []
  @Prop selectedType: string[] = []
  @Prop breakpoint: WindowBreakpoint = WindowBreakpoint.COMPACT

  // 面板临时状态
  @State filterSalaryMin: number = 0
  @State filterSalaryMax: number = 0
  @State filterSalaryUnit: number = -1
  @State filterIncludeNeg: boolean = true
  @State filterRegion: string[] = []
  @State filterType: string[] = []

  // 地区选择器内部状态
  @State fsSelectedProvinces: string[] = []
  @State fsSelectedCities: string[] = []
  @State fsSelectedDistricts: string[] = []
  @State fsActiveProvince: string = ''
  @State fsActiveCity: string = ''

  // 类型选择器内部状态
  @State fsSelectedFields: string[] = []
  @State fsSelectedOccupations: string[] = []
  @State fsActiveField: string = ''

  // 数据源
  private provinces: Province[] = DataService.getProvinces()
  private fields: Field[] = DataService.getFields()

  aboutToAppear(): void {
    this.copyFromProps()
  }

  // 从父组件同步筛选条件，并清空面板中的展开/勾选 intermediate 状态
  private copyFromProps(): void {
    this.filterSalaryMin = this.salaryMin
    this.filterSalaryMax = this.salaryMax
    this.filterSalaryUnit = this.selectedSalaryUnit
    this.filterIncludeNeg = this.includeNegotiable
    this.filterRegion = [...this.selectedRegion]
    this.filterType = [...this.selectedType]

    this.fsSelectedProvinces = []
    this.fsSelectedCities = []
    this.fsSelectedDistricts = []
    this.fsActiveProvince = ''
    this.fsActiveCity = ''
    this.fsSelectedFields = []
    this.fsSelectedOccupations = []
    this.fsActiveField = ''
  }

  private fsIsSelected(list: string[], name: string): boolean {
    return list.indexOf(name) >= 0
  }

  // ==================== 地区选择器逻辑 ====================

  private fsGenerateRegionResults(): string[] {
    const results: string[] = []
    for (const pName of this.fsSelectedProvinces) {
      const province = DataService.getProvinceByName(pName)
      if (!province) continue
      if (province.isMunicipality) {
        const city = province.cities[0]
        const selDists = this.fsSelectedDistricts.filter(
          (d: string) => city.districts.some((dd: District) => dd.name === d)
        )
        if (selDists.length > 0) {
          for (const d of selDists) results.push(pName + '-' + d)
        } else {
          results.push(pName)
        }
      } else {
        const selCities = this.fsSelectedCities.filter(
          (c: string) => province.cities.some((pc: City) => pc.name === c)
        )
        if (selCities.length > 0) {
          for (const c of selCities) {
            const city = province.cities.find((pc: City) => pc.name === c)
            if (city) {
              const selDists = this.fsSelectedDistricts.filter(
                (d: string) => city.districts.some((dd: District) => dd.name === d)
              )
              if (selDists.length > 0) {
                for (const d of selDists) results.push(c + '-' + d)
              } else {
                results.push(c)
              }
            }
          }
        } else {
          results.push(pName)
        }
      }
    }
    return results
  }

  private fsToggleProvince(name: string): void {
    if (this.fsIsSelected(this.fsSelectedProvinces, name)) {
      this.fsSelectedProvinces = this.fsSelectedProvinces.filter(n => n !== name)
      const province = DataService.getProvinceByName(name)
      if (province) {
        const cityNames = province.cities.map((c: City) => c.name)
        this.fsSelectedCities = this.fsSelectedCities.filter(c => cityNames.indexOf(c) < 0)
        const districtNames: string[] = []
        for (const city of province.cities) {
          for (const district of city.districts) {
            districtNames.push(district.name)
          }
        }
        this.fsSelectedDistricts = this.fsSelectedDistricts.filter(d => districtNames.indexOf(d) < 0)
      }
      if (this.fsActiveProvince === name) {
        this.fsActiveProvince = ''
      }
      this.fsActiveCity = ''
    } else {
      this.fsSelectedProvinces = [...this.fsSelectedProvinces, name]
      this.fsActiveProvince = name
      this.fsActiveCity = ''
    }
    this.filterRegion = this.fsGenerateRegionResults()
  }

  private fsToggleCity(name: string): void {
    if (this.fsIsSelected(this.fsSelectedCities, name)) {
      this.fsSelectedCities = this.fsSelectedCities.filter(n => n !== name)
    } else {
      this.fsSelectedCities = [...this.fsSelectedCities, name]
    }
    this.fsActiveCity = name
    this.filterRegion = this.fsGenerateRegionResults()
  }

  private fsToggleDistrict(name: string): void {
    if (this.fsIsSelected(this.fsSelectedDistricts, name)) {
      this.fsSelectedDistricts = this.fsSelectedDistricts.filter(n => n !== name)
    } else {
      this.fsSelectedDistricts = [...this.fsSelectedDistricts, name]
    }
    this.filterRegion = this.fsGenerateRegionResults()
  }

  private fsToggleAllCities(): void {
    const province = DataService.getProvinceByName(this.fsActiveProvince)
    if (!province || province.isMunicipality) return
    const allNames = province.cities.map((c: City) => c.name)
    const allSelected = allNames.every(n => this.fsIsSelected(this.fsSelectedCities, n))
    if (allSelected) {
      this.fsSelectedCities = this.fsSelectedCities.filter(n => allNames.indexOf(n) < 0)
    } else {
      const result = [...this.fsSelectedCities]
      for (const n of allNames) {
        if (result.indexOf(n) < 0) result.push(n)
      }
      this.fsSelectedCities = result
    }
    this.filterRegion = this.fsGenerateRegionResults()
  }

  private fsToggleAllDistricts(): void {
    const province = DataService.getProvinceByName(this.fsActiveProvince)
    if (!province) return
    const city = province.cities.find((c: City) => c.name === this.fsActiveCity)
    if (!city) return
    const allNames = city.districts.map((d: District) => d.name)
    const allSelected = allNames.every(n => this.fsIsSelected(this.fsSelectedDistricts, n))
    if (allSelected) {
      this.fsSelectedDistricts = this.fsSelectedDistricts.filter(n => allNames.indexOf(n) < 0)
    } else {
      const result = [...this.fsSelectedDistricts]
      for (const n of allNames) {
        if (result.indexOf(n) < 0) result.push(n)
      }
      this.fsSelectedDistricts = result
    }
    this.filterRegion = this.fsGenerateRegionResults()
  }

  private fsCityOptions(): City[] {
    if (!this.fsActiveProvince) return []
    const province = DataService.getProvinceByName(this.fsActiveProvince)
    if (!province || province.isMunicipality) return []
    return province.cities
  }

  private fsDistrictOptions(): District[] {
    if (!this.fsActiveCity) return []
    const province = DataService.getProvinceByName(this.fsActiveProvince)
    if (!province) return []
    const city = province.cities.find((c: City) => c.name === this.fsActiveCity)
    return city?.districts || []
  }

  private fsIsMunicipalityActive(): boolean {
    if (!this.fsActiveProvince) return false
    const province = DataService.getProvinceByName(this.fsActiveProvince)
    return province?.isMunicipality || false
  }

  private fsMunicipalityDistricts(): District[] {
    if (!this.fsIsMunicipalityActive()) return []
    const province = DataService.getProvinceByName(this.fsActiveProvince)
    return province?.cities[0]?.districts || []
  }

  // ==================== 职位类型选择器逻辑 ====================

  private fsGenerateTypeResults(): string[] {
    const results: string[] = []
    for (const fName of this.fsSelectedFields) {
      const field = DataService.getFieldByName(fName)
      if (!field) continue
      const selOccupations = this.fsSelectedOccupations.filter(
        (o: string) => field.occupations.some((fo: Occupation) => fo.name === o)
      )
      if (selOccupations.length > 0) {
        for (const o of selOccupations) results.push(fName + '-' + o)
      } else {
        results.push(fName)
      }
    }
    return results
  }

  private fsToggleField(name: string): void {
    if (this.fsIsSelected(this.fsSelectedFields, name)) {
      this.fsSelectedFields = this.fsSelectedFields.filter(n => n !== name)
      const field = DataService.getFieldByName(name)
      if (field) {
        const occupationNames = field.occupations.map((o: Occupation) => o.name)
        this.fsSelectedOccupations = this.fsSelectedOccupations.filter(o => occupationNames.indexOf(o) < 0)
      }
      if (this.fsActiveField === name) {
        this.fsActiveField = ''
      }
    } else {
      this.fsSelectedFields = [...this.fsSelectedFields, name]
      this.fsActiveField = name
    }
    this.filterType = this.fsGenerateTypeResults()
  }

  private fsToggleOccupation(name: string): void {
    if (this.fsIsSelected(this.fsSelectedOccupations, name)) {
      this.fsSelectedOccupations = this.fsSelectedOccupations.filter(n => n !== name)
    } else {
      this.fsSelectedOccupations = [...this.fsSelectedOccupations, name]
    }
    this.filterType = this.fsGenerateTypeResults()
  }

  private fsToggleAllOccupations(): void {
    const field = DataService.getFieldByName(this.fsActiveField)
    if (!field) return
    const allNames = field.occupations.map((o: Occupation) => o.name)
    const allSelected = allNames.every(n => this.fsIsSelected(this.fsSelectedOccupations, n))
    if (allSelected) {
      this.fsSelectedOccupations = this.fsSelectedOccupations.filter(n => allNames.indexOf(n) < 0)
    } else {
      const result = [...this.fsSelectedOccupations]
      for (const n of allNames) {
        if (result.indexOf(n) < 0) result.push(n)
      }
      this.fsSelectedOccupations = result
    }
    this.filterType = this.fsGenerateTypeResults()
  }

  private fsOccupationOptions(): Occupation[] {
    if (!this.fsActiveField) return []
    const field = DataService.getFieldByName(this.fsActiveField)
    return field?.occupations || []
  }

  // ==================== 应用/重置 ====================

  onApply?: (selection: FilterSelection) => void
  onReset?: () => void

  private applyFilters(): void {
    this.onApply?.({
      salaryMin: this.filterSalaryMin,
      salaryMax: this.filterSalaryMax,
      salaryUnit: this.filterSalaryUnit,
      includeNegotiable: this.filterIncludeNeg,
      region: this.fsGenerateRegionResults(),
      type: this.fsGenerateTypeResults()
    })
  }

  private resetFilters(): void {
    this.filterSalaryMin = 0
    this.filterSalaryMax = 0
    this.filterSalaryUnit = -1
    this.filterIncludeNeg = true
    this.filterRegion = []
    this.filterType = []
    this.fsSelectedProvinces = []
    this.fsSelectedCities = []
    this.fsSelectedDistricts = []
    this.fsActiveProvince = ''
    this.fsActiveCity = ''
    this.fsSelectedFields = []
    this.fsSelectedOccupations = []
    this.fsActiveField = ''
    this.onReset?.()
  }

  // ==================== UI 构建器 ====================

  @Builder
  SectionHeader(title: string) {
    Text(title)
      .fontSize(AppFilter.SECTION_TITLE_FONT_SIZE)
      .fontWeight(AppFilter.SECTION_TITLE_FONT_WEIGHT)
      .fontColor(AppColors.TEXT_PRIMARY)
      .margin({ left: AppSpacing.SM, top: AppFilter.SECTION_TITLE_MARGIN, bottom: AppFilter.SECTION_TITLE_MARGIN })
  }

  @Builder
  AllOption(selected: boolean, onClick: () => void) {
    Row() {
      Text('全部')
        .fontSize(AppFilter.CHECK_OPTION_FONT_SIZE)
        .fontColor(selected ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Start)
        .width('100%')
    }
    .width('100%')
    .padding({
      top: AppSpacing.SM,
      bottom: AppSpacing.SM,
      left: AppFilter.CHECK_OPTION_HORIZONTAL_PADDING,
      right: AppFilter.CHECK_OPTION_HORIZONTAL_PADDING
    })
    .backgroundColor(selected ? AppColors.PRIMARY : 'transparent')
    .borderRadius(AppRadius.MD)
    .onClick(onClick)
    .stateStyles({
      pressed: { .opacity(0.8) }
    })
    .animation({ duration: 180 })
  }

  @Builder
  RegionColumn() {
    List({ space: AppSpacing.XS }) {
      ForEach(this.provinces, (province: Province) => {
        ListItem() {
          Row() {
            Text(province.name)
              .fontSize(AppFilter.CHECK_OPTION_FONT_SIZE)
              .fontColor(this.fsIsSelected(this.fsSelectedProvinces, province.name) ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
              .textAlign(TextAlign.Start)
              .width('100%')
          }
          .width('100%')
          .padding({
            top: AppSpacing.SM,
            bottom: AppSpacing.SM,
            left: AppFilter.CHECK_OPTION_HORIZONTAL_PADDING,
            right: AppFilter.CHECK_OPTION_HORIZONTAL_PADDING
          })
          .backgroundColor(this.fsIsSelected(this.fsSelectedProvinces, province.name) ? AppColors.PRIMARY : 'transparent')
          .borderRadius(AppRadius.MD)
          .onClick(() => {
            this.fsToggleProvince(province.name)
          })
          .stateStyles({
            pressed: { .opacity(0.7) }
          })
        }
      }, (province: Province) => province.name)
    }
    .layoutWeight(1)
  }

  @Builder
  CityColumn() {
    if (this.fsActiveProvince && !this.fsIsMunicipalityActive()) {
      List({ space: AppSpacing.XS }) {
        ListItem() {
          this.AllOption(
            this.fsSelectedCities.length > 0 && this.fsCityOptions().every(
              (c: City) => this.fsIsSelected(this.fsSelectedCities, c.name)
            ),
            () => { this.fsToggleAllCities() }
          )
        }
        ForEach(this.fsCityOptions(), (city: City) => {
          ListItem() {
            FilterCheckOption({
              label: city.name,
              checked: this.fsIsSelected(this.fsSelectedCities, city.name),
              onChange: (checked: boolean): void => {
                this.fsToggleCity(city.name)
              }
            })
          }
        }, (city: City) => city.name)
      }
      .layoutWeight(1)
    }
  }

  @Builder
  DistrictColumn() {
    if (this.fsIsMunicipalityActive()) {
      List({ space: AppSpacing.XS }) {
        ListItem() {
          this.AllOption(
            this.fsSelectedDistricts.length > 0 && this.fsMunicipalityDistricts().every(
              (d: District) => this.fsIsSelected(this.fsSelectedDistricts, d.name)
            ),
            () => { this.fsToggleAllDistricts() }
          )
        }
        ForEach(this.fsMunicipalityDistricts(), (district: District) => {
          ListItem() {
            FilterCheckOption({
              label: district.name,
              checked: this.fsIsSelected(this.fsSelectedDistricts, district.name),
              onChange: (checked: boolean): void => {
                this.fsToggleDistrict(district.name)
              }
            })
          }
        }, (district: District) => district.name)
      }
      .layoutWeight(1)
    }

    if (this.fsActiveCity) {
      List({ space: AppSpacing.XS }) {
        ListItem() {
          this.AllOption(
            this.fsSelectedDistricts.length > 0 && this.fsDistrictOptions().every(
              (d: District) => this.fsIsSelected(this.fsSelectedDistricts, d.name)
            ),
            () => { this.fsToggleAllDistricts() }
          )
        }
        ForEach(this.fsDistrictOptions(), (district: District) => {
          ListItem() {
            FilterCheckOption({
              label: district.name,
              checked: this.fsIsSelected(this.fsSelectedDistricts, district.name),
              onChange: (checked: boolean): void => {
                this.fsToggleDistrict(district.name)
              }
            })
          }
        }, (district: District) => district.name)
      }
      .layoutWeight(1)
    }
  }

  @Builder
  FieldColumn() {
    List({ space: AppSpacing.XS }) {
      ForEach(this.fields, (field: Field) => {
        ListItem() {
          Row() {
            Text(field.name)
              .fontSize(AppFilter.CHECK_OPTION_FONT_SIZE)
              .fontColor(this.fsIsSelected(this.fsSelectedFields, field.name) ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
              .textAlign(TextAlign.Start)
              .width('100%')
          }
          .width('100%')
          .padding({
            top: AppSpacing.SM,
            bottom: AppSpacing.SM,
            left: AppFilter.CHECK_OPTION_HORIZONTAL_PADDING,
            right: AppFilter.CHECK_OPTION_HORIZONTAL_PADDING
          })
          .backgroundColor(this.fsIsSelected(this.fsSelectedFields, field.name) ? AppColors.PRIMARY : 'transparent')
          .borderRadius(AppRadius.MD)
          .onClick(() => {
            this.fsToggleField(field.name)
          })
          .stateStyles({
            pressed: { .opacity(0.7) }
          })
        }
      }, (field: Field) => field.name)
    }
    .layoutWeight(1)
  }

  @Builder
  OccupationColumn() {
    if (this.fsActiveField) {
      List({ space: AppSpacing.XS }) {
        ListItem() {
          this.AllOption(
            this.fsSelectedOccupations.length > 0 && this.fsOccupationOptions().every(
              (o: Occupation) => this.fsIsSelected(this.fsSelectedOccupations, o.name)
            ),
            () => { this.fsToggleAllOccupations() }
          )
        }
        ForEach(this.fsOccupationOptions(), (occupation: Occupation) => {
          ListItem() {
            FilterCheckOption({
              label: occupation.name,
              checked: this.fsIsSelected(this.fsSelectedOccupations, occupation.name),
              onChange: (checked: boolean): void => {
                this.fsToggleOccupation(occupation.name)
              }
            })
          }
        }, (occupation: Occupation) => occupation.name)
      }
      .layoutWeight(1)
    }
  }

  build() {
    Column() {
      FilterSheetHeader({
        title: '筛选',
        showReset: true,
        onReset: () => {
          this.resetFilters()
        }
      })

      Scroll() {
        Column() {
          // ===== 薪资区段 =====
          this.SectionHeader('薪资范围')
          Column() {
            Row() {
              TextInput({ placeholder: '最低薪资', text: this.filterSalaryMin > 0 ? String(this.filterSalaryMin) : '' })
                .onChange((v: string) => {
                  this.filterSalaryMin = parseInt(v) || 0
                })
                .height(AppSpacing.BUTTON_HEIGHT_MD)
                .backgroundColor(AppColors.INPUT_BG)
                .borderRadius(AppRadius.MD)
                .layoutWeight(1)
              Text(' — ')
                .fontColor(AppColors.TEXT_MUTED)
                .margin({ left: AppSpacing.SM, right: AppSpacing.SM })
              TextInput({ placeholder: '最高薪资', text: this.filterSalaryMax > 0 ? String(this.filterSalaryMax) : '' })
                .onChange((v: string) => {
                  this.filterSalaryMax = parseInt(v) || 0
                })
                .height(AppSpacing.BUTTON_HEIGHT_MD)
                .backgroundColor(AppColors.INPUT_BG)
                .borderRadius(AppRadius.MD)
                .layoutWeight(1)
            }
            .width('100%')
            .margin({ bottom: AppSpacing.SM_PLUS })

            ChoiceChips({
              options: SALARY_UNIT_OPTIONS,
              selected: this.filterSalaryUnit,
              onSelect: (value: number): void => {
                this.filterSalaryUnit = this.filterSalaryUnit === value ? -1 : value
              }
            })
              .margin({ bottom: AppSpacing.SM_PLUS })

            Row() {
              Checkbox({ name: 'includeNegotiable' })
                .select(this.filterIncludeNeg)
                .selectedColor(AppColors.PRIMARY)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
                .onChange((value: boolean) => {
                  this.filterIncludeNeg = value
                })
              Text('包含面议')
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.TEXT_SECONDARY)
                .margin({ left: AppSpacing.SM })
              Blank()
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
          }
          .padding({ left: AppSpacing.SM })

          Divider()
            .height(AppFilter.DIVIDER_HEIGHT)
            .color(AppFilter.DIVIDER_COLOR)
            .margin({ top: AppSpacing.SM_PLUS, bottom: AppSpacing.SM_PLUS })

          // ===== 区域区段 =====
          this.SectionHeader('工作区域')
          Column() {
            Row() {
              this.RegionColumn()
              this.CityColumn()
              this.DistrictColumn()
            }
            .width('100%')
            .height(AppSpacing.FILTER_LIST_HEIGHT)
          }
          .padding({ left: AppSpacing.SM })

          Divider()
            .height(AppFilter.DIVIDER_HEIGHT)
            .color(AppFilter.DIVIDER_COLOR)
            .margin({ top: AppSpacing.SM_PLUS, bottom: AppSpacing.SM_PLUS })

          // ===== 类型区段 =====
          this.SectionHeader('职位类型')
          Column() {
            Row() {
              this.FieldColumn()
              this.OccupationColumn()
            }
            .width('100%')
            .height(AppSpacing.FILTER_OCCUPATION_LIST_HEIGHT)
          }
          .padding({ left: AppSpacing.SM })
        }
        .width('100%')
        .padding({ bottom: AppSpacing.MD })
      }
      .layoutWeight(1)

      Button('确定')
        .width('100%')
        .height(AppSpacing.INPUT_HEIGHT)
        .backgroundColor(AppColors.PRIMARY)
        .fontColor('#FFFFFF')
        .fontSize(AppFontSize.MD)
        .fontWeight(FontWeight.Medium)
        .borderRadius(AppRadius.LG)
        .margin({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.MD })
        .onClick(() => {
          this.applyFilters()
        })
    }
    .width('100%')
    .height('100%')
    .constraintSize({ maxWidth: this.breakpoint === WindowBreakpoint.COMPACT ? '100%' : 560 })
    .backgroundColor(AppColors.BG_PAGE)
  }
}
