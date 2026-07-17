import { router } from '@kit.ArkUI';
import { ApiClient } from '../../../services/ApiClient';
import { DataService, Province, City, District, Field, Occupation } from '../../../services/DataService';
import { JobData, TaskVO, mapTaskToJobData } from '../../../services/ChatTypes';
import { PageResult } from '../../../services/ResumeService';
import { SALARY_UNIT_LABELS } from '../../../services/RecruiterTypes';

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
          .fontColor('#999999')
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
                .fontColor(this.isSelected(this.selectedProvinces, province.name) ? '#FFFFFF' : '#333333')
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
                ) ? '#FFFFFF' : '#333333')
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
                  .fontColor(this.isSelected(this.selectedCities, city.name) ? '#FFFFFF' : '#333333')
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
                ) ? '#FFFFFF' : '#333333')
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
                  .fontColor(this.isSelected(this.selectedDistricts, district.name) ? '#FFFFFF' : '#333333')
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
                ) ? '#FFFFFF' : '#333333')
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
                  .fontColor(this.isSelected(this.selectedDistricts, district.name) ? '#FFFFFF' : '#333333')
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
          .backgroundColor('#007AFF')
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
    .height('60%')
    .backgroundColor('#FFFFFF')
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
          .fontColor('#999999')
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
                .fontColor(this.isSelected(this.selectedFields, field.name) ? '#FFFFFF' : '#333333')
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
                ) ? '#FFFFFF' : '#333333')
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
                  .fontColor(this.isSelected(this.selectedOccupations, occupation.name) ? '#FFFFFF' : '#333333')
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
          .backgroundColor('#007AFF')
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
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}

@CustomDialog
struct SalaryDialog {
  controller?: CustomDialogController
  selectedUnit: number = -1
  onConfirm?: (min: number, max: number, unit: number) => void
  onCancel?: () => void

  @State minText: string = ''
  @State maxText: string = ''
  @State currentUnit: number = -1

  aboutToAppear(): void {
    this.currentUnit = this.selectedUnit
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
          .fontColor('#999999')
          .onClick(() => { this.onCancel?.() })
      }
      .width('100%')
      .padding({ bottom: 16 })

      TextInput({ placeholder: '最低薪资(元)', text: this.minText })
        .onChange((value: string) => { this.minText = value })
        .width('100%')
        .height(44)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .margin({ bottom: 12 })

      TextInput({ placeholder: '最高薪资(元)', text: this.maxText })
        .onChange((value: string) => { this.maxText = value })
        .width('100%')
        .height(44)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .margin({ bottom: 16 })

      Text('薪资类型')
        .fontSize(15)
        .fontColor('#333333')
        .width('100%')
        .margin({ bottom: 10 })

      Row() {
        Text('日结')
          .fontSize(14)
          .fontColor(this.currentUnit === 0 ? '#FFFFFF' : '#666666')
          .backgroundColor(this.currentUnit === 0 ? '#007AFF' : '#F5F5F5')
          .borderRadius(16)
          .padding({ left: 20, right: 20, top: 8, bottom: 8 })
          .onClick(() => { this.currentUnit = this.currentUnit === 0 ? -1 : 0 })

        Text('时薪')
          .fontSize(14)
          .fontColor(this.currentUnit === 1 ? '#FFFFFF' : '#666666')
          .backgroundColor(this.currentUnit === 1 ? '#007AFF' : '#F5F5F5')
          .borderRadius(16)
          .padding({ left: 20, right: 20, top: 8, bottom: 8 })
          .onClick(() => { this.currentUnit = this.currentUnit === 1 ? -1 : 1 })

        Text('月结')
          .fontSize(14)
          .fontColor(this.currentUnit === 2 ? '#FFFFFF' : '#666666')
          .backgroundColor(this.currentUnit === 2 ? '#007AFF' : '#F5F5F5')
          .borderRadius(16)
          .padding({ left: 20, right: 20, top: 8, bottom: 8 })
          .onClick(() => { this.currentUnit = this.currentUnit === 2 ? -1 : 2 })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ bottom: 16 })

      Row() {
        Row().layoutWeight(1)
        Text('确定')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .borderRadius(20)
          .padding({ left: 28, right: 28, top: 10, bottom: 10 })
          .onClick(() => {
            const min = parseInt(this.minText) || 0
            const max = parseInt(this.maxText) || 0
            this.onConfirm?.(min, max, this.currentUnit)
          })
      }
      .width('100%')
      .padding({ top: 8 })
    }
    .padding(20)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}

@Component
export struct JobCard {
  job: JobData = {
    id: '', title: '', company: '', salary: '',
    salaryMid: 0, popularity: 0, region: '',
    type: '', category: '', description: '',
    enterpriseId: 0, categoryId: 0, regionId: 0,
    salaryMin: 0, salaryMax: 0, salaryUnit: 0,
    jobType: 0, status: 0, hasApplied: false,
    applicationId: 0,
    tag: [], remainingQuota: 0,
    hrName: '', hrAvatar: ''
  }

  build() {
    Row() {
      Column() {
        Text(this.job.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
        Text(this.job.company)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 6 })
        Row() {
          Text(SALARY_UNIT_LABELS[this.job.salaryUnit] ?? '月薪')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#007AFF')
            .borderRadius(4)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          if (this.job.tag) {
            ForEach(this.job.tag, (tag: string) => {
              Text(tag)
                .fontSize(12)
                .fontColor('#999999')
                .backgroundColor('#F5F5F5')
                .borderRadius(4)
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .margin({ left: 8 })
            }, (tag: string) => tag)
          }
        }
        .margin({ top: 8 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column() {
        Text(this.job.salary)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#007AFF')
        Text('剩余:' + this.job.remainingQuota)
          .fontSize(12)
          .fontColor('#BBBBBB')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: '#0D000000', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/JobDetailPage',
        params: { jobData: JSON.stringify(this.job) }
      })
    })
  }
}

@Component
export struct HomePage {
  @State activeCategory: string = '全职'
  @State popSort: string = 'none'
  @State salaryMin: number = 0
  @State salaryMax: number = 0
  @State selectedSalaryUnit: number = -1
  @State selectedRegion: string[] = []
  @State selectedType: string[] = []
  @State allJobs: JobData[] = []
  @State filteredJobs: JobData[] = []
  @State currentPage: number = 1
  @State totalPages: number = 1
  @State isLoadingMore: boolean = false

  aboutToAppear(): void {
    this.loadJobs()
  }

  async loadJobs(): Promise<void> {
    try {
      const result = await ApiClient.get<PageResult<TaskVO>>('/api/tasks', [['page', '1'], ['pageSize', '100']])
      this.currentPage = 1
      this.totalPages = result.totalPages
      this.allJobs = result.records.map((task: TaskVO) => mapTaskToJobData(task))
      this.applyFilters()
      this.loadRemainingPages()
    } catch (e) {
      console.error('加载职位列表失败', e)
    }
  }

  async loadRemainingPages(): Promise<void> {
    for (let page = 2; page <= this.totalPages; page++) {
      if (page <= this.currentPage) continue
      try {
        const result = await ApiClient.get<PageResult<TaskVO>>('/api/tasks', [['page', String(page)], ['pageSize', '100']])
        const newJobs = result.records.map((task: TaskVO) => mapTaskToJobData(task))
        this.allJobs = this.allJobs.concat(newJobs)
        this.currentPage = page
        this.applyFilters()
      } catch (e) {
        console.error('加载剩余职位失败', e)
      }
    }
  }

  async loadMoreJobs(): Promise<void> {
    if (this.isLoadingMore || this.currentPage >= this.totalPages) return
    this.isLoadingMore = true
    try {
      const nextPage = this.currentPage + 1
      const result = await ApiClient.get<PageResult<TaskVO>>('/api/tasks', [['page', String(nextPage)], ['pageSize', '100']])
      const newJobs = result.records.map((task: TaskVO) => mapTaskToJobData(task))
      this.allJobs = this.allJobs.concat(newJobs)
      this.currentPage = nextPage
      this.applyFilters()
    } catch (e) {
      console.error('加载更多职位失败', e)
    } finally {
      this.isLoadingMore = false
    }
  }

  private applyFilters(): void {
    let result = this.allJobs.filter(job => {
      if (job.category !== this.activeCategory) return false
      if (this.selectedRegion.length > 0 && !this.selectedRegion.some(r => job.region.startsWith(r))) return false
      if (this.selectedType.length > 0 && !this.selectedType.some(t => job.type.startsWith(t))) return false
      if (this.salaryMin > 0 && job.salaryMid < this.salaryMin) return false
      if (this.salaryMax > 0 && job.salaryMid > this.salaryMax) return false
      if (this.selectedSalaryUnit >= 0 && job.salaryUnit !== this.selectedSalaryUnit) return false
      if (job.status === 0 || job.status === 3 || job.status === 4) return false
      return true
    })

    if (this.popSort === 'asc') {
      result.sort((a, b) => a.popularity - b.popularity)
    } else if (this.popSort === 'desc') {
      result.sort((a, b) => b.popularity - a.popularity)
    }

    this.filteredJobs = result
  }

  private nextSort(current: string): string {
    if (current === 'none') return 'asc'
    if (current === 'asc') return 'desc'
    return 'none'
  }

  private sortLabel(sort: string): string {
    if (sort === 'asc') return ' ↑'
    if (sort === 'desc') return ' ↓'
    return ''
  }

  private compactLabel(list: string[]): string {
    if (list.length === 0) return ''
    if (list.length === 1) {
      const parts = list[0].split('-')
      return parts[parts.length - 1]
    }
    return list[0] + '等' + list.length + '项'
  }

  private showRegionDialog(): void {
    let dialog = new CustomDialogController({
      builder: RegionPickerDialog({
        onSelect: (results: string[]) => {
          this.selectedRegion = results
          this.applyFilters()
          dialog.close()
        },
        onCancel: () => {
          dialog.close()
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Bottom
    })
    dialog.open()
  }

  private showTypeDialog(): void {
    let dialog = new CustomDialogController({
      builder: TypePickerDialog({
        onSelect: (results: string[]) => {
          this.selectedType = results
          this.applyFilters()
          dialog.close()
        },
        onCancel: () => {
          dialog.close()
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Bottom
    })
    dialog.open()
  }

  private showSalaryDialog(): void {
    let dialog = new CustomDialogController({
      builder: SalaryDialog({
        selectedUnit: this.selectedSalaryUnit,
        onConfirm: (min: number, max: number, unit: number) => {
          this.salaryMin = min
          this.salaryMax = max
          this.selectedSalaryUnit = unit
          this.applyFilters()
          dialog.close()
        },
        onCancel: () => {
          dialog.close()
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Bottom
    })
    dialog.open()
  }

  private salaryLabel(): string {
    let parts: string[] = []
    if (this.salaryMin > 0 && this.salaryMax > 0) parts.push(this.salaryMin + '-' + this.salaryMax + '元')
    else if (this.salaryMin > 0) parts.push('≥' + this.salaryMin + '元')
    else if (this.salaryMax > 0) parts.push('≤' + this.salaryMax + '元')
    if (this.selectedSalaryUnit >= 0) parts.push(SALARY_UNIT_LABELS[this.selectedSalaryUnit])
    return parts.join('/')
  }

  build() {
    Column() {
      Row() {
        Text('如果你想要，就自己来找')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)

        Row() {
          Image($r('app.media.search'))
            .width(18)
            .height(18)
            .fillColor('#999999')
          Text('搜索')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ left: 6 })
        }
        .height(36)
        .backgroundColor('#F5F5F5')
        .borderRadius(18)
        .padding({ left: 12, right: 16 })
        .alignItems(VerticalAlign.Center)
        .onClick(() => { router.pushUrl({ url: 'pages/SearchPage' }) })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      Row() {
        ForEach(['全职', '实习', '兼职'], (category: string) => {
          Text(category)
            .fontSize(16)
            .fontColor(this.activeCategory === category ? '#333333' : '#999999')
            .fontWeight(this.activeCategory === category ? FontWeight.Bold : FontWeight.Regular)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .height(40)
            .onClick(() => {
              this.activeCategory = category
              this.applyFilters()
            })
        })
      }
      .width('100%')
      .margin({ top: 4 })

      Row() {
        Row() {
          Text('热度' + this.sortLabel(this.popSort))
            .fontSize(13)
            .fontColor(this.popSort !== 'none' ? '#007AFF' : '#666666')
        }
        .height(32)
        .backgroundColor(this.popSort !== 'none' ? '#EBF5FF' : '#F5F5F5')
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .margin({ right: 6 })
        .onClick(() => { this.popSort = this.nextSort(this.popSort); this.applyFilters() })

        Row() {
          Text(this.salaryMin > 0 || this.salaryMax > 0 || this.selectedSalaryUnit >= 0 ? this.salaryLabel() : '薪资')
            .fontSize(13)
            .fontColor(this.salaryMin > 0 || this.salaryMax > 0 || this.selectedSalaryUnit >= 0 ? '#007AFF' : '#666666')
        }
        .height(32)
        .backgroundColor(this.salaryMin > 0 || this.salaryMax > 0 || this.selectedSalaryUnit >= 0 ? '#EBF5FF' : '#F5F5F5')
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .margin({ right: 6 })
        .onClick(() => { this.showSalaryDialog() })

        Row() {
          Text(this.selectedRegion.length > 0 ? this.compactLabel(this.selectedRegion) : '区域')
            .fontSize(13)
            .fontColor(this.selectedRegion.length > 0 ? '#007AFF' : '#666666')
        }
        .height(32)
        .backgroundColor(this.selectedRegion.length > 0 ? '#EBF5FF' : '#F5F5F5')
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .margin({ right: 6 })
        .onClick(() => { this.showRegionDialog() })

        Row() {
          Text(this.selectedType.length > 0 ? this.compactLabel(this.selectedType) : '类型')
            .fontSize(13)
            .fontColor(this.selectedType.length > 0 ? '#007AFF' : '#666666')
        }
        .height(32)
        .backgroundColor(this.selectedType.length > 0 ? '#EBF5FF' : '#F5F5F5')
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .onClick(() => { this.showTypeDialog() })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })

      List() {
        ForEach(this.filteredJobs, (job: JobData) => {
          ListItem() {
            JobCard({ job: job })
          }
        }, (job: JobData) => job.id)

        if (this.isLoadingMore) {
          ListItem() {
            Row() {
              LoadingProgress().width(24).height(24)
              Text('加载中...').fontSize(14).fontColor('#999999').margin({ left: 8 })
            }.width('100%').justifyContent(FlexAlign.Center).padding(16)
          }
        } else if (this.currentPage >= this.totalPages && this.allJobs.length > 0) {
          ListItem() {
            Text('没有更多了').fontSize(14).fontColor('#999999')
              .width('100%').textAlign(TextAlign.Center).padding(16)
          }
        }
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 12, right: 12, top: 4 })
      .onReachEnd(() => { this.loadMoreJobs() })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
    .padding({ top: 12 })
  }
}
