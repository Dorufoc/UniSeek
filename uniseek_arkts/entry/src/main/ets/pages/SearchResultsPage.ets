import { router } from '@kit.ArkUI'
import { ApiClient } from '../services/ApiClient'
import { JobData, mapTaskToJobData, TaskSearchParams, TaskVO } from '../services/ChatTypes'
import { PageResult } from '../services/ResumeService'
import { AppColors, AppFontSize, AppRadius, AppSpacing } from '../common/AppStyles'
import { NavBar } from '../common/NavBar'
import { PageLoadPolicy } from '../common/BusinessPolicies'
import { JobCard } from './tab/seeker/HomePage'

interface SearchSortOption {
  value: string
  label: string
}

const SEARCH_SORT_OPTIONS: SearchSortOption[] = [
  { value: 'create_time', label: '最新发布' },
  { value: 'popular', label: '热度优先' },
  { value: 'salary_max', label: '薪资优先' }
]

@Entry
@Component
struct SearchResultsPage {
  @State keyword: string = ''
  @State results: JobData[] = []
  @State tags: string[] = []
  @State selectedTag: string = ''
  @State sortBy: string = 'create_time'
  @State isLoading: boolean = true
  @State isLoadingMore: boolean = false
  @State totalCount: number = 0
  @State currentPage: number = 1
  @State totalPages: number = 0
  @State errorText: string = ''
  @State showFilterSheet: boolean = false

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    if (params && params['keyword']) {
      this.keyword = params['keyword']
    }
    void this.loadTags()
    void this.loadResults(true)
  }

  private async loadTags(): Promise<void> {
    try {
      this.tags = await ApiClient.get<string[]>('/api/tasks/tags/all')
    } catch {
      this.tags = []
    }
  }

  private async loadResults(reset: boolean): Promise<void> {
    if (reset) {
      this.isLoading = true
      this.currentPage = 1
      this.errorText = ''
    } else {
      this.isLoadingMore = true
    }
    const targetPage: number = reset ? 1 : this.currentPage + 1
    const params: TaskSearchParams = {
      keyword: this.keyword.trim(),
      tags: this.selectedTag,
      sortBy: this.sortBy,
      sortOrder: 'desc',
      page: targetPage,
      pageSize: 20
    }
    try {
      const result: PageResult<TaskVO> = await ApiClient.searchTasks(params)
      const nextRecords: JobData[] = result.records.map((task: TaskVO): JobData => mapTaskToJobData(task))
      this.results = reset ? nextRecords : this.results.concat(nextRecords)
      this.totalCount = result.total
      this.currentPage = result.page
      this.totalPages = result.totalPages
    } catch {
      if (reset) {
        this.results = []
        this.totalCount = 0
        this.totalPages = 0
        this.errorText = '职位列表加载失败，请检查网络后重试'
      }
    }
    this.isLoading = false
    this.isLoadingMore = false
  }

  private sortLabel(): string {
    const currentSort: string = this.sortBy
    for (const option of SEARCH_SORT_OPTIONS) {
      if (option.value === currentSort) {
        return option.label
      }
    }
    return '最新发布'
  }

  private selectTag(tag: string): void {
    this.selectedTag = this.selectedTag === tag ? '' : tag
    this.showFilterSheet = false
    void this.loadResults(true)
  }

  private selectSort(value: string): void {
    this.sortBy = value
    this.showFilterSheet = false
    void this.loadResults(true)
  }

  @Builder
  filterSheet() {
    Column() {
      Text('筛选与排序')
        .fontSize(AppFontSize.LG)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: AppSpacing.SM })
      Text('职位标签')
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM })
      List() {
        ListItem() {
          this.filterOption('全部标签', this.selectedTag.length === 0, (): void => { this.selectTag('') })
        }
        ForEach(this.tags, (tag: string) => {
          ListItem() {
            this.filterOption(tag, this.selectedTag === tag, (): void => { this.selectTag(tag) })
          }
        }, (tag: string): string => tag)
      }
      .layoutWeight(1)
      .width('100%')
      .divider({ strokeWidth: 0.5, color: AppColors.BORDER, startMargin: AppSpacing.MD, endMargin: AppSpacing.MD })
      Text('排序方式')
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD })
      Row({ space: AppSpacing.SM }) {
        ForEach(SEARCH_SORT_OPTIONS, (option: SearchSortOption) => {
          Button(option.label, { type: ButtonType.Capsule })
            .height(36)
            .fontSize(AppFontSize.XS)
            .fontColor(this.sortBy === option.value ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
            .backgroundColor(this.sortBy === option.value ? AppColors.PRIMARY : AppColors.INPUT_BG)
            .onClick((): void => { this.selectSort(option.value) })
        }, (option: SearchSortOption): string => option.value)
      }
      .width('100%')
      .padding(AppSpacing.MD)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  filterOption(label: string, selected: boolean, onClick: () => void) {
    Row() {
      Text(label)
        .fontSize(AppFontSize.SM)
        .fontColor(selected ? AppColors.PRIMARY : AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
      if (selected) {
        SymbolGlyph($r('sys.symbol.checkmark'))
          .fontSize(18)
          .fontColor([AppColors.PRIMARY])
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: AppSpacing.LG, right: AppSpacing.LG })
    .backgroundColor(selected ? AppColors.SELECTED_BG : AppColors.BG_CARD)
    .onClick(onClick)
  }

  build() {
    Column() {
      NavBar({ title: '搜索结果', showBack: true, onBack: (): void => { router.back() } })

      Row({ space: AppSpacing.SM }) {
        Search({ value: this.keyword, placeholder: '搜索职位、企业或技能' })
          .layoutWeight(1)
          .height(40)
          .backgroundColor(AppColors.INPUT_BG)
          .borderRadius(AppRadius.FULL)
          .onChange((value: string): void => { this.keyword = value })
          .onSubmit((): void => { void this.loadResults(true) })
        Button('筛选', { type: ButtonType.Capsule })
        .width(56)
        .height(40)
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
        .backgroundColor(this.selectedTag || this.sortBy !== 'create_time' ? AppColors.SELECTED_BG : AppColors.INPUT_BG)
        .accessibilityText('筛选和排序')
        .onClick((): void => { this.showFilterSheet = true })
      }
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.SM })

      if (this.selectedTag || this.sortBy !== 'create_time') {
        Text((this.selectedTag || '全部标签') + ' · ' + this.sortLabel())
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.PRIMARY)
          .width('100%')
          .padding({ left: AppSpacing.MD, right: AppSpacing.MD, bottom: AppSpacing.SM })
      }

      if (this.isLoading) {
        LoadingProgress().width(32).height(32).margin({ top: 100 }).color(AppColors.PRIMARY)
      } else if (this.errorText) {
        Column({ space: AppSpacing.SM }) {
          Text(this.errorText).fontSize(AppFontSize.SM).fontColor(AppColors.TEXT_SECONDARY)
          Button('重新加载', { type: ButtonType.Capsule })
            .height(40)
            .fontSize(AppFontSize.SM)
            .fontColor('#FFFFFF')
            .backgroundColor(AppColors.PRIMARY)
            .onClick((): void => { void this.loadResults(true) })
        }
        .width('100%')
        .margin({ top: 80 })
        .alignItems(HorizontalAlign.Center)
      } else if (this.results.length === 0) {
        Column({ space: AppSpacing.SM }) {
          Text('未找到相关职位').fontSize(AppFontSize.MD).fontColor(AppColors.TEXT_MUTED)
          Text('试试其他关键词或筛选条件').fontSize(AppFontSize.SM).fontColor(AppColors.TEXT_MUTED)
        }
        .width('100%')
        .margin({ top: 80 })
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: AppSpacing.SM }) {
          ListItem() {
            Text('共 ' + this.totalCount + ' 条结果')
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.TEXT_MUTED)
              .width('100%')
          }
          ForEach(this.results, (job: JobData) => {
            ListItem() { JobCard({ job: job }) }
          }, (job: JobData): string => job.id)
          if (PageLoadPolicy.hasNext(this.currentPage, this.totalPages)) {
            ListItem() {
              Button(this.isLoadingMore ? '加载中...' : '加载更多', { type: ButtonType.Capsule })
                .width('100%')
                .height(40)
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.PRIMARY)
                .backgroundColor(AppColors.SELECTED_BG)
                .enabled(!this.isLoadingMore)
                .onClick((): void => { void this.loadResults(false) })
            }
          }
        }
        .width('100%')
        .layoutWeight(1)
        .padding(AppSpacing.MD)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
    .bindSheet($$this.showFilterSheet, this.filterSheet(), {
      height: SheetSize.LARGE,
      dragBar: true,
      showClose: true,
      backgroundColor: AppColors.BG_CARD
    })
  }
}
