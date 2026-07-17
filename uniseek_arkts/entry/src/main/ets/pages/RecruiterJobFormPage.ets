import { router } from '@kit.ArkUI';
import { RecruiterService } from '../services/RecruiterService';
import { RecruiterJobRequest } from '../services/RecruiterTypes';

interface PickerOption {
  value: number
  label: string
}

const SALARY_UNIT_OPTIONS: PickerOption[] = [
  { value: 0, label: '日薪' },
  { value: 1, label: '时薪' },
  { value: 2, label: '月薪' }
]

const JOB_TYPE_OPTIONS: PickerOption[] = [
  { value: 1, label: '全职' },
  { value: 2, label: '兼职' },
  { value: 3, label: '实习' }
]

@Entry
@Component
struct RecruiterJobFormPage {
  @State title: string = ''
  @State salaryMin: string = ''
  @State salaryMax: string = ''
  @State salaryUnit: number = 0
  @State jobType: number = 1
  @State totalQuota: string = ''
  @State address: string = ''
  @State tag: string = ''
  @State deadline: string = ''

  aboutToAppear(): void {
    RecruiterService.getEnterpriseInfo().then((info) => {
      if (info && info.auditStatus !== 1) {
        this.getUIContext().showAlertDialog({
          message: '企业资质审核未通过，暂无法发布职位',
          confirm: { value: '确定', action: () => {} },
          autoCancel: true
        })
        router.back()
      }
    })
  }

  build() {
    Column() {
      this.topBar()

      Scroll() {
        Column() {
          this.sectionTitle('基本信息')

          this.inputField('职位标题', this.title, (v: string) => { this.title = v })

          Row() {
            this.inputFieldHalf('最低薪资（元）', this.salaryMin, (v: string) => { this.salaryMin = v })
            Text('—')
              .fontSize(16)
              .fontColor('#999999')
              .margin({ left: 8, right: 8 })
            this.inputFieldHalf('最高薪资（元）', this.salaryMax, (v: string) => { this.salaryMax = v })
          }
          .width('100%')
          .margin({ top: 8 })

          this.pickerRow('薪资单位', this.salaryUnit, SALARY_UNIT_OPTIONS, (v: number) => { this.salaryUnit = v })
          this.pickerRow('工作类型', this.jobType, JOB_TYPE_OPTIONS, (v: number) => { this.jobType = v })

          this.inputField('招聘名额', this.totalQuota, (v: string) => { this.totalQuota = v })
          this.inputField('工作地址', this.address, (v: string) => { this.address = v })
          this.inputField('截止日期', this.deadline, (v: string) => { this.deadline = v })

          Button('发布职位')
            .width('100%')
            .height(48)
            .backgroundColor('#007AFF')
            .borderRadius(8)
            .fontColor('#FFFFFF')
            .fontSize(16)
            .margin({ top: 32, bottom: 40 })
            .onClick(() => {
              this.handlePublish()
            })
        }
        .padding(16)
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  topBar(): void {
    Row() {
      Image($r('app.media.left_arrow'))
        .width(24).height(24)
        .fillColor('#333333')
        .onClick(() => { router.back() })
      Text('发布职位')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Text('')
        .width(24)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  sectionTitle(text: string): void {
    Text(text)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor('#333333')
      .width('100%')
      .margin({ top: 16, bottom: 8 })
  }

  @Builder
  inputField(label: string, value: string, onChange: (v: string) => void): void {
    Column() {
      Text(label)
        .fontSize(13)
        .fontColor('#666666')
        .width('100%')
      TextInput({ placeholder: '请输入' + label, text: value })
        .height(44)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .padding({ left: 12 })
        .margin({ top: 6 })
        .onChange(onChange)
    }
    .width('100%')
    .margin({ top: 8 })
  }

  @Builder
  inputFieldHalf(label: string, value: string, onChange: (v: string) => void): void {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor('#666666')
        .width('100%')
      TextInput({ placeholder: '', text: value })
        .height(44)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .padding({ left: 12 })
        .margin({ top: 6 })
        .onChange(onChange)
    }
    .layoutWeight(1)
  }

  @Builder
  pickerRow(label: string, selected: number, options: PickerOption[], onSelect: (v: number) => void): void {
    Column() {
      Text(label)
        .fontSize(13)
        .fontColor('#666666')
        .width('100%')
      Row() {
        ForEach(options, (opt: PickerOption) => {
          Text(opt.label)
            .fontSize(13)
            .fontColor(selected === opt.value ? '#FFFFFF' : '#666666')
            .backgroundColor(selected === opt.value ? '#007AFF' : '#F5F5F5')
            .borderRadius(16)
            .padding({ left: 16, right: 16, top: 6, bottom: 6 })
            .margin({ right: 8 })
            .onClick(() => { onSelect(opt.value) })
        })
      }
      .width('100%')
      .margin({ top: 6 })
    }
    .width('100%')
    .margin({ top: 8 })
  }

  handlePublish(): void {
    if (!this.title.trim()) {
      return
    }

    const data: RecruiterJobRequest = {
      title: this.title.trim(),
      categoryId: 0,
      salaryMin: parseInt(this.salaryMin) || 0,
      salaryMax: parseInt(this.salaryMax) || 0,
      salaryUnit: this.salaryUnit,
      jobType: this.jobType,
      totalQuota: parseInt(this.totalQuota) || 1,
      address: this.address.trim(),
      tag: this.tag,
      deadline: this.deadline
    }

    RecruiterService.createJob(data).then(() => {
      router.back()
    })
  }
}
