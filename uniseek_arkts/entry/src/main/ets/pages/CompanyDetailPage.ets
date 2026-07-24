import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles'
import { NavBar } from '../common/NavBar'
import { StandardCard } from '../common/StandardCard'
import { EmptyView } from '../components/EmptyView'
import { ErrorView } from '../components/ErrorView'
import { EnterpriseDiscoveryService, EnterpriseListItem } from '../services/EnterpriseDiscoveryService'
import { TaskVO } from '../services/ChatTypes'
import { DataService } from '../services/DataService'

/**
 * 企业详情页
 * 职责：作为独立页面展示企业简介与在招职位；与 CompanyPage 列表解耦，避免覆盖式布局。
 * 设计要点：
 * 1. 顶部采用品牌渐变 Hero 卡片，突出企业名称与行业标签。
 * 2. 基本信息、企业简介分区使用 StandardCard，层级清晰。
 * 3. 在招职位改为原生 List 列表，支持弹性滚动与统一分隔线，更贴合手机 App 使用习惯。
 * 4. 保持显示字段不变：公司名称、行业、地区、简介、在招职位列表。
 */
@Entry
@Component
struct CompanyDetailPage {
  @State enterprise: EnterpriseListItem | null = null
  @State enterpriseJobs: TaskVO[] = []
  @State isLoading: boolean = true
  @State isLoadingJobs: boolean = true
  @State errorText: string = ''
  @State regionName: string = ''

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
      const region = await DataService.getRegionNameById(enterprise.regionId)
      this.regionName = region || ''
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

  // 企业详情主体：使用 List 承载首页头与各在招职位，避免 Scroll 嵌套。
  @Builder
  companyDetail() {
    List({ space: AppSpacing.MD }) {
      // 顶部品牌渐变 Hero
      ListItem() {
        this.companyHero()
      }

      // 基本信息
      ListItem() {
        this.companyInfo()
      }

      // 企业简介
      ListItem() {
        this.companyIntro()
      }

      // 列表分区标题
      ListItem() {
        this.jobsSectionHeader()
      }

      // 职位加载中
      if (this.isLoadingJobs) {
        ListItem() {
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
        }
      } else if (this.enterpriseJobs.length === 0) {
        // 暂无职位
        ListItem() {
          EmptyView({
            message: '该企业暂无招聘中的职位',
            icon: $r('sys.symbol.briefcase')
          })
            .width('100%')
            .padding({ top: AppSpacing.LG, bottom: AppSpacing.LG })
        }
      } else {
        ForEach(this.enterpriseJobs, (job: TaskVO) => {
          ListItem() {
            this.jobItem(job)
          }
        }, (job: TaskVO): string => job.id.toString())
      }
    }
    .width('100%')
    .layoutWeight(1)
    .padding({
      left: AppSpacing.MD,
      right: AppSpacing.MD,
      top: AppSpacing.MD,
      bottom: AppSpacing.XL
    })
    .backgroundColor(AppColors.BG_PAGE)
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Auto)
  }

  // 顶部企业品牌卡片：渐变背景 + 大头像 + 名称/行业/在招数量。
  @Builder
  companyHero() {
    Column({ space: AppSpacing.MD }) {
      Row({ space: AppSpacing.LG }) {
        // 企业首字大头像（白色背板，品牌色文字）
        Stack() {
          Text(this.companyInitials(this.enterprise!.companyName))
            .fontSize(AppFontSize.XXXL)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.PRIMARY)
        }
        .width(AppSpacing.AVATAR_XL)
        .height(AppSpacing.AVATAR_XL)
        .borderRadius(AppRadius.FULL)
        .backgroundColor('#FFFFFF')
        .shadow({ radius: 8, color: 'rgba(0,0,0,0.08)', offsetX: 0, offsetY: 2 })

        // 名称与标签
        Column({ space: AppSpacing.XS }) {
          Text(this.enterprise!.companyName || '企业')
            .fontSize(AppFontSize.XXL)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          if (this.enterprise!.industry) {
            Text(this.enterprise!.industry)
              .fontSize(AppFontSize.SM)
              .fontColor('rgba(255,255,255,0.9)')
              .backgroundColor('rgba(255,255,255,0.18)')
              .borderRadius(AppRadius.PILL)
              .padding({
                left: AppSpacing.SM_PLUS,
                right: AppSpacing.SM_PLUS,
                top: AppSpacing.XXS,
                bottom: AppSpacing.XXS
              })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 在招职位数量
      Text('在招 ' + this.enterpriseJobs.length + ' 个职位')
        .fontSize(AppFontSize.SM)
        .fontColor('rgba(255,255,255,0.85)')
        .width('100%')
    }
    .width('100%')
    .padding(AppSpacing.LG)
    .backgroundColor(AppColors.PRIMARY)
    .linearGradient({
      angle: 135,
      colors: [[AppColors.PRIMARY, 0.0], [AppColors.PRIMARY_LIGHT, 1.0]]
    })
    .borderRadius(AppRadius.XL)
    .shadow({ radius: 12, color: 'rgba(23, 98, 251, 0.18)', offsetX: 0, offsetY: 4 })
  }

  // 基本信息卡：行业、地区、在招数量。
  @Builder
  companyInfo() {
    StandardCard() {
      Column({ space: AppSpacing.MD }) {
        this.infoRow('所属行业', this.enterprise!.industry || '暂无', $r('sys.symbol.building'))
        if (this.regionName !== '') {
          this.infoRow('所在地区', this.regionName)
        }
        this.infoRow('在招职位', this.enterpriseJobs.length + ' 个', $r('sys.symbol.briefcase'))
      }
      .width('100%')
    }
  }

  @Builder
  infoRow(label: string, value: string, icon?: Resource) {
    Row({ space: AppSpacing.SM }) {
      if (icon) {
        SymbolGlyph(icon)
          .fontSize(AppFontSize.ICON_MD)
          .fontColor([AppColors.PRIMARY])
      } else {
        // 无图标时使用品牌色圆点占位，保持每行视觉对齐
        Column()
          .width(AppFontSize.ICON_MD)
          .height(AppFontSize.ICON_MD)
          .borderRadius(AppRadius.FULL)
          .backgroundColor(AppColors.PRIMARY)
      }

      Text(label)
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_MUTED)
        .width(72)

      Text(value)
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  // 企业简介卡
  @Builder
  companyIntro() {
    StandardCard() {
      Column({ space: AppSpacing.SM }) {
        // 标题
        Row({ space: AppSpacing.SM }) {
          SymbolGlyph($r('sys.symbol.doc_text'))
            .fontSize(AppFontSize.MD)
            .fontColor([AppColors.PRIMARY])
          Text('企业简介')
            .fontSize(AppFontSize.MD)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
          Blank()
        }
        .width('100%')

        Text(this.enterprise!.description || '暂无企业简介')
          .fontSize(AppFontSize.SM)
          .fontColor(this.enterprise!.description ? AppColors.TEXT_SECONDARY : AppColors.TEXT_MUTED)
          .lineHeight(22)
          .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
  }

  // 在招职位分区标题
  @Builder
  jobsSectionHeader() {
    Row({ space: AppSpacing.SM }) {
      SymbolGlyph($r('sys.symbol.briefcase'))
        .fontSize(AppFontSize.MD)
        .fontColor([AppColors.PRIMARY])

      Text('在招职位')
        .fontSize(AppFontSize.MD)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)

      Text(this.enterpriseJobs.length + ' 个')
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_MUTED)
    }
    .width('100%')
    .padding({ left: AppSpacing.XS, right: AppSpacing.XS })
  }

  // 普通信息标签
  @Builder
  infoChip(label: string) {
    Text(label)
      .fontSize(AppFontSize.XXS)
      .fontColor(AppColors.PRIMARY)
      .backgroundColor(AppColors.SELECTED_BG)
      .borderRadius(AppRadius.SM)
      .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
  }

  // 职位列表项
  @Builder
  jobItem(job: TaskVO) {
    StandardCard({
      onClickAction: () => { this.goToJob(job.id) },
      accessibilityLabel: job.title
    }) {
      Column({ space: AppSpacing.SM }) {
        // 标题 + 薪资
        Row({ space: AppSpacing.SM }) {
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

        // 标签与地点
        Row({ space: AppSpacing.SM }) {
          // 类型标签
          Text(this.jobTypeText(job.jobType))
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.PRIMARY)
            .backgroundColor(AppColors.SELECTED_BG)
            .borderRadius(AppRadius.SM)
            .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
            .maxLines(1)

          // 分类标签（有则显示）
          if (job.categoryName) {
            Text(job.categoryName)
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.TEXT_SECONDARY)
              .backgroundColor(AppColors.INPUT_BG)
              .borderRadius(AppRadius.SM)
              .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
              .maxLines(1)
          }

          Text(job.regionName || job.address || '地点待定')
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.TEXT_SECONDARY)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 投递人数
          Text((job.applicationCount || 0) + ' 人投递')
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.TEXT_MUTED)
        }
        .width('100%')
      }
      .width('100%')
    }
  }
}
