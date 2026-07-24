import { ApplicationService, ApplicationData } from '../services/ApplicationService'
import { TaskVO, mapTaskToJobData } from '../services/ChatTypes'
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles'
import { NavBar } from '../common/NavBar'
import { ApplicationTabPolicy } from '../common/ApplicationTabPolicy'

@Component
struct ApplicationCard {
  app: ApplicationData = {
    id: 0, taskId: 0, applicantId: 0, resumeSnapshot: '', attachmentUrl: '',
    status: 0, interviewTime: '', interviewLocation: '', rejectReason: '',
    hrNote: '', createTime: '', updateTime: ''
  }
  task: TaskVO | null = null
  expanded: boolean = false
  onToggle?: () => void
  onOpenTask?: () => void

  build() {
    Column() {
      Row() {
        Column() {
          Text(this.task?.title || ('职位 #' + this.app.taskId))
            .fontSize(AppFontSize.MD)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.task?.enterpriseName || '职位信息暂不可用')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_SECONDARY)
            .margin({ top: AppSpacing.XS })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column() {
          Text(ApplicationService.statusLabel(this.app.status))
            .fontSize(AppFontSize.XS)
            .fontColor(ApplicationService.statusColor(this.app.status))
            .backgroundColor(AppColors.SELECTED_BG)
            .borderRadius(AppRadius.SM)
            .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: 4, bottom: 4 })
          Text(ApplicationService.formatTime(this.app.createTime))
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.TEXT_MUTED)
            .margin({ top: AppSpacing.XS })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .onClick(() => {
        this.onToggle?.()
      })

      if (this.expanded) {
        Divider()
          .margin({ top: AppSpacing.MD, bottom: AppSpacing.SM })

        if (this.app.interviewTime) {
          Text('面试时间：' + ApplicationService.formatTime(this.app.interviewTime))
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.WARNING)
            .width('100%')
        }
        if (this.app.interviewLocation) {
          Text('面试地点：' + this.app.interviewLocation)
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_SECONDARY)
            .width('100%')
            .margin({ top: AppSpacing.XS })
        }
        if (this.app.rejectReason) {
          Text('淘汰原因：' + this.app.rejectReason)
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.DANGER)
            .width('100%')
            .margin({ top: AppSpacing.XS })
        }
        if (this.app.hrNote) {
          Text('HR备注：' + this.app.hrNote)
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_SECONDARY)
            .width('100%')
            .margin({ top: AppSpacing.XS })
        }

        Button('查看职位', { type: ButtonType.Capsule })
          .height(36)
          .padding({ left: AppSpacing.LG, right: AppSpacing.LG })
          .fontSize(AppFontSize.SM)
          .fontColor('#FFFFFF')
          .backgroundColor(AppColors.PRIMARY)
          .margin({ top: AppSpacing.MD })
          .onClick(() => {
            this.onOpenTask?.()
          })
      }
    }
    .width('100%')
    .padding(AppSpacing.MD)
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius(AppRadius.LG)
    .margin({ top: AppSpacing.SM })
    .stateStyles({
      pressed: {
        .backgroundColor(AppColors.SELECTED_BG)
      }
    })
    .animation({ duration: 180 })
  }
}

@Entry
@Component
struct SubmittedPage {
  @State activeTab: number = 0
  @State applications: ApplicationData[] = []
  @State taskMap: Record<number, TaskVO> = {}
  @State expandedId: number = -1
  @State isLoading: boolean = true
  @State loadError: string = ''

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>
    this.activeTab = ApplicationTabPolicy.resolve(params['tab'] || '')
    this.loadApplications()
  }

  onPageShow(): void {
    this.loadApplications()
  }

  async loadApplications(): Promise<void> {
    this.isLoading = true
    this.loadError = ''
    try {
      const result = await ApplicationService.getMyApplications()
      this.applications = result.records || []
      const nextTaskMap: Record<number, TaskVO> = {}
      const taskPromises = this.applications.map(async (app: ApplicationData): Promise<void> => {
        try {
          const task = await ApplicationService.getTask(app.taskId)
          if (task) {
            nextTaskMap[app.taskId] = task
          }
        } catch {
          // 单个职位详情失败不影响整体列表展示
        }
      })
      await Promise.all(taskPromises)
      this.taskMap = nextTaskMap
    } catch (e) {
      this.loadError = '投递记录加载失败，请稍后重试'
      this.applications = []
    }
    this.isLoading = false
  }

  filteredApplications(): ApplicationData[] {
    if (this.activeTab === 1) {
      return this.applications.filter((app: ApplicationData) => app.status === 1)
    }
    if (this.activeTab === 2) {
      return this.applications.filter((app: ApplicationData) => app.status === 3)
    }
    return this.applications
  }

  countByStatus(status: number): number {
    return this.applications.filter((app: ApplicationData) => app.status === status).length
  }

  toggleApplication(id: number): void {
    this.expandedId = this.expandedId === id ? -1 : id
  }

  openTask(task: TaskVO | null): void {
    if (!task) {
      return
    }
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/JobDetailPage',
      params: { jobData: JSON.stringify(mapTaskToJobData(task)) }
    })
  }

  build() {
    Column() {
      NavBar({
        title: '我的求职',
        showBack: true,
        onBack: () => this.getUIContext().getRouter().back()
      })

      Row() {
        this.statItem(String(this.applications.length), '全部投递', AppColors.PRIMARY, (): void => { this.activeTab = 0 })
        this.statItem(String(this.countByStatus(1)), '待面试', AppColors.WARNING, (): void => { this.activeTab = 1 })
        this.statItem(String(this.countByStatus(3)), '已录用', AppColors.SUCCESS, (): void => { this.activeTab = 2 })
      }
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.SM })
      .backgroundColor(AppColors.BG_CARD)

      Row() {
        this.tabItem('投递记录', 0)
        this.tabItem('面试邀请', 1)
        this.tabItem('已录用', 2)
        this.favoriteTab()
      }
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, bottom: AppSpacing.SM })
      .backgroundColor(AppColors.BG_CARD)

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(28)
            .height(28)
            .color(AppColors.PRIMARY)
          Text('加载中...')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
            .margin({ top: AppSpacing.SM })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.loadError) {
        Column() {
          Text(this.loadError)
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_SECONDARY)
          Button('重新加载', { type: ButtonType.Capsule })
            .height(36)
            .backgroundColor(AppColors.PRIMARY)
            .fontColor('#FFFFFF')
            .margin({ top: AppSpacing.MD })
            .onClick(() => {
              this.loadApplications()
            })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.filteredApplications().length === 0) {
        Column() {
          SymbolGlyph($r('sys.symbol.doc_text'))
            .fontSize(42)
            .fontColor([AppColors.TEXT_MUTED])
          Text(this.activeTab === 1 ? '暂无面试邀请' : '还没有投递记录')
            .fontSize(AppFontSize.MD)
            .fontColor(AppColors.TEXT_SECONDARY)
            .margin({ top: AppSpacing.SM })
          Text('去首页发现心仪的职位吧')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
            .margin({ top: AppSpacing.XS })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.filteredApplications(), (app: ApplicationData) => {
            ListItem() {
              ApplicationCard({
                app: app,
                task: this.taskMap[app.taskId] || null,
                expanded: this.expandedId === app.id,
                onToggle: () => { this.toggleApplication(app.id) },
                onOpenTask: () => { this.openTask(this.taskMap[app.taskId] || null) }
              })
            }
          }, (app: ApplicationData) => String(app.id))
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
        .backgroundColor(AppColors.BG_PAGE)
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  @Builder
  statItem(value: string, label: string, color: ResourceColor, onClick: () => void): void {
    Column() {
      Text(value)
        .fontSize(AppFontSize.XL)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_MUTED)
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .onClick(onClick)
    .stateStyles({ pressed: { .opacity(0.72) } })
  }

  @Builder
  tabItem(label: string, index: number): void {
    Button(label, { type: ButtonType.Capsule })
      .height(32)
      .fontSize(AppFontSize.SM)
      .fontColor(this.activeTab === index ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
      .backgroundColor(this.activeTab === index ? AppColors.PRIMARY : AppColors.INPUT_BG)
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.XS, bottom: AppSpacing.XS })
      .margin({ right: AppSpacing.SM })
      .onClick(() => {
        this.activeTab = index
      })
      .animation({ duration: 180 })
  }

  @Builder
  favoriteTab(): void {
    Button('收藏职位', { type: ButtonType.Capsule })
      .height(32)
      .fontSize(AppFontSize.SM)
      .fontColor(AppColors.TEXT_SECONDARY)
      .backgroundColor(AppColors.INPUT_BG)
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.XS, bottom: AppSpacing.XS })
      .onClick(() => {
        this.getUIContext().getRouter().pushUrl({ url: 'pages/FavoritesPage' })
      })
  }
}
