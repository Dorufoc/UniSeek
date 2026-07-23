import { router, promptAction, SegmentButton, SegmentButtonOptions } from '@kit.ArkUI';
import { AuthService } from '../services/AuthService';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { InputValidator } from '../common/FormValidators'

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
  @State agreed: boolean = false

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
    // 由组件转场承载首屏进入动效，避免使用已弃用的显式动画接口。
    setTimeout(() => {
      this.pageLoaded = true
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
        .width('100%')
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
        .width('100%')
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
        .width('100%')
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
        .width('100%')
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
        .width('100%')
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

        Row() {
          Checkbox({ name: 'registerAgreement' })
            .select(this.agreed)
            .selectedColor(AppColors.PRIMARY)
            .shape(CheckBoxShape.ROUNDED_SQUARE)
            .onChange((value: boolean): void => { this.agreed = value })
          Text('我已阅读并同意')
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.TEXT_SECONDARY)
            .margin({ left: AppSpacing.XS })
          Button('用户协议', { type: ButtonType.Normal })
            .height(28)
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.PRIMARY)
            .backgroundColor(Color.Transparent)
            .onClick((): void => { router.pushUrl({ url: 'pages/UserAgreementPage' }) })
          Text('和')
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.TEXT_SECONDARY)
          Button('隐私政策', { type: ButtonType.Normal })
            .height(28)
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.PRIMARY)
            .backgroundColor(Color.Transparent)
            .onClick((): void => { router.pushUrl({ url: 'pages/PrivacyPolicyPage' }) })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ top: AppSpacing.MD })

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

        Button('立即登录', { type: ButtonType.Normal })
          .height(32)
          .fontSize(AppFontSize.SM)
          .fontColor(AppColors.PRIMARY)
          .backgroundColor(Color.Transparent)
          .padding({ left: AppSpacing.XS, right: AppSpacing.XS })
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
    .transition({ opacity: 0, translate: { y: 12 } })
    .backgroundColor('#FFFFFF')
  }

  async handleRegister() {
    if (!InputValidator.isPhone(this.phone.trim())) {
      promptAction.showToast({ message: '请输入正确的 11 位手机号', duration: 2000 })
      return
    }
    if (!InputValidator.isEmail(this.email.trim())) {
      promptAction.showToast({ message: '请输入正确的邮箱地址', duration: 2000 })
      return
    }
    if (!InputValidator.isNickname(this.nickname.trim())) {
      promptAction.showToast({ message: '昵称长度应为 2 到 20 个字符', duration: 2000 })
      return
    }
    if (!InputValidator.isStrongPassword(this.password)) {
      promptAction.showToast({ message: '密码需为 8 到 20 位，且同时包含字母和数字', duration: 2000 })
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
    if (!this.agreed) {
      promptAction.showToast({ message: '请先阅读并同意用户协议和隐私政策', duration: 2000 })
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
      const loginResult = await AuthService.login(this.phone.trim(), this.password)
      router.replaceUrl({ url: loginResult.userInfo.role === 0 ? 'pages/MainPage' : 'pages/RecruiterHomePage' })
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message || '注册失败', duration: 2000 })
    }
  }
}
