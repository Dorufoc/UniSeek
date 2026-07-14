import { router } from '@kit.ArkUI';

@Component
export struct HomePage {
  @State activeCategory: string = '全职'

  build() {
    Column() {
      Row() {
        Text('如果你想要，就自己来找')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)

        Row() {
          Image($r('app.media.search'))
            .width(18)
            .height(18)
            .fillColor('#999999')
          Text('搜索')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ left: 6 })
        }
        .height(36)
        .backgroundColor('#F5F5F5')
        .borderRadius(18)
        .padding({ left: 12, right: 16 })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          router.pushUrl({ url: 'pages/SearchPage' })
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      Row() {
        ForEach(['全职', '实习', '兼职'], (category: string) => {
          Text(category)
            .fontSize(16)
            .fontColor(this.activeCategory === category ? '#333333' : '#999999')
            .fontWeight(this.activeCategory === category ? FontWeight.Bold : FontWeight.Regular)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .height(40)
            .onClick(() => {
              this.activeCategory = category
              // TODO: 加载对应分类的职位数据
            })
        })
      }
      .width('100%')
      .margin({ top: 4 })

      Column()
        .layoutWeight(1)
        .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .padding({ top: 12 })
  }
}
