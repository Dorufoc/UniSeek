import { AppColors, AppSpacing, AppRadius, AppFontSize, AppShadow, AppAnimation } from '../../../common/AppStyles'
import { StandardCard } from '../../../common/StandardCard'
import { EmptyView } from '../../../components/EmptyView'
import { ErrorView } from '../../../components/ErrorView'
import { RecruiterService } from '../../../services/RecruiterService'
import {
  RecruiterEnterpriseVO,
  RecruiterRequestVO,
  APPLICATION_STATUS_LABELS,
  AUDIT_STATUS_LABELS
} from '../../../services/RecruiterTypes'
import { UserService, UserStats } from '../../../services/UserService'
import { AuthService, UserVO } from '../../../services/AuthService'

const ACTIVE_APPLICATION_STATUSES: number[] = [0, 1, 2]

interface QuickMenuItem {
  key: string
  label: string
  icon: Resource
  target: string
  requiresAudit: boolean
}

const QUICK_MENUS: QuickMenuItem[] = [
  {
    key: 'publish',
    label: '发布职位',
    icon: $r('sys.symbol.briefcase'),
    target: 'pages/RecruiterPublishJobPage',
    requiresAudit: true
  },
  {
    key: 'requests',
    label: '应聘管理',
    icon: $r('sys.symbol.inbox'),
    target: 'pages/RecruiterRequestsPage',
    requiresAudit: false
  },
  {
    key: 'talent',
    label: '人才搜索',
    icon: $r('sys.symbol.magnifyingglass'),
    target: 'pages/RecruiterSearchPage',
    requiresAudit: false
  },
  {
    key: 'enterprise',
    label: '企业资质',
    icon: $r('sys.symbol.building'),
    target: 'pages/RecruiterEnterprisePage',
    requiresAudit: false
  }
]

@Component
export struct RecruiterHomeTab {
  @State isRefreshing: boolean = false
  @State isLoading: boolean = true
  @State loadErrorText: string = ''
  @State username: string = ''
  @State enterpriseInfo: RecruiterEnterpriseVO | null = null
  // 四个计数器使用 UserService.getStats() 实时获取，不依赖 incomingRequests 推导
  @State stats: UserStats = { receivedResumes: 0, interviews: 0, pending: 0, activeJobs: 0 }
  @State incomingRequests: RecruiterRequestVO[] = []
  // 通过 AppStorage 监听页面返回与首页 Tab 切换，确保统计和待办数据及时更新。
  @StorageLink('recruiterHomeRefreshTrigger') @Watch('onRefreshTrigger') recruiterHomeRefreshTrigger: number = 0
  // 用于避免 aboutToAppear 与首次 onPageShow 重复发起请求；从子页面返回时该标识已为 false，可正常刷新
  private isFirstPageShow: boolean = true
  private isDashboardLoading: boolean = false
  private pendingDashboardRefresh: boolean = false

  aboutToAppear(): void {
    // 首次进入由 aboutToAppear 触发加载；onPageShow 首次到达时通过 isFirstPageShow 跳过，避免重复请求
    this.isFirstPageShow = true
    this.loadCachedData()
    void this.loadDashboard()
  }

  onPageShow(): void {
    // 从子页面返回时需要刷新；首次进入时与 aboutToAppear 重复，直接跳过
    if (this.isFirstPageShow) {
      this.isFirstPageShow = false
      return
    }
    // 从子页面返回时刷新一次数据
    void this.loadDashboard()
  }

  private onRefreshTrigger(): void {
    void this.loadDashboard()
  }

  private loadCachedData(): void {
    const cachedUser: UserVO | null = AuthService.getCachedCurrentUser()
    if (cachedUser) {
      this.username = cachedUser.nickname || ''
    }
  }

  private async loadDashboard(): Promise<void> {
    if (this.isDashboardLoading) {
      this.pendingDashboardRefresh = true
      return
    }
    this.isDashboardLoading = true
    this.pendingDashboardRefresh = false
    this.loadErrorText = ''
    try {
      // 计数器由 loadStats() 通过 UserService.getStats() 实时获取，不依赖 incomingRequests
      await Promise.all([
        this.loadUserInfo(),
        this.loadEnterpriseInfo(),
        this.loadStats(),
        this.loadIncomingRequests()
      ])
    } catch {
      this.loadErrorText = '页面数据加载失败，请重试'
    } finally {
      this.isLoading = false
      this.isRefreshing = false
      this.isDashboardLoading = false
      if (this.pendingDashboardRefresh) {
        this.pendingDashboardRefresh = false
        void this.loadDashboard()
      }
    }
  }

  private async loadUserInfo(): Promise<void> {
    try {
      const user: UserVO = await AuthService.getCurrentUser()
      this.username = user.nickname || ''
    } catch {
      if (this.loadErrorText.length === 0) {
        this.loadErrorText = '用户信息加载失败'
      }
    }
  }

  private async loadEnterpriseInfo(): Promise<void> {
    try {
      this.enterpriseInfo = await RecruiterService.getEnterpriseInfo()
    } catch {
      if (this.loadErrorText.length === 0) {
        this.loadErrorText = '企业信息加载失败'
      }
    }
  }

  private async loadStats(): Promise<void> {
    try {
      const result = await UserService.getStats()
      this.stats = {
        receivedResumes: result.receivedResumes ?? 0,
        interviews: result.interviews ?? 0,
        pending: result.pending ?? 0,
        activeJobs: result.activeJobs ?? 0
      }
      if (result.fromCache) {
        console.warn('[RecruiterHomeTab] 统计数据来自本地缓存，可能不是最新')
        if (this.loadErrorText.length === 0) {
          this.loadErrorText = '招聘统计暂时无法刷新，当前显示缓存数据'
        }
      }
    } catch {
      if (this.loadErrorText.length === 0) {
        this.loadErrorText = '招聘统计加载失败，请检查网络连接'
      }
    }
  }

  private async loadIncomingRequests(): Promise<void> {
    try {
      this.incomingRequests = await RecruiterService.getIncomingRequests()
    } catch {
      if (this.loadErrorText.length === 0) {
        this.loadErrorText = '应聘记录加载失败'
      }
      this.incomingRequests = []
    }
  }

  private goRequestsWithFilter(status: number): void {
    console.info('[RecruiterHomeTab] goRequestsWithFilter status=', status, 'incomingRequests=', this.incomingRequests.length)
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/RecruiterRequestsPage',
      params: { filterStatus: status }
    })
  }

  private openResumeDetail(request: RecruiterRequestVO): void {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/ResumeDetailPage',
      params: {
        resumeData: JSON.stringify({
          id: String(request.applicantId),
          name: request.applicantName || '匿名求职者',
          age: request.applicantAge || 0,
          avatar: request.applicantAvatar || '',
          education: request.applicantEducation || '',
          school: request.applicantSchool || '',
          major: request.applicantMajor || '',
          experience: request.applicantExperience || '',
          skills: request.applicantSkills || '',
          region: request.applicantRegion || '',
          type: request.applicantType || '',
          category: '',
          expectedSalary: request.applicantSalary || '',
          description: '',
          attachmentUrl: request.attachmentUrl || '',
          applicationId: request.id,
          applicationStatus: request.status,
          jobTitle: request.jobTitle,
          createTime: request.createTime
        })
      }
    })
  }

  private enterpriseAuditLabel(): string {
    if (!this.enterpriseInfo) {
      return '未提交'
    }
    return AUDIT_STATUS_LABELS[this.enterpriseInfo.auditStatus] ?? '未知'
  }

  private canPublishJob(): boolean {
    return this.enterpriseInfo?.auditStatus === 1
  }

  private filteredRequests(): RecruiterRequestVO[] {
    const activeRequests = this.incomingRequests.filter((req: RecruiterRequestVO): boolean =>
      ACTIVE_APPLICATION_STATUSES.includes(req.status)
    )
    return activeRequests.sort((a: RecruiterRequestVO, b: RecruiterRequestVO): number =>
      this.parseTime(b.createTime) - this.parseTime(a.createTime)
    )
  }

  private parseTime(timeText?: string): number {
    if (!timeText) {
      return 0
    }
    const ts = new Date(timeText).getTime()
    return Number.isNaN(ts) ? 0 : ts
  }

  private statusColor(status: number): ResourceColor {
    switch (status) {
      case 3:
        return AppColors.SUCCESS
      case 4:
        return AppColors.DANGER
      case 1:
        return AppColors.WARNING
      default:
        return AppColors.INFO
    }
  }

  private statusBgColor(status: number): ResourceColor {
    switch (status) {
      case 3:
        return AppColors.SUCCESS_BG
      case 4:
        return AppColors.ERROR_BG
      case 1:
        return AppColors.WARNING_BG
      default:
        return AppColors.SELECTED_BG
    }
  }

  private formatRequestTime(timeText?: string): string {
    if (!timeText) {
      return ''
    }
    return timeText.split('T')[0] || timeText.split(' ')[0] || timeText
  }

  private handleQuickClick(item: QuickMenuItem): void {
    if (item.requiresAudit && !this.canPublishJob()) {
      this.getUIContext().showAlertDialog({
        message: '企业资质审核通过后才能使用该功能',
        primaryButton: { value: '取消', action: (): void => {} },
        secondaryButton: { value: '确定', action: (): void => {} },
        autoCancel: true
      })
      return
    }
    this.getUIContext().getRouter().pushUrl({ url: item.target })
  }

  private goRequests(): void {
    this.getUIContext().getRouter().pushUrl({ url: 'pages/RecruiterRequestsPage' })
  }

  private goEnterprise(): void {
    this.getUIContext().getRouter().pushUrl({ url: 'pages/RecruiterEnterprisePage' })
  }

  @Builder
  enterpriseHeader() {
    StandardCard({
      onClickAction: (): void => { this.goEnterprise() },
      accessibilityLabel: '企业资质'
    }) {
      Row({ space: AppSpacing.MD }) {
        Column() {
          SymbolGlyph($r('sys.symbol.building'))
            .fontSize(AppFontSize.ICON_LG)
            .fontColor([AppColors.PRIMARY])
        }
        .width(AppSpacing.ICON_XXL)
        .height(AppSpacing.ICON_XXL)
        .backgroundColor(AppColors.PRIMARY_ALPHA_8)
        .borderRadius(AppRadius.LG)
        .justifyContent(FlexAlign.Center)

        Column() {
          Text(this.enterpriseInfo?.companyName || (this.username ? `${this.username} 的企业` : '您的企业'))
            .fontSize(AppFontSize.LG)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.enterpriseInfo
            ? `${this.enterpriseInfo.industry || '其他'} · ${this.enterpriseAuditLabel()}`
            : '完善企业资质，开启招聘工作')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_SECONDARY)
            .margin({ top: AppSpacing.XS })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(AppFontSize.MD)
          .fontColor([AppColors.TEXT_MUTED])
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
  }

  @Builder
  statItem(value: number, label: string, filterStatus: number = -2) {
    Column() {
      Text(value.toString())
        .fontSize(AppFontSize.XL)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.PRIMARY)
      Text(label)
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_MUTED)
        .margin({ top: AppSpacing.XS })
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height(72)
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius(AppRadius.LG)
    .justifyContent(FlexAlign.Center)
    .shadow(AppShadow.SM)
    .onClick(() => {
      if (filterStatus >= -1) {
        this.goRequestsWithFilter(filterStatus)
      }
    })
    .stateStyles({
      pressed: {
        .backgroundColor(AppColors.INPUT_BG)
        .scale({ x: 0.97, y: 0.97 })
      }
    })
    .animation({ duration: AppAnimation.DURATION_FAST, curve: AppAnimation.CURVE_EMPHASIZED })
  }

  @Builder
  statsSection() {
    Grid() {
      // 四个计数器均直接使用 UserService.getStats() 实时数据，不与 myJobs/incomingRequests 耦合
      GridItem() { this.statItem(this.stats.receivedResumes ?? 0, '收到简历', -1) }
      GridItem() { this.statItem(this.stats.interviews ?? 0, '待面试', 1) }
      GridItem() { this.statItem(this.stats.pending ?? 0, '待定', 2) }
      GridItem() { this.statItem(this.stats.activeJobs ?? 0, '在招职位', -1) }
    }
    .columnsTemplate('1fr 1fr 1fr 1fr')
    .columnsGap(AppSpacing.SM)
    .rowsGap(AppSpacing.SM)
    .width('100%')
  }

  @Builder
  quickItem(item: QuickMenuItem) {
    Column() {
      SymbolGlyph(item.icon)
        .fontSize(AppFontSize.ICON_LG)
        .fontColor([AppColors.PRIMARY])
      Text(item.label)
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_PRIMARY)
        .margin({ top: AppSpacing.SM })
    }
    .width('100%')
    .height(72)
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius(AppRadius.LG)
    .justifyContent(FlexAlign.Center)
    .shadow(AppShadow.SM)
    .onClick(() => { this.handleQuickClick(item) })
    .stateStyles({
      pressed: {
        .backgroundColor(AppColors.INPUT_BG)
        .scale({ x: 0.97, y: 0.97 })
      }
    })
    .animation({ duration: AppAnimation.DURATION_FAST, curve: AppAnimation.CURVE_EMPHASIZED })
  }

  @Builder
  quickActions() {
    Grid() {
      ForEach(QUICK_MENUS, (item: QuickMenuItem) => {
        GridItem() {
          this.quickItem(item)
        }
      }, (item: QuickMenuItem): string => item.key)
    }
    .columnsTemplate('1fr 1fr 1fr 1fr')
    .columnsGap(AppSpacing.SM)
    .rowsGap(AppSpacing.SM)
    .width('100%')
  }

  @Builder
  statusBadge(status: number) {
    Text(APPLICATION_STATUS_LABELS[status] ?? '未知')
      .fontSize(AppFontSize.XS)
      .fontColor(this.statusColor(status))
      .backgroundColor(this.statusBgColor(status))
      .borderRadius(AppRadius.PILL)
      .padding({
        left: AppSpacing.SM,
        right: AppSpacing.SM,
        top: AppSpacing.XS,
        bottom: AppSpacing.XS
      })
  }

  @Builder
  requestCard(request: RecruiterRequestVO) {
    StandardCard({
      onClickAction: (): void => { this.openResumeDetail(request) },
      accessibilityLabel: `${request.applicantName || '匿名求职者'} 的简历`
    }) {
      Row({ space: AppSpacing.SM }) {
        Column() {
          if (request.applicantAvatar) {
            Image(request.applicantAvatar)
              .width('100%')
              .height('100%')
              .borderRadius(AppRadius.FULL)
              .objectFit(ImageFit.Cover)
          } else {
            SymbolGlyph($r('sys.symbol.person'))
              .fontSize(AppFontSize.ICON_MD)
              .fontColor([AppColors.TEXT_MUTED])
          }
        }
        .width(AppSpacing.ICON_XL)
        .height(AppSpacing.ICON_XL)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.FULL)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Text(request.applicantName || '匿名求职者')
            .fontSize(AppFontSize.MD)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(request.jobTitle || '未知职位')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_SECONDARY)
            .margin({ top: AppSpacing.XS })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.formatRequestTime(request.createTime))
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.TEXT_MUTED)
            .margin({ top: AppSpacing.XS })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        this.statusBadge(request.status)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
  }

  @Builder
  requestsSection() {
    Column({ space: AppSpacing.SM }) {
      Row() {
        Text('待完成任务')
          .fontSize(AppFontSize.MD)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
        Row({ space: AppSpacing.XS }) {
          Text('查看全部')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_SECONDARY)
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(AppFontSize.SM)
            .fontColor([AppColors.TEXT_SECONDARY])
        }
        .onClick(() => { this.goRequests() })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  loadingPlaceholder() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(AppColors.PRIMARY)
      Text('加载中...')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_SECONDARY)
        .margin({ top: AppSpacing.SM })
    }
    .width('100%')
    .padding({ top: 120, bottom: 120 })
  }

  build() {
    Refresh({ refreshing: this.isRefreshing, promptText: '下拉刷新...' }) {
      List({ space: AppSpacing.MD }) {
        if (this.loadErrorText) {
          ListItem() {
            ErrorView({
              message: this.loadErrorText,
              retryText: '重新加载',
              onRetry: (): void => { void this.loadDashboard() }
            })
          }
        }

        if (this.isLoading && this.incomingRequests.length === 0) {
          ListItem() {
            this.loadingPlaceholder()
          }
        }

        ListItem() { this.enterpriseHeader() }

        ListItem() { this.quickActions() }

        ListItem() { this.statsSection() }

        ListItem() { this.requestsSection() }

        if (this.filteredRequests().length === 0 && !this.isLoading) {
          ListItem() {
            EmptyView({
              message: '暂无待完成任务',
              icon: $r('sys.symbol.inbox')
            })
              .margin({ top: 24 })
          }
        } else {
          ForEach(this.filteredRequests(), (request: RecruiterRequestVO) => {
            ListItem() {
              this.requestCard(request)
            }
          }, (request: RecruiterRequestVO): string => String(request.id))
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: AppSpacing.XL })
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
    .onRefreshing(() => {
      this.isRefreshing = true
      void this.loadDashboard()
    })
  }
}
