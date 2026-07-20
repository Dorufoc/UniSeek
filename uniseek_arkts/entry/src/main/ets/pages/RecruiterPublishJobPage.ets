import { router } from '@kit.ArkUI';
import { RecruiterService } from '../services/RecruiterService';
import {
  RecruiterJobVO,
  JOB_STATUS_LABELS,
  JOB_TYPE_LABELS,
  SALARY_UNIT_LABELS,
  AUDIT_STATUS_LABELS
} from '../services/RecruiterTypes';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';

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
      NavBar({
        title: '发布职位',
        showBack: true,
        onBack: () => router.back()
      })

      if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
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
                  .fontSize(AppFontSize.XS)
                  .fontColor(AppColors.WARNING)
                  .layoutWeight(1)
              }
              .width('100%')
              .padding(AppSpacing.SM)
              .backgroundColor('#FFF3E0')
              .borderRadius(AppRadius.SM)
              .margin({ top: AppSpacing.SM })
            }

            Button({ type: ButtonType.Capsule }) {
              Text('发布新职位')
                .fontSize(AppFontSize.MD)
                .fontColor('#FFFFFF')
            }
              .width('100%')
              .height(48)
              .backgroundColor(this.auditStatus === 1 ? AppColors.PRIMARY : AppColors.TEXT_MUTED)
              .margin({ top: AppSpacing.SM })
              .enabled(this.auditStatus === 1)
              .onClick(() => {
                if (this.auditStatus !== 1) {
                  this.getUIContext().showAlertDialog({ message: '企业资质审核未通过，暂无法发布职位', confirm: { value: '确定', action: () => {} } })
                  return
                }
                router.pushUrl({ url: 'pages/RecruiterJobFormPage' })
              })
              .stateStyles({
                pressed: {
                  .scale({ x: 0.97, y: 0.97 })
                  .opacity(0.9)
                  .backgroundColor(AppColors.PRIMARY_HOVER)
                },
                normal: {
                  .scale({ x: 1, y: 1 })
                  .opacity(1)
                  .backgroundColor(AppColors.PRIMARY)
                }
              })
              .animation({
                duration: 200
              })

            if (this.jobList.length === 0) {
              Column() {
                Text('暂无已发布职位')
                  .fontSize(AppFontSize.SM)
                  .fontColor(AppColors.TEXT_MUTED)
                  .margin({ top: AppSpacing.XXL })
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
          .padding(AppSpacing.MD)
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.INPUT_BG)
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
            .fontSize(AppFontSize.MD)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.job.salaryMin.toString() + '-' + this.job.salaryMax.toString() + '元/'
            + SALARY_UNIT_LABELS[this.job.salaryUnit] + ' · '
            + JOB_TYPE_LABELS[this.job.jobType])
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.WARNING)
            .margin({ top: AppSpacing.XS })

          Row() {
            Text(JOB_STATUS_LABELS[this.job.status])
              .fontSize(AppFontSize.XS)
              .fontColor(this.job.status === 1 ? AppColors.SUCCESS : AppColors.TEXT_MUTED)
              .backgroundColor(this.job.status === 1 ? '#E8F8ED' : AppColors.INPUT_BG)
              .borderRadius(AppRadius.SM)
              .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: 2, bottom: 2 })

            Text(this.job.applicationCount.toString() + '人投递')
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.TEXT_MUTED)
              .margin({ left: AppSpacing.SM })
          }
          .margin({ top: AppSpacing.XS })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text('删除')
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.DANGER)
          .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XS, bottom: AppSpacing.XS })
          .onClick(() => {
            this.onDelete?.()
          })
          .stateStyles({
            pressed: {
              .opacity(0.6)
            }
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(AppSpacing.SM)
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius(AppRadius.LG)
    .margin({ top: AppSpacing.SM })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/JobDetailPage',
        params: {
          jobData: JSON.stringify(this.job),
          hideActions: 'true'
        }
      })
    })
    .stateStyles({
      pressed: {
        .backgroundColor(AppColors.SELECTED_BG)
      }
    })
  }
}
