@Component
export struct ChatPage {
  build() {
    Column() {
      Text('聊天')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
