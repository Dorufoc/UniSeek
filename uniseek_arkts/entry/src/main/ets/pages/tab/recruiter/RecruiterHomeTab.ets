import { router } from '@kit.ArkUI';
import { DataService, Province, City, District, Field, Occupation } from '../../../services/DataService';
import { ResumeCardData } from '../../../services/RecruiterTypes';
import { ResumeService, ResumeData } from '../../../services/ResumeService';
import { AppColors, AppSpacing, AppRadius, AppFontSize, AppShadow, AppAnimation } from '../../../common/AppStyles';

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

@Component
struct ResumeCard {
  resume: ResumeCardData = {
    id: '', name: '', age: 0, avatar: '', education: '', school: '',
    major: '', experience: '', skills: '', region: '',
    type: '', category: '', expectedSalary: '', description: ''
  }

  build() {
    Row() {
      Column() {
        Row() {
          Text(this.resume.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')

          Text(this.resume.age + '岁')
            .fontSize(14)
            .fontColor(AppColors.TEXT_SECONDARY)
            .margin({ left: 8 })
        }
        .alignItems(VerticalAlign.Center)

        Text(this.resume.school + ' · ' + this.resume.major)
          .fontSize(14)
          .fontColor(AppColors.TEXT_SECONDARY)
          .margin({ top: 4 })

        Text(this.resume.education + ' · ' + this.resume.experience)
          .fontSize(13)
          .fontColor(AppColors.TEXT_MUTED)
          .margin({ top: 4 })

        Row() {
          Text(this.resume.region)
            .fontSize(12)
            .fontColor(AppColors.TEXT_MUTED)
            .backgroundColor(AppColors.INPUT_BG)
            .borderRadius(4)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          Text(this.resume.type)
            .fontSize(12)
            .fontColor(AppColors.TEXT_MUTED)
            .backgroundColor(AppColors.INPUT_BG)
            .borderRadius(4)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .margin({ left: 8 })
        }
        .margin({ top: 8 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column() {
        Text('期望薪资')
          .fontSize(11)
          .fontColor('#BBBBBB')

        Text(this.resume.expectedSalary)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.WARNING)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius(12)
    .shadow({ radius: 4, color: '#0D000000', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/ResumeDetailPage',
        params: { resumeData: JSON.stringify(this.resume) }
      })
    })
    .stateStyles({
      pressed: {
        .backgroundColor(AppColors.SELECTED_BG)
      }
    })
  }
}

@Component
export struct RecruiterHomeTab {
  @State selectedRegion: string[] = []
  @State selectedType: string[] = []
  @State filteredResumes: ResumeCardData[] = []

  aboutToAppear(): void {
    this.loadResumes()
  }

  async loadResumes(): Promise<void> {
    try {
      const result = await ResumeService.searchPublishedResumes(undefined, 1, 100)
      this.allResumes = result.records.map((r: ResumeData) => ({
        id: String(r.id),
        name: r.realName || '',
        age: 0,
        avatar: '',
        education: r.education || '',
        school: r.school || '',
        major: '',
        experience: '',
        skills: r.skills || '',
        region: '',
        type: '',
        category: '',
        expectedSalary: '',
        description: r.experience || ''
      } as ResumeCardData))
    } catch {
    }
    this.applyFilters()
  }

  @State allResumes: ResumeCardData[] = []

  private applyFilters(): void {
    let result = this.allResumes.filter(resume => {
      if (this.selectedRegion.length > 0 && !this.selectedRegion.some(r => resume.region.startsWith(r))) return false
      if (this.selectedType.length > 0 && !this.selectedType.some(t => resume.type.startsWith(t))) return false
      return true
    })

    this.filteredResumes = result
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

  build() {
    Column() {
      Row() {
        Text('如果你想要，就自己来找')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)

        Row() {
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontSize(18)
            .fontColor([AppColors.TEXT_MUTED])
          Text('搜索')
            .fontSize(14)
            .fontColor(AppColors.TEXT_MUTED)
            .margin({ left: 6 })
        }
        .height(36)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(18)
        .padding({ left: 12, right: 16 })
        .alignItems(VerticalAlign.Center)
        .onClick(() => { router.pushUrl({ url: 'pages/RecruiterSearchPage' }) })
        .stateStyles({
          pressed: {
            .backgroundColor(AppColors.SELECTED_BG)
          }
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      Row() {
        Row() {
          Text(this.selectedRegion.length > 0 ? this.compactLabel(this.selectedRegion) : '区域')
            .fontSize(13)
            .fontColor(this.selectedRegion.length > 0 ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
        }
        .height(32)
        .backgroundColor(this.selectedRegion.length > 0 ? AppColors.SELECTED_BG : AppColors.INPUT_BG)
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .margin({ right: 6 })
        .onClick(() => { this.showRegionDialog() })
        .stateStyles({
          pressed: {
            .backgroundColor(AppColors.SELECTED_BG)
          }
        })

        Row() {
          Text(this.selectedType.length > 0 ? this.compactLabel(this.selectedType) : '类型')
            .fontSize(13)
            .fontColor(this.selectedType.length > 0 ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
        }
        .height(32)
        .backgroundColor(this.selectedType.length > 0 ? AppColors.SELECTED_BG : AppColors.INPUT_BG)
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .onClick(() => { this.showTypeDialog() })
        .stateStyles({
          pressed: {
            .backgroundColor(AppColors.SELECTED_BG)
          }
        })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })

      List() {
        ForEach(this.filteredResumes, (resume: ResumeCardData) => {
          ListItem() {
            ResumeCard({ resume: resume })
          }
          .transition(TransitionEffect.asymmetric(
            TransitionEffect.opacity(0).combine(TransitionEffect.translate({ y: 20 })),
            TransitionEffect.opacity(1)
          ))
        }, (resume: ResumeCardData) => resume.id)
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 12, right: 12, top: 4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
    .padding({ top: 12 })
  }
}