import { router } from '@kit.ArkUI';
import { RecruiterService } from '../../../services/RecruiterService';
import {
  RecruiterJobVO,
  JOB_STATUS_LABELS,
  JOB_TYPE_LABELS
} from '../../../services/RecruiterTypes';

@Component
export struct RecruiterHomeTab {
  @State jobList: RecruiterJobVO[] = []

  aboutToAppear(): void {
    RecruiterService.getMyJobs().then((list: RecruiterJobVO[]) => {
      this.jobList = list
    })
  }

  build() {
    Column() {
      Text('招聘者中心')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width('100%')
        .padding({ left: 16, top: 12, bottom: 8 })

      if (this.jobList.length === 0) {
        Column() {
          Text('暂无发布职位')
            .fontSize(16)
            .fontColor('#999999')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.jobList, (job: RecruiterJobVO) => {
            ListItem() {
              RecruiterJobCard({ job: job })
            }
          }, (job: RecruiterJobVO) => job.id.toString())
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }
}

@Component
struct RecruiterJobCard {
  job: RecruiterJobVO = {
    id: 0,
    title: '',
    salaryMin: 0,
    salaryMax: 0,
    salaryUnit: 0,
    jobType: 1,
    address: '',
    status: 0,
    applicationCount: 0,
    remainingQuota: 0,
    totalQuota: 0,
    deadline: '',
    createTime: ''
  }

  build() {
    Row() {
      Column() {
        Row() {
          Text(this.job.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(JOB_STATUS_LABELS[this.job.status])
            .fontSize(11)
            .fontColor(this.job.status === 1 ? '#34C759' : '#999999')
            .backgroundColor(this.job.status === 1 ? '#E8F8ED' : '#F5F5F5')
            .borderRadius(8)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Text(this.job.address)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column() {
        Text(this.job.salaryMin.toString() + '-' + this.job.salaryMax.toString() + '元')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF6B35')

        Text(this.job.applicationCount.toString() + '人投递')
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
    .shadow({ radius: 4, color: '#0D000000', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/RecruiterApplicationsPage',
        params: { jobId: this.job.id.toString(), jobTitle: this.job.title }
      })
    })
  }
}
