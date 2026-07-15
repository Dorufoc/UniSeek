import { router } from '@kit.ArkUI';
import { RecruiterService } from '../services/RecruiterService';
import { AUDIT_STATUS_LABELS, RecruiterEnterpriseRequest } from '../services/RecruiterTypes';

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
      this.topBar()

      Scroll() {
        Column() {
          if (this.auditStatus >= 0) {
            Row() {
              Text('审核状态：')
                .fontSize(14)
                .fontColor('#666666')
              Text(AUDIT_STATUS_LABELS[this.auditStatus])
                .fontSize(14)
                .fontColor(this.auditStatus === 1 ? '#34C759' : this.auditStatus === 2 ? '#FF4444' : '#FF6B35')
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .padding(14)
            .backgroundColor(this.auditStatus === 1 ? '#E8F8ED' : this.auditStatus === 2 ? '#FFEBEE' : '#FFF3E0')
            .borderRadius(12)
            .margin({ top: 12 })
          }

          Text('修改企业信息后需重新提交审核')
            .fontSize(13)
            .fontColor('#999999')
            .width('100%')
            .margin({ top: 16, bottom: 8 })
            .visibility(this.auditStatus === -1 ? Visibility.Hidden : Visibility.Visible)

          this.inputField('企业名称', this.companyName, (v: string) => { this.companyName = v })
          this.inputField('统一社会信用代码', this.creditCode, (v: string) => { this.creditCode = v })

          Text('营业执照图片')
            .fontSize(13)
            .fontColor('#666666')
            .width('100%')
            .margin({ top: 8 })
          Row() {
            Text('点击上传营业执照')
              .fontSize(14)
              .fontColor('#007AFF')
          }
          .width('100%')
          .height(44)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 12 })
          .margin({ top: 6 })
          .onClick(() => {
            // TODO: 文件选择器上传营业执照
          })

          this.inputField('所属行业', this.industry, (v: string) => { this.industry = v })
          this.inputField('企业所在地区', this.regionName, (v: string) => { this.regionName = v })

          Column() {
            Text('公司简介')
              .fontSize(13)
              .fontColor('#666666')
              .width('100%')
            TextArea({ placeholder: '请输入公司简介', text: this.description })
              .height(100)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .padding({ left: 12 })
              .margin({ top: 6 })
              .onChange((v: string) => { this.description = v })
          }
          .width('100%')
          .margin({ top: 8 })

          Button(this.submitButtonText())
            .width('100%')
            .height(48)
            .backgroundColor('#007AFF')
            .borderRadius(8)
            .fontColor('#FFFFFF')
            .fontSize(16)
            .margin({ top: 32, bottom: 40 })
            .onClick(() => {
              this.handleSubmit()
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
      Text('我的公司')
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
