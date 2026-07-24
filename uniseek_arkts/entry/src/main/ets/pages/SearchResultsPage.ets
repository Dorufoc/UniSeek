import { ApiClient } from '../services/ApiClient'
import { DataService } from '../services/DataService'
import { JobData, mapTaskToJobData, TaskSearchParams, TaskVO } from '../services/ChatTypes'
import { PageResult } from '../services/ResumeService'
import { AppColors, AppFontSize, AppRadius, AppSpacing } from '../common/AppStyles'
import { WindowBreakpoint } from '../common/Responsive'
import { FilterBar } from './tab/seeker/FilterBar'
import { PageLoadPolicy } from '../common/BusinessPolicies'
import { JobCard } from '../components/JobCard'
import { EmptyView } from '../components/EmptyView'
import { ErrorView } from '../components/ErrorView'
import { LoadMoreFooter } from '../components/LoadMoreFooter'
import { FilterSheet, FilterSelection } from '../components/filter/FilterSheet'

@Entry
@Component
struct SearchResultsPage {
  @StorageLink('breakpoint') breakpoint: WindowBreakpoint = WindowBreakpoint.COMPACT
  @State keyword: string = ''
  @State results: JobData[] = []
  @State isLoading: boolean = true
  @State isLoadingMore: boolean = false
  @State totalCount: number = 0
  @State currentPage: number = 1
  @State totalPages: number = 0
  @State errorText: string = ''
  @State showFilterSheet: boolean = false

  // 复用首页 FilterSheet 的筛选状态
  @State salaryMin: number = 0
  @State salaryMax: number = 0
  @State selectedSalaryUnit: number = -1
  @State includeNegotiable: boolean = true
  @State selectedRegion: string[] = []
  @State selectedType: string[] = []
  @State selectedTags: string[] = []
  @State sortBy: string = 'create_time'

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>
    if (params && params['keyword']) {
      this.keyword = params['keyword']
    }
    this.preloadFilters()
    void this.loadResults(true)
  }

  // 预加载地区/分类联级数据，确保 FilterSheet 打开时直接从 Java 后端展示
  private async preloadFilters(): Promise<void> {
    try {
      await Promise.all([
        DataService.getRegionTree(),
        DataService.getCategoryTree()
      ])
    } catch (e) {
      console.error('预加载筛选条件失败', e)
    }
  }

  private hasActiveFilters(): boolean {
    return this.salaryMin > 0 ||
      this.salaryMax > 0 ||
      this.selectedSalaryUnit >= 0 ||
      !this.includeNegotiable ||
      this.selectedRegion.length > 0 ||
      this.selectedType.length > 0 ||
      this.selectedTags.length > 0
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
      sortBy: this.sortBy,
      sortOrder: 'desc',
      page: targetPage,
      pageSize: 20,
      salaryMin: this.salaryMin > 0 ? this.salaryMin : undefined,
      salaryMax: this.salaryMax > 0 ? this.salaryMax : undefined,
      salaryUnit: this.selectedSalaryUnit >= 0 ? this.selectedSalaryUnit : undefined,
      includeNegotiable: this.includeNegotiable,
      tags: this.selectedTags.length > 0 ? this.selectedTags.join(',') : undefined
    }

    // 地区名称转换为地区 ID 列表
    if (this.selectedRegion.length > 0) {
      const regionIdList: string[] = []
      for (const regionName of this.selectedRegion) {
        const id = DataService.getRegionIdByName(regionName)
        if (id !== null) {
          regionIdList.push(String(id))
        }
      }
      if (regionIdList.length > 0) {
        params.regionIds = regionIdList.join(',')
      }
    }

    // 分类名称转换为分类 ID 列表
    if (this.selectedType.length > 0) {
      const categoryIdList: string[] = []
      for (const typeName of this.selectedType) {
        const id = DataService.getCategoryIdByName(typeName)
        if (id !== null) {
          categoryIdList.push(String(id))
        }
      }
      if (categoryIdList.length > 0) {
        params.categoryIds = categoryIdList.join(',')
      }
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

  // 子组件 FilterSheet 应用筛选后回调
  private applyFilterSelection(selection: FilterSelection): void {
    this.salaryMin = selection.salaryMin
    this.salaryMax = selection.salaryMax
    this.selectedSalaryUnit = selection.salaryUnit
    this.includeNegotiable = selection.includeNegotiable
    this.selectedRegion = selection.region
    this.selectedType = selection.type
    this.selectedTags = selection.tags
    this.showFilterSheet = false
    void this.loadResults(true)
  }

  @Builder
  FilterSheetBuilder() {
    FilterSheet({
      salaryMin: this.salaryMin,
      salaryMax: this.salaryMax,
      selectedSalaryUnit: this.selectedSalaryUnit,
      includeNegotiable: this.includeNegotiable,
      selectedRegion: this.selectedRegion,
      selectedType: this.selectedType,
      selectedTags: this.selectedTags,
      breakpoint: this.breakpoint,
      onApply: (selection: FilterSelection) => { this.applyFilterSelection(selection) },
      onReset: () => { }
    })
  }

  build() {
    Column() {
      // 顶部标题与操作栏：与职位主页面（HomePage）保持一致的 FilterBar
      FilterBar({
        title: '搜索结果',
        filterActive: this.hasActiveFilters(),
        onFilterClick: () => { this.showFilterSheet = true },
        onSearch: () => {
          this.getUIContext().getRouter().pushUrl({ url: 'pages/SearchPage' })
        }
      })

      // 搜索输入栏
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

      if (this.isLoading && this.results.length === 0) {
        Column() {
          LoadingProgress()
            .width(32)
            .height(32)
            .color(AppColors.PRIMARY)
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
    .bindSheet($$this.showFilterSheet, this.FilterSheetBuilder(), {
      height: SheetSize.LARGE,
      dragBar: true,
      showClose: true,
      backgroundColor: AppColors.BG_CARD
    })
  }
}
