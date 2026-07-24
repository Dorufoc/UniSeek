import { AuthService } from '../services/AuthService';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';
import { InputValidator } from '../common/FormValidators'

@Entry
@Component
struct RealNameAuthPage {
  @State realName: string = ''
  @State idCard: string = ''
  @State showError: boolean = false
  @State errorMsg: string = ''
  @State submitted: boolean = false
  @State existing: boolean = false
  @State authStatus: number = 0
  @State statusText: string = ''

  aboutToAppear(): void {
    AuthService.getRealNameStatus().then((info) => {
      this.authStatus = info.status
      if (info.status === 1) {
        this.existing = true
        this.submitted = true
        this.realName = info.realName
        this.statusText = '认证已通过'
      } else if (info.status === 2) {
        this.statusText = '认证审核中，请耐心等待'
      }
    }).catch(() => {
      this.statusText = '认证状态暂时无法获取'
    })
  }

  build() {
    Column() {
      NavBar({
        title: '实名认证',
        showBack: true,
        onBack: () => this.getUIContext().getRouter().back()
      })

      Scroll() {
        Column() {
          if (this.showError) {
            Text(this.errorMsg)
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.DANGER)
              .width('100%')
              .margin({ bottom: AppSpacing.SM })
          }

          if (this.existing) {
            Text('您已通过实名认证')
              .fontSize(AppFontSize.MD)
              .fontColor(AppColors.SUCCESS)
              .fontWeight(FontWeight.Medium)
              .width('100%')
              .margin({ bottom: AppSpacing.LG })
          }

          if (!this.existing && this.statusText) {
            Text(this.statusText)
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.TEXT_SECONDARY)
              .width('100%')
              .margin({ bottom: AppSpacing.MD })
          }

          Text('真实姓名')
            .fontSize(AppFontSize.SM)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .width('100%')
            .margin({ bottom: AppSpacing.SM })

          TextInput({ placeholder: '请输入真实姓名', text: this.realName })
            .onChange((value: string) => { this.realName = value })
            .height(44)
            .backgroundColor(AppColors.INPUT_BG)
            .borderRadius(AppRadius.SM)
            .padding({ left: AppSpacing.SM })
            .margin({ bottom: AppSpacing.LG })
            .enabled(!this.existing)

          Text('身份证号')
            .fontSize(AppFontSize.SM)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .width('100%')
            .margin({ bottom: AppSpacing.SM })

          TextInput({ placeholder: '请输入身份证号', text: this.idCard })
            .onChange((value: string) => {
              this.idCard = value
            })
            .height(44)
            .backgroundColor(AppColors.INPUT_BG)
            .borderRadius(AppRadius.SM)
            .padding({ left: AppSpacing.SM })
            .margin({ bottom: AppSpacing.XL })
            .enabled(!this.existing)

          if (!this.existing) {
            Button({ type: ButtonType.Capsule }) {
              Text('提交认证')
                .fontSize(AppFontSize.MD)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
            }
              .width('100%')
              .height(48)
              .backgroundColor(AppColors.PRIMARY)
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
        }
        .width('100%')
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  async handleSubmit(): Promise<void> {
    this.showError = false

    if (!this.realName.trim()) {
      this.showError = true
      this.errorMsg = '请输入真实姓名'
      return
    }

    const id = this.idCard.trim().toUpperCase()
    if (!id) {
      this.showError = true
      this.errorMsg = '请输入身份证号'
      return
    }
    if (!InputValidator.isValidIdCard(id)) {
      this.showError = true
      this.errorMsg = '请输入正确的 18 位身份证号'
      return
    }

    try {
      await AuthService.realNameAuth(this.realName.trim(), id)
      this.submitted = true
      this.existing = true
    } catch (e) {
      this.showError = true
      this.errorMsg = (e as Error).message || '认证失败'
    }
  }
}
