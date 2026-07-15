import { router } from '@kit.ArkUI';
import { ChatService } from '../services/ChatService';
import { JobData } from '../services/ChatTypes';
import { RecordService } from '../services/RecordService';

@Entry
@Component
struct JobDetailPage {
  @State job: JobData = {
    id: '', title: '', company: '', salary: '',
    salaryMid: 0, popularity: 0, region: '',
    type: '', category: '', description: ''
  }
  @State hrName: string = '张经理'
  @State hrAvatar: string = ''
  @State applied: boolean = false
  @State favorited: boolean = false

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    if (params['jobData']) {
      this.job = JSON.parse(params['jobData']) as JobData
      RecordService.addViewedJob(this.job)
      this.favorited = RecordService.isFavorited(this.job.id)
    }
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.left_arrow'))
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

          Row() {
            Image(this.hrAvatar ? this.hrAvatar : $r('app.media.theme'))
              .width(48)
              .height(48)
              .borderRadius(24)
              .margin({ right: 12 })

            Column() {
              Text('招聘HR')
                .fontSize(12)
                .fontColor('#999999')

              Text(this.hrName)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)

            Text(this.job.company)
              .fontSize(14)
              .fontColor('#666666')
              .layoutWeight(1)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .padding({ top: 4, bottom: 4 })


          Divider()
            .margin({ top: 16, bottom: 16 })

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

      Row() {
        Button() {
          Row() {
            Image($r('app.media.star'))
              .width(18)
              .height(18)
              .fillColor(this.favorited ? '#FFFFFF' : '#333333')
            Text('收藏')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.favorited ? '#FFFFFF' : '#333333')
              .margin({ left: 4 })
          }
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.Center)
        }
        .layoutWeight(1)
        .height(48)
        .backgroundColor(this.favorited ? '#FFD700' : '#FFFFFF')
        .borderRadius(24)
        .margin({ right: 10 })
        .onClick(() => {
          this.favorited = !this.favorited
          if (this.favorited) {
            RecordService.addFavoriteJob(this.job)
          } else {
            RecordService.removeFavoriteJob(this.job.id)
          }
        })

        Button(this.applied ? '继续沟通' : '立即沟通')
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#007AFF')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .borderRadius(24)
          .onClick(() => {
            if (this.applied) {
              router.pushUrl({
                url: 'pages/ChatDetailPage',
                params: {
                  applicationId: 0,
                  counterpartName: this.hrName,
                  counterpartAvatar: this.hrAvatar
                }
              })
              return
            }
            RecordService.addChattedJob(this.job)
            ChatService.createApplication(Number(this.job.id)).then((app) => {
              if (app) {
                this.applied = true
                router.pushUrl({
                  url: 'pages/ChatDetailPage',
                  params: {
                    applicationId: app.id,
                    counterpartName: this.hrName,
                    counterpartAvatar: this.hrAvatar
                  }
                })
              }
            })
          })
      }
      .width('90%')
      .margin({ bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .alignItems(HorizontalAlign.Center)
  }
}
