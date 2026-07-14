import { router } from '@kit.ArkUI';

@Entry
@Component
struct RegisterPage {
  @State phone: string = ''
  @State email: string = ''
  @State password: string = ''
  @State confirmPassword: string = ''
  @State showError: boolean = false
  @State errorMsg: string = ''

  build() {
    Column() {
      Column() {
        Text('创建账号')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .textAlign(TextAlign.Start)

        Text('注册一个新账号')
          .fontSize(16)
          .fontColor('#888888')
          .width('100%')
          .textAlign(TextAlign.Start)
          .margin({ top: 8 })
      }
      .width('100%')
      .margin({ top: 60, bottom: 40 })

      Column() {
        if (this.showError) {
          Text(this.errorMsg)
            .fontSize(14)
            .fontColor('#FF4444')
            .width('100%')
            .margin({ bottom: 8 })
        }

        TextInput({ placeholder: '手机号', text: this.phone })
          .onChange((value: string) => {
            this.phone = value
          })
          .height(48)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 16 })

        TextInput({ placeholder: '邮箱', text: this.email })
          .onChange((value: string) => {
            this.email = value
          })
          .height(48)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 16 })
          .margin({ top: 16 })

        TextInput({ placeholder: '密码', text: this.password })
          .onChange((value: string) => {
            this.password = value
          })
          .type(InputType.Password)
          .height(48)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 16 })
          .margin({ top: 16 })

        TextInput({ placeholder: '确认密码', text: this.confirmPassword })
          .onChange((value: string) => {
            this.confirmPassword = value
          })
          .type(InputType.Password)
          .height(48)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 16 })
          .margin({ top: 16 })

        Button('注册')
          .width('100%')
          .height(48)
          .backgroundColor('#007AFF')
          .borderRadius(8)
          .fontColor('#FFFFFF')
          .fontSize(16)
          .margin({ top: 32 })
          .onClick(() => {
            this.handleRegister()
          })
      }
      .width('100%')

      Row() {
        Text('已有账号？')
          .fontSize(14)
          .fontColor('#888888')

        Text('立即登录')
          .fontSize(14)
          .fontColor('#007AFF')
          .onClick(() => {
            router.pushUrl({ url: 'pages/LoginPage' })
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 24 })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 32, right: 32 })
    .backgroundColor('#FFFFFF')
  }

  handleRegister() {
    if (!this.phone.trim()) {
      this.showError = true
      this.errorMsg = '请输入手机号'
      return
    }
    if (!this.email.trim()) {
      this.showError = true
      this.errorMsg = '请输入邮箱'
      return
    }
    if (!this.password.trim()) {
      this.showError = true
      this.errorMsg = '请输入密码'
      return
    }
    if (!this.confirmPassword.trim()) {
      this.showError = true
      this.errorMsg = '请确认密码'
      return
    }
    if (this.password !== this.confirmPassword) {
      this.showError = true
      this.errorMsg = '两次密码输入不一致'
      return
    }

    this.showError = false

    // TODO: 调用后端注册接口
    console.log('注册:', this.phone, this.email, this.password)

    router.replaceUrl({ url: 'pages/MainPage' })
  }
}
