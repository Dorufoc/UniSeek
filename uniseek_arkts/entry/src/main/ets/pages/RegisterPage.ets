import { router, promptAction, SegmentButton, SegmentButtonOptions } from '@kit.ArkUI';
import { AuthService } from '../services/AuthService';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';

@Entry
@Component
struct RegisterPage {
  @State phone: string = ''
  @State email: string = ''
  @State nickname: string = ''
  @State password: string = ''
  @State confirmPassword: string = ''
  @State role: number = 0
  @State pageLoaded: boolean = false
  @State selectedRoleIndexes: number[] = [0]

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

  aboutToAppear(): void {
    // 入场动画——整体内容淡入
    setTimeout(() => {
      animateTo({ duration: 400 }, () => { this.pageLoaded = true })
    }, 50)
  }

  build() {
    Column() {
      Column() {
        Text('创建账号')
          .fontSize(AppFontSize.XXL)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .textAlign(TextAlign.Start)

        Text('注册一个新账号')
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_MUTED)
          .width('100%')
          .textAlign(TextAlign.Start)
          .margin({ top: AppSpacing.SM })
      }
      .width('100%')
      .margin({ top: 60, bottom: AppSpacing.XL })

      Column() {
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

        // 邮箱输入框
        Row() {
          SymbolGlyph($r('sys.symbol.envelope'))
            .fontSize(18)
            .fontColor([AppColors.TEXT_MUTED])
            .margin({ right: AppSpacing.SM })
          TextInput({ placeholder: '邮箱', text: this.email })
            .onChange((value: string) => {
              this.email = value
            })
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

        // 昵称输入框
        Row() {
          SymbolGlyph($r('sys.symbol.person'))
            .fontSize(18)
            .fontColor([AppColors.TEXT_MUTED])
            .margin({ right: AppSpacing.SM })
          TextInput({ placeholder: '昵称', text: this.nickname })
            .onChange((value: string) => {
              this.nickname = value
            })
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

        // 确认密码输入框
        Row() {
          SymbolGlyph($r('sys.symbol.lock'))
            .fontSize(18)
            .fontColor([AppColors.TEXT_MUTED])
            .margin({ right: AppSpacing.SM })
          TextInput({ placeholder: '确认密码', text: this.confirmPassword })
            .onChange((value: string) => {
              this.confirmPassword = value
            })
            .type(InputType.Password)
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

        Text('选择身份')
          .fontSize(AppFontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
          .width('100%')
          .margin({ top: AppSpacing.LG, bottom: AppSpacing.SM })

        // HMOS 胶囊分段按钮——求职者/招聘者切换
        SegmentButton({
          options: this.roleOptions,
          selectedIndexes: $selectedRoleIndexes,
          onItemClicked: (index: number): void => {
            this.role = index
          }
        })
        .width('100%')

        Button('注册', { type: ButtonType.Capsule })
          .width('100%')
          .height(40)
          .backgroundColor(AppColors.PRIMARY)
          .fontColor('#FFFFFF')
          .fontSize(AppFontSize.MD)
          .fontWeight(FontWeight.Medium)
          .margin({ top: AppSpacing.LG })
          .onClick(() => {
            this.handleRegister()
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

      Row() {
        Text('已有账号？')
          .fontSize(AppFontSize.SM)
          .fontColor(AppColors.TEXT_MUTED)

        Text('立即登录')
          .fontSize(AppFontSize.SM)
          .fontColor(AppColors.PRIMARY)
          .onClick(() => {
            router.replaceUrl({ url: 'pages/LoginPage' })
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: AppSpacing.LG })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 32, right: 32 })
    .opacity(this.pageLoaded ? 1 : 0)
    .animation({ duration: 400 })
    .backgroundColor('#FFFFFF')
  }

  async handleRegister() {
    if (!this.phone.trim()) {
      promptAction.showToast({ message: '请输入手机号', duration: 2000 })
      return
    }
    if (!this.email.trim()) {
      promptAction.showToast({ message: '请输入邮箱', duration: 2000 })
      return
    }
    if (!this.nickname.trim()) {
      promptAction.showToast({ message: '请输入昵称', duration: 2000 })
      return
    }
    if (!this.password.trim()) {
      promptAction.showToast({ message: '请输入密码', duration: 2000 })
      return
    }
    if (!this.confirmPassword.trim()) {
      promptAction.showToast({ message: '请确认密码', duration: 2000 })
      return
    }
    if (this.password !== this.confirmPassword) {
      promptAction.showToast({ message: '两次密码输入不一致', duration: 2000 })
      return
    }

    try {
      await AuthService.register(
        this.phone.trim(),
        this.email.trim(),
        this.password.trim(),
        this.confirmPassword.trim(),
        this.nickname.trim(),
        this.role
      )
      router.pushUrl({ url: 'pages/LoginPage' })
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message || '注册失败', duration: 2000 })
    }
  }
}
