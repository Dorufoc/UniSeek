import { CustomContentDialog } from '@kit.ArkUI';
import { AuthService } from '../services/AuthService';
import { UserSession } from '../services/UserSession';
import { ApiClient } from '../services/ApiClient';
import { AppColors, AppSpacing, AppRadius, AppFontSize, StandardInput, PrimaryButton } from '../common/AppStyles';
import { InputValidator } from '../common/FormValidators'
import { WindowBreakpoint } from '../common/Responsive';

@Entry
@Component
struct LoginPage {
  @State phone: string = ''
  @State password: string = ''
  @State serverAddrInput: string = ''
  @State isLoggingIn: boolean = false
  @StorageLink('breakpoint') breakpoint: WindowBreakpoint = WindowBreakpoint.COMPACT

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
  }

  build() {
    Stack() {
      Column(){
        Image($r('app.media.uniseek_text'))
          .width('90%')
          .fillColor(AppColors.PRIMARY)
          .onClick(() => {
            this.handleTitleClick()
          })
          .margin({ bottom: AppSpacing.SM_GAP })
        Column({ space: AppSpacing.MD }) {
          // 手机号输入框
          StandardInput({
            placeholder: '手机号',
            value: $phone,
            inputType: InputType.PhoneNumber,
            maxLength: 11,
            leadingIcon: $r('sys.symbol.phone')
          })
          .margin({ top: AppSpacing.XL })

          // 密码输入框
          StandardInput({
            placeholder: '密码',
            value: $password,
            inputType: InputType.Password,
            maxLength: 20,
            leadingIcon: $r('sys.symbol.lock')
          })

          // 登录按钮
          PrimaryButton({
            text: '登录',
            loading: this.isLoggingIn,
            disabled: this.phone.length === 0 || this.password.length === 0,
            onTap: () => { this.handleLogin() }
          })
          .margin({ top: AppSpacing.XL })

          // 注册引导
          Row() {
            Text('没有账号？')
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.TEXT_MUTED)

            Button('立即注册', { type: ButtonType.Normal })
              .height(AppSpacing.BUTTON_HEIGHT_MINI)
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.PRIMARY)
              .backgroundColor(Color.Transparent)
              .padding({ left: AppSpacing.XS, right: AppSpacing.XS })
              .onClick(() => {
                this.getUIContext().getRouter().replaceUrl({ url: 'pages/RegisterPage' })
              })
          }
          .width('100%')
          .padding({
            bottom: 40
          })
          .justifyContent(FlexAlign.Center)
          .margin({ top: AppSpacing.XL })
        }
        .justifyContent(FlexAlign.Center)
        .borderRadius(AppRadius.XL)
.width(this.breakpoint === WindowBreakpoint.COMPACT ? '90%' : 420)
.margin({ bottom: AppSpacing.BOTTOM_ACTION_HEIGHT })
.padding({ left: AppSpacing.XL, right: AppSpacing.XL })
.backgroundColor(AppColors.BG_CARD)

      }
      .backgroundColor(AppColors.BG_PAGE)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
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
                this.getUIContext().getPromptAction().showToast({ message: '后端地址已持久化保存', duration: 1800 })
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
    if (this.isLoggingIn) {
      return
    }
    if (!InputValidator.isPhone(this.phone.trim())) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入正确的 11 位手机号', duration: 2000 })
      return
    }
    if (!this.password.trim()) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入密码', duration: 2000 })
      return
    }

    this.isLoggingIn = true
    try {
      await AuthService.login(this.phone.trim(), this.password.trim())
      if (UserSession.role === 0) {
        this.getUIContext().getRouter().replaceUrl({ url: 'pages/MainPage' })
      } else {
        this.getUIContext().getRouter().replaceUrl({ url: 'pages/RecruiterHomePage' })
      }
    } catch (e) {
      this.getUIContext().getPromptAction().showToast({ message: (e as Error).message || '登录失败', duration: 2000 })
    } finally {
      this.isLoggingIn = false
    }
  }
}
