import { router } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';

const PREF_NAME = 'user_profile_db';
const KEY_USERNAME = 'username';

@Component
export struct ProfilePage {
  @State username: string = ''

  aboutToAppear(): void {
    this.loadUsername()
  }

  loadUsername(): void {
    let pref = preferences.getPreferencesSync(getContext(), { name: PREF_NAME })
    let saved = pref.getSync(KEY_USERNAME, '') as string
    if (saved) {
      this.username = saved
    } else {
      let num = Math.floor(10000 + Math.random() * 90000)
      this.username = '用户' + num
      pref.putSync(KEY_USERNAME, this.username)
      pref.flushSync()
    }
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.theme'))
          .width(68)
          .height(68)
          .borderRadius(34)

        Column() {
          Text(this.username)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 16 })

        Text('>')
          .fontSize(22)
          .fontColor('#CCCCCC')
          .onClick(() => {
            router.pushUrl({ url: 'pages/ProfileDetailPage' })
          })
      }
      .width('100%')
      .height(96)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      Divider()
        .width('100%')
        .color('#F0F0F0')
        .height(6)

      this.menuItem('已投简历', 'pages/SubmittedPage')
      Divider().width('100%').color('#F0F0F0').height(0.5)
      this.menuItem('收藏', 'pages/FavoritesPage')
      Divider().width('100%').color('#F0F0F0').height(0.5)
      this.menuItem('个人简历', 'pages/ResumePage')
      Divider().width('100%').color('#F0F0F0').height(0.5)
      this.menuItem('设置', 'pages/SettingsPage')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder menuItem(text: string, target: string) {
    Row() {
      Text(text)
        .fontSize(18)
        .fontColor('#333333')
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      router.pushUrl({ url: target })
    })
  }
}
