import { ApplicationService, ApplicationData } from '../services/ApplicationService'
import { TaskVO, mapTaskToJobData } from '../services/ChatTypes'
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles'
import { NavBar } from '../common/NavBar'
import { ChoiceOption } from '../components/filter/ChoiceChips'
import { StandardCard } from '../common/StandardCard'

/** 投递卡片对外暴露的点击回调。 */
interface ApplicationCardCallbacks {
  onToggle: () => void
  onOpenTask: () => void
}

// 投递记录状态筛选选项：-1 表示全部，其余对应 application status
const FILTER_OPTIONS: ChoiceOption[] = [
  { value: -1, label: '全部' },
  { value: 1, label: '待面试' },
  { value: 2, label: '待定' },
  { value: 3, label: '已录用' },
  { value: 4, label: '已淘汰' }
]

@Component
struct ApplicationCard {
  @Prop app: ApplicationData = {
    id: 0, taskId: 0, applicantId: 0, resumeSnapshot: '', attachmentUrl: '',
    status: 0, interviewTime: '', interviewLocation: '', rejectReason: '',
    hrNote: '', createTime: '', updateTime: ''
  }
  @Prop task: TaskVO | null = null
  @Prop expanded: boolean = false
  @Prop callbacks: ApplicationCardCallbacks = { onToggle: () => {}, onOpenTask: () => {} }

  build() {
    StandardCard({
      onClickAction: () => { this.callbacks.onToggle() },
      accessibilityLabel: (this.task?.title || ('职位 #' + this.app.taskId)) + ' 投递记录'
    }) {
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
            this.callbacks.onOpenTask()
          })
      }
      }
      .width('100%')
    }
  }
}

@Entry
@Component
struct SubmittedPage {
  @State selectedFilter: number = -1
  @State applications: ApplicationData[] = []
  @State taskMap: Record<number, TaskVO> = {}
  @State expandedId: number = -1
  @State isLoading: boolean = true
  @State loadError: string = ''

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>
    const tab = params['tab'] || ''
    // 兼容旧入口参数，默认进入“全部”
    if (tab === 'interviews') {
      this.selectedFilter = 1
    } else if (tab === 'hired') {
      this.selectedFilter = 3
    } else {
      this.selectedFilter = -1
    }
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
    if (this.selectedFilter === -1) {
      return this.applications
    }
    return this.applications.filter((app: ApplicationData) => app.status === this.selectedFilter)
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

      // 状态筛选：横向滚动展示完整按钮，选中项使用主色强调
      Scroll() {
        Row() {
          ForEach(FILTER_OPTIONS, (option: ChoiceOption) => {
            Button(option.label, { type: ButtonType.Capsule })
              .height(AppSpacing.BUTTON_HEIGHT_SM)
              .fontSize(AppFontSize.SM)
              .fontColor(this.selectedFilter === option.value ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
              .backgroundColor(this.selectedFilter === option.value ? AppColors.PRIMARY : AppColors.INPUT_BG)
              .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
              .margin({ right: AppSpacing.SM })
              .onClick((): void => {
                this.selectedFilter = option.value
              })
              .stateStyles({
                pressed: {
                  .opacity(0.88)
                },
                normal: {
                  .opacity(1)
                }
              })
              .animation({ duration: 180 })
          }, (option: ChoiceOption): string => String(option.value))
        }
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })
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
          Text(this.selectedFilter === -1 ? '还没有投递记录' : `暂无${ApplicationService.statusLabel(this.selectedFilter)}的记录`)
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
                callbacks: {
                  onToggle: () => { this.toggleApplication(app.id) },
                  onOpenTask: () => { this.openTask(this.taskMap[app.taskId] || null) }
                }
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

}
