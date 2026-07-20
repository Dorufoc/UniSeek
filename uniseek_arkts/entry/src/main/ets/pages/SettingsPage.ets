import { router } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';

@Entry
@Component
struct SettingsPage {
  handleLogout() {
    let pref = preferences.getPreferencesSync(getContext(), { name: 'search_history_db' })
    pref.clearSync()
    pref.flushSync()
    router.replaceUrl({ url: 'pages/LoginPage' })
  }

  build() {
    Column() {
      NavBar({
        title: '设置',
        showBack: true,
        onBack: () => router.back()
      })

      Blank().layoutWeight(1)

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
}
