import { router } from '@kit.ArkUI';
import { RecruiterService } from '../services/RecruiterService';
import { RecruiterJobRequest } from '../services/RecruiterTypes';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';

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
      NavBar({
        title: '发布职位',
        showBack: true,
        onBack: () => router.back()
      })

      Scroll() {
        Column() {
          this.sectionTitle('基本信息')

          this.inputField('职位标题', this.title, (v: string) => { this.title = v })

          Row() {
            this.inputFieldHalf('最低薪资（元）', this.salaryMin, (v: string) => { this.salaryMin = v })
            Text('—')
              .fontSize(AppFontSize.MD)
              .fontColor(AppColors.TEXT_MUTED)
              .margin({ left: AppSpacing.SM, right: AppSpacing.SM })
            this.inputFieldHalf('最高薪资（元）', this.salaryMax, (v: string) => { this.salaryMax = v })
          }
          .width('100%')
          .margin({ top: AppSpacing.SM })

          this.pickerRow('薪资单位', this.salaryUnit, SALARY_UNIT_OPTIONS, (v: number) => { this.salaryUnit = v })
          this.pickerRow('工作类型', this.jobType, JOB_TYPE_OPTIONS, (v: number) => { this.jobType = v })

          this.inputField('招聘名额', this.totalQuota, (v: string) => { this.totalQuota = v })
          this.inputField('工作地址', this.address, (v: string) => { this.address = v })
          this.inputField('截止日期', this.deadline, (v: string) => { this.deadline = v })

          Button({ type: ButtonType.Capsule }) {
            Text('发布职位')
              .fontSize(AppFontSize.MD)
              .fontColor('#FFFFFF')
          }
            .width('100%')
            .height(48)
            .backgroundColor(AppColors.PRIMARY)
            .margin({ top: AppSpacing.XL, bottom: AppSpacing.XXL })
            .onClick(() => {
              this.handlePublish()
            })
            .stateStyles({
              pressed: {
                .scale({ x: 0.97, y: 0.97 })
                .opacity(0.9)
                .backgroundColor(AppColors.PRIMARY_HOVER)
              },
              normal: {
                .scale({ x: 1, y: 1 })
                .opacity(1)
                .backgroundColor(AppColors.PRIMARY)
              }
            })
            .animation({
              duration: 200
            })
        }
        .padding(AppSpacing.MD)
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  @Builder
  sectionTitle(text: string): void {
    Text(text)
      .fontSize(AppFontSize.MD)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.TEXT_PRIMARY)
      .width('100%')
      .margin({ top: AppSpacing.MD, bottom: AppSpacing.SM })
  }

  @Builder
  inputField(label: string, value: string, onChange: (v: string) => void): void {
    Column() {
      Text(label)
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
      TextInput({ placeholder: '请输入' + label, text: value })
        .height(44)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .padding({ left: AppSpacing.SM })
        .margin({ top: AppSpacing.XS })
        .onChange(onChange)
    }
    .width('100%')
    .margin({ top: AppSpacing.SM })
  }

  @Builder
  inputFieldHalf(label: string, value: string, onChange: (v: string) => void): void {
    Column() {
      Text(label)
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
      TextInput({ placeholder: '', text: value })
        .height(44)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .padding({ left: AppSpacing.SM })
        .margin({ top: AppSpacing.XS })
        .onChange(onChange)
    }
    .layoutWeight(1)
  }

  @Builder
  pickerRow(label: string, selected: number, options: PickerOption[], onSelect: (v: number) => void): void {
    Column() {
      Text(label)
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
      Row() {
        ForEach(options, (opt: PickerOption) => {
          Text(opt.label)
            .fontSize(AppFontSize.XS)
            .fontColor(selected === opt.value ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
            .backgroundColor(selected === opt.value ? AppColors.PRIMARY : AppColors.INPUT_BG)
            .borderRadius(AppRadius.XL)
            .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.XS, bottom: AppSpacing.XS })
            .margin({ right: AppSpacing.SM })
            .onClick(() => { onSelect(opt.value) })
            .animation({
              duration: 150
            })
        })
      }
      .width('100%')
      .margin({ top: AppSpacing.XS })
    }
    .width('100%')
    .margin({ top: AppSpacing.SM })
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
