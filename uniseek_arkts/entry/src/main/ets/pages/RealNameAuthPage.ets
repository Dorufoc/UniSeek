import { router } from '@kit.ArkUI';
import { AuthService } from '../services/AuthService';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';

@Entry
@Component
struct RealNameAuthPage {
  @State realName: string = ''
  @State idCard: string = ''
  @State showError: boolean = false
  @State errorMsg: string = ''
  @State submitted: boolean = false
  @State existing: boolean = false

  aboutToAppear(): void {
    AuthService.getRealNameStatus().then((info) => {
      if (info.status === 1) {
        this.existing = true
        this.submitted = true
        this.realName = info.realName
      }
    }).catch(() => {
    })
  }

  build() {
    Column() {
      NavBar({
        title: '实名认证',
        showBack: true,
        onBack: () => router.back()
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
