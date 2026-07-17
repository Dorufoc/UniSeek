import { router } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { AuthService } from '../../../services/AuthService';

const PREF_NAME = 'user_profile_db';
const KEY_USERNAME = 'username';

@Component
export struct ProfilePage {
  @State username: string = ''
  @State isVerified: boolean = false

  aboutToAppear(): void {
    this.loadUsername()
    AuthService.getRealNameStatus().then((info) => {
      this.isVerified = info.status === 1
    }).catch(() => {})
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
              .fontColor('#FFFFFF')

            Row() {
              Text(this.isVerified ? '已实名' : '去实名')
                .fontSize(13)
                .fontColor(this.isVerified ? '#8CE0FF' : '#FFFFFF')
              if (!this.isVerified) {
                Image($r('app.media.right_arrow'))
                  .width(14)
                  .height(14)
                  .fillColor('#FFFFFF')
                  .margin({ left: 2 })
              }
            }
            .margin({ top: 6 })
            .onClick(() => {
              if (!this.isVerified) {
                router.pushUrl({ url: 'pages/RealNameAuthPage' })
              }
            })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .margin({ left: 16 })

          Image($r('app.media.right_arrow'))
            .width(16)
            .height(16)
            .onClick(() => {
              router.pushUrl({ url: 'pages/ProfileDetailPage' })
            })
        }
        .width('100%')
        .height(96)
        .padding({ left: 25, right: 25 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')

      Column() {
        Divider()
          .width('100%')
          .color('#F0F0F0')
          .height(6)

        Column() {
          this.menuItem('已投简历', $r('app.media.resume1'), 'pages/SubmittedPage')
          Divider().width('100%').color('#F0F0F0').height(0.5)
          this.menuItem('收藏', $r('app.media.star'), 'pages/FavoritesPage')
          Divider().width('100%').color('#F0F0F0').height(0.5)
          this.menuItem('个人简历', $r('app.media.resume2'), 'pages/ResumePage')
          Divider().width('100%').color('#F0F0F0').height(0.5)
          this.menuItem('设置', $r('app.media.setting'), 'pages/SettingsPage')
        }
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
      }
      .width('80%')
      .alignSelf(ItemAlign.Center)
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [['#ff4eb2e9', 0], ['#ff18e2fd', 0.08], ['#ffa1e7e4', 0.16], ['#FFFFFF', 0.24], ['#FFFFFF', 1]]
    })
  }

  @Builder menuItem(text: string, icon: Resource, target: string) {
    Row() {
      Image(icon)
        .width(22)
        .height(22)
        .margin({ right: 12 })
      Text(text)
        .fontSize(16)
        .fontColor('#333333')
    }
    .width('100%')
    .height(56)
    .onClick(() => {
      router.pushUrl({ url: target })
    })
  }
}
