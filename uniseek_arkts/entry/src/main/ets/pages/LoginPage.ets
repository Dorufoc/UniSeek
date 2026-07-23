import { router, promptAction, CustomContentDialog } from '@kit.ArkUI';
import { AuthService } from '../services/AuthService';
import { UserSession } from '../services/UserSession';
import { ApiClient } from '../services/ApiClient';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { InputValidator } from '../common/FormValidators'

@Entry
@Component
struct LoginPage {
  @State phone: string = ''
  @State password: string = ''
  @State serverAddrInput: string = ''
  @State pageLoaded: boolean = false

  // 原生弹窗控制器
  private serverDialogController: CustomDialogController | null = null;

  // 调试用：记录标题点击时间戳，5 秒内连点 10 次弹出后端地址
  private clickTimestamps: number[] = []

  // 自定义弹窗内容区——TextInput 由系统原生弹窗的 contentBuilder 承载
  @Builder
  buildServerDialogContent(): void {
    TextInput({ placeholder: '请输入后端服务器地址', text: this.serverAddrInput })
      .onChange((value: string) => {
        this.serverAddrInput = value
      })
  }

  aboutToAppear(): void {
    ApiClient.restoreConfiguration()
    // 由组件转场承载首屏进入动效，避免使用已弃用的显式动画接口。
    setTimeout(() => {
      this.pageLoaded = true
    }, 50)
  }

  build() {
    Stack() {
      Column(){
        Image($r('app.media.uniseek_text'))
          .width('90%')
          .opacity(this.pageLoaded ? 1 : 0)
          .transition({ opacity: 0, translate: { y: -8 } })
          .onClick(() => {
            this.handleTitleClick()
          })
          .margin({bottom:10})
        Column() {
          // 表单区域

            // 手机号输入框
            Row() {
              SymbolGlyph($r('sys.symbol.phone'))
                .fontSize(18)
                .fontColor([AppColors.TEXT_MUTED])
                .margin({ right: AppSpacing.SM })
              TextInput({ placeholder: '手机号', text: this.phone })
                .onChange((value: string) => {
                  this.phone = value
                })
                .type(InputType.PhoneNumber)
                .maxLength(11)
                .layoutWeight(1)
                .backgroundColor(Color.Transparent)
                .fontSize(AppFontSize.MD)
                .fontColor(AppColors.TEXT_PRIMARY)
                .placeholderColor(AppColors.TEXT_MUTED)
            }
            .height(50)
        .width('100%')
            .backgroundColor(AppColors.INPUT_BG)
            .borderRadius(20)
            .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
            .margin({ top: 40 })

            // 密码输入框
            Row() {
              SymbolGlyph($r('sys.symbol.lock'))
                .fontSize(18)
                .fontColor([AppColors.TEXT_MUTED])
                .margin({ right: AppSpacing.SM })
              TextInput({ placeholder: '密码', text: this.password })
                .onChange((value: string) => {
                  this.password = value
                })
                .type(InputType.Password)
                .maxLength(20)
                .layoutWeight(1)
                .backgroundColor(Color.Transparent)
                .fontSize(AppFontSize.MD)
                .fontColor(AppColors.TEXT_PRIMARY)
                .placeholderColor(AppColors.TEXT_MUTED)
            }
            .height(50)
        .width('100%')
            .backgroundColor(AppColors.INPUT_BG)
            .borderRadius(20)
            .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
            .margin({ top: AppSpacing.MD })




          Column() {
            // 登录按钮——使用 HMOS Capsule 风格
            Button('登录', { type: ButtonType.Capsule })
              .width('100%')
              .height(50)
              .backgroundColor(AppColors.PRIMARY)
              .fontColor('#FFFFFF')
              .fontSize(AppFontSize.MD)
              .fontWeight(FontWeight.Medium)
              .margin({ top: AppSpacing.XL })
              .onClick(() => {
                this.handleLogin()
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

          .width('100%')

          // 注册引导
          Row() {
            Text('没有账号？')
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.TEXT_MUTED)

            Button('立即注册', { type: ButtonType.Normal })
              .height(32)
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.PRIMARY)
              .backgroundColor(Color.Transparent)
              .padding({ left: AppSpacing.XS, right: AppSpacing.XS })
              .onClick(() => {
                router.replaceUrl({ url: 'pages/RegisterPage' })
              })
          }
          .width('90%')
          .padding({
            bottom: 40
          })
          .justifyContent(FlexAlign.Center)
          .margin({ top: AppSpacing.XL })
        }
        .justifyContent(FlexAlign.Center)
        .borderRadius(AppRadius.XL)
        .width('95%')
        .margin({bottom:128})
        .padding({ left: AppSpacing.XL, right: AppSpacing.XL })
        .backgroundColor(AppColors.BG_CARD)
        .opacity(this.pageLoaded ? 1 : 0)
        .transition({ opacity: 0, translate: { y: 12 } })

      }
      // .backgroundImage($r('app.media.background_v2'))
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [
          [AppColors.PRIMARY, 0.0],
          ['#5A8CFF', 0.15],
          ['#A8C4FF', 0.3],
          ['#E4EEFF', 0.5],
          ['#FFFFFF', 0.7],
          ['#FFFFFF', 1.0]
        ]
      })
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .height('100%')
      // ---------- 主登录区域 ----------

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
      this.serverDialogController = new CustomDialogController({
        builder: CustomContentDialog({
          primaryTitle: '后端服务器地址',
          contentBuilder: () => {
            this.buildServerDialogContent()
          },
          buttons: [
            {
              value: '取消',
              action: (): void => {
                this.serverDialogController?.close()
              }
            },
            {
              value: '保存',
              action: (): void => {
                const savedUrl: string = ApiClient.setBaseUrl(this.serverAddrInput)
                this.serverAddrInput = savedUrl
                promptAction.showToast({ message: '后端地址已持久化保存', duration: 1800 })
                this.serverDialogController?.close()
              }
            }
          ]
        }),
        autoCancel: true,
        alignment: DialogAlignment.Center
      })
      this.serverDialogController.open()
    }
  }

  async handleLogin() {
    if (!InputValidator.isPhone(this.phone.trim())) {
      promptAction.showToast({ message: '请输入正确的 11 位手机号', duration: 2000 })
      return
    }
    if (!this.password.trim()) {
      promptAction.showToast({ message: '请输入密码', duration: 2000 })
      return
    }

    try {
      await AuthService.login(this.phone.trim(), this.password.trim())
      if (UserSession.role === 0) {
        router.replaceUrl({ url: 'pages/MainPage' })
      } else {
        router.replaceUrl({ url: 'pages/RecruiterHomePage' })
      }
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message || '登录失败', duration: 2000 })
    }
  }
}
