// 招聘方简历池 / 面试安排页
// 职位选择、Tabs 切换、新投递通知铃铛、候选人卡片展示。

import { RecruiterService } from '../services/RecruiterService'
import { RecruiterApplicationVO, RecruiterJobVO, ResumeCardData } from '../services/RecruiterTypes'
import { PoolApplicationCard } from '../components/application/PoolApplicationCard'
import { NotificationBell } from '../components/NotificationBell'
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles'
import { EmptyView } from '../components/EmptyView'
import { ErrorView } from '../components/ErrorView'

interface ResumeSnapshot {
  realName?: string
  birthDate?: string
  education?: string
  school?: string
  skills?: string
  experience?: string
  attachmentUrl?: string
}

interface SelectOption {
  value: string
}

@Entry
@Component
struct RecruiterRequestsPage {
  // 职位相关
  @State jobs: RecruiterJobVO[] = []
  @State selectedJobIndex: number = -1

  // 投递数据
  @State applications: RecruiterApplicationVO[] = []
  @State poolApplications: RecruiterApplicationVO[] = []
  @State interviewApplications: RecruiterApplicationVO[] = []

  // 页面状态
  @State isLoadingJobs: boolean = true
  @State isLoadingApps: boolean = false
  @State errorText: string = ''

  // Tab 状态
  @State activeTab: 'pool' | 'interview' = 'pool'
  @State activeTabIndex: number = 0

  // 简历池内状态筛选（兼容首页 filterStatus 传入 0/2/3 的场景）
  @State poolStatusFilter: number = -1

  aboutToAppear(): void {
    this.parseRouteParams()
    this.loadJobs()
  }

  onPageShow(): void {
    // 从子页面返回时刷新当前职位投递列表
    if (this.selectedJobIndex >= 0 && this.jobs.length > 0) {
      this.loadApplications()
    }
  }

  // 解析路由参数：filterStatus=1 打开面试安排 Tab，其余保留在简历池并按状态筛选
  private parseRouteParams(): void {
    try {
      const params = this.getUIContext().getRouter().getParams() as Record<string, string | number> | null
      if (!params) {
        return
      }
      const rawStatus = params['filterStatus']
      let targetStatus: number = -1
      if (typeof rawStatus === 'number') {
        targetStatus = rawStatus
      } else if (typeof rawStatus === 'string') {
        targetStatus = parseInt(rawStatus)
      }
      if (Number.isNaN(targetStatus)) {
        return
      }
      if (targetStatus === 1) {
        this.activeTab = 'interview'
        this.activeTabIndex = 1
      } else if (targetStatus >= 0) {
        this.poolStatusFilter = targetStatus
      }
    } catch (err) {
      console.error('[RecruiterRequestsPage] parseRouteParams error:', String(err))
    }
  }

  // 加载企业职位列表
  private loadJobs(): void {
    this.isLoadingJobs = true
    this.errorText = ''
    RecruiterService.getMyJobs().then((list: RecruiterJobVO[]) => {
      this.jobs = list ?? []
      if (this.jobs.length > 0) {
        this.selectedJobIndex = 0
        this.isLoadingJobs = false
        this.loadApplications()
      } else {
        this.isLoadingJobs = false
      }
    }).catch(() => {
      this.jobs = []
      this.isLoadingJobs = false
      this.errorText = '职位列表加载失败，请检查网络后重试'
    })
  }

  // 加载选中职位的投递记录
  private loadApplications(): void {
    if (this.selectedJobIndex < 0 || this.selectedJobIndex >= this.jobs.length) {
      this.isLoadingApps = false
      return
    }
    this.isLoadingApps = true
    this.errorText = ''
    const jobId = this.jobs[this.selectedJobIndex].id
    RecruiterService.getJobApplications(jobId).then((list: RecruiterApplicationVO[]) => {
      this.applications = list ?? []
      this.updateDerivedLists()
      this.isLoadingApps = false
    }).catch(() => {
      this.applications = []
      this.poolApplications = []
      this.interviewApplications = []
      this.isLoadingApps = false
      this.errorText = '投递记录加载失败，请检查网络后重试'
    })
  }

  // 根据当前 Tab 和筛选条件拆分列表
  private updateDerivedLists(): void {
    // 简历池：排除面试安排、已淘汰、已完成
    let pool = this.applications.filter((item: RecruiterApplicationVO) => ![1, 4, 5].includes(item.status))
    if (this.poolStatusFilter !== -1) {
      pool = pool.filter((item: RecruiterApplicationVO) => item.status === this.poolStatusFilter)
    }
    this.poolApplications = pool
    this.interviewApplications = this.applications.filter((item: RecruiterApplicationVO) => item.status === 1)
  }

  private getSelectOptions(): SelectOption[] {
    if (this.jobs.length === 0) {
      return [{ value: '暂无职位' }]
    }
    return this.jobs.map((job: RecruiterJobVO): SelectOption => {
      return {
        value: job.title
      }
    })
  }

  private getSelectValue(): string {
    if (this.selectedJobIndex >= 0 && this.selectedJobIndex < this.jobs.length) {
      const job: RecruiterJobVO = this.jobs[this.selectedJobIndex]
      return job.title + '（' + this.applications.length + ' 人投递）'
    }
    return '请选择职位'
  }

  private handleJobSelected(index: number): void {
    if (index < 0 || index >= this.jobs.length || index === this.selectedJobIndex) {
      return
    }
    this.selectedJobIndex = index
    this.loadApplications()
  }

  // 解析简历快照
  private parseResumeSnapshot(snapshot?: string): ResumeSnapshot {
    if (!snapshot) {
      return {}
    }
    try {
      return JSON.parse(snapshot) as ResumeSnapshot
    } catch {
      return {}
    }
  }

  private getAge(birthDate?: string): number {
    if (!birthDate || birthDate.length < 4) {
      return 0
    }
    const year = Number(birthDate.substring(0, 4))
    const currentYear = new Date().getFullYear()
    return year >= 1900 && year <= currentYear ? currentYear - year : 0
  }

  // 打开简历详情页
  private openResume(app: RecruiterApplicationVO): void {
    const snapshot = this.parseResumeSnapshot(app.resumeSnapshot)
    const resumeData: ResumeCardData = {
      id: String(app.applicantId),
      name: app.applicantName || snapshot.realName || '匿名求职者',
      age: this.getAge(snapshot.birthDate),
      avatar: app.applicantAvatar || '',
      education: snapshot.education || '',
      school: snapshot.school || '',
      major: '',
      experience: snapshot.experience || '',
      skills: snapshot.skills || '',
      region: '',
      type: '',
      category: '',
      expectedSalary: '',
      description: '',
      attachmentUrl: app.attachmentUrl || snapshot.attachmentUrl || '',
      applicationId: app.id,
      applicationStatus: app.status,
      jobTitle: this.selectedJobIndex >= 0 ? this.jobs[this.selectedJobIndex].title : '',
      createTime: app.createTime
    }
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/ResumeDetailPage',
      params: { resumeData: JSON.stringify(resumeData) }
    })
  }

  // 通知铃铛点击回调：定位职位并打开简历详情
  private async handleNotificationClick(applicationId: number): Promise<void> {
    const app = await RecruiterService.getApplicationById(applicationId)
    if (!app) {
      this.getUIContext().getPromptAction().showToast({ message: '投递记录不存在或已删除' })
      return
    }
    const jobIndex = this.jobs.findIndex((job: RecruiterJobVO) => job.id === app.taskId)
    if (jobIndex >= 0 && jobIndex !== this.selectedJobIndex) {
      this.selectedJobIndex = jobIndex
      this.activeTab = app.status === 1 ? 'interview' : 'pool'
      this.activeTabIndex = app.status === 1 ? 1 : 0
      this.loadApplications()
    }
    this.openResume(app)
  }

  build() {
    Column() {
      // 顶部标题栏
      this.header()

      // 职位选择器（独立一行，不挤占标题栏）
      if (!this.isLoadingJobs && this.jobs.length > 0) {
        Row() {
          Row() {
            Select(this.getSelectOptions())
              .selected(this.selectedJobIndex >= 0 ? this.selectedJobIndex : 0)
              .value(this.getSelectValue())
              .fontColor(AppColors.TEXT_PRIMARY)
              .backgroundColor(AppColors.BG_CARD)
              .borderRadius(AppRadius.SM)
              .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
              .layoutWeight(1)
              .onSelect((index: number) => { this.handleJobSelected(index) })
          }
          .layoutWeight(1)
          .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
          .backgroundColor(AppColors.BG_CARD)
        }
        .width('100%')
        .height(44)
      }

      // Tabs：简历池 / 面试安排
      Tabs({ index: this.activeTabIndex, barPosition: BarPosition.Start }) {
        TabContent() {
          this.poolContent()
        }
        .tabBar('简历池')

        TabContent() {
          this.interviewContent()
        }
        .tabBar('面试安排')
      }
      .barHeight(44)
      .animationDuration(200)
      .onChange((index: number) => {
        this.activeTabIndex = index
        this.activeTab = index === 0 ? 'pool' : 'interview'
      })
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  @Builder
  header(): void {
    Column() {
      Row() {
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(AppFontSize.ICON_MD)
            .fontColor([AppColors.TEXT_PRIMARY])
        }
          .width(40)
          .height(40)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.getUIContext().getRouter().back()
          })
          .stateStyles({
            pressed: {
              .backgroundColor(AppColors.INPUT_BG)
            }
          })
          .animation({ duration: 150 })

        Text('投递管理')
          .fontSize(AppFontSize.XL)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 新投递通知铃铛
        NotificationBell({
          onNavigateToApplication: (applicationId: number): void => {
            void this.handleNotificationClick(applicationId)
          }
        })
      }
      .width('100%')
      .height(AppSpacing.BUTTON_HEIGHT_MD)
      .padding({ left: AppSpacing.SM, right: AppSpacing.MD })
      .backgroundColor(AppColors.BG_CARD)
      .alignItems(VerticalAlign.Center)
    }
  }

  @Builder
  poolContent(): void {
    Column() {
      // 简历池内状态筛选标签（兼容首页传入 filterStatus）
      this.filterTabs()

      if (this.isLoadingJobs || this.isLoadingApps) {
        Column() {
          LoadingProgress()
            .width(AppSpacing.ICON_MD)
            .height(AppSpacing.ICON_MD)
            .color(AppColors.PRIMARY)
          Text('加载中...')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
            .margin({ top: AppSpacing.SM })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.errorText) {
        Column() {
          ErrorView({
            message: this.errorText,
            retryText: '重新加载',
            onRetry: () => { this.loadJobs() }
          })
            .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.jobs.length === 0) {
        Column() {
          EmptyView({ message: '暂无职位，请先发布职位' })
            .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.poolApplications.length === 0) {
        Column() {
          EmptyView({ message: '简历池暂无候选人' })
            .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.poolApplications, (app: RecruiterApplicationVO) => {
            ListItem() {
              PoolApplicationCard({
                app: app,
                jobTitle: this.selectedJobIndex >= 0 ? this.jobs[this.selectedJobIndex].title : '',
                onViewResume: (item: RecruiterApplicationVO): void => { this.openResume(item) }
              })
                .margin({ bottom: AppSpacing.MD })
            }
          }, (app: RecruiterApplicationVO): string => app.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  interviewContent(): void {
    Column() {
      if (this.isLoadingJobs || this.isLoadingApps) {
        Column() {
          LoadingProgress()
            .width(AppSpacing.ICON_MD)
            .height(AppSpacing.ICON_MD)
            .color(AppColors.PRIMARY)
          Text('加载中...')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
            .margin({ top: AppSpacing.SM })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.errorText) {
        Column() {
          ErrorView({
            message: this.errorText,
            retryText: '重新加载',
            onRetry: () => { this.loadJobs() }
          })
            .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.interviewApplications.length === 0) {
        Column() {
          EmptyView({ message: '暂无面试安排' })
            .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.interviewApplications, (app: RecruiterApplicationVO) => {
            ListItem() {
              PoolApplicationCard({
                app: app,
                jobTitle: this.selectedJobIndex >= 0 ? this.jobs[this.selectedJobIndex].title : '',
                onViewResume: (item: RecruiterApplicationVO): void => { this.openResume(item) }
              })
                .margin({ bottom: AppSpacing.MD })
            }
          }, (app: RecruiterApplicationVO): string => app.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  filterTabs(): void {
    Scroll() {
      Row({ space: AppSpacing.SM }) {
        this.filterTab('全部', -1)
        this.filterTab('已投递', 0)
        this.filterTab('待定', 2)
        this.filterTab('已录用', 3)
      }
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.SM })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .backgroundColor(AppColors.BG_CARD)
  }

  @Builder
  filterTab(label: string, status: number): void {
    Button(label, { type: ButtonType.Capsule })
      .height(28)
      .fontSize(AppFontSize.XS)
      .fontColor(this.poolStatusFilter === status ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
      .backgroundColor(this.poolStatusFilter === status ? AppColors.PRIMARY : AppColors.INPUT_BG)
      .padding({ left: AppSpacing.LG, right: AppSpacing.LG, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
      .onClick(() => {
        this.poolStatusFilter = status
        this.updateDerivedLists()
      })
      .stateStyles({
        pressed: {
          .scale({ x: 0.97, y: 0.97 })
          .opacity(0.9)
        }
      })
      .animation({ duration: 150 })
  }
}
