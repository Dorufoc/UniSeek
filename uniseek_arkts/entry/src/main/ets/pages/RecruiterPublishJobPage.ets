import { router } from '@kit.ArkUI';
import { RecruiterService } from '../services/RecruiterService';
import {
  RecruiterJobVO,
  JOB_STATUS_LABELS,
  JOB_TYPE_LABELS,
  SALARY_UNIT_LABELS,
  AUDIT_STATUS_LABELS
} from '../services/RecruiterTypes';

@Entry
@Component
struct RecruiterPublishJobPage {
  @State jobList: RecruiterJobVO[] = []
  @State isLoading: boolean = true
  @State auditStatus: number = -1

  aboutToAppear(): void {
    this.loadJobs()
    this.loadAuditStatus()
  }

  loadAuditStatus(): void {
    RecruiterService.getEnterpriseInfo().then((info) => {
      if (info) {
        this.auditStatus = info.auditStatus
      }
    })
  }

  loadJobs(): void {
    this.isLoading = true
    RecruiterService.getMyJobs().then((list: RecruiterJobVO[]) => {
      this.jobList = list
      this.isLoading = false
    })
  }

  build() {
    Column() {
      this.topBar()

      if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column() {
            if (this.auditStatus >= 0 && this.auditStatus !== 1) {
              Row() {
                Text('企业资质' + AUDIT_STATUS_LABELS[this.auditStatus] + '，暂无法发布新职位')
                  .fontSize(13)
                  .fontColor('#FF6B35')
                  .layoutWeight(1)
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#FFF3E0')
              .borderRadius(8)
              .margin({ top: 12 })
            }

            Button('发布新职位')
              .width('100%')
              .height(48)
              .backgroundColor(this.auditStatus === 1 ? '#007AFF' : '#CCCCCC')
              .borderRadius(8)
              .fontColor('#FFFFFF')
              .fontSize(16)
              .margin({ top: 12 })
              .enabled(this.auditStatus === 1)
              .onClick(() => {
                if (this.auditStatus !== 1) {
                  this.getUIContext().showAlertDialog({ message: '企业资质审核未通过，暂无法发布职位', confirm: { value: '确定', action: () => {} } })
                  return
                }
                router.pushUrl({ url: 'pages/RecruiterJobFormPage' })
              })

            if (this.jobList.length === 0) {
              Column() {
                Text('暂无已发布职位')
                  .fontSize(14)
                  .fontColor('#999999')
                  .margin({ top: 40 })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
            } else {
              ForEach(this.jobList, (job: RecruiterJobVO) => {
                JobManageCard({
                  job: job,
                  onDelete: () => { this.deleteJob(job.id) }
                })
              })
            }
          }
          .padding(16)
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  topBar(): void {
    Row() {
      Image($r('app.media.left_arrow'))
        .width(24).height(24)
        .fillColor('#333333')
        .onClick(() => { router.back() })
      Text('发布职位')
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
  }

  deleteJob(jobId: number): void {
    RecruiterService.deleteJob(jobId).then((success: boolean) => {
      if (success) {
        this.loadJobs()
      }
    })
  }
}

@Component
struct JobManageCard {
  job: RecruiterJobVO = {
    id: 0, title: '', salaryMin: 0, salaryMax: 0, salaryUnit: 0,
    jobType: 1, address: '', status: 0, applicationCount: 0,
    remainingQuota: 0, totalQuota: 0, deadline: '', createTime: ''
  }
  onDelete?: () => void

  build() {
    Column() {
      Row() {
        Column() {
          Text(this.job.title)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.job.salaryMin.toString() + '-' + this.job.salaryMax.toString() + '元/'
            + SALARY_UNIT_LABELS[this.job.salaryUnit] + ' · '
            + JOB_TYPE_LABELS[this.job.jobType])
            .fontSize(13)
            .fontColor('#FF6B35')
            .margin({ top: 4 })

          Row() {
            Text(JOB_STATUS_LABELS[this.job.status])
              .fontSize(12)
              .fontColor(this.job.status === 1 ? '#34C759' : '#999999')
              .backgroundColor(this.job.status === 1 ? '#E8F8ED' : '#F5F5F5')
              .borderRadius(8)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })

            Text(this.job.applicationCount.toString() + '人投递')
              .fontSize(12)
              .fontColor('#999999')
              .margin({ left: 8 })
          }
          .margin({ top: 6 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text('删除')
          .fontSize(13)
          .fontColor('#FF4444')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .onClick(() => {
            this.onDelete?.()
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ top: 8 })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/JobDetailPage',
        params: {
          jobData: JSON.stringify(this.job),
          hideActions: 'true'
        }
      })
    })
  }
}
