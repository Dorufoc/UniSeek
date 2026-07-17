import { router } from '@kit.ArkUI';
import { ChatService } from '../services/ChatService';
import { JobData } from '../services/ChatTypes';
import { RecordService } from '../services/RecordService';
import { FavoriteService } from '../services/FavoriteService';
import { SALARY_UNIT_LABELS } from '../services/RecruiterTypes';

@Entry
@Component
struct JobDetailPage {
  @State job: JobData = {
    id: '', title: '', company: '', salary: '',
    salaryMid: 0, popularity: 0, region: '',
    type: '', category: '', description: '',
    enterpriseId: 0, categoryId: 0, regionId: 0,
    salaryMin: 0, salaryMax: 0, salaryUnit: 0,
    jobType: 0, status: 0, hasApplied: false,
    applicationId: 0,
    tag: [], remainingQuota: 0,
    hrName: '', hrAvatar: ''
  }
  @State applied: boolean = false
  @State favorited: boolean = false
  @State hideActions: boolean = false
  @State showError: boolean = false
  @State errorMsg: string = ''

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    if (params['jobData']) {
      this.job = JSON.parse(params['jobData']) as JobData
      RecordService.addViewedJob(this.job)
      this.applied = this.job.hasApplied
      FavoriteService.checkFavorited(Number(this.job.id)).then((fav: boolean) => {
        this.favorited = fav
      }).catch(() => {
        this.favorited = false
      })
    }
    if (params['hideActions']) {
      this.hideActions = params['hideActions'] === 'true'
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

      if (this.showError) {
        Text(this.errorMsg)
          .fontSize(14)
          .fontColor('#FF4444')
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor('#FFF0F0')
          .borderRadius(8)
          .margin({ left: 16, right: 16 })
      }

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
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#007AFF')
            Text(SALARY_UNIT_LABELS[this.job.salaryUnit] ?? '月薪')
              .fontSize(12)
              .fontColor('#FFFFFF')
              .backgroundColor('#007AFF')
              .borderRadius(4)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .margin({ left: 8 })
            Text('剩余:' + this.job.remainingQuota)
              .fontSize(12)
              .fontColor('#BBBBBB')
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

          if (this.job.tag && this.job.tag.length > 0) {
            Row() {
              ForEach(this.job.tag, (tag: string) => {
                Text(tag)
                  .fontSize(12)
                  .fontColor('#999999')
                  .backgroundColor('#F5F5F5')
                  .borderRadius(4)
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .margin({ right: 8 })
              }, (tag: string) => tag)
            }
            .margin({ top: 8 })
            .width('100%')
          }

          Divider()
            .margin({ top: 20, bottom: 16 })

          Row() {
            Image(this.job.hrAvatar ? this.job.hrAvatar : $r('app.media.theme'))
              .width(48)
              .height(48)
              .borderRadius(24)
              .margin({ right: 12 })

            Column() {
              Text('招聘HR')
                .fontSize(12)
                .fontColor('#999999')

              Text(this.job.hrName || '招聘方')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
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
            .margin({ bottom: 10 })

          RichText('<p>' + (this.job.description || '').replace(/\n/g, '<br/>') + '</p>')
            .width('100%')
        }
        .padding({ left: 16, right: 16, bottom: 24 })
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')

      if (!this.hideActions) {
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
            const newFav = !this.favorited
            this.favorited = newFav
            if (newFav) {
              FavoriteService.addFavorite(Number(this.job.id)).catch(() => {
                this.favorited = false
              })
            } else {
              FavoriteService.removeFavorite(Number(this.job.id)).catch(() => {
                this.favorited = true
              })
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
              this.showError = false
              if (this.applied) {
                if (this.job.applicationId > 0) {
                  router.pushUrl({
                    url: 'pages/ChatDetailPage',
                    params: {
                      applicationId: this.job.applicationId,
                      counterpartName: this.job.hrName || '招聘方',
                      counterpartAvatar: this.job.hrAvatar || ''
                    }
                  })
                } else {
                  this.errorMsg = '未找到会话信息，请从消息列表进入'
                  this.showError = true
                }
                return
              }
              ChatService.createApplication(Number(this.job.id)).then((app) => {
                this.applied = true
                router.pushUrl({
                  url: 'pages/ChatDetailPage',
                  params: {
                    applicationId: app.id,
                    counterpartName: this.job.hrName || '招聘方',
                    counterpartAvatar: this.job.hrAvatar || ''
                  }
                })
              }).catch((e: Error) => {
                this.errorMsg = e.message || '投递失败，请稍后重试'
                this.showError = true
              })
            })
        }
        .width('90%')
        .margin({ bottom: 24 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .alignItems(HorizontalAlign.Center)
  }
}
