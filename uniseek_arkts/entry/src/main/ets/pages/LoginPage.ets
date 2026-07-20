import { router, promptAction, CustomContentDialog, SegmentButton, SegmentButtonOptions } from '@kit.ArkUI';
import { AuthService } from '../services/AuthService';
import { UserSession } from '../services/UserSession';
import { ApiClient } from '../services/ApiClient';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';

@Entry
@Component
struct LoginPage {
  @State phone: string = ''
  @State password: string = ''
  @State role: number = 0
  @State selectedRoleIndexes: number[] = [0]
  @State serverAddrInput: string = ''
  @State pageLoaded: boolean = false
  @State logoOpacity: number = 0
  @State contentOpacity: number = 0

  // 原生弹窗控制器
  private serverDialogController: CustomDialogController | null = null;

  // 调试用：记录标题点击时间戳，5 秒内连点 10 次弹出后端地址
  private clickTimestamps: number[] = []

  // 胶囊单选分段按钮——求职者/招聘者切换
  @State roleOptions: SegmentButtonOptions = SegmentButtonOptions.capsule({
    buttons: [{ text: '求职者' }, { text: '招聘者' }],
    multiply: false,
    selectedBackgroundColor: AppColors.PRIMARY,
    backgroundColor: AppColors.INPUT_BG,
    selectedFontColor: '#FFFFFF',
    fontColor: AppColors.TEXT_SECONDARY,
    fontSize: AppFontSize.SM,
    selectedFontSize: AppFontSize.SM
  })

  // 自定义弹窗内容区——TextInput 由系统原生弹窗的 contentBuilder 承载
  @Builder
  buildServerDialogContent(): void {
    TextInput({ placeholder: '请输入后端服务器地址', text: this.serverAddrInput })
      .onChange((value: string) => {
        this.serverAddrInput = value
      })
  }

  aboutToAppear(): void {
    // 页面入场动画：延迟一帧启动淡入 + 上移
    setTimeout(() => {
      this.pageLoaded = true
    }, 50)
    // 入场动画——Logo 先行，内容延迟跟随
    animateTo({ duration: 400 }, () => { this.logoOpacity = 1 })
    setTimeout(() => {
      animateTo({ duration: 400 }, () => { this.contentOpacity = 1 })
    }, 200)
  }

  build() {
    Stack() {
      Column(){
        Image($r('app.media.uniseek_text'))
          .width('90%')
          .opacity(this.logoOpacity)
          .onClick(() => {
            this.handleTitleClick()
          })
          .margin({bottom:10})
        Column() {
          // 表单区域

            // 胶囊单选分段按钮——求职者/招聘者切换
            Column() {
              SegmentButton({
                options: this.roleOptions,
                selectedIndexes: $selectedRoleIndexes,
                onItemClicked: (index: number): void => {
                  this.role = index
                }
              })
            }
            .width('100%')
            .margin({ top: 40 })
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
            .backgroundColor(AppColors.INPUT_BG)
            .borderRadius(20)
            .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
            .margin({ top: AppSpacing.MD })

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

            Text('立即注册')
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.PRIMARY)
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
        .opacity(this.contentOpacity)
        .animation({ duration: 400 })

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
                ApiClient.BASE_URL = this.serverAddrInput.trim()
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
    if (!this.phone.trim()) {
      promptAction.showToast({ message: '请输入手机号', duration: 2000 })
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
