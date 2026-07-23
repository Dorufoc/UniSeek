import { router } from '@kit.ArkUI';
import { ApiClient } from '../../../services/ApiClient';
import { DataService, Province, City, District, Field, Occupation } from '../../../services/DataService';
import { JobData, TaskVO, TaskSearchParams, mapTaskToJobData } from '../../../services/ChatTypes';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../../../common/AppStyles';
import { FilterBar } from './FilterBar';
import { JobFeedList } from './JobFeedList';
import { JobFeedCard } from './JobFeedCard';
import { TabDataState } from './JobFeedTypes'

interface FilterState {
  salaryMin: number
  salaryMax: number
  regionId: number
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
    1: { jobs: [], page: 1, hasMore: true, loading: false, errorText: '' },
    2: { jobs: [], page: 1, hasMore: true, loading: false, errorText: '' },
    3: { jobs: [], page: 1, hasMore: true, loading: false, errorText: '' }
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
      loading: true,
      errorText: ''
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
        loading: false,
        errorText: ''
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
        loading: false,
        errorText: '职位列表加载失败，请检查网络后重试'
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
      1: { jobs: [], page: 1, hasMore: true, loading: false, errorText: '' },
      2: { jobs: [], page: 1, hasMore: true, loading: false, errorText: '' },
      3: { jobs: [], page: 1, hasMore: true, loading: false, errorText: '' }
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
        Button('重置', { type: ButtonType.Capsule })
          .height(32)
          .fontSize(AppFontSize.SM)
          .fontColor(AppColors.TEXT_MUTED)
          .backgroundColor(AppColors.INPUT_BG)
          .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
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
                .backgroundColor(this.filterSalaryUnit === 0 ? AppColors.PRIMARY : AppColors.INPUT_BG)
                .fontColor(this.filterSalaryUnit === 0 ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
                .fontSize(AppFontSize.SM)
                .height(36)
                .onClick(() => {
                  this.filterSalaryUnit = this.filterSalaryUnit === 0 ? -1 : 0
                })
              Button('时薪')
                .type(ButtonType.Capsule)
                .backgroundColor(this.filterSalaryUnit === 1 ? AppColors.PRIMARY : AppColors.INPUT_BG)
                .fontColor(this.filterSalaryUnit === 1 ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
                .fontSize(AppFontSize.SM)
                .height(36)
                .onClick(() => {
                  this.filterSalaryUnit = this.filterSalaryUnit === 1 ? -1 : 1
                })
              Button('月结')
                .type(ButtonType.Capsule)
                .backgroundColor(this.filterSalaryUnit === 2 ? AppColors.PRIMARY : AppColors.INPUT_BG)
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
                        .fontColor(this.fsIsSelected(this.fsSelectedProvinces, province.name) ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
                        .textAlign(TextAlign.Start)
                    }
                    .width('100%')
                    .padding({ top: 10, bottom: 10, left: 12, right: 12 })
                    .backgroundColor(this.fsIsSelected(this.fsSelectedProvinces, province.name) ? AppColors.PRIMARY : 'transparent')
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
                }, (province: Province) => province.name)
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
                      ) ? AppColors.PRIMARY : 'transparent')
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
                          .selectedColor(AppColors.PRIMARY)
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
                  }, (city: City) => city.name)
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
                      ) ? AppColors.PRIMARY : 'transparent')
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
                          .selectedColor(AppColors.PRIMARY)
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
                  }, (district: District) => district.name)
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
                      ) ? AppColors.PRIMARY : 'transparent')
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
                          .selectedColor(AppColors.PRIMARY)
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
                  }, (district: District) => district.name)
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
                        .fontColor(this.fsIsSelected(this.fsSelectedFields, field.name) ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
                        .textAlign(TextAlign.Start)
                    }
                    .width('100%')
                    .padding({ top: 10, bottom: 10, left: 12, right: 12 })
                    .backgroundColor(this.fsIsSelected(this.fsSelectedFields, field.name) ? AppColors.PRIMARY : 'transparent')
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
                }, (field: Field) => field.name)
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
                      ) ? AppColors.PRIMARY : 'transparent')
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
                          .selectedColor(AppColors.PRIMARY)
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
                  }, (occupation: Occupation) => occupation.name)
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
    .backgroundColor(AppColors.BG_PAGE)
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
        Button({ type: ButtonType.Capsule }) {
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontSize(20)
            .fontColor([AppColors.TEXT_SECONDARY])
        }
        .width(40)
        .height(40)
        .backgroundColor(AppColors.INPUT_BG)
        .accessibilityText('搜索职位')
        .onClick((): void => { router.pushUrl({ url: 'pages/SearchPage' }) })
      }
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.XS })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(AppColors.BG_PAGE)

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
      .backgroundColor(AppColors.BG_PAGE)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
    .padding({ top: AppSpacing.XS })
    .bindSheet($$this.showFilterSheet, this.FilterSheetBuilder(), {
      height: SheetSize.LARGE,
      dragBar: true,
      showClose: true,
      backgroundColor: AppColors.BG_CARD
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
