import { ApiClient } from '../../../services/ApiClient';
import { DataService } from '../../../services/DataService';
import { TaskVO, TaskSearchParams, mapTaskToJobData } from '../../../services/ChatTypes';
import { AppColors, AppSpacing, AppFontSize } from '../../../common/AppStyles';
import { FilterBar } from './FilterBar';
import { JobFeedList } from './JobFeedList';
import { FilterSheet, FilterSelection } from '../../../components/filter/FilterSheet';
import { TabDataState } from './JobFeedTypes'
import { WindowBreakpoint } from '../../../common/Responsive';

@Component
export struct HomePage {
  @StorageLink('breakpoint') breakpoint: WindowBreakpoint = WindowBreakpoint.COMPACT
  @State activeCategory: string = '全职'
  @State selectedTabIndex: number = 0
  @State salaryMin: number = 0
  @State salaryMax: number = 0
  @State selectedSalaryUnit: number = -1
  @State includeNegotiable: boolean = true
  @State selectedRegion: string[] = []
  @State selectedType: string[] = []
  @State selectedTags: string[] = []
  @State tabData: Record<number, TabDataState> = {
    1: { jobs: [], page: 1, hasMore: true, loading: false, errorText: '' },
    2: { jobs: [], page: 1, hasMore: true, loading: false, errorText: '' },
    3: { jobs: [], page: 1, hasMore: true, loading: false, errorText: '' }
  }

  // 筛选抽屉显隐控制
  @State showFilterSheet: boolean = false

  aboutToAppear(): void {
    this.loadTabData(1, false)
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

  async loadTabData(jobType: number, append: boolean): Promise<void> {
    const state = this.tabData[jobType]
    if (state.loading || (!append && state.jobs.length > 0 && !state.hasMore) || (append && !state.hasMore)) return

    const loadingState: TabDataState = {
      jobs: state.jobs,
      page: state.page,
      hasMore: state.hasMore,
      loading: true,
      errorText: ''
    }
    this.tabData = {
      1: jobType === 1 ? loadingState : this.tabData[1],
      2: jobType === 2 ? loadingState : this.tabData[2],
      3: jobType === 3 ? loadingState : this.tabData[3]
    }

    try {
      const params: TaskSearchParams = {
        jobType: jobType,
        page: append ? state.page + 1 : 1,
        pageSize: 10,
        salaryMin: this.salaryMin > 0 ? this.salaryMin : undefined,
        salaryMax: this.salaryMax > 0 ? this.salaryMax : undefined,
        salaryUnit: this.selectedSalaryUnit >= 0 ? this.selectedSalaryUnit : undefined,
        includeNegotiable: this.includeNegotiable,
        tags: this.selectedTags.length > 0 ? this.selectedTags.join(',') : undefined
      }

      // 构建地区筛选参数：将 selectedRegion 中的名称转换为地区ID
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

      // 构建分类筛选参数：将 selectedType 中的名称转换为分类ID
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

      const result = await ApiClient.searchTasks(params)
      const newJobs = result.records.map((task: TaskVO) => mapTaskToJobData(task))
      const hasMore = result.page < result.totalPages

      const successState: TabDataState = {
        jobs: append ? state.jobs.concat(newJobs) : newJobs,
        page: result.page,
        hasMore: hasMore,
        loading: false,
        errorText: ''
      }
      this.tabData = {
        1: jobType === 1 ? successState : this.tabData[1],
        2: jobType === 2 ? successState : this.tabData[2],
        3: jobType === 3 ? successState : this.tabData[3]
      }
    } catch (e) {
      console.error('加载职位失败 jobType=' + jobType, e)
      const errorState: TabDataState = {
        jobs: state.jobs,
        page: state.page,
        hasMore: state.hasMore,
        loading: false,
        errorText: '职位列表加载失败，请检查网络后重试'
      }
      this.tabData = {
        1: jobType === 1 ? errorState : this.tabData[1],
        2: jobType === 2 ? errorState : this.tabData[2],
        3: jobType === 3 ? errorState : this.tabData[3]
      }
    }
  }

  resetAllTabs(): void {
    this.tabData = {
      1: { jobs: [], page: 1, hasMore: true, loading: false, errorText: '' },
      2: { jobs: [], page: 1, hasMore: true, loading: false, errorText: '' },
      3: { jobs: [], page: 1, hasMore: true, loading: false, errorText: '' }
    }
    const currentType = this.activeCategory === '兼职' ? 2 : this.activeCategory === '实习' ? 3 : 1
    this.loadTabData(currentType, false)
  }

  private onTabChange(index: number): void {
    const jobTypes = [1, 2, 3]
    const jobType = jobTypes[index]
    const state = this.tabData[jobType]
    if (state.jobs.length === 0 && !state.loading) {
      this.loadTabData(jobType, false)
    }
  }

  loadMoreForTab(jobType: number): void {
    this.loadTabData(jobType, true)
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
    this.resetAllTabs()
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

  @Builder TabLabel(label: string, index: number) {
    Text(label)
      .fontSize(AppFontSize.MD)
      .fontColor(this.selectedTabIndex === index ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
      .fontWeight(this.selectedTabIndex === index ? FontWeight.Bold : FontWeight.Regular)
      .padding({ bottom: 6 })
      .animation({
        duration: 250,
        curve: 'cubic-bezier(0.2, 0, 0, 1.0)'
      })
  }

  @Builder tabFullTime() {
    this.TabLabel('全职', 0)
  }

  @Builder tabPartTime() {
    this.TabLabel('兼职', 1)
  }

  @Builder tabIntern() {
    this.TabLabel('实习', 2)
  }

  build() {
    Column() {
      // === 顶部标题与操作栏：标题 + 筛选按钮 + 搜索按钮 ===
      FilterBar({
        title: '发现职位',
        filterActive: this.hasActiveFilters(),
        onFilterClick: () => { this.showFilterSheet = true },
        onSearch: () => {
          this.getUIContext().getRouter().pushUrl({ url: 'pages/SearchPage' })
        }
      })

      // === Tabs 三页面（带下拉刷新） ===
      Tabs({ barPosition: BarPosition.Start }) {
        TabContent() {
          JobFeedList({
            jobType: 1,
            tabData: this.tabData,
            loadMore: (jt: number) => this.loadMoreForTab(jt),
            onRefresh: (jt: number) => { this.loadTabData(jt, false) }
          })
        }
        .tabBar(this.tabFullTime)

        TabContent() {
          JobFeedList({
            jobType: 2,
            tabData: this.tabData,
            loadMore: (jt: number) => this.loadMoreForTab(jt),
            onRefresh: (jt: number) => { this.loadTabData(jt, false) }
          })
        }
        .tabBar(this.tabPartTime)

        TabContent() {
          JobFeedList({
            jobType: 3,
            tabData: this.tabData,
            loadMore: (jt: number) => this.loadMoreForTab(jt),
            onRefresh: (jt: number) => { this.loadTabData(jt, false) }
          })
        }
        .tabBar(this.tabIntern)
      }
      .scrollable(true)
      .layoutWeight(1)
      .width('100%')
      .animationDuration(300)
      .onChange((index: number) => {
        this.selectedTabIndex = index
        this.onTabChange(index)
      })
      .barMode(BarMode.Fixed)
      .backgroundColor(AppColors.BG_PAGE)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
    .padding({ top: AppSpacing.XS })
    .bindSheet($$this.showFilterSheet, this.FilterSheetBuilder(), {
      height: SheetSize.LARGE,
      dragBar: true,
      showClose: true,
      backgroundColor: AppColors.BG_CARD
    })
  }
}
