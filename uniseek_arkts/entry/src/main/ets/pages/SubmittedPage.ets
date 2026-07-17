import { router } from '@kit.ArkUI';
import { JobData } from '../services/ChatTypes';
import { RecordService } from '../services/RecordService';

@Component
struct JobCard {
  job: JobData = {
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

  build() {
    Row() {
      Column() {
        Text(this.job.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
        Text(this.job.company)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 6 })
        Row() {
          Text(this.job.region)
            .fontSize(12)
            .fontColor('#999999')
            .backgroundColor('#F5F5F5')
            .borderRadius(4)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          Text(this.job.type)
            .fontSize(12)
            .fontColor('#999999')
            .backgroundColor('#F5F5F5')
            .borderRadius(4)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .margin({ left: 8 })
        }
        .margin({ top: 8 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column() {
        Text(this.job.salary)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF6B35')
        Text(this.job.popularity + '人投递')
          .fontSize(12)
          .fontColor('#BBBBBB')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 16, right: 16, top: 8, bottom: 8 })
    .shadow({ radius: 4, color: '#0D000000', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/JobDetailPage',
        params: { jobData: JSON.stringify(this.job) }
      })
    })
  }
}

@Entry
@Component
struct SubmittedPage {
  @State activeTab: number = 0
  @State viewedJobs: JobData[] = []
  @State chattedJobs: JobData[] = []

  aboutToAppear(): void {
    this.viewedJobs = RecordService.getViewedJobs()
    this.chattedJobs = RecordService.getChattedJobs()
  }

  currentJobs(): JobData[] {
    if (this.activeTab === 0) {
      return this.viewedJobs
    }
    if (this.activeTab === 1) {
      return this.chattedJobs
    }
    return []
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.left_arrow'))
          .width(20)
          .height(20)
          .fillColor('#333333')
          .onClick(() => {
            router.back()
          })
        Text('已投简历')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ left: 12 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .alignItems(VerticalAlign.Center)

      Row() {
        this.tabItem('看过', 0)
        this.tabItem('沟通过', 1)
        this.tabItem('面试', 2)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor('#FFFFFF')

      if (this.currentJobs().length === 0) {
        Column() {
          Text('暂无记录')
            .fontSize(16)
            .fontColor('#999999')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.currentJobs(), (job: JobData) => {
            ListItem() {
              JobCard({ job: job })
            }
          }, (job: JobData) => job.id)
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor('#F8F8F8')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder tabItem(label: string, index: number) {
    Text(label)
      .fontSize(14)
      .fontColor(this.activeTab === index ? '#FFFFFF' : '#666666')
      .backgroundColor(this.activeTab === index ? '#007AFF' : '#F5F5F5')
      .borderRadius(16)
      .padding({ left: 24, right: 24, top: 8, bottom: 8 })
      .margin({ right: 10 })
      .onClick(() => {
        this.activeTab = index
      })
  }
}
