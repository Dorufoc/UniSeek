import { router } from '@kit.ArkUI';
import { AuthService } from '../services/AuthService';
import { UserSession } from '../services/UserSession';
import { ApiClient } from '../services/ApiClient';

@Entry
@Component
struct LoginPage {
  @State phone: string = ''
  @State password: string = ''
  @State role: number = 0
  @State showError: boolean = false
  @State errorMsg: string = ''
  @State showServerDialog: boolean = false
  @State serverAddrInput: string = ''

  // 调试用：记录标题点击时间戳，5 秒内连点 10 次弹出后端地址
  private clickTimestamps: number[] = []

  build() {
    Stack() {
      Column() {
        Column() {
          Text('UniSeek')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .textAlign(TextAlign.Start)
            .onClick(() => {
              this.handleTitleClick()
            })

          Text('为你寻找最适合你的')
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

          Text('选择身份')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .width('100%')
            .margin({ top: 20, bottom: 10 })

          Row() {
            Text('求职者')
              .fontSize(14)
              .fontColor(this.role === 0 ? '#FFFFFF' : '#666666')
              .backgroundColor(this.role === 0 ? '#007AFF' : '#F5F5F5')
              .borderRadius(16)
              .padding({ left: 28, right: 28, top: 8, bottom: 8 })
              .onClick(() => { this.role = 0 })

            Text('招聘者')
              .fontSize(14)
              .fontColor(this.role === 1 ? '#FFFFFF' : '#666666')
              .backgroundColor(this.role === 1 ? '#007AFF' : '#F5F5F5')
              .borderRadius(16)
              .padding({ left: 28, right: 28, top: 8, bottom: 8 })
              .margin({ left: 12 })
              .onClick(() => { this.role = 1 })
          }
          .width('100%')

          Button('登录')
            .width('100%')
            .height(48)
            .backgroundColor('#007AFF')
            .borderRadius(8)
            .fontColor('#FFFFFF')
            .fontSize(16)
            .margin({ top: 24 })
            .onClick(() => {
              this.handleLogin()
            })
        }
        .width('100%')

        Row() {
          Text('没有账号？')
            .fontSize(14)
            .fontColor('#888888')

          Text('立即注册')
            .fontSize(14)
            .fontColor('#007AFF')
            .onClick(() => {
              router.pushUrl({ url: 'pages/RegisterPage' })
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

      // 调试弹窗：遮罩 + 居中卡片（点击遮罩可关闭）
      if (this.showServerDialog) {
        Stack() {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#000000')
            .opacity(0.4)
            .onClick(() => {
              this.showServerDialog = false
            })

          Column() {
            Text('后端服务器地址')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 16 })

            TextInput({ placeholder: '请输入后端服务器地址', text: this.serverAddrInput })
              .onChange((value: string) => {
                this.serverAddrInput = value
              })
              .width('100%')
              .height(48)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .padding({ left: 12, right: 12 })

            Row() {
              Button('取消')
                .layoutWeight(1)
                .height(40)
                .backgroundColor('#F5F5F5')
                .fontColor('#333333')
                .onClick(() => {
                  this.showServerDialog = false
                })

              Button('保存')
                .layoutWeight(1)
                .height(40)
                .margin({ left: 12 })
                .backgroundColor('#007AFF')
                .fontColor('#FFFFFF')
                .onClick(() => {
                  ApiClient.BASE_URL = this.serverAddrInput.trim()
                  this.showServerDialog = false
                })
            }
            .width('100%')
            .margin({ top: 20 })
          }
          .width('80%')
          .padding(24)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
        }
        .width('100%')
        .height('100%')
        .zIndex(1000)
      }
    }
    .width('100%')
    .height('100%')
  }

  // 标题点击：在 5 秒窗口内累计 10 次触发调试弹窗
  private handleTitleClick(): void {
    const now: number = Date.now()
    this.clickTimestamps.push(now)
    // 仅保留最近 5 秒内的点击记录
    this.clickTimestamps = this.clickTimestamps.filter((time: number) => now - time <= 5000)
    if (this.clickTimestamps.length >= 10) {
      this.clickTimestamps = []
      this.serverAddrInput = ApiClient.BASE_URL
      this.showServerDialog = true
    }
  }

  async handleLogin() {
    if (!this.phone.trim()) {
      this.showError = true
      this.errorMsg = '请输入手机号'
      return
    }
    if (!this.password.trim()) {
      this.showError = true
      this.errorMsg = '请输入密码'
      return
    }

    this.showError = false

    try {
      await AuthService.login(this.phone.trim(), this.password.trim())
      if (UserSession.role === 0) {
        router.replaceUrl({ url: 'pages/MainPage' })
      } else {
        router.replaceUrl({ url: 'pages/RecruiterHomePage' })
      }
    } catch (e) {
      this.showError = true
      this.errorMsg = (e as Error).message || '登录失败'
    }
  }
}
