import { router } from '@kit.ArkUI';

interface JobData {
  id: string
  title: string
  company: string
  salary: string
  salaryMid: number
  popularity: number
  region: string
  type: string
  category: string
  description: string
}

@Entry
@Component
struct JobDetailPage {
  @State job: JobData = {
    id: '', title: '', company: '', salary: '',
    salaryMid: 0, popularity: 0, region: '',
    type: '', category: '', description: ''
  }

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    if (params['jobData']) {
      this.job = JSON.parse(params['jobData']) as JobData
    }
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.search'))
          .width(24)
          .height(24)
          .fillColor('#333333')
          .onClick(() => { router.back() })
        Text('职位详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Row().width(24).height(24)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          Text(this.job.title)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .width('100%')

          Text(this.job.company)
            .fontSize(16)
            .fontColor('#666666')
            .margin({ top: 8 })
            .width('100%')

          Row() {
            Text(this.job.salary)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF6B35')
            Text(this.job.popularity + '人投递')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ left: 16 })
          }
          .margin({ top: 12 })
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row() {
            Text(this.job.region)
              .fontSize(13)
              .fontColor('#666666')
              .backgroundColor('#F5F5F5')
              .borderRadius(4)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            Text(this.job.type)
              .fontSize(13)
              .fontColor('#666666')
              .backgroundColor('#F5F5F5')
              .borderRadius(4)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .margin({ left: 10 })
            Text(this.job.category)
              .fontSize(13)
              .fontColor('#666666')
              .backgroundColor('#F5F5F5')
              .borderRadius(4)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .margin({ left: 10 })
          }
          .margin({ top: 12 })
          .width('100%')

          Divider()
            .margin({ top: 20, bottom: 16 })

          Text('职位描述')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .width('100%')

          Text(this.job.description)
            .fontSize(15)
            .fontColor('#666666')
            .lineHeight(24)
            .margin({ top: 10 })
            .width('100%')
        }
        .padding({ left: 16, right: 16, bottom: 24 })
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')

      Button('立即投递')
        .width('90%')
        .height(48)
        .backgroundColor('#FF6B35')
        .fontColor('#FFFFFF')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .borderRadius(24)
        .margin({ bottom: 24 })
        .onClick(() => {})
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .alignItems(HorizontalAlign.Center)
  }
}
