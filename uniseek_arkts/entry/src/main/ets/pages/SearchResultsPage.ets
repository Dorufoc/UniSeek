import { ApiClient } from '../services/ApiClient'
import { JobData, mapTaskToJobData, TaskSearchParams, TaskVO } from '../services/ChatTypes'
import { PageResult } from '../services/ResumeService'
import { AppColors, AppFilter, AppFontSize, AppRadius, AppSpacing } from '../common/AppStyles'
import { NavBar } from '../common/NavBar'
import { PageLoadPolicy } from '../common/BusinessPolicies'
import { JobCard } from '../components/JobCard'
import { EmptyView } from '../components/EmptyView'
import { ErrorView } from '../components/ErrorView'
import { LoadMoreFooter } from '../components/LoadMoreFooter'
import { FilterChipBar, FilterChipData } from '../components/filter/FilterChipBar'
import { FilterSheetHeader } from '../components/filter/FilterSheetHeader'
import { SelectorOptionItem } from '../components/filter/SelectorOptionItem'
import { ChoiceChips, ChoiceOption } from '../components/filter/ChoiceChips'

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
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>
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

  private selectedSortIndex(): number {
    for (let index = 0; index < SEARCH_SORT_OPTIONS.length; index++) {
      if (SEARCH_SORT_OPTIONS[index].value === this.sortBy) {
        return index
      }
    }
    return 0
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

  private sortOptionsForChoice(): ChoiceOption[] {
    const options: ChoiceOption[] = []
    for (let index = 0; index < SEARCH_SORT_OPTIONS.length; index++) {
      options.push({ value: index, label: SEARCH_SORT_OPTIONS[index].label })
    }
    return options
  }

  private buildFilterChips(): FilterChipData[] {
    const chips: FilterChipData[] = []
    const hasActiveFilter: boolean = this.selectedTag.length > 0 || this.sortBy !== 'create_time'
    chips.push({
      label: '筛选',
      active: hasActiveFilter
    })
    if (this.selectedTag.length > 0) {
      chips.push({
        label: this.selectedTag,
        active: true,
        hasClose: true
      })
    }
    chips.push({
      label: this.sortLabel(),
      active: this.sortBy !== 'create_time',
      hasClose: this.sortBy !== 'create_time'
    })
    return chips
  }

  @Builder
  filterSheet() {
    Column() {
      FilterSheetHeader({
        title: '筛选与排序',
        showReset: false
      })

      Text('职位标签')
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM })

      List() {
        ListItem() {
          SelectorOptionItem({
            label: '全部标签',
            selected: this.selectedTag.length === 0,
            onItemClick: (): void => { this.selectTag('') }
          })
        }
        ForEach(this.tags, (tag: string) => {
          ListItem() {
            SelectorOptionItem({
              label: tag,
              selected: this.selectedTag === tag,
              onItemClick: (): void => { this.selectTag(tag) }
            })
          }
        }, (tag: string): string => tag)
      }
      .layoutWeight(1)
      .width('100%')
      .divider({ strokeWidth: AppFilter.DIVIDER_HEIGHT, color: AppFilter.DIVIDER_COLOR, startMargin: AppFilter.DIVIDER_INSETS, endMargin: AppFilter.DIVIDER_INSETS })

      Text('排序方式')
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD })

      ChoiceChips({
        options: this.sortOptionsForChoice(),
        selected: this.selectedSortIndex(),
        onSelect: (index: number): void => {
          if (index >= 0 && index < SEARCH_SORT_OPTIONS.length) {
            this.selectSort(SEARCH_SORT_OPTIONS[index].value)
          }
        }
      })
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.XS, bottom: AppSpacing.MD })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_CARD)
  }

  build() {
    Column() {
      NavBar({ title: '搜索结果', showBack: true, onBack: (): void => { this.getUIContext().getRouter().back() } })

      Row({ space: AppSpacing.SM }) {
        Search({ value: this.keyword, placeholder: '搜索职位、企业或技能' })
          .layoutWeight(1)
          .height(AppSpacing.BUTTON_HEIGHT)
          .backgroundColor(AppColors.INPUT_BG)
          .borderRadius(AppRadius.FULL)
          .onChange((value: string): void => { this.keyword = value })
          .onSubmit((): void => { void this.loadResults(true) })
      }
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.SM })

      FilterChipBar({
        chips: this.buildFilterChips(),
        onChipClick: (index: number): void => {
          this.showFilterSheet = true
        },
        onClose: (index: number): void => {
          if (index === 0) {
            this.showFilterSheet = true
          } else if (this.selectedTag.length > 0 && index === 1) {
            this.selectTag('')
          } else {
            this.selectSort('create_time')
          }
        }
      })

      if (this.isLoading) {
        LoadingProgress().width(32).height(32).margin({ top: 100 }).color(AppColors.PRIMARY)
      } else if (this.errorText) {
        Column() {
          ErrorView({
            message: this.errorText,
            retryText: '重新加载',
            onRetry: () => { void this.loadResults(true) }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding(AppSpacing.MD)
      } else if (this.results.length === 0) {
        Column() {
          EmptyView({
            message: '未找到相关职位，试试其他关键词或筛选条件',
            actionText: '调整筛选',
            onAction: () => { this.showFilterSheet = true }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding(AppSpacing.MD)
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
          ListItem() {
            LoadMoreFooter({
              loading: this.isLoadingMore,
              hasMore: PageLoadPolicy.hasNext(this.currentPage, this.totalPages),
              finishedText: '已展示全部 ' + this.totalCount + ' 条结果'
            })
          }
        }
        .width('100%')
        .layoutWeight(1)
        .padding(AppSpacing.MD)
        .onReachEnd((): void => {
          if (PageLoadPolicy.hasNext(this.currentPage, this.totalPages) && !this.isLoadingMore) {
            void this.loadResults(false)
          }
        })
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
