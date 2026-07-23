import { router } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';
import { AuthService } from '../services/AuthService';

@Entry
@Component
struct SettingsPage {
  async handleLogout(): Promise<void> {
    try {
      const pref = preferences.getPreferencesSync(getContext(), { name: 'search_history_db' })
      pref.clearSync()
      pref.flushSync()
    } catch {
    }
    await AuthService.logout()
    router.replaceUrl({ url: 'pages/LoginPage' })
  }

  build() {
    Column() {
      NavBar({
        title: '设置',
        showBack: true,
        onBack: () => router.back()
      })

      List({ space: AppSpacing.SM }) {
        ListItem() { this.settingRow('用户协议', '查看服务使用规则', (): void => { router.pushUrl({ url: 'pages/UserAgreementPage' }) }) }
        ListItem() { this.settingRow('隐私政策', '查看信息处理说明', (): void => { router.pushUrl({ url: 'pages/PrivacyPolicyPage' }) }) }
        ListItem() { this.settingRow('关于 UniSeek', '校园招聘与求职服务', (): void => {}) }
        ListItem() {
          Row() {
            Text('当前版本').fontSize(AppFontSize.SM).fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1)
            Text('1.0.0').fontSize(AppFontSize.SM).fontColor(AppColors.TEXT_MUTED)
          }
          .height(52)
          .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
          .backgroundColor(AppColors.BG_CARD)
          .borderRadius(AppRadius.MD)
        }
      }
      .layoutWeight(1)
      .width('100%')
      .padding(AppSpacing.MD)

      Button({ type: ButtonType.Capsule }) {
        Text('退出登录')
          .fontSize(AppFontSize.MD)
          .fontColor('#FFFFFF')
      }
        .width('90%')
        .height(48)
        .backgroundColor(AppColors.DANGER)
        .margin({ bottom: AppSpacing.XXL })
        .onClick(() => {
          this.handleLogout()
        })
        .stateStyles({
          pressed: {
            .scale({ x: 0.97, y: 0.97 })
            .opacity(0.9)
            .backgroundColor(AppColors.DANGER)
          },
          normal: {
            .scale({ x: 1, y: 1 })
            .opacity(1)
            .backgroundColor(AppColors.DANGER)
          }
        })
        .animation({
          duration: 200
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
    .padding({ top: AppSpacing.SM })
  }

  @Builder
  settingRow(title: string, subtitle: string, onClick: () => void) {
    Row() {
      Column({ space: AppSpacing.XS }) {
        Text(title).fontSize(AppFontSize.SM).fontColor(AppColors.TEXT_PRIMARY)
        Text(subtitle).fontSize(AppFontSize.XS).fontColor(AppColors.TEXT_MUTED)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor([AppColors.TEXT_MUTED])
    }
    .height(60)
    .width('100%')
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius(AppRadius.MD)
    .onClick(onClick)
  }
}
