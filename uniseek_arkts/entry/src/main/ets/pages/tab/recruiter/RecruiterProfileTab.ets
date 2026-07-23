import { router } from '@kit.ArkUI';
import { AuthService } from '../../../services/AuthService';
import { UserService } from '../../../services/UserService';
import { ApiClient } from '../../../services/ApiClient';
import { RecruiterService } from '../../../services/RecruiterService';
import { AUDIT_STATUS_LABELS } from '../../../services/RecruiterTypes';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../../../common/AppStyles';

@Component
export struct RecruiterProfileTab {
  @State username: string = ''
  @State avatarUri: string = ''
  @State isVerified: boolean = false
  @State enterpriseAuditStatus: number = -1
  @State receivedResumes: number = 0
  @State hired: number = 0
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
    RecruiterService.getEnterpriseInfo().then((info) => {
      if (info) {
        this.enterpriseAuditStatus = info.auditStatus
      }
    }).catch(() => {
      this.loadErrorText = '企业资质状态加载失败'
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
      this.receivedResumes = stats.receivedResumes || 0
      this.hired = stats.hired || 0
    } catch {
      this.receivedResumes = 0
      this.hired = 0
      this.loadErrorText = '招聘统计加载失败'
    }
  }

  build() {
    Column() {
      Column() {
        Row() {
          Image(this.avatarSource())
            .width(72)
            .height(72)
            .borderRadius(36)

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
                  .fontSize(14)
                  .fontColor([AppColors.PRIMARY])
                  .margin({ left: AppSpacing.XS })
              }
            }
            .margin({ top: AppSpacing.SM })
            .onClick(() => {
              if (!this.isVerified) {
                router.pushUrl({ url: 'pages/RealNameAuthPage' })
              }
            })

            Row() {
              Text('企业资质：')
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.TEXT_SECONDARY)
              Text(this.enterpriseAuditStatus >= 0 ? AUDIT_STATUS_LABELS[this.enterpriseAuditStatus] : '未审核')
                .fontSize(AppFontSize.SM)
                .fontColor(this.enterpriseAuditStatus === 1 ? AppColors.SUCCESS : AppColors.PRIMARY)
              if (this.enterpriseAuditStatus !== 1) {
                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(14)
                  .fontColor([AppColors.PRIMARY])
                  .margin({ left: AppSpacing.XS })
              }
            }
            .margin({ top: AppSpacing.XS })
            .onClick(() => {
              router.pushUrl({ url: 'pages/RecruiterEnterprisePage' })
            })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .margin({ left: AppSpacing.MD })

          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(AppFontSize.MD)
            .fontColor([AppColors.TEXT_MUTED])
            .onClick(() => {
              router.pushUrl({ url: 'pages/ProfileDetailPage' })
            })
        }
        .width('100%')
        .height(128)
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
            .height(32)
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
          this.menuItemCheck('我的公司', $r('sys.symbol.building'), () => {
            if (!this.isVerified) {
              this.getUIContext().showAlertDialog({ message: '请先完成实名认证', confirm: { value: '确定', action: () => {} } })
              return
            }
            router.pushUrl({ url: 'pages/RecruiterEnterprisePage' })
          })
          Divider().width('100%').color(AppColors.BORDER).height(0.5)
          this.menuItemCheck('发布职位', $r('sys.symbol.briefcase'), () => {
            if (this.enterpriseAuditStatus !== 1) {
              this.getUIContext().showAlertDialog({ message: '企业资质审核未通过，暂无法发布职位', confirm: { value: '确定', action: () => {} } })
              return
            }
            router.pushUrl({ url: 'pages/RecruiterPublishJobPage' })
          })
          Divider().width('100%').color(AppColors.BORDER).height(0.5)
          this.menuItemCheck('请求处理', $r('sys.symbol.inbox'), () => {
            router.pushUrl({ url: 'pages/RecruiterRequestsPage' })
          })
          Divider().width('100%').color(AppColors.BORDER).height(0.5)
          this.menuItemCheck('设置', $r('sys.symbol.gearshape'), () => {
            router.pushUrl({ url: 'pages/SettingsPage' })
          })
          Divider().width('100%').color(AppColors.BORDER).height(0.5)
          this.menuItemCheck('账号管理', $r('sys.symbol.lock'), () => {
            router.pushUrl({ url: 'pages/ProfileDetailPage' })
          })
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
      this.statItem(this.receivedResumes, '收到简历')
      this.statItem(this.hired, '已录用')
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceAround)
    .padding({ top: AppSpacing.MD, bottom: AppSpacing.MD })
    .backgroundColor(AppColors.BG_CARD)
    .margin({ top: AppSpacing.SM })
  }

  @Builder
  statItem(value: number, label: string) {
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
  }

  @Builder menuItemCheck(text: string, icon: Resource, onClick: () => void) {
    Row() {
      SymbolGlyph(icon)
        .fontSize(22)
        .fontColor([AppColors.TEXT_PRIMARY])
        .margin({ right: AppSpacing.MD })
      Text(text)
        .fontSize(AppFontSize.MD)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor([AppColors.TEXT_MUTED])
    }
    .width('100%')
    .height(56)
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
    .onClick(onClick)
    .stateStyles({
      pressed: {
        .backgroundColor(AppColors.SELECTED_BG)
      }
    })
  }
}
