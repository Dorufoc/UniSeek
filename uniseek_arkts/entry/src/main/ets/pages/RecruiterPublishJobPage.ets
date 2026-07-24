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
import { StandardCard } from '../common/StandardCard';
import { ErrorView } from '../components/ErrorView';
import { EmptyView } from '../components/EmptyView';

@Entry
@Component
struct RecruiterPublishJobPage {
  @State jobList: RecruiterJobVO[] = []
  @State isLoading: boolean = true
  @State errorText: string = ''
  @State auditErrorText: string = ''
  @State auditStatus: number = -1

  aboutToAppear(): void {
    this.loadJobs()
    this.loadAuditStatus()
  }

  onPageShow(): void {
    this.loadJobs()
    this.loadAuditStatus()
  }

  loadAuditStatus(): void {
    this.auditErrorText = ''
    RecruiterService.getEnterpriseInfo().then((info) => {
      if (info) {
        this.auditStatus = info.auditStatus
      }
    }).catch(() => {
      this.auditErrorText = '企业资质状态加载失败'
    })
  }

  loadJobs(): void {
    this.isLoading = true
    this.errorText = ''
    RecruiterService.getMyJobs().then((list: RecruiterJobVO[]) => {
      this.jobList = list
      this.isLoading = false
    }).catch(() => {
      this.jobList = []
      this.isLoading = false
      this.errorText = '职位列表加载失败，请检查网络后重试'
    })
  }

  build() {
    Column() {
      NavBar({
        title: '发布职位',
        showBack: true,
        onBack: () => this.getUIContext().getRouter().back()
      })

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(AppSpacing.ICON_MD)
            .height(AppSpacing.ICON_MD)
            .color(AppColors.PRIMARY)
          Text('正在加载职位')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
            .margin({ top: AppSpacing.SM })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.errorText) {
        ErrorView({
          message: this.errorText,
          retryText: '重新加载',
          onRetry: () => { this.loadJobs() }
        })
          .width('100%')
          .layoutWeight(1)
      } else {
        Scroll() {
          Column() {
            if (this.auditErrorText) {
              Row({ space: AppSpacing.SM }) {
                Text(this.auditErrorText)
                  .fontSize(AppFontSize.XS)
                  .fontColor(AppColors.DANGER)
                  .layoutWeight(1)
                Button('重试', { type: ButtonType.Capsule })
                  .height(AppSpacing.BUTTON_HEIGHT_MINI)
                  .fontSize(AppFontSize.XS)
                  .fontColor(AppColors.PRIMARY)
                  .backgroundColor(AppColors.SELECTED_BG)
                  .onClick(() => { this.loadAuditStatus() })
              }
              .width('100%')
              .padding(AppSpacing.SM)
              .backgroundColor(AppColors.ERROR_BG)
              .borderRadius(AppRadius.SM)
              .margin({ top: AppSpacing.SM })
            } else if (this.auditStatus !== 1) {
              Row() {
                Text(this.auditStatus === -1 ? '请先完成企业资质认证，再发布职位' :
                  '企业资质' + AUDIT_STATUS_LABELS[this.auditStatus] + '，暂无法发布新职位')
                  .fontSize(AppFontSize.XS)
                  .fontColor(AppColors.WARNING)
                  .layoutWeight(1)
                if (this.auditStatus === -1) {
                  Button('去认证', { type: ButtonType.Capsule })
                    .height(AppSpacing.BUTTON_HEIGHT_MINI)
                    .fontSize(AppFontSize.XS)
                    .fontColor(AppColors.PRIMARY)
                    .backgroundColor(AppColors.SELECTED_BG)
                    .onClick(() => { this.getUIContext().getRouter().pushUrl({ url: 'pages/RecruiterEnterprisePage' }) })
                }
              }
              .width('100%')
              .padding(AppSpacing.SM)
              .backgroundColor(AppColors.WARNING_BG)
              .borderRadius(AppRadius.SM)
              .margin({ top: AppSpacing.SM })
            }

            Button({ type: ButtonType.Capsule }) {
              Text('发布新职位')
                .fontSize(AppFontSize.MD)
                .fontColor('#FFFFFF')
            }
              .width('100%')
              .height(AppSpacing.INPUT_HEIGHT)
              .backgroundColor(this.auditStatus === 1 ? AppColors.PRIMARY : AppColors.TEXT_MUTED)
              .margin({ top: AppSpacing.SM })
              .enabled(this.auditStatus === 1)
              .onClick(() => {
                if (this.auditStatus !== 1) {
                  this.getUIContext().showAlertDialog({ message: '企业资质审核未通过，暂无法发布职位', confirm: { value: '确定', action: () => {} } })
                  return
                }
                this.getUIContext().getRouter().pushUrl({ url: 'pages/RecruiterJobFormPage' })
              })
              .stateStyles({
                pressed: {
                  .scale({ x: 0.97, y: 0.97 })
                  .opacity(0.9)
                },
                normal: {
                  .scale({ x: 1, y: 1 })
                  .opacity(1)
                }
              })
              .animation({
                duration: 200
              })

            if (this.jobList.length === 0) {
              EmptyView({ message: '暂无已发布职位' })
                .width('100%')
                .layoutWeight(1)
            } else {
              ForEach(this.jobList, (job: RecruiterJobVO) => {
                Column() {
                  StandardCard({
                    onClickAction: () => {
                      this.getUIContext().getRouter().pushUrl({
                        url: 'pages/JobDetailPage',
                        params: {
                          jobData: JSON.stringify(job),
                          hideActions: 'true'
                        }
                      })
                    },
                    accessibilityLabel: job.title
                  }) {
                    JobManageCard({
                      job: job,
                      onDelete: () => { this.confirmStatusChange(job) },
                      onApplications: () => { this.openApplications(job) },
                      onEdit: () => { this.openEdit(job) },
                      onResubmit: () => { this.confirmResubmit(job) }
                    })
                  }
                }
                .width('100%')
                .margin({ top: AppSpacing.SM })
              }, (job: RecruiterJobVO) => job.id.toString())
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
    .backgroundColor(AppColors.BG_PAGE)
  }

  confirmStatusChange(job: RecruiterJobVO): void {
    const targetStatus = job.status === 1 ? 4 : 1
    const action = targetStatus === 1 ? '上架' : '下架'
    this.getUIContext().showAlertDialog({
      message: '确定要' + action + '“' + job.title + '”吗？',
      confirm: {
        value: '确定',
        action: (): void => {
          RecruiterService.updateJobStatus(job.id, targetStatus).then((success: boolean) => {
            if (success) {
              this.loadJobs()
            } else {
              this.getUIContext().getPromptAction().showToast({ message: action + '失败，请稍后重试' })
            }
          }).catch(() => {
            this.getUIContext().getPromptAction().showToast({ message: action + '失败，请稍后重试' })
          })
        }
      },
      cancel: (): void => {}
    })
  }

  confirmResubmit(job: RecruiterJobVO): void {
    this.getUIContext().showAlertDialog({
      message: '确定重新提交“' + job.title + '”审核吗？',
      confirm: {
        value: '重新提交',
        action: (): void => {
          RecruiterService.resubmitJob(job.id).then((success: boolean) => {
            if (success) {
              this.loadJobs()
            } else {
              this.getUIContext().getPromptAction().showToast({ message: '重新提交失败，请稍后重试' })
            }
          }).catch(() => {
            this.getUIContext().getPromptAction().showToast({ message: '重新提交失败，请稍后重试' })
          })
        }
      },
      cancel: (): void => {}
    })
  }
  deleteJob(jobId: number): void {
    RecruiterService.deleteJob(jobId).then((success: boolean) => {
      if (success) {
        this.loadJobs()
      } else {
        this.getUIContext().getPromptAction().showToast({ message: '删除失败，请稍后重试' })
      }
    }).catch(() => {
      this.getUIContext().getPromptAction().showToast({ message: '删除失败，请稍后重试' })
    })
  }

  openEdit(job: RecruiterJobVO): void {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/RecruiterJobFormPage',
      params: { jobId: String(job.id) }
    })
  }

  openApplications(job: RecruiterJobVO): void {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/RecruiterApplicationsPage',
      params: { jobId: String(job.id), jobTitle: job.title }
    })
  }
}

@Component
struct JobManageCard {
  job: RecruiterJobVO = {
    id: 0, title: '', salaryMin: 0, salaryMax: 0, salaryUnit: 0,
    jobType: 1, address: '', status: 0, applicationCount: 0,
    remainingQuota: 0, totalQuota: 0, deadline: '', createTime: '', rejectReason: ''
  }
  onDelete?: () => void
  onApplications?: () => void
  onEdit?: () => void
  onResubmit?: () => void

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
              .backgroundColor(this.job.status === 1 ? AppColors.SUCCESS_BG : AppColors.INPUT_BG)
              .borderRadius(AppRadius.SM)
              .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XXS, bottom: AppSpacing.XXS })

            Text(this.job.applicationCount.toString() + '人投递')
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.TEXT_MUTED)
              .margin({ left: AppSpacing.SM })
          }
          .margin({ top: AppSpacing.XS })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Row({ space: AppSpacing.XS }) {
        Button(this.job.applicationCount + '份投递', { type: ButtonType.Capsule })
          .height(AppSpacing.BUTTON_HEIGHT_MINI)
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.PRIMARY)
          .backgroundColor(AppColors.SELECTED_BG)
          .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
          .onClick(() => {
            this.onApplications?.()
          })

        if (this.job.status === 0 && this.job.rejectReason) {
          Button('编辑', { type: ButtonType.Capsule })
            .height(AppSpacing.BUTTON_HEIGHT_MINI)
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.PRIMARY)
            .backgroundColor(AppColors.SELECTED_BG)
            .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
            .onClick(() => { this.onEdit?.() })
          Button('重新提交', { type: ButtonType.Capsule })
            .height(AppSpacing.BUTTON_HEIGHT_MINI)
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.SUCCESS)
            .backgroundColor(AppColors.SUCCESS_BG)
            .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
            .onClick(() => { this.onResubmit?.() })
        } else if (this.job.status === 0) {
          Text('审核中')
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.WARNING)
            .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.SM, bottom: AppSpacing.SM })
        } else if (this.job.status === 1 || this.job.status === 4) {
          Button(this.job.status === 1 ? '下架' : '上架', { type: ButtonType.Capsule })
            .height(AppSpacing.BUTTON_HEIGHT_MINI)
            .fontSize(AppFontSize.XS)
            .fontColor(this.job.status === 1 ? AppColors.DANGER : AppColors.SUCCESS)
            .backgroundColor(this.job.status === 1 ? AppColors.ERROR_BG : AppColors.SUCCESS_BG)
            .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
            .onClick(() => { this.onDelete?.() })
            .stateStyles({
              pressed: {
                .opacity(0.6)
              }
            })
        }
      }
      .width('100%')
      .margin({ top: AppSpacing.SM })
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
  }
}
