import { router } from '@kit.ArkUI';
import { RecruiterService } from '../services/RecruiterService';
import { AUDIT_STATUS_LABELS, RecruiterEnterpriseRequest } from '../services/RecruiterTypes';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';

@Entry
@Component
struct RecruiterEnterprisePage {
  @State companyName: string = ''
  @State creditCode: string = ''
  @State industry: string = ''
  @State regionName: string = ''
  @State description: string = ''
  @State auditStatus: number = -1
  @State isSubmitted: boolean = false

  aboutToAppear(): void {
    this.loadEnterpriseInfo()
  }

  loadEnterpriseInfo(): void {
    RecruiterService.getEnterpriseInfo().then((info) => {
      if (info) {
        this.companyName = info.companyName
        this.creditCode = info.creditCode
        this.industry = info.industry
        this.regionName = info.regionName
        this.description = info.description
        this.auditStatus = info.auditStatus
        this.isSubmitted = true
      }
    })
  }

  build() {
    Column() {
      NavBar({
        title: '企业资质',
        showBack: true,
        onBack: () => router.back()
      })

      Scroll() {
        Column() {
          if (this.auditStatus >= 0) {
            Row() {
              Text('审核状态：')
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.TEXT_SECONDARY)
              Text(AUDIT_STATUS_LABELS[this.auditStatus])
                .fontSize(AppFontSize.SM)
                .fontColor(this.auditStatus === 1 ? AppColors.SUCCESS : this.auditStatus === 2 ? AppColors.DANGER : AppColors.WARNING)
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .padding(AppSpacing.SM)
            .backgroundColor(this.auditStatus === 1 ? '#E8F8ED' : this.auditStatus === 2 ? '#FFEBEE' : '#FFF3E0')
            .borderRadius(AppRadius.LG)
            .margin({ top: AppSpacing.SM })
          }

          Text('修改企业信息后需重新提交审核')
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.TEXT_MUTED)
            .width('100%')
            .margin({ top: AppSpacing.MD, bottom: AppSpacing.SM })
            .visibility(this.auditStatus === -1 ? Visibility.Hidden : Visibility.Visible)

          this.inputField('企业名称', this.companyName, (v: string) => { this.companyName = v })
          this.inputField('统一社会信用代码', this.creditCode, (v: string) => { this.creditCode = v })

          Text('营业执照图片')
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.TEXT_SECONDARY)
            .width('100%')
            .margin({ top: AppSpacing.SM })
          Row() {
            Text('点击上传营业执照')
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.PRIMARY)
          }
          .width('100%')
          .height(44)
          .backgroundColor(AppColors.INPUT_BG)
          .borderRadius(AppRadius.SM)
          .padding({ left: AppSpacing.SM })
          .margin({ top: AppSpacing.XS })
          .onClick(() => {
            // TODO: 文件选择器上传营业执照
          })
          .stateStyles({
            pressed: {
              .backgroundColor(AppColors.SELECTED_BG)
            }
          })

          this.inputField('所属行业', this.industry, (v: string) => { this.industry = v })
          this.inputField('企业所在地区', this.regionName, (v: string) => { this.regionName = v })

          Column() {
            Text('公司简介')
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.TEXT_SECONDARY)
              .width('100%')
            TextArea({ placeholder: '请输入公司简介', text: this.description })
              .height(100)
              .backgroundColor(AppColors.INPUT_BG)
              .borderRadius(AppRadius.SM)
              .padding({ left: AppSpacing.SM })
              .margin({ top: AppSpacing.XS })
              .onChange((v: string) => { this.description = v })
          }
          .width('100%')
          .margin({ top: AppSpacing.SM })

          Button({ type: ButtonType.Capsule }) {
            Text(this.submitButtonText())
              .fontSize(AppFontSize.MD)
              .fontColor('#FFFFFF')
          }
            .width('100%')
            .height(48)
            .backgroundColor(AppColors.PRIMARY)
            .margin({ top: AppSpacing.XL, bottom: AppSpacing.XXL })
            .onClick(() => {
              this.handleSubmit()
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

  submitButtonText(): string {
    if (this.auditStatus === -1) return '提交认证'
    if (this.auditStatus === 1) return '修改并重新提交审核'
    if (this.auditStatus === 2) return '重新提交审核'
    return '更新并重新提交'
  }

  handleSubmit(): void {
    if (!this.companyName.trim()) {
      return
    }

    const data: RecruiterEnterpriseRequest = {
      companyName: this.companyName.trim(),
      creditCode: this.creditCode.trim(),
      licenseImgUrl: '',
      industry: this.industry.trim(),
      regionId: 0,
      description: this.description.trim()
    }

    RecruiterService.saveEnterpriseInfo(data).then(() => {
      this.auditStatus = 0
      this.isSubmitted = true
      router.back()
    })
  }
}
