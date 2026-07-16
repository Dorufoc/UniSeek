import { router } from '@kit.ArkUI';
import { DataService, Province, City, District, Field, Occupation } from '../../../services/DataService';
import { ResumeCardData } from '../../../services/RecruiterTypes';

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
            .fontColor('#666666')
            .margin({ left: 8 })
        }
        .alignItems(VerticalAlign.Center)

        Text(this.resume.school + ' · ' + this.resume.major)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 4 })

        Text(this.resume.education + ' · ' + this.resume.experience)
          .fontSize(13)
          .fontColor('#999999')
          .margin({ top: 4 })

        Row() {
          Text(this.resume.region)
            .fontSize(12)
            .fontColor('#999999')
            .backgroundColor('#F5F5F5')
            .borderRadius(4)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          Text(this.resume.type)
            .fontSize(12)
            .fontColor('#999999')
            .backgroundColor('#F5F5F5')
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
          .fontColor('#FF6B35')
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
        url: 'pages/ResumeDetailPage',
        params: { resumeData: JSON.stringify(this.resume) }
      })
    })
  }
}

@Component
export struct RecruiterHomeTab {
  @State selectedRegion: string[] = []
  @State selectedType: string[] = []
  @State filteredResumes: ResumeCardData[] = []

  aboutToAppear(): void {
    this.applyFilters()
  }

  allResumes: ResumeCardData[] = [
    { id: '1', name: '张明', age: 24, avatar: '', education: '本科', school: '北京大学', major: '计算机科学与技术', experience: '2年经验', skills: 'Vue, React, TypeScript', region: '北京-海淀区', type: '互联网/IT-前端工程师', category: '全职', expectedSalary: '20k-30k', description: '2年前端开发经验，熟悉主流前端框架，有大型项目开发经验。' },
    { id: '2', name: '李华', age: 26, avatar: '', education: '硕士', school: '浙江大学', major: '软件工程', experience: '3年经验', skills: 'Java, Spring Cloud, MySQL', region: '浙江-杭州-西湖区', type: '互联网/IT-后端工程师', category: '全职', expectedSalary: '25k-35k', description: '3年后端开发经验，熟悉微服务架构，有高并发系统设计经验。' },
    { id: '3', name: '王芳', age: 23, avatar: '', education: '本科', school: '中国美术学院', major: '视觉传达设计', experience: '1年经验', skills: 'Figma, Sketch, Photoshop', region: '广东-深圳-南山区', type: '互联网/IT-UI设计师', category: '全职', expectedSalary: '15k-22k', description: '1年UI设计经验，擅长移动端和Web端界面设计。' },
    { id: '4', name: '赵雷', age: 21, avatar: '', education: '本科', school: '华中科技大学', major: '统计学', experience: '应届生', skills: 'Python, SQL, Excel', region: '北京-朝阳区', type: '互联网/IT-数据分析师', category: '实习', expectedSalary: '4k-6k', description: '在校期间参与多个数据分析项目，熟练使用Python进行数据处理。' },
    { id: '5', name: '陈雪', age: 27, avatar: '', education: '硕士', school: '复旦大学', major: '金融学', experience: '4年经验', skills: 'CFA, 风险管理, 产品设计', region: '上海-浦东新区', type: '金融-金融产品经理', category: '全职', expectedSalary: '28k-40k', description: '4年金融产品经验，负责过多个零售金融产品线的规划与落地。' },
    { id: '6', name: '刘洋', age: 22, avatar: '', education: '本科', school: '华南师范大学', major: '数学与应用数学', experience: '应届生', skills: '数学分析, 逻辑思维, 沟通能力', region: '广东-广州-天河区', type: '教育-教师', category: '兼职', expectedSalary: '6k-10k', description: '有家教经验，耐心细致，擅长初中数学教学。' },
    { id: '7', name: '孙婷', age: 23, avatar: '', education: '硕士', school: '浙江大学', major: '计算机技术', experience: '应届生', skills: 'Java, Python, 数据结构', region: '浙江-杭州-滨江区', type: '互联网/IT-后端工程师', category: '实习', expectedSalary: '5k-8k', description: '在校成绩优异，有企业实习经历，学习能力强。' },
    { id: '8', name: '周杰', age: 28, avatar: '', education: '博士', school: '上海交通大学', major: '药学', experience: '3年经验', skills: 'GCP, 临床研究, 数据分析', region: '上海-静安区', type: '医疗-临床研究协调员', category: '全职', expectedSalary: '18k-28k', description: '3年临床研究经验，熟悉GCP规范，有多个临床试验项目管理经验。' },
    { id: '9', name: '吴迪', age: 21, avatar: '', education: '本科', school: '武汉大学', major: '计算机科学与技术', experience: '应届生', skills: 'HTML, CSS, JavaScript, React', region: '北京-海淀区', type: '互联网/IT-前端工程师', category: '实习', expectedSalary: '4k-7k', description: '熟练掌握前端基础技术栈，有个人项目作品。' },
    { id: '10', name: '郑欣', age: 25, avatar: '', education: '本科', school: '中山大学', major: '市场营销', experience: '2年经验', skills: '市场调研, 活动策划, 数据分析', region: '广东-广州-天河区', type: '消费品-市场营销', category: '全职', expectedSalary: '12k-18k', description: '2年快消品市场营销经验，熟悉线上线下营销活动策划与执行。' },
    { id: '11', name: '黄磊', age: 29, avatar: '', education: '硕士', school: '同济大学', major: '土木工程', experience: '5年经验', skills: 'AutoCAD, 项目管理, 施工管理', region: '广东-深圳-福田区', type: '房地产-土建工程师', category: '全职', expectedSalary: '18k-28k', description: '5年土建工程经验，持有注册建造师证书，有大型项目现场管理经验。' },
    { id: '12', name: '林悦', age: 20, avatar: '', education: '本科', school: '中国传媒大学', major: '网络与新媒体', experience: '应届生', skills: '内容策划, 视频剪辑, 社区运营', region: '北京-海淀区', type: '传媒-新媒体运营', category: '实习', expectedSalary: '3k-5k', description: '熟悉各大社交媒体平台运营，有短视频内容创作经验。' }
  ]

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
        .onClick(() => { router.pushUrl({ url: 'pages/RecruiterSearchPage' }) })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      Row() {
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
        ForEach(this.filteredResumes, (resume: ResumeCardData) => {
          ListItem() {
            ResumeCard({ resume: resume })
          }
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