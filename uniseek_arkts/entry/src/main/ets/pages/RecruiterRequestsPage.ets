import { router } from '@kit.ArkUI';

@Entry
@Component
struct RecruiterRequestsPage {
  build() {
    Column() {
      Row() {
        Image($r('app.media.left_arrow'))
          .width(24).height(24)
          .fillColor('#333333')
          .onClick(() => { router.back() })
        Text('请求处理')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('')
          .width(24)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFF')

      Column() {
        Text('请求处理功能开发中')
          .fontSize(16)
          .fontColor('#999999')
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
