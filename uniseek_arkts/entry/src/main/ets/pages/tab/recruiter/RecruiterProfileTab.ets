import { router } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { AuthService } from '../../../services/AuthService';
import { RecruiterService } from '../../../services/RecruiterService';
import { AUDIT_STATUS_LABELS } from '../../../services/RecruiterTypes';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../../../common/AppStyles';

const PREF_NAME = 'user_profile_db';
const KEY_USERNAME = 'username';

@Component
export struct RecruiterProfileTab {
  @State username: string = ''
  @State isVerified: boolean = false
  @State enterpriseAuditStatus: number = -1

  aboutToAppear(): void {
    this.loadUsername()
    AuthService.getRealNameStatus().then((info) => {
      this.isVerified = info.status === 1
    }).catch(() => {})
    RecruiterService.getEnterpriseInfo().then((info) => {
      if (info) {
        this.enterpriseAuditStatus = info.auditStatus
      }
    })
  }

  loadUsername(): void {
    let pref = preferences.getPreferencesSync(getContext(), { name: PREF_NAME })
    let saved = pref.getSync(KEY_USERNAME, '') as string
    if (saved) {
      this.username = saved
    } else {
      let num = Math.floor(10000 + Math.random() * 90000)
      this.username = '企业' + num
      pref.putSync(KEY_USERNAME, this.username)
      pref.flushSync()
    }
  }

  build() {
    Column() {
      // HMOS 渐变头像卡片头
      Column() {
        Row() {
          Image($r('app.media.theme'))
            .width(72)
            .height(72)
            .borderRadius(36)

          Column() {
            Text(this.username)
              .fontSize(AppFontSize.XXL)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')

            Row() {
              Text(this.isVerified ? '已实名' : '去实名')
                .fontSize(AppFontSize.SM)
                .fontColor(this.isVerified ? '#8CE0FF' : '#FFFFFF')
              if (!this.isVerified) {
                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(14)
                  .fontColor(['#FFFFFF'])
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
                .fontColor('#CCCCCC')
              Text(this.enterpriseAuditStatus >= 0 ? AUDIT_STATUS_LABELS[this.enterpriseAuditStatus] : '未审核')
                .fontSize(AppFontSize.SM)
                .fontColor(this.enterpriseAuditStatus === 1 ? '#8CE0FF' : '#FFFFFF')
              if (this.enterpriseAuditStatus !== 1) {
                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(14)
                  .fontColor(['#FFFFFF'])
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
            .fontColor(['#FFFFFF'])
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

      // HMOS 菜单卡片
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
        }
        .width('100%')
        .backgroundColor(AppColors.BG_CARD)
        .borderRadius(AppRadius.LG)
      }
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        [AppColors.HMOS_BRAND, 0],
        ['#5A8CFF', 0.12],
        ['#A8C4FF', 0.25],
        ['#E4EEFF', 0.38],
        ['#FFFFFF', 0.5],
        ['#FFFFFF', 1]
      ]
    })
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
