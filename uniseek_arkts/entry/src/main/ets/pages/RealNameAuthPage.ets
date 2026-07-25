import { AuthService } from '../services/AuthService'
import {
  AppColors,
  AppFontSize,
  AppRadius,
  AppSpacing,
  PrimaryButton,
  StandardInput
} from '../common/AppStyles'
import { NavBar } from '../common/NavBar'
import { InputValidator } from '../common/FormValidators'

@Entry
@Component
struct RealNameAuthPage {
  @State realName: string = ''
  @State idCard: string = ''
  @State realNameError: string = ''
  @State idCardError: string = ''
  @State errorMsg: string = ''
  @State authStatus: number = -1
  @State isSubmitting: boolean = false

  aboutToAppear(): void {
    AuthService.getRealNameStatus()
      .then((info) => {
        this.authStatus = info.status
        if (info.status === 1) {
          this.realName = info.realName
        }
      })
      .catch(() => {
        this.errorMsg = '认证状态加载失败，请检查网络后重试'
      })
  }

  // 是否已通过认证
  private isVerified(): boolean {
    return this.authStatus === 1
  }

  // 是否审核中
  private isPending(): boolean {
    return this.authStatus === 2
  }

  // 是否显示表单
  private showForm(): boolean {
    return this.authStatus !== 1 && this.authStatus !== 2
  }

  // 页面头部：图标 + 标题 + 说明
  @Builder
  pageHeader() {
    Column({ space: AppSpacing.SM }) {
      Stack() {
        SymbolGlyph(this.isVerified() ? $r('sys.symbol.checkmark') : $r('sys.symbol.person'))
          .fontSize(AppFontSize.XXXL)
          .fontColor([this.isVerified() ? AppColors.SUCCESS : AppColors.PRIMARY])
      }
      .width(88)
      .height(88)
      .borderRadius(AppRadius.FULL)
      .backgroundColor(this.isVerified() ? AppColors.SUCCESS_BG : AppColors.PRIMARY_ALPHA_8)

      Text('实名认证')
        .fontSize(AppFontSize.XXL)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)

      Text(this.isVerified() ? '您的身份信息已通过认证，可正常使用平台服务' : '完成实名认证后即可投递职位、发布信息')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: AppSpacing.LG, bottom: AppSpacing.SM })
  }

  // 通用状态卡片容器
  @Builder
  statusCard(icon: Resource, title: string, desc: string, iconColor: ResourceColor, bgColor: ResourceColor) {
    Row({ space: AppSpacing.MD }) {
      Stack() {
        SymbolGlyph(icon)
          .fontSize(AppFontSize.ICON_LG)
          .fontColor([iconColor])
      }
      .width(AppSpacing.ICON_XL)
      .height(AppSpacing.ICON_XL)
      .borderRadius(AppRadius.FULL)
      .backgroundColor(bgColor)

      Column({ space: AppSpacing.XS }) {
        Text(title)
          .fontSize(AppFontSize.LG)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
          .width('100%')

        Text(desc)
          .fontSize(AppFontSize.SM)
          .fontColor(AppColors.TEXT_SECONDARY)
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius(AppRadius.LG)
    .padding(AppSpacing.MD)
  }

  // 已通过状态卡片
  @Builder
  verifiedCard() {
    this.statusCard(
      $r('sys.symbol.checkmark'),
      this.realName || '已认证用户',
      '已通过实名认证',
      AppColors.SUCCESS,
      AppColors.SUCCESS_BG
    )
  }

  // 审核中状态卡片
  @Builder
  pendingCard() {
    this.statusCard(
      $r('sys.symbol.info_circle'),
      '认证审核中',
      '信息已提交，工作人员将在 1-3 个工作日内完成审核',
      AppColors.WARNING,
      AppColors.WARNING_BG
    )
  }

  // 全局错误提示
  @Builder
  errorBanner(message: string) {
    Row({ space: AppSpacing.SM }) {
      SymbolGlyph($r('sys.symbol.exclamationmark_circle'))
        .fontSize(AppFontSize.ICON_MD)
        .fontColor([AppColors.DANGER])

      Text(message)
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.DANGER)
        .layoutWeight(1)
    }
    .width('100%')
    .backgroundColor(AppColors.ERROR_BG)
    .borderRadius(AppRadius.LG)
    .padding(AppSpacing.MD)
  }

  // 表单卡片
  @Builder
  formCard() {
    Column({ space: AppSpacing.LG }) {
      // 真实姓名
      Column({ space: AppSpacing.XS }) {
        Text('真实姓名')
          .fontSize(AppFontSize.SM)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
          .width('100%')

        StandardInput({
          value: $realName,
          placeholder: '请输入真实姓名',
          leadingIcon: $r('sys.symbol.person'),
          maxLength: 30,
          hasError: this.realNameError.length > 0,
          errorText: this.realNameError
        })
          .enabled(this.showForm())
      }
      .width('100%')

      // 身份证号
      Column({ space: AppSpacing.XS }) {
        Text('身份证号')
          .fontSize(AppFontSize.SM)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
          .width('100%')

        StandardInput({
          value: $idCard,
          placeholder: '请输入 18 位身份证号',
          leadingIcon: $r('sys.symbol.doc_text'),
          maxLength: 18,
          hasError: this.idCardError.length > 0,
          errorText: this.idCardError
        })
          .enabled(this.showForm())
      }
      .width('100%')

      PrimaryButton({
        text: '提交认证',
        loading: this.isSubmitting,
        onTap: () => { void this.handleSubmit() }
      })

      Text('身份信息仅用于实名认证，UniSeek 不会对外展示或泄露您的隐私')
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_MUTED)
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius(AppRadius.LG)
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.LG, bottom: AppSpacing.LG })
  }

  build() {
    Column() {
      NavBar({
        title: '实名认证',
        showBack: true,
        onBack: () => this.getUIContext().getRouter().back()
      })

      Scroll() {
        Column({ space: AppSpacing.LG }) {
          this.pageHeader()

          if (this.errorMsg.length > 0) {
            this.errorBanner(this.errorMsg)
          }

          if (this.isVerified()) {
            this.verifiedCard()
          } else if (this.isPending()) {
            this.pendingCard()
          }

          if (this.showForm()) {
            this.formCard()
          }
        }
        .width('100%')
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.LG, bottom: AppSpacing.XL })
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  private validateForm(): boolean {
    this.realNameError = ''
    this.idCardError = ''
    this.errorMsg = ''

    if (!this.realName.trim()) {
      this.realNameError = '请输入真实姓名'
    }

    const cardNo = this.idCard.trim().toUpperCase()
    if (!cardNo) {
      this.idCardError = '请输入身份证号'
    } else if (!InputValidator.isValidIdCard(cardNo)) {
      this.idCardError = '请输入正确的 18 位身份证号'
    }

    return this.realNameError.length === 0 && this.idCardError.length === 0
  }

  async handleSubmit(): Promise<void> {
    if (!this.validateForm()) {
      return
    }

    this.isSubmitting = true
    try {
      await AuthService.realNameAuth(this.realName.trim(), this.idCard.trim().toUpperCase())
      this.authStatus = 1
      this.realName = this.realName.trim()
      this.idCard = ''
    } catch (e) {
      this.errorMsg = (e as Error).message || '认证失败，请稍后重试'
    }
    this.isSubmitting = false
  }
}
