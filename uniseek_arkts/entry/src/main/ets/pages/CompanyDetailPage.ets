import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles'
import { NavBar } from '../common/NavBar'
import { StandardCard } from '../common/StandardCard'
import { EmptyView } from '../components/EmptyView'
import { ErrorView } from '../components/ErrorView'
import { EnterpriseDiscoveryService, EnterpriseListItem } from '../services/EnterpriseDiscoveryService'
import { TaskVO } from '../services/ChatTypes'

/**
 * 企业详情页
 * 职责：作为独立页面展示企业简介与在招职位；与 CompanyPage 列表解耦，避免覆盖式布局。
 */
@Entry
@Component
struct CompanyDetailPage {
  @State enterprise: EnterpriseListItem | null = null
  @State enterpriseJobs: TaskVO[] = []
  @State isLoading: boolean = true
  @State isLoadingJobs: boolean = true
  @State errorText: string = ''

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>
    const enterpriseId = params && params['enterpriseId'] ? Number(params['enterpriseId']) : 0
    if (enterpriseId > 0) {
      this.loadEnterprise(enterpriseId)
    } else {
      this.isLoading = false
      this.errorText = '未找到企业信息，请返回后重试'
    }
  }

  private async loadEnterprise(enterpriseId: number): Promise<void> {
    this.isLoading = true
    this.errorText = ''
    try {
      const enterprise = await EnterpriseDiscoveryService.getEnterprise(enterpriseId)
      this.enterprise = enterprise
      await this.loadJobs(enterpriseId)
    } catch {
      this.enterprise = null
      this.errorText = '企业信息加载失败，请返回后重试'
    }
    this.isLoading = false
  }

  private async loadJobs(enterpriseId: number): Promise<void> {
    this.isLoadingJobs = true
    try {
      this.enterpriseJobs = await EnterpriseDiscoveryService.getPublishedJobs(enterpriseId)
    } catch {
      this.enterpriseJobs = []
    }
    this.isLoadingJobs = false
  }

  private goToJob(taskId: number): void {
    this.getUIContext().getRouter().pushUrl({ url: 'pages/JobDetailPage', params: { jobId: taskId } })
  }

  private salaryText(job: TaskVO): string {
    if (job.salaryMin === 0 && job.salaryMax === 0) {
      return '面议'
    }
    const unit = job.salaryUnit === 0 ? '/日' : job.salaryUnit === 1 ? '/时' : '/月'
    return '￥' + job.salaryMin + '-' + job.salaryMax + unit
  }

  private jobTypeText(jobType: number): string {
    if (jobType === 1) {
      return '全职'
    }
    if (jobType === 2) {
      return '兼职'
    }
    if (jobType === 3) {
      return '实习'
    }
    return '职位'
  }

  private companyInitials(name: string): string {
    const safeName = name || '企'
    return safeName.charAt(0)
  }

  // ===== UI 构建 =====
  build() {
    Column() {
      NavBar({
        title: this.enterprise?.companyName || '企业详情',
        showBack: true,
        onBack: () => this.getUIContext().getRouter().back()
      })

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(AppSpacing.ICON_MD)
            .height(AppSpacing.ICON_MD)
            .color(AppColors.PRIMARY)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.errorText !== '' && this.enterprise === null) {
        Column() {
          ErrorView({
            message: this.errorText,
            retryText: '重新加载',
            onRetry: () => {
              const id = this.enterprise?.id || 0
              if (id > 0) {
                this.loadEnterprise(id)
              } else {
                this.getUIContext().getRouter().back()
              }
            }
          })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding(AppSpacing.MD)
      } else if (this.enterprise !== null) {
        this.companyDetail()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  // 企业详情内容
  @Builder
  companyDetail() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        // 头部信息卡
        StandardCard() {
          Row({ space: AppSpacing.MD }) {
            Stack() {
              Text(this.companyInitials(this.enterprise!.companyName))
                .fontSize(AppFontSize.XXL)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.BG_CARD)
            }
            .width(AppSpacing.ICON_XXL)
            .height(AppSpacing.ICON_XXL)
            .borderRadius(AppRadius.LG)
            .backgroundColor(AppColors.PRIMARY)

            Column({ space: AppSpacing.SM }) {
              Text(this.enterprise!.companyName || '企业')
                .fontSize(AppFontSize.XL)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT_PRIMARY)
                .width('100%')
              if (this.enterprise!.industry) {
                this.infoChip(this.enterprise!.industry)
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }

        // 简介
        StandardCard() {
          Column({ space: AppSpacing.SM }) {
            Text('企业简介')
              .fontSize(AppFontSize.MD)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT_PRIMARY)
              .width('100%')
            Text(this.enterprise!.description || '暂无企业简介')
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.TEXT_SECONDARY)
              .lineHeight(AppSpacing.BUTTON_HEIGHT_MD)
              .width('100%')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }

        // 招聘职位
        StandardCard() {
          Column({ space: AppSpacing.SM }) {
            Text('招聘中的职位')
              .fontSize(AppFontSize.MD)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT_PRIMARY)
              .width('100%')

            if (this.isLoadingJobs) {
              Column() {
                LoadingProgress()
                  .width(AppSpacing.ICON_MD)
                  .height(AppSpacing.ICON_MD)
                  .color(AppColors.PRIMARY)
              }
              .width('100%')
              .padding(AppSpacing.LG)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
            } else if (this.enterpriseJobs.length === 0) {
              EmptyView({
                message: '该企业暂无招聘中的职位',
                icon: $r('sys.symbol.briefcase')
              })
                .width('100%')
                .padding({ top: AppSpacing.LG, bottom: AppSpacing.LG })
            } else {
              Column({ space: AppSpacing.SM }) {
                ForEach(this.enterpriseJobs, (job: TaskVO) => {
                  this.jobItem(job)
                }, (job: TaskVO): string => job.id.toString())
              }
              .width('100%')
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
      }
      .width('100%')
      .padding(AppSpacing.MD)
    }
    .layoutWeight(1)
    .width('100%')
  }

  @Builder
  infoChip(label: string) {
    Text(label)
      .fontSize(AppFontSize.XXS)
      .fontColor(AppColors.PRIMARY)
      .backgroundColor(AppColors.SELECTED_BG)
      .borderRadius(AppRadius.SM)
      .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
  }

  @Builder
  jobItem(job: TaskVO) {
    StandardCard({
      onClickAction: () => { this.goToJob(job.id) },
      accessibilityLabel: job.title
    }) {
      Column({ space: AppSpacing.XS }) {
        Row() {
          Text(job.title)
            .fontSize(AppFontSize.MD)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Text(this.salaryText(job))
            .fontSize(AppFontSize.SM)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.DANGER)
        }
        .width('100%')

        Row({ space: AppSpacing.SM }) {
          Text(this.jobTypeText(job.jobType)).fontSize(AppFontSize.XS).fontColor(AppColors.PRIMARY)
          Text(job.regionName || job.address || '地点待定').fontSize(AppFontSize.XS).fontColor(AppColors.TEXT_SECONDARY)
          Text((job.applicationCount || 0) + ' 人投递').fontSize(AppFontSize.XS).fontColor(AppColors.TEXT_MUTED)
        }
        .width('100%')
      }
      .width('100%')
    }
  }
}
