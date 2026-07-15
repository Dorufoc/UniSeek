import { router } from '@kit.ArkUI';
import { AuthService } from '../services/AuthService';

@Entry
@Component
struct RealNameAuthPage {
  @State realName: string = ''
  @State idCard: string = ''
  @State idCardDisplay: string = ''
  @State showError: boolean = false
  @State errorMsg: string = ''
  @State submitted: boolean = false

  aboutToAppear(): void {
    const info = AuthService.getRealNameInfo()
    if (info) {
      // TODO: 对接后端后从 API 获取已认证信息
    }
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.left_arrow'))
          .width(24)
          .height(24)
          .fillColor('#333333')
          .onClick(() => { router.back() })
        Text('实名认证')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 24 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          if (this.showError) {
            Text(this.errorMsg)
              .fontSize(14)
              .fontColor('#FF4444')
              .width('100%')
              .margin({ bottom: 12 })
          }

          Text('真实姓名')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .width('100%')
            .margin({ bottom: 8 })

          TextInput({ placeholder: '请输入真实姓名', text: this.realName })
            .onChange((value: string) => { this.realName = value })
            .height(44)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({ left: 14 })
            .margin({ bottom: 20 })

          Text('身份证号')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .width('100%')
            .margin({ bottom: 8 })

          TextInput({ placeholder: '请输入身份证号', text: this.idCard })
            .onChange((value: string) => {
              this.idCard = value
            })
            .height(44)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({ left: 14 })
            .margin({ bottom: 32 })

          Button('提交认证')
            .width('100%')
            .height(48)
            .backgroundColor('#007AFF')
            .fontColor('#FFFFFF')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .borderRadius(8)
            .onClick(() => {
              this.handleSubmit()
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  handleSubmit(): void {
    this.showError = false

    if (!this.realName.trim()) {
      this.showError = true
      this.errorMsg = '请输入真实姓名'
      return
    }

    const id = this.idCard.trim()
    if (!id) {
      this.showError = true
      this.errorMsg = '请输入身份证号'
      return
    }
    if (id.length !== 15 && id.length !== 18) {
      this.showError = true
      this.errorMsg = '身份证号格式不正确（15或18位）'
      return
    }

    AuthService.setRealNameVerified(this.realName.trim(), id)
    router.back()
  }
}
