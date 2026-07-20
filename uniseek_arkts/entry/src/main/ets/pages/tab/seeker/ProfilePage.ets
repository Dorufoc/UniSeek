import { router } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { AuthService } from '../../../services/AuthService';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../../../common/AppStyles';

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
            .stateStyles({
              pressed: {
                .opacity(0.6)
              }
            })
        }
        .width('100%')
        .height(104)
        .padding({ left: AppSpacing.LG, right: AppSpacing.LG })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')

      // HMOS 菜单卡片
      Column() {
        Column() {
          this.menuItem('已投简历', $r('sys.symbol.doc_text'), 'pages/SubmittedPage')
          Divider().width('100%').color(AppColors.BORDER).height(0.5)
          this.menuItem('收藏', $r('sys.symbol.star'), 'pages/FavoritesPage')
          Divider().width('100%').color(AppColors.BORDER).height(0.5)
          this.menuItem('个人简历', $r('sys.symbol.doc_text'), 'pages/ResumePage')
          Divider().width('100%').color(AppColors.BORDER).height(0.5)
          this.menuItem('设置', $r('sys.symbol.gearshape'), 'pages/SettingsPage')
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

  @Builder menuItem(text: string, icon: Resource, target: string) {
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
    .onClick(() => {
      router.pushUrl({ url: target })
    })
    .stateStyles({
      pressed: {
        .backgroundColor(AppColors.SELECTED_BG)
      }
    })
  }
}
