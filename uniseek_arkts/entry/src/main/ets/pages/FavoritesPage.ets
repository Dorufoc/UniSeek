import { router } from '@kit.ArkUI';

@Entry
@Component
struct FavoritesPage {
  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(20)
          .fontColor('#333333')
          .onClick(() => {
            router.back()
          })
        Text('收藏')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ left: 12 })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      Column() {
        Text('收藏页面')
          .fontSize(16)
          .fontColor('#999999')
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .padding({ top: 12 })
  }
}
