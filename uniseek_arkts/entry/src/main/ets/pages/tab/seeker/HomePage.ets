import { router } from '@kit.ArkUI';
import { ApiClient } from '../../../services/ApiClient';
import { DataService, Province, City, District, Field, Occupation } from '../../../services/DataService';
import { JobData, TaskVO, TaskSearchParams, mapTaskToJobData } from '../../../services/ChatTypes';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../../../common/AppStyles';
import { FilterBar } from './FilterBar';
import { JobFeedList } from './JobFeedList';
import { JobFeedCard } from './JobFeedCard';

interface TabDataState {
  jobs: JobData[]
  page: number
  hasMore: boolean
  loading: boolean
}

interface FilterState {
  salaryMin: number
  salaryMax: number
  regionId: number
}

@CustomDialog
struct RegionPickerDialog {
  controller?: CustomDialogController
  onSelect?: (results: string[]) => void
  onCancel?: () => void

  @State selectedProvinces: string[] = []
  @State selectedCities: string[] = []
  @State selectedDistricts: string[] = []
  @State activeProvince: string = ''
  @State activeCity: string = ''

  private provinces: Province[] = DataService.getProvinces()

  isSelected(list: string[], name: string): boolean {
    return list.indexOf(name) >= 0
  }

  toggleProvince(name: string): void {
    if (this.isSelected(this.selectedProvinces, name)) {
      this.selectedProvinces = this.selectedProvinces.filter(n => n !== name)
      const province = DataService.getProvinceByName(name)
      if (province) {
        const cityNames = province.cities.map((c: City) => c.name)
        this.selectedCities = this.selectedCities.filter(c => cityNames.indexOf(c) < 0)
        const districtNames: string[] = []
        for (const city of province.cities) {
          for (const district of city.districts) {
            districtNames.push(district.name)
          }
        }
        this.selectedDistricts = this.selectedDistricts.filter(d => districtNames.indexOf(d) < 0)
      }
      if (this.activeProvince === name) {
        this.activeProvince = ''
      }
      this.activeCity = ''
    } else {
      this.selectedProvinces = [...this.selectedProvinces, name]
      this.activeProvince = name
      this.activeCity = ''
    }
  }

  toggleCity(name: string): void {
    if (this.isSelected(this.selectedCities, name)) {
      this.selectedCities = this.selectedCities.filter(n => n !== name)
    } else {
      this.selectedCities = [...this.selectedCities, name]
    }
    this.activeCity = name
  }

  toggleDistrict(name: string): void {
    if (this.isSelected(this.selectedDistricts, name)) {
      this.selectedDistricts = this.selectedDistricts.filter(n => n !== name)
    } else {
      this.selectedDistricts = [...this.selectedDistricts, name]
    }
  }

  toggleAllCities(): void {
    const province = DataService.getProvinceByName(this.activeProvince)
    if (!province || province.isMunicipality) return
    const allNames = province.cities.map((c: City) => c.name)
    const allSelected = allNames.every(n => this.isSelected(this.selectedCities, n))
    if (allSelected) {
      this.selectedCities = this.selectedCities.filter(n => allNames.indexOf(n) < 0)
    } else {
      const result = [...this.selectedCities]
      for (const n of allNames) {
        if (result.indexOf(n) < 0) result.push(n)
      }
      this.selectedCities = result
    }
  }

  toggleAllDistricts(): void {
    const province = DataService.getProvinceByName(this.activeProvince)
    if (!province) return
    const city = province.cities.find((c: City) => c.name === this.activeCity)
    if (!city) return
    const allNames = city.districts.map((d: District) => d.name)
    const allSelected = allNames.every(n => this.isSelected(this.selectedDistricts, n))
    if (allSelected) {
      this.selectedDistricts = this.selectedDistricts.filter(n => allNames.indexOf(n) < 0)
    } else {
      const result = [...this.selectedDistricts]
      for (const n of allNames) {
        if (result.indexOf(n) < 0) result.push(n)
      }
      this.selectedDistricts = result
    }
  }

  generateResults(): string[] {
    const results: string[] = []

    for (const pName of this.selectedProvinces) {
      const province = DataService.getProvinceByName(pName)
      if (!province) continue

      if (province.isMunicipality) {
        const city = province.cities[0]
        const selDists = this.selectedDistricts.filter(
          (d: string) => city.districts.some((dd: District) => dd.name === d)
        )
        if (selDists.length > 0) {
          for (const d of selDists) results.push(pName + '-' + d)
        } else {
          results.push(pName)
        }
      } else {
        const selCities = this.selectedCities.filter(
          (c: string) => province.cities.some((pc: City) => pc.name === c)
        )
        if (selCities.length === 0) {
          results.push(pName)
        } else {
          for (const cName of selCities) {
            const city = province.cities.find((c: City) => c.name === cName)
            if (!city) continue
            const selDists = this.selectedDistricts.filter(
              (d: string) => city.districts.some((dd: District) => dd.name === d)
            )
            if (selDists.length > 0) {
              for (const d of selDists) results.push(pName + '-' + cName + '-' + d)
            } else {
              results.push(pName + '-' + cName)
            }
          }
        }
      }
    }

    return results
  }

  cityOptions(): City[] {
    if (!this.activeProvince) return []
    const province = DataService.getProvinceByName(this.activeProvince)
    if (!province || province.isMunicipality) return []
    return province.cities
  }

  districtOptions(): District[] {
    if (!this.activeCity) return []
    const province = DataService.getProvinceByName(this.activeProvince)
    if (!province) return []
    const city = province.cities.find((c: City) => c.name === this.activeCity)
    return city?.districts || []
  }

  isMunicipalityActive(): boolean {
    if (!this.activeProvince) return false
    const province = DataService.getProvinceByName(this.activeProvince)
    return province?.isMunicipality || false
  }

  municipalityDistricts(): District[] {
    if (!this.isMunicipalityActive()) return []
    const province = DataService.getProvinceByName(this.activeProvince)
    return province?.cities[0]?.districts || []
  }

  build() {
    Column() {
      Row() {
        Text('选择区域')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
        Text('取消')
          .fontSize(15)
          .fontColor(AppColors.TEXT_MUTED)
          .onClick(() => { this.onCancel?.() })
      }
      .width('100%')
      .padding({ bottom: 16 })

      Row() {
        Scroll() {
          Column() {
            ForEach(this.provinces, (province: Province) => {
              Text(province.name)
                .fontSize(15)
                .fontColor(this.isSelected(this.selectedProvinces, province.name) ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
                .backgroundColor(this.isSelected(this.selectedProvinces, province.name) ? '#2F8BE6' : 'transparent')
                .borderRadius(8)
                .padding({ top: 10, bottom: 10, left: 12, right: 12 })
                .textAlign(TextAlign.Start)
                .width('100%')
                .onClick(() => { this.toggleProvince(province.name) })
            })
          }
          .width('100%')
          .padding({ left: 6, right: 6 })
        }
        .layoutWeight(1)
        .width(0)

        if (this.activeProvince && !this.isMunicipalityActive()) {
          Scroll() {
            Column() {
              Text('全部')
                .fontSize(15)
                .fontColor(this.selectedCities.length > 0 && this.cityOptions().every(
                  (c: City) => this.isSelected(this.selectedCities, c.name)
                ) ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
                .backgroundColor(this.selectedCities.length > 0 && this.cityOptions().every(
                  (c: City) => this.isSelected(this.selectedCities, c.name)
                ) ? '#2F8BE6' : 'transparent')
                .borderRadius(8)
                .padding({ top: 10, bottom: 10, left: 12, right: 12 })
                .textAlign(TextAlign.Start)
                .fontWeight(FontWeight.Bold)
                .width('100%')
                .onClick(() => { this.toggleAllCities() })

              ForEach(this.cityOptions(), (city: City) => {
                Text(city.name)
                  .fontSize(15)
                  .fontColor(this.isSelected(this.selectedCities, city.name) ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
                  .backgroundColor(this.isSelected(this.selectedCities, city.name) ? '#2F8BE6' : 'transparent')
                  .borderRadius(8)
                  .padding({ top: 10, bottom: 10, left: 12, right: 12 })
                  .textAlign(TextAlign.Start)
                  .width('100%')
                  .onClick(() => { this.toggleCity(city.name) })
              })
            }
            .width('100%')
            .padding({ left: 6, right: 6 })
          }
          .layoutWeight(1)
          .width(0)
        }

        if (this.isMunicipalityActive()) {
          Scroll() {
            Column() {
              Text('全部')
                .fontSize(15)
                .fontColor(this.selectedDistricts.length > 0 && this.municipalityDistricts().every(
                  (d: District) => this.isSelected(this.selectedDistricts, d.name)
                ) ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
                .backgroundColor(this.selectedDistricts.length > 0 && this.municipalityDistricts().every(
                  (d: District) => this.isSelected(this.selectedDistricts, d.name)
                ) ? '#2F8BE6' : 'transparent')
                .borderRadius(8)
                .padding({ top: 10, bottom: 10, left: 12, right: 12 })
                .textAlign(TextAlign.Start)
                .fontWeight(FontWeight.Bold)
                .width('100%')
                .onClick(() => { this.toggleAllDistricts() })

              ForEach(this.municipalityDistricts(), (district: District) => {
                Text(district.name)
                  .fontSize(15)
                  .fontColor(this.isSelected(this.selectedDistricts, district.name) ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
                  .backgroundColor(this.isSelected(this.selectedDistricts, district.name) ? '#2F8BE6' : 'transparent')
                  .borderRadius(8)
                  .padding({ top: 10, bottom: 10, left: 12, right: 12 })
                  .textAlign(TextAlign.Start)
                  .width('100%')
                  .onClick(() => { this.toggleDistrict(district.name) })
              })
            }
            .width('100%')
            .padding({ left: 6, right: 6 })
          }
          .layoutWeight(1)
          .width(0)
        }

        if (this.activeCity) {
          Scroll() {
            Column() {
              Text('全部')
                .fontSize(15)
                .fontColor(this.selectedDistricts.length > 0 && this.districtOptions().every(
                  (d: District) => this.isSelected(this.selectedDistricts, d.name)
                ) ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
                .backgroundColor(this.selectedDistricts.length > 0 && this.districtOptions().every(
                  (d: District) => this.isSelected(this.selectedDistricts, d.name)
                ) ? '#2F8BE6' : 'transparent')
                .borderRadius(8)
                .padding({ top: 10, bottom: 10, left: 12, right: 12 })
                .textAlign(TextAlign.Start)
                .fontWeight(FontWeight.Bold)
                .width('100%')
                .onClick(() => { this.toggleAllDistricts() })

              ForEach(this.districtOptions(), (district: District) => {
                Text(district.name)
                  .fontSize(15)
                  .fontColor(this.isSelected(this.selectedDistricts, district.name) ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
                  .backgroundColor(this.isSelected(this.selectedDistricts, district.name) ? '#2F8BE6' : 'transparent')
                  .borderRadius(8)
                  .padding({ top: 10, bottom: 10, left: 12, right: 12 })
                  .textAlign(TextAlign.Start)
                  .width('100%')
                  .onClick(() => { this.toggleDistrict(district.name) })
              })
            }
            .width('100%')
            .padding({ left: 6, right: 6 })
          }
          .layoutWeight(1)
          .width(0)
        }
      }
      .layoutWeight(1)
      .width('100%')

      Row() {
        Row().layoutWeight(1)
        Text('完成')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor(AppColors.PRIMARY)
          .borderRadius(20)
          .padding({ left: 28, right: 28, top: 10, bottom: 10 })
          .onClick(() => {
            this.onSelect?.(this.generateResults())
          })
          .stateStyles({
            pressed: {
              .scale({ x: 0.97, y: 0.97 })
              .opacity(0.9)
            },
            normal: {
              .scale({ x: 1, y: 1 })
              .opacity(1)
            }
          })
          .animation({
            duration: 200
          })
      }
      .width('100%')
      .padding({ top: 16 })
    }
    .padding(20)
    .width('100%')
    .height('60%')
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}

@CustomDialog
struct TypePickerDialog {
  controller?: CustomDialogController
  onSelect?: (results: string[]) => void
  onCancel?: () => void

  @State selectedFields: string[] = []
  @State selectedOccupations: string[] = []
  @State activeField: string = ''

  private fields: Field[] = DataService.getFields()

  isSelected(list: string[], name: string): boolean {
    return list.indexOf(name) >= 0
  }

  toggleField(name: string): void {
    if (this.isSelected(this.selectedFields, name)) {
      this.selectedFields = this.selectedFields.filter(n => n !== name)
      const field = DataService.getFieldByName(name)
      if (field) {
        const occupationNames = field.occupations.map((o: Occupation) => o.name)
        this.selectedOccupations = this.selectedOccupations.filter(o => occupationNames.indexOf(o) < 0)
      }
      if (this.activeField === name) {
        this.activeField = ''
      }
    } else {
      this.selectedFields = [...this.selectedFields, name]
      this.activeField = name
    }
  }

  toggleOccupation(name: string): void {
    if (this.isSelected(this.selectedOccupations, name)) {
      this.selectedOccupations = this.selectedOccupations.filter(n => n !== name)
    } else {
      this.selectedOccupations = [...this.selectedOccupations, name]
    }
  }

  toggleAllOccupations(): void {
    const field = DataService.getFieldByName(this.activeField)
    if (!field) return
    const allNames = field.occupations.map((o: Occupation) => o.name)
    const allSelected = allNames.every(n => this.isSelected(this.selectedOccupations, n))
    if (allSelected) {
      this.selectedOccupations = this.selectedOccupations.filter(n => allNames.indexOf(n) < 0)
    } else {
      const result = [...this.selectedOccupations]
      for (const n of allNames) {
        if (result.indexOf(n) < 0) result.push(n)
      }
      this.selectedOccupations = result
    }
  }

  occupationOptions(): Occupation[] {
    if (!this.activeField) return []
    const field = DataService.getFieldByName(this.activeField)
    return field?.occupations || []
  }

  generateResults(): string[] {
    const results: string[] = []

    for (const fName of this.selectedFields) {
      const field = DataService.getFieldByName(fName)
      if (!field) continue
      const selOccupations = this.selectedOccupations.filter(
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

  build() {
    Column() {
      Row() {
        Text('选择类型')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
        Text('取消')
          .fontSize(15)
          .fontColor(AppColors.TEXT_MUTED)
          .onClick(() => { this.onCancel?.() })
      }
      .width('100%')
      .padding({ bottom: 16 })

      Row() {
        Scroll() {
          Column() {
            ForEach(this.fields, (field: Field) => {
              Text(field.name)
                .fontSize(15)
                .fontColor(this.isSelected(this.selectedFields, field.name) ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
                .backgroundColor(this.isSelected(this.selectedFields, field.name) ? '#2F8BE6' : 'transparent')
                .borderRadius(8)
                .padding({ top: 10, bottom: 10, left: 12, right: 12 })
                .textAlign(TextAlign.Start)
                .width('100%')
                .onClick(() => { this.toggleField(field.name) })
            })
          }
          .width('100%')
          .padding({ left: 6, right: 6 })
        }
        .layoutWeight(1)
        .width(0)

        if (this.activeField) {
          Scroll() {
            Column() {
              Text('全部')
                .fontSize(15)
                .fontColor(this.selectedOccupations.length > 0 && this.occupationOptions().every(
                  (o: Occupation) => this.isSelected(this.selectedOccupations, o.name)
                ) ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
                .backgroundColor(this.selectedOccupations.length > 0 && this.occupationOptions().every(
                  (o: Occupation) => this.isSelected(this.selectedOccupations, o.name)
                ) ? '#2F8BE6' : 'transparent')
                .borderRadius(8)
                .padding({ top: 10, bottom: 10, left: 12, right: 12 })
                .textAlign(TextAlign.Start)
                .fontWeight(FontWeight.Bold)
                .width('100%')
                .onClick(() => { this.toggleAllOccupations() })

              ForEach(this.occupationOptions(), (occupation: Occupation) => {
                Text(occupation.name)
                  .fontSize(15)
                  .fontColor(this.isSelected(this.selectedOccupations, occupation.name) ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
                  .backgroundColor(this.isSelected(this.selectedOccupations, occupation.name) ? '#2F8BE6' : 'transparent')
                  .borderRadius(8)
                  .padding({ top: 10, bottom: 10, left: 12, right: 12 })
                  .textAlign(TextAlign.Start)
                  .width('100%')
                  .onClick(() => { this.toggleOccupation(occupation.name) })
              })
            }
            .width('100%')
            .padding({ left: 6, right: 6 })
          }
          .layoutWeight(1)
          .width(0)
        }
      }
      .layoutWeight(1)
      .width('100%')

      Row() {
        Row().layoutWeight(1)
        Text('完成')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor(AppColors.PRIMARY)
          .borderRadius(20)
          .padding({ left: 28, right: 28, top: 10, bottom: 10 })
          .onClick(() => {
            this.onSelect?.(this.generateResults())
          })
      }
      .width('100%')
      .padding({ top: 16 })
    }
    .padding(20)
    .width('100%')
    .height('55%')
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}

@CustomDialog
struct SalaryDialog {
  controller?: CustomDialogController
  selectedUnit: number = -1
  includeNegotiable: boolean = true
  onConfirm?: (min: number, max: number, unit: number, includeNegotiable: boolean) => void
  onCancel?: () => void

  @State minText: string = ''
  @State maxText: string = ''
  @State currentUnit: number = -1
  @State localIncludeNegotiable: boolean = true

  aboutToAppear(): void {
    this.currentUnit = this.selectedUnit
    this.localIncludeNegotiable = this.includeNegotiable
  }

  build() {
    Column() {
      Row() {
        Text('薪资筛选')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
        Text('取消')
          .fontSize(15)
          .fontColor(AppColors.TEXT_MUTED)
          .onClick(() => { this.onCancel?.() })
      }
      .width('100%')
      .padding({ bottom: 16 })

      TextInput({ placeholder: '最低薪资(元)', text: this.minText })
        .onChange((value: string) => { this.minText = value })
        .width('100%')
        .height(44)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(8)
        .margin({ bottom: 12 })

      TextInput({ placeholder: '最高薪资(元)', text: this.maxText })
        .onChange((value: string) => { this.maxText = value })
        .width('100%')
        .height(44)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(8)
        .margin({ bottom: 16 })

      Text('薪资类型')
        .fontSize(15)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')
        .margin({ bottom: 10 })

      Row() {
        Text('日结')
          .fontSize(14)
          .fontColor(this.currentUnit === 0 ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
          .backgroundColor(this.currentUnit === 0 ? AppColors.PRIMARY : AppColors.INPUT_BG)
          .borderRadius(16)
          .padding({ left: 20, right: 20, top: 8, bottom: 8 })
          .onClick(() => { this.currentUnit = this.currentUnit === 0 ? -1 : 0 })

        Text('时薪')
          .fontSize(14)
          .fontColor(this.currentUnit === 1 ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
          .backgroundColor(this.currentUnit === 1 ? AppColors.PRIMARY : AppColors.INPUT_BG)
          .borderRadius(16)
          .padding({ left: 20, right: 20, top: 8, bottom: 8 })
          .onClick(() => { this.currentUnit = this.currentUnit === 1 ? -1 : 1 })

        Text('月结')
          .fontSize(14)
          .fontColor(this.currentUnit === 2 ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
          .backgroundColor(this.currentUnit === 2 ? AppColors.PRIMARY : AppColors.INPUT_BG)
          .borderRadius(16)
          .padding({ left: 20, right: 20, top: 8, bottom: 8 })
          .onClick(() => { this.currentUnit = this.currentUnit === 2 ? -1 : 2 })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ bottom: 16 })

      // 包含面议复选框
      Row() {
        Row()
          .width(18)
          .height(18)
          .borderRadius(4)
          .border({
            width: this.localIncludeNegotiable ? 0 : 1,
            color: AppColors.TEXT_MUTED
          })
          .backgroundColor(this.localIncludeNegotiable ? AppColors.PRIMARY : 'transparent')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.localIncludeNegotiable = !this.localIncludeNegotiable
          })
        if (this.localIncludeNegotiable) {
          Text('✓')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .position({ x: 3, y: 0 })
        }
        Text('包含面议')
          .fontSize(14)
          .fontColor(AppColors.TEXT_SECONDARY)
          .margin({ left: 8 })
          .onClick(() => {
            this.localIncludeNegotiable = !this.localIncludeNegotiable
          })
        Blank()
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 16 })

      Row() {
        Row().layoutWeight(1)
        Text('确定')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor(AppColors.PRIMARY)
          .borderRadius(20)
          .padding({ left: 28, right: 28, top: 10, bottom: 10 })
          .onClick(() => {
            const min = parseInt(this.minText) || 0
            const max = parseInt(this.maxText) || 0
            this.onConfirm?.(min, max, this.currentUnit, this.localIncludeNegotiable)
          })
      }
      .width('100%')
      .padding({ top: 8 })
    }
    .padding(20)
    .width('100%')
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}

@Component
export struct HomePage {
  @State activeCategory: string = '全职'
  @State selectedTabIndex: number = 0
  @State salaryMin: number = 0
  @State salaryMax: number = 0
  @State selectedSalaryUnit: number = -1
  @State includeNegotiable: boolean = true
  @State selectedRegion: string[] = []
  @State selectedType: string[] = []
  @State tabData: Record<number, TabDataState> = {
    1: { jobs: [], page: 1, hasMore: true, loading: false },
    2: { jobs: [], page: 1, hasMore: true, loading: false },
    3: { jobs: [], page: 1, hasMore: true, loading: false }
  }

  // ==== bindSheet 筛选弹窗控制 ====
  @State @Watch('onFilterSheetChange') showFilterSheet: boolean = false

  // ==== bindSheet 内临时筛选状态（确定后才同步到父组件）====
  @State filterSalaryMin: number = 0
  @State filterSalaryMax: number = 0
  @State filterSalaryUnit: number = -1
  @State filterIncludeNeg: boolean = true
  @State filterRegion: string[] = []
  @State filterType: string[] = []

  // ==== bindSheet 内区域选择器内部状态 ====
  @State fsSelectedProvinces: string[] = []
  @State fsSelectedCities: string[] = []
  @State fsSelectedDistricts: string[] = []
  @State fsActiveProvince: string = ''
  @State fsActiveCity: string = ''

  // ==== bindSheet 内类型选择器内部状态 ====
  @State fsSelectedFields: string[] = []
  @State fsSelectedOccupations: string[] = []
  @State fsActiveField: string = ''

  // ==== 选择器数据源 ====
  private provinces: Province[] = DataService.getProvinces()
  private fields: Field[] = DataService.getFields()

  aboutToAppear(): void {
    this.loadTabData(1, false)
  }

  async loadTabData(jobType: number, append: boolean): Promise<void> {
    const state = this.tabData[jobType]
    if (state.loading || (!append && state.jobs.length > 0 && !state.hasMore) || (append && !state.hasMore)) return
    
    const loadingState: TabDataState = {
      jobs: state.jobs,
      page: state.page,
      hasMore: state.hasMore,
      loading: true
    }
    this.tabData = {
      1: jobType === 1 ? loadingState : this.tabData[1],
      2: jobType === 2 ? loadingState : this.tabData[2],
      3: jobType === 3 ? loadingState : this.tabData[3]
    }
    
    try {
      const params: TaskSearchParams = {
        jobType: jobType,
        page: append ? state.page + 1 : 1,
        pageSize: 10,
        salaryMin: this.salaryMin > 0 ? this.salaryMin : undefined,
        salaryMax: this.salaryMax > 0 ? this.salaryMax : undefined,
        salaryUnit: this.selectedSalaryUnit >= 0 ? this.selectedSalaryUnit : undefined,
        includeNegotiable: this.includeNegotiable
      }

      // 构建地区筛选参数：将 selectedRegion 中的名称转换为地区ID
      if (this.selectedRegion.length > 0) {
        const regionIdList: string[] = []
        for (const regionName of this.selectedRegion) {
          const id = DataService.getRegionIdByName(regionName)
          if (id !== null) {
            regionIdList.push(String(id))
          }
        }
        if (regionIdList.length > 0) {
          params.regionIds = regionIdList.join(',')
        }
      }

      // 构建分类筛选参数：将 selectedType 中的名称转换为分类ID
      if (this.selectedType.length > 0) {
        const categoryIdList: string[] = []
        for (const typeName of this.selectedType) {
          const id = DataService.getCategoryIdByName(typeName)
          if (id !== null) {
            categoryIdList.push(String(id))
          }
        }
        if (categoryIdList.length > 0) {
          params.categoryIds = categoryIdList.join(',')
        }
      }

      const result = await ApiClient.searchTasks(params)
      const newJobs = result.records.map((task: TaskVO) => mapTaskToJobData(task))
      const hasMore = result.page < result.totalPages
      
      const successState: TabDataState = {
        jobs: append ? state.jobs.concat(newJobs) : newJobs,
        page: result.page,
        hasMore: hasMore,
        loading: false
      }
      this.tabData = {
        1: jobType === 1 ? successState : this.tabData[1],
        2: jobType === 2 ? successState : this.tabData[2],
        3: jobType === 3 ? successState : this.tabData[3]
      }
    } catch (e) {
      console.error('加载职位失败 jobType=' + jobType, e)
      const errorState: TabDataState = {
        jobs: state.jobs,
        page: state.page,
        hasMore: state.hasMore,
        loading: false
      }
      this.tabData = {
        1: jobType === 1 ? errorState : this.tabData[1],
        2: jobType === 2 ? errorState : this.tabData[2],
        3: jobType === 3 ? errorState : this.tabData[3]
      }
    }
  }

  resetAllTabs(): void {
    this.tabData = {
      1: { jobs: [], page: 1, hasMore: true, loading: false },
      2: { jobs: [], page: 1, hasMore: true, loading: false },
      3: { jobs: [], page: 1, hasMore: true, loading: false }
    }
    const currentType = this.activeCategory === '兼职' ? 2 : this.activeCategory === '实习' ? 3 : 1
    this.loadTabData(currentType, false)
  }

  private onTabChange(index: number): void {
    const jobTypes = [1, 2, 3]
    const jobType = jobTypes[index]
    const state = this.tabData[jobType]
    if (state.jobs.length === 0 && !state.loading) {
      this.loadTabData(jobType, false)
    }
  }

  loadMoreForTab(jobType: number): void {
    this.loadTabData(jobType, true)
  }

  // 打开 sheet 时初始化临时状态
  onFilterSheetChange(): void {
    if (this.showFilterSheet) {
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
  }

  // ==================== 选择器通用方法 ====================

  fsIsSelected(list: string[], name: string): boolean {
    return list.indexOf(name) >= 0
  }

  // ==================== 区域选择器方法 ====================

  fsGenerateRegionResults(): string[] {
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

  fsGenerateTypeResults(): string[] {
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

  fsToggleProvince(name: string): void {
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

  fsToggleCity(name: string): void {
    if (this.fsIsSelected(this.fsSelectedCities, name)) {
      this.fsSelectedCities = this.fsSelectedCities.filter(n => n !== name)
    } else {
      this.fsSelectedCities = [...this.fsSelectedCities, name]
    }
    this.fsActiveCity = name
    this.filterRegion = this.fsGenerateRegionResults()
  }

  fsToggleDistrict(name: string): void {
    if (this.fsIsSelected(this.fsSelectedDistricts, name)) {
      this.fsSelectedDistricts = this.fsSelectedDistricts.filter(n => n !== name)
    } else {
      this.fsSelectedDistricts = [...this.fsSelectedDistricts, name]
    }
    this.filterRegion = this.fsGenerateRegionResults()
  }

  fsToggleAllCities(): void {
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

  fsToggleAllDistricts(): void {
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

  fsCityOptions(): City[] {
    if (!this.fsActiveProvince) return []
    const province = DataService.getProvinceByName(this.fsActiveProvince)
    if (!province || province.isMunicipality) return []
    return province.cities
  }

  fsDistrictOptions(): District[] {
    if (!this.fsActiveCity) return []
    const province = DataService.getProvinceByName(this.fsActiveProvince)
    if (!province) return []
    const city = province.cities.find((c: City) => c.name === this.fsActiveCity)
    return city?.districts || []
  }

  fsIsMunicipalityActive(): boolean {
    if (!this.fsActiveProvince) return false
    const province = DataService.getProvinceByName(this.fsActiveProvince)
    return province?.isMunicipality || false
  }

  fsMunicipalityDistricts(): District[] {
    if (!this.fsIsMunicipalityActive()) return []
    const province = DataService.getProvinceByName(this.fsActiveProvince)
    return province?.cities[0]?.districts || []
  }

  // ==================== 类型选择器方法 ====================

  fsToggleField(name: string): void {
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

  fsToggleOccupation(name: string): void {
    if (this.fsIsSelected(this.fsSelectedOccupations, name)) {
      this.fsSelectedOccupations = this.fsSelectedOccupations.filter(n => n !== name)
    } else {
      this.fsSelectedOccupations = [...this.fsSelectedOccupations, name]
    }
    this.filterType = this.fsGenerateTypeResults()
  }

  fsToggleAllOccupations(): void {
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

  fsOccupationOptions(): Occupation[] {
    if (!this.fsActiveField) return []
    const field = DataService.getFieldByName(this.fsActiveField)
    return field?.occupations || []
  }

  // ==================== 筛选应用/重置 ====================

  private applySheetFilters(): void {
    this.salaryMin = this.filterSalaryMin
    this.salaryMax = this.filterSalaryMax
    this.selectedSalaryUnit = this.filterSalaryUnit
    this.includeNegotiable = this.filterIncludeNeg
    this.selectedRegion = this.fsGenerateRegionResults()
    this.selectedType = this.fsGenerateTypeResults()
    this.resetAllTabs()
    this.showFilterSheet = false
  }

  private resetSheetFilters(): void {
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
  }

  // ==================== bindSheet 内容构建 ====================

  @Builder
  SectionHeader(title: string) {
    Text(title)
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .fontColor(AppColors.TEXT_PRIMARY)
      .margin({ left: AppSpacing.SM, top: 12, bottom: 12 })
  }

  @Builder
  FilterSheetBuilder() {
    Column() {
      // 标题行
      Row() {
        Text('筛选')
          .fontSize(AppFontSize.LG)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Blank()
        Text('重置')
          .fontSize(AppFontSize.SM)
          .fontColor(AppColors.TEXT_MUTED)
          .onClick(() => {
            this.resetSheetFilters()
          })
      }
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: AppSpacing.SM })

      // 可滚动筛选内容
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
                .height(44)
                .backgroundColor(AppColors.INPUT_BG)
                .borderRadius(8)
                .layoutWeight(1)
              Text(' — ')
                .fontColor(AppColors.TEXT_MUTED)
                .margin({ left: 8, right: 8 })
              TextInput({ placeholder: '最高薪资', text: this.filterSalaryMax > 0 ? String(this.filterSalaryMax) : '' })
                .onChange((v: string) => {
                  this.filterSalaryMax = parseInt(v) || 0
                })
                .height(44)
                .backgroundColor(AppColors.INPUT_BG)
                .borderRadius(8)
                .layoutWeight(1)
            }
            .width('100%')
            .margin({ bottom: 12 })

            Row() {
              Button('日结')
                .type(ButtonType.Capsule)
                .backgroundColor(this.filterSalaryUnit === 0 ? AppColors.PRIMARY : '#F0F0F0')
                .fontColor(this.filterSalaryUnit === 0 ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
                .fontSize(AppFontSize.SM)
                .height(36)
                .onClick(() => {
                  this.filterSalaryUnit = this.filterSalaryUnit === 0 ? -1 : 0
                })
              Button('时薪')
                .type(ButtonType.Capsule)
                .backgroundColor(this.filterSalaryUnit === 1 ? AppColors.PRIMARY : '#F0F0F0')
                .fontColor(this.filterSalaryUnit === 1 ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
                .fontSize(AppFontSize.SM)
                .height(36)
                .onClick(() => {
                  this.filterSalaryUnit = this.filterSalaryUnit === 1 ? -1 : 1
                })
              Button('月结')
                .type(ButtonType.Capsule)
                .backgroundColor(this.filterSalaryUnit === 2 ? AppColors.PRIMARY : '#F0F0F0')
                .fontColor(this.filterSalaryUnit === 2 ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
                .fontSize(AppFontSize.SM)
                .height(36)
                .onClick(() => {
                  this.filterSalaryUnit = this.filterSalaryUnit === 2 ? -1 : 2
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceEvenly)
            .margin({ bottom: 12 })

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
                .margin({ left: 8 })
              Blank()
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
          }
          .padding({ left: AppSpacing.SM })

          Divider()
            .height(0.5)
            .color(AppColors.BORDER)
            .margin({ top: 12, bottom: 12 })

          // ===== 区域区段 =====
          this.SectionHeader('工作区域')
          Column() {
            Row() {
              // 省列表
              List({ space: 4 }) {
                ForEach(this.provinces, (province: Province) => {
                  ListItem() {
                    Row() {
                      Text(province.name)
                        .fontSize(15)
                        .textAlign(TextAlign.Start)
                    }
                    .width('100%')
                    .padding({ top: 10, bottom: 10, left: 12, right: 12 })
                    .backgroundColor(this.fsIsSelected(this.fsSelectedProvinces, province.name) ? '#2F8BE6' : 'transparent')
                    .borderRadius(8)
                    .onClick(() => {
                      this.fsToggleProvince(province.name)
                    })
                    .stateStyles({
                      pressed: {
                        .opacity(0.7)
                      }
                    })
                  }
                })
              }
              .layoutWeight(1)

              // 市列表（非直辖市时显示）
              if (this.fsActiveProvince && !this.fsIsMunicipalityActive()) {
                List({ space: 4 }) {
                  ListItem() {
                    Text('全部')
                      .fontSize(15)
                      .fontColor(this.fsSelectedCities.length > 0 && this.fsCityOptions().every(
                        (c: City) => this.fsIsSelected(this.fsSelectedCities, c.name)
                      ) ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
                      .backgroundColor(this.fsSelectedCities.length > 0 && this.fsCityOptions().every(
                        (c: City) => this.fsIsSelected(this.fsSelectedCities, c.name)
                      ) ? '#2F8BE6' : 'transparent')
                      .borderRadius(8)
                      .padding({ top: 10, bottom: 10, left: 12, right: 12 })
                      .textAlign(TextAlign.Start)
                      .fontWeight(FontWeight.Bold)
                      .width('100%')
                      .onClick(() => {
                        this.fsToggleAllCities()
                      })
                  }
                  ForEach(this.fsCityOptions(), (city: City) => {
                    ListItem() {
                      Row() {
                        Checkbox({ name: city.name })
                          .select(this.fsIsSelected(this.fsSelectedCities, city.name))
                          .selectedColor('#2F8BE6')
                          .shape(CheckBoxShape.ROUNDED_SQUARE)
                        Text(city.name)
                          .fontSize(15)
                          .margin({ left: 8 })
                      }
                      .width('100%')
                      .padding({ top: 6, bottom: 6, left: 12, right: 12 })
                      .onClick(() => {
                        this.fsToggleCity(city.name)
                      })
                    }
                  })
                }
                .layoutWeight(1)
              }

              // 区列表（直辖市）
              if (this.fsIsMunicipalityActive()) {
                List({ space: 4 }) {
                  ListItem() {
                    Text('全部')
                      .fontSize(15)
                      .fontColor(this.fsSelectedDistricts.length > 0 && this.fsMunicipalityDistricts().every(
                        (d: District) => this.fsIsSelected(this.fsSelectedDistricts, d.name)
                      ) ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
                      .backgroundColor(this.fsSelectedDistricts.length > 0 && this.fsMunicipalityDistricts().every(
                        (d: District) => this.fsIsSelected(this.fsSelectedDistricts, d.name)
                      ) ? '#2F8BE6' : 'transparent')
                      .borderRadius(8)
                      .padding({ top: 10, bottom: 10, left: 12, right: 12 })
                      .textAlign(TextAlign.Start)
                      .fontWeight(FontWeight.Bold)
                      .width('100%')
                      .onClick(() => {
                        this.fsToggleAllDistricts()
                      })
                  }
                  ForEach(this.fsMunicipalityDistricts(), (district: District) => {
                    ListItem() {
                      Row() {
                        Checkbox({ name: district.name })
                          .select(this.fsIsSelected(this.fsSelectedDistricts, district.name))
                          .selectedColor('#2F8BE6')
                          .shape(CheckBoxShape.ROUNDED_SQUARE)
                        Text(district.name)
                          .fontSize(15)
                          .margin({ left: 8 })
                      }
                      .width('100%')
                      .padding({ top: 6, bottom: 6, left: 12, right: 12 })
                      .onClick(() => {
                        this.fsToggleDistrict(district.name)
                      })
                    }
                  })
                }
                .layoutWeight(1)
              }

              // 区列表（选中的市）
              if (this.fsActiveCity) {
                List({ space: 4 }) {
                  ListItem() {
                    Text('全部')
                      .fontSize(15)
                      .fontColor(this.fsSelectedDistricts.length > 0 && this.fsDistrictOptions().every(
                        (d: District) => this.fsIsSelected(this.fsSelectedDistricts, d.name)
                      ) ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
                      .backgroundColor(this.fsSelectedDistricts.length > 0 && this.fsDistrictOptions().every(
                        (d: District) => this.fsIsSelected(this.fsSelectedDistricts, d.name)
                      ) ? '#2F8BE6' : 'transparent')
                      .borderRadius(8)
                      .padding({ top: 10, bottom: 10, left: 12, right: 12 })
                      .textAlign(TextAlign.Start)
                      .fontWeight(FontWeight.Bold)
                      .width('100%')
                      .onClick(() => {
                        this.fsToggleAllDistricts()
                      })
                  }
                  ForEach(this.fsDistrictOptions(), (district: District) => {
                    ListItem() {
                      Row() {
                        Checkbox({ name: district.name })
                          .select(this.fsIsSelected(this.fsSelectedDistricts, district.name))
                          .selectedColor('#2F8BE6')
                          .shape(CheckBoxShape.ROUNDED_SQUARE)
                        Text(district.name)
                          .fontSize(15)
                          .margin({ left: 8 })
                      }
                      .width('100%')
                      .padding({ top: 6, bottom: 6, left: 12, right: 12 })
                      .onClick(() => {
                        this.fsToggleDistrict(district.name)
                      })
                    }
                  })
                }
                .layoutWeight(1)
              }
            }
            .width('100%')
            .height(200)
          }
          .padding({ left: AppSpacing.SM })

          Divider()
            .height(0.5)
            .color(AppColors.BORDER)
            .margin({ top: 12, bottom: 12 })

          // ===== 类型区段 =====
          this.SectionHeader('职位类型')
          Column() {
            Row() {
              // 行业列表
              List({ space: 4 }) {
                ForEach(this.fields, (field: Field) => {
                  ListItem() {
                    Row() {
                      Text(field.name)
                        .fontSize(15)
                        .textAlign(TextAlign.Start)
                    }
                    .width('100%')
                    .padding({ top: 10, bottom: 10, left: 12, right: 12 })
                    .backgroundColor(this.fsIsSelected(this.fsSelectedFields, field.name) ? '#2F8BE6' : 'transparent')
                    .borderRadius(8)
                    .onClick(() => {
                      this.fsToggleField(field.name)
                    })
                    .stateStyles({
                      pressed: {
                        .opacity(0.7)
                      }
                    })
                  }
                })
              }
              .layoutWeight(1)

              // 岗位列表
              if (this.fsActiveField) {
                List({ space: 4 }) {
                  ListItem() {
                    Text('全部')
                      .fontSize(15)
                      .fontColor(this.fsSelectedOccupations.length > 0 && this.fsOccupationOptions().every(
                        (o: Occupation) => this.fsIsSelected(this.fsSelectedOccupations, o.name)
                      ) ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
                      .backgroundColor(this.fsSelectedOccupations.length > 0 && this.fsOccupationOptions().every(
                        (o: Occupation) => this.fsIsSelected(this.fsSelectedOccupations, o.name)
                      ) ? '#2F8BE6' : 'transparent')
                      .borderRadius(8)
                      .padding({ top: 10, bottom: 10, left: 12, right: 12 })
                      .textAlign(TextAlign.Start)
                      .fontWeight(FontWeight.Bold)
                      .width('100%')
                      .onClick(() => {
                        this.fsToggleAllOccupations()
                      })
                  }
                  ForEach(this.fsOccupationOptions(), (occupation: Occupation) => {
                    ListItem() {
                      Row() {
                        Checkbox({ name: occupation.name })
                          .select(this.fsIsSelected(this.fsSelectedOccupations, occupation.name))
                          .selectedColor('#2F8BE6')
                          .shape(CheckBoxShape.ROUNDED_SQUARE)
                        Text(occupation.name)
                          .fontSize(15)
                          .margin({ left: 8 })
                      }
                      .width('100%')
                      .padding({ top: 6, bottom: 6, left: 12, right: 12 })
                      .onClick(() => {
                        this.fsToggleOccupation(occupation.name)
                      })
                    }
                  })
                }
                .layoutWeight(1)
              }
            }
            .width('100%')
            .height(180)
          }
          .padding({ left: AppSpacing.SM })
        }
        .width('100%')
        .padding({ bottom: AppSpacing.MD })
      }
      .layoutWeight(1)

      // 底部确定按钮
      Button('确定')
        .width('100%')
        .height(48)
        .backgroundColor(AppColors.PRIMARY)
        .fontColor('#FFFFFF')
        .fontSize(AppFontSize.MD)
        .fontWeight(FontWeight.Medium)
        .borderRadius(AppRadius.LG)
        .margin({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.MD })
        .onClick(() => {
          this.applySheetFilters()
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder TabLabel(label: string, index: number) {
    Text(label)
      .fontSize(16)
      .fontColor(this.selectedTabIndex === index ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
      .fontWeight(this.selectedTabIndex === index ? FontWeight.Bold : FontWeight.Regular)
      .padding({ bottom: 6 })
      .animation({
        duration: 250,
        curve: 'cubic-bezier(0.2, 0, 0, 1.0)'
      })
  }

  @Builder tabFullTime() {
    this.TabLabel('全职', 0)
  }

  @Builder tabPartTime() {
    this.TabLabel('兼职', 1)
  }

  @Builder tabIntern() {
    this.TabLabel('实习', 2)
  }

  build() {
    Column() {
      // === 顶部栏 ===
      Row() {
        Text('发现职位')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Blank()
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(22)
          .fontColor([AppColors.TEXT_MUTED])
          .onClick(() => {
            router.pushUrl({ url: 'pages/SearchPage' })
          })
          .stateStyles({
            pressed: {
              .scale({ x: 0.9, y: 0.9 })
            }
          })
          .animation({ duration: 150 })
      }
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.XS })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#D1FFFFFF')
      .backgroundBlurStyle(BlurStyle.Regular)

      // === 筛选芯片栏 ===
      FilterBar({
        salaryMin: this.salaryMin,
        salaryMax: this.salaryMax,
        selectedSalaryUnit: this.selectedSalaryUnit,
        includeNegotiable: this.includeNegotiable,
        selectedRegion: this.selectedRegion,
        selectedType: this.selectedType,
        onShowSheet: () => { this.showFilterSheet = true },
        onClearSalary: () => { this.salaryMin = 0; this.salaryMax = 0; this.selectedSalaryUnit = -1; this.includeNegotiable = true; this.resetAllTabs() },
        onClearRegion: () => { this.selectedRegion = []; this.resetAllTabs() },
        onClearType: () => { this.selectedType = []; this.resetAllTabs() }
      })

      // === Tabs 三页面（带下拉刷新） ===
      Tabs({ barPosition: BarPosition.Start }) {
        TabContent() {
          JobFeedList({
            jobType: 1,
            tabData: this.tabData,
            loadMore: (jt: number) => this.loadMoreForTab(jt),
            onRefresh: (jt: number) => { this.loadTabData(jt, false) }
          })
        }
        .tabBar(this.tabFullTime)

        TabContent() {
          JobFeedList({
            jobType: 2,
            tabData: this.tabData,
            loadMore: (jt: number) => this.loadMoreForTab(jt),
            onRefresh: (jt: number) => { this.loadTabData(jt, false) }
          })
        }
        .tabBar(this.tabPartTime)

        TabContent() {
          JobFeedList({
            jobType: 3,
            tabData: this.tabData,
            loadMore: (jt: number) => this.loadMoreForTab(jt),
            onRefresh: (jt: number) => { this.loadTabData(jt, false) }
          })
        }
        .tabBar(this.tabIntern)
      }
      .scrollable(true)
      .layoutWeight(1)
      .width('100%')
      .animationDuration(300)
      .onChange((index: number) => {
        this.selectedTabIndex = index
        this.onTabChange(index)
      })
      .barMode(BarMode.Fixed)
      .backgroundColor('#FFFFFF')
      .backgroundBlurStyle(BlurStyle.Thin)
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [['rgba(23,98,251,0.03)', 0.0], ['#ffffff', 1.0]]
    })
    .padding({ top: AppSpacing.XS })
    .bindSheet($$this.showFilterSheet, this.FilterSheetBuilder(), {
      height: SheetSize.LARGE,
      dragBar: true,
      showClose: true,
      backgroundColor: '#F5F5F5'
    })
  }
}

// JobCard 兼容包装组件 — 供其他页面（SubmittedPage / FavoritesPage / SearchResultsPage）导入使用
@Component
export struct JobCard {
  @Prop job: JobData = {
    id: '', title: '', company: '', salary: '',
    salaryMid: 0, popularity: 0, region: '',
    type: '', category: '', description: '',
    enterpriseId: 0, categoryId: 0, regionId: 0,
    salaryMin: 0, salaryMax: 0, salaryUnit: 0,
    jobType: 0, status: 0, hasApplied: false,
    applicationId: 0,
    tag: [], remainingQuota: 0,
    hrName: '', hrAvatar: '',
    enterpriseName: '', totalQuota: 0, address: '', deadline: '',
    applicationCount: 0, hasFavorited: false
  }

  build() {
    JobFeedCard({ job: this.job })
  }
}
