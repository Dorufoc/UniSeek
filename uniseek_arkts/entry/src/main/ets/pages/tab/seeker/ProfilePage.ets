import { AuthService } from '../../../services/AuthService';
import { UserService } from '../../../services/UserService';
import { ApiClient } from '../../../services/ApiClient';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../../../common/AppStyles';

@Component
export struct ProfilePage {
  @State username: string = ''
  @State avatarUri: string = ''
  @State isVerified: boolean = false
  @State applications: number = 0
  @State interviews: number = 0
  @State favorites: number = 0
  @State loadErrorText: string = ''

  aboutToAppear(): void {
    this.reloadProfile()
  }

  reloadProfile(): void {
    this.loadErrorText = ''
    this.loadUser()
    this.loadStats()
    AuthService.getRealNameStatus().then((info) => {
      this.isVerified = info.status === 1
    }).catch(() => {
      this.loadErrorText = '部分个人信息加载失败'
    })
  }

  async loadUser(): Promise<void> {
    try {
      const user = await AuthService.getCurrentUser()
      this.username = user.nickname || '未设置昵称'
      this.avatarUri = user.avatarUrl || ''
    } catch {
      this.username = '未设置昵称'
      this.avatarUri = ''
      this.loadErrorText = '部分个人信息加载失败'
    }
  }

  avatarSource(): Resource | string {
    if (!this.avatarUri) {
      return $r('app.media.theme')
    }
    if (this.avatarUri.startsWith('http')) {
      return this.avatarUri
    }
    return ApiClient.BASE_URL + (this.avatarUri.startsWith('/') ? this.avatarUri : '/' + this.avatarUri)
  }

  async loadStats(): Promise<void> {
    try {
      const stats = await UserService.getStats()
      this.applications = stats.applications || 0
      this.interviews = stats.interviews || 0
      this.favorites = stats.favorites || 0
    } catch {
      this.applications = 0
      this.interviews = 0
      this.favorites = 0
      this.loadErrorText = '个人统计加载失败'
    }
  }

  build() {
    Column() {
      // HMOS 原生个人信息头部
      Column() {
        Row() {
          Image(this.avatarSource())
            .width(AppSpacing.AVATAR_XL)
            .height(AppSpacing.AVATAR_XL)
            .borderRadius(AppSpacing.AVATAR_XL / 2)

          Column() {
            Text(this.username)
              .fontSize(AppFontSize.XXL)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT_PRIMARY)

            Row() {
              Text(this.isVerified ? '已实名' : '去实名')
                .fontSize(AppFontSize.SM)
                .fontColor(this.isVerified ? AppColors.SUCCESS : AppColors.PRIMARY)
              if (!this.isVerified) {
                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(AppFontSize.SM)
                  .fontColor([AppColors.PRIMARY])
                  .margin({ left: AppSpacing.XS })
              }
            }
            .margin({ top: AppSpacing.SM })
            .accessibilityText('实名认证')
            .onClick(() => {
              if (!this.isVerified) {
                this.getUIContext().getRouter().pushUrl({ url: 'pages/RealNameAuthPage' })
              }
            })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .margin({ left: AppSpacing.MD })

          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(AppFontSize.MD)
            .fontColor([AppColors.TEXT_MUTED])
            .accessibilityText('个人资料')
            .onClick(() => {
              this.getUIContext().getRouter().pushUrl({ url: 'pages/ProfileDetailPage' })
            })
            .stateStyles({
              pressed: {
                .opacity(0.6)
              }
            })
        }
        .width('100%')
        .height(AppSpacing.HEADER_HEIGHT)
        .padding({ left: AppSpacing.LG, right: AppSpacing.LG })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .backgroundColor(AppColors.BG_CARD)

      if (this.loadErrorText) {
        Row({ space: AppSpacing.SM }) {
          Text(this.loadErrorText)
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.DANGER)
            .layoutWeight(1)
          Button('重试', { type: ButtonType.Capsule })
            .height(AppSpacing.BUTTON_HEIGHT_MINI)
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.PRIMARY)
            .backgroundColor(AppColors.SELECTED_BG)
            .onClick(() => { this.reloadProfile() })
        }
        .width('100%')
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.SM })
        .backgroundColor(AppColors.ERROR_BG)
      }

      this.statsCard()

      Column() {
        Column() {
          this.menuItem('已投简历', $r('sys.symbol.doc_text'), 'pages/SubmittedPage')
          Divider().width('100%').color(AppColors.BORDER).height(AppSpacing.DIVIDER_THICKNESS)
          this.menuItem('收藏', $r('sys.symbol.star'), 'pages/FavoritesPage')
          Divider().width('100%').color(AppColors.BORDER).height(AppSpacing.DIVIDER_THICKNESS)
          this.menuItem('个人简历', $r('sys.symbol.doc_text'), 'pages/ResumePage')
          Divider().width('100%').color(AppColors.BORDER).height(AppSpacing.DIVIDER_THICKNESS)
          this.menuItem('设置', $r('sys.symbol.gearshape'), 'pages/SettingsPage')
          Divider().width('100%').color(AppColors.BORDER).height(AppSpacing.DIVIDER_THICKNESS)
          this.menuItem('账号管理', $r('sys.symbol.lock'), 'pages/ProfileDetailPage')
        }
        .width('100%')
        .backgroundColor(AppColors.BG_CARD)
      }
      .width('100%')
      .margin({ top: AppSpacing.MD })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  @Builder
  statsCard() {
    Row() {
      this.statItem(this.applications, '已投简历', (): void => { this.getUIContext().getRouter().pushUrl({ url: 'pages/SubmittedPage', params: { tab: 'applications' } }) })
      this.statItem(this.interviews, '待面试', (): void => { this.getUIContext().getRouter().pushUrl({ url: 'pages/SubmittedPage', params: { tab: 'interviews' } }) })
      this.statItem(this.favorites, '收藏职位', (): void => { this.getUIContext().getRouter().pushUrl({ url: 'pages/FavoritesPage' }) })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceAround)
    .padding({ top: AppSpacing.MD, bottom: AppSpacing.MD })
    .backgroundColor(AppColors.BG_CARD)
    .margin({ top: AppSpacing.SM })
  }

  @Builder
  statItem(value: number, label: string, onClick: () => void) {
    Column() {
      Text(value.toString())
        .fontSize(AppFontSize.XL)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.PRIMARY)
      Text(label)
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_MUTED)
        .margin({ top: AppSpacing.XS })
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
    .onClick(onClick)
    .stateStyles({ pressed: { .opacity(0.72) } })
  }

  @Builder menuItem(text: string, icon: Resource, target: string) {
    Row() {
      SymbolGlyph(icon)
        .fontSize(AppFontSize.ICON_LG)
        .fontColor([AppColors.TEXT_PRIMARY])
        .margin({ right: AppSpacing.MD })
      Text(text)
        .fontSize(AppFontSize.MD)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(AppFontSize.MD)
        .fontColor([AppColors.TEXT_MUTED])
    }
    .width('100%')
    .height(AppSpacing.BOTTOM_ACTION_HEIGHT)
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
    .accessibilityText(text)
    .onClick(() => {
      this.getUIContext().getRouter().pushUrl({ url: target })
    })
    .stateStyles({
      pressed: {
        .backgroundColor(AppColors.SELECTED_BG)
      }
    })
  }
}
