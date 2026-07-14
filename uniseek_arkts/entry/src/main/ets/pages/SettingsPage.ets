import { router } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';

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
      Row() {
        Text('←')
          .fontSize(20)
          .fontColor('#333333')
          .onClick(() => {
            router.back()
          })
        Text('设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ left: 12 })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      Blank().layoutWeight(1)

      Button('退出登录')
        .width('90%')
        .height(48)
        .backgroundColor('#FF4444')
        .borderRadius(8)
        .fontColor('#FFFFFF')
        .fontSize(16)
        .margin({ bottom: 40 })
        .onClick(() => {
          this.handleLogout()
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .padding({ top: 12 })
  }
}
