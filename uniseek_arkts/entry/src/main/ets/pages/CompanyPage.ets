import { AppColors, AppFontSize, AppRadius, AppSpacing, AppFilter } from '../common/AppStyles'
import { NavBar } from '../common/NavBar'
import { StandardCard } from '../common/StandardCard'
import { EmptyView } from '../components/EmptyView'
import { ErrorView } from '../components/ErrorView'
import { LoadMoreFooter } from '../components/LoadMoreFooter'
import { CategoryNode, DataService, RegionNode } from '../services/DataService'
import { EnterpriseDiscoveryService, EnterpriseListItem } from '../services/EnterpriseDiscoveryService'
import { FilterBar } from './tab/seeker/FilterBar'
import { FilterSheetHeader } from '../components/filter/FilterSheetHeader'

const PAGE_SIZE = 15

/**
 * 企业发现联级选择弹窗
 * 职责：在筛选 Sheet 内统一展示省/市/区县、行业大类/子类等单选列表。
 */
@CustomDialog
struct CascadePickerDialog {
  controller: CustomDialogController
  @Prop title: string = ''
  @Prop options: string[] = []
  onSelect?: (name: string) => void
  onClose?: () => void

  build() {
    Column() {
      Text(this.title)
        .fontSize(AppFontSize.MD)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .margin({ bottom: AppSpacing.MD })

      List({ space: AppSpacing.XS }) {
        ForEach(this.options, (name: string) => {
          ListItem() {
            Row() {
              Text(name)
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.TEXT_PRIMARY)
                .textAlign(TextAlign.Start)
                .width('100%')
            }
            .width('100%')
            .height(AppSpacing.BUTTON_HEIGHT_MD)
            .padding({ left: AppSpacing.SM_PLUS, right: AppSpacing.SM_PLUS })
            .backgroundColor(AppColors.INPUT_BG)
            .borderRadius(AppRadius.MD)
            .onClick(() => {
              this.onSelect?.(name)
            })
            .stateStyles({
              pressed: { .opacity(0.8) }
            })
          }
        }, (name: string): string => name)
      }
      .width('100%')
      .height(280)

      Button('取消', { type: ButtonType.Capsule })
        .width('100%')
        .height(AppSpacing.BUTTON_HEIGHT)
        .backgroundColor(AppColors.INPUT_BG)
        .fontColor(AppColors.TEXT_SECONDARY)
        .fontSize(AppFontSize.MD)
        .margin({ top: AppSpacing.MD })
        .onClick(() => {
          this.onClose?.()
          this.controller.close()
        })
    }
    .width('80%')
    .padding(AppSpacing.MD)
    .backgroundColor(AppColors.BG_PAGE)
    .borderRadius(AppRadius.LG)
  }
}

@Component
export struct CompanyDiscovery {
  @Prop showBack: boolean = true

  @State keyword: string = ''
  @State enterprises: EnterpriseListItem[] = []
  @State page: number = 1
  @State totalPages: number = 1
  @State totalCount: number = 0
  @State isLoading: boolean = true
  @State isRefreshing: boolean = false
  @State hasMore: boolean = true
  @State errorText: string = ''
  @State showFilterSheet: boolean = false

  // 从 Java 后端获取的联级筛选数据
  @State regionTree: RegionNode[] = []
  @State categoryTree: CategoryNode[] = []

  // 当前已应用的筛选条件（地区为路径数组， deepest 作为筛选值）
  @State regionPath: string[] = []
  @State categoryPath: string[] = []
  @State selectedIndustry: string = ''
  @State selectedRegionId: number = 0
  @State selectedRegionName: string = '地区'

  // 联级选择器弹窗运行时状态
  @State pickerOptions: string[] = []
  @State pickerTitle: string = ''
  @State pickerType: 'region' | 'category' | '' = ''
  @State pickerLevel: number = 1
  @State pickerPath: string[] = []

  private regionDialogController: CustomDialogController = new CustomDialogController({
    builder: CascadePickerDialog({
      title: this.pickerTitle,
      options: this.pickerOptions,
      onSelect: (name: string): void => { this.handlePickerSelect(name) },
      onClose: (): void => { this.resetPicker() }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  })

  private categoryDialogController: CustomDialogController = new CustomDialogController({
    builder: CascadePickerDialog({
      title: this.pickerTitle,
      options: this.pickerOptions,
      onSelect: (name: string): void => { this.handlePickerSelect(name) },
      onClose: (): void => { this.resetPicker() }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  })

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>
    if (params && params['keyword']) {
      this.keyword = params['keyword']
    }
    // 支持由外部/Tab调用时隐藏返回按钮
    if (params && params['showBack'] !== undefined) {
      this.showBack = params['showBack'] !== 'false'
    }
    // 提前从 Java 后端加载地区/分类联级数据
    this.loadFilters()
    this.loadEnterprises()
  }

  /**
   * 加载筛选联级数据：调用后端 /api/region/tree 与 /api/categories
   */
  private async loadFilters(): Promise<void> {
    try {
      // ArkTS 不支持数组解构，使用顺序 await 分别获取地区树与分类树
      this.regionTree = await DataService.getRegionTree()
      this.categoryTree = await DataService.getCategoryTree()
    } catch (e) {
      console.error('加载筛选条件失败', e)
    }
  }

  /**
   * 加载企业列表
   * @param append true 表示追加下一页（流式懒加载），false 表示刷新/重新加载首页
   */
  private async loadEnterprises(append: boolean = false): Promise<void> {
    // 仅加载更多时避免并发；刷新/首次加载直接执行
    if (append && this.isLoading) {
      return
    }
    this.isLoading = true
    this.errorText = ''
    const currentPage = append ? this.page + 1 : 1
    try {
      const result = await EnterpriseDiscoveryService.getEnterprises({
        page: currentPage,
        pageSize: PAGE_SIZE,
        keyword: this.keyword.trim(),
        industry: this.selectedIndustry,
        regionId: this.selectedRegionId > 0 ? this.selectedRegionId : undefined
      })
      const records = result.records || []
      this.enterprises = append ? [...this.enterprises, ...records] : [...records]
      this.totalCount = result.total || 0
      this.totalPages = result.totalPages > 0 ? result.totalPages : 1
      this.page = currentPage
      this.hasMore = currentPage < this.totalPages
    } catch {
      if (!append) {
        this.enterprises = []
        this.totalCount = 0
        this.totalPages = 1
        this.page = 1
        this.hasMore = false
        this.errorText = '企业列表加载失败，请检查网络后重试'
      } else {
        this.errorText = '加载更多企业失败，请检查网络后重试'
      }
    }
    this.isLoading = false
    this.isRefreshing = false
  }

  private search(): void {
    this.loadEnterprises(false)
  }

  private showEnterprise(item: EnterpriseListItem): void {
    // 点击企业卡片跳转独立企业详情页，不再在当前页面覆盖布局
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/CompanyDetailPage',
      params: { enterpriseId: item.id }
    })
  }

  private companyInitials(name: string): string {
    const safeName = name || '企'
    return safeName.charAt(0)
  }

  private hasActiveFilters(): boolean {
    return this.regionPath.length > 0 || this.categoryPath.length > 0
  }

  // ===== 筛选条件应用与重置 =====
  private applyFilters(): void {
    if (this.regionPath.length === 0) {
      this.selectedRegionId = 0
      this.selectedRegionName = '地区'
    } else {
      const regionId = DataService.getRegionIdByName(this.regionPath.join('-'))
      this.selectedRegionId = regionId || 0
      this.selectedRegionName = this.regionPath.join('-')
    }
    this.selectedIndustry = this.categoryPath.length > 0 ? this.categoryPath[this.categoryPath.length - 1] : ''
    this.showFilterSheet = false
    this.loadEnterprises(false)
  }

  private resetFilters(): void {
    this.regionPath = []
    this.categoryPath = []
    this.selectedIndustry = ''
    this.selectedRegionId = 0
    this.selectedRegionName = '地区'
    this.loadEnterprises(false)
  }

  // ===== 联级选择器逻辑 =====
  private resetPicker(): void {
    this.pickerType = ''
    this.pickerLevel = 1
    this.pickerPath = []
    this.pickerOptions = []
    this.pickerTitle = ''
  }

  private openRegionPicker(): void {
    this.resetPicker()
    this.pickerType = 'region'
    this.pickerLevel = 1
    this.pickerTitle = '选择省份 / 直辖市'
    this.pickerOptions = this.regionTree.map((n: RegionNode) => n.name)
    this.regionDialogController.open()
  }

  private openCategoryPicker(): void {
    this.resetPicker()
    this.pickerType = 'category'
    this.pickerLevel = 1
    this.pickerTitle = '选择行业大类'
    this.pickerOptions = this.categoryTree.map((n: CategoryNode) => n.name)
    this.categoryDialogController.open()
  }

  private handlePickerSelect(name: string): void {
    this.pickerPath = [...this.pickerPath, name]
    if (this.pickerType === 'region') {
      this.advanceRegionPicker(name)
    } else if (this.pickerType === 'category') {
      this.advanceCategoryPicker(name)
    }
  }

  private advanceRegionPicker(name: string): void {
    const node = this.findRegionNode(this.pickerPath)
    if (!node) {
      return
    }

    if (this.pickerLevel === 1) {
      if (node.children && node.children.length > 0) {
        this.pickerLevel = 2
        this.pickerTitle = '选择城市'
        this.pickerOptions = node.children.map((c: RegionNode) => c.name)
        return
      }
    } else if (this.pickerLevel === 2) {
      if (node.children && node.children.length > 0) {
        this.pickerLevel = 3
        this.pickerTitle = '选择区县'
        this.pickerOptions = node.children.map((c: RegionNode) => c.name)
        return
      }
    }

    // 已选择到最深层（或无子级），应用地区筛选
    this.regionPath = [...this.pickerPath]
    this.regionDialogController.close()
    this.applyFilters()
  }

  private advanceCategoryPicker(name: string): void {
    const node = this.findCategoryNode(this.pickerPath)
    if (!node) {
      return
    }

    if (this.pickerLevel === 1) {
      if (node.children && node.children.length > 0) {
        this.pickerLevel = 2
        this.pickerTitle = '选择行业子类'
        this.pickerOptions = node.children.map((c: CategoryNode) => c.name)
        return
      }
    }

    // 已选择到最深层（或无子级），应用行业筛选
    this.categoryPath = [...this.pickerPath]
    this.categoryDialogController.close()
    this.applyFilters()
  }

  private findRegionNode(path: string[]): RegionNode | null {
    let nodes = this.regionTree
    let found: RegionNode | null = null
    for (const name of path) {
      found = nodes.find((n: RegionNode) => n.name === name) || null
      if (!found) {
        return null
      }
      nodes = found.children || []
    }
    return found
  }

  private findCategoryNode(path: string[]): CategoryNode | null {
    let nodes = this.categoryTree
    let found: CategoryNode | null = null
    for (const name of path) {
      found = nodes.find((n: CategoryNode) => n.name === name) || null
      if (!found) {
        return null
      }
      nodes = found.children || []
    }
    return found
  }

  // ===== UI 构建 =====
  build() {
    Column() {
      this.companyListPage()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
    .bindSheet($$this.showFilterSheet, this.companyFilterSheet(), {
      height: SheetSize.FIT_CONTENT,
      dragBar: true,
      showClose: true,
      backgroundColor: AppColors.BG_CARD
    })
  }

  // 企业列表主页面
  @Builder
  companyListPage() {
    Column() {
      // 作为独立页面进入时显示原生返回导航栏
      if (this.showBack) {
        NavBar({
          title: '企业发现',
          showBack: true,
          onBack: () => this.getUIContext().getRouter().back()
        })
      }

      // 顶部标题与操作栏：标题 + 筛选按钮 + 搜索按钮（与首页发现职位保持一致）
      FilterBar({
        title: this.showBack ? '' : '企业发现',
        filterActive: this.hasActiveFilters(),
        onFilterClick: () => { this.showFilterSheet = true },
        onSearch: () => {
          this.getUIContext().getRouter().pushUrl({
            url: 'pages/SearchPage',
            params: { from: 'company' }
          })
        }
      })

      // 内容区
      if (this.isLoading && this.enterprises.length === 0 && !this.isRefreshing) {
        Column() {
          LoadingProgress()
            .width(AppSpacing.ICON_MD)
            .height(AppSpacing.ICON_MD)
            .color(AppColors.PRIMARY)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.errorText !== '' && this.enterprises.length === 0) {
        Column() {
          ErrorView({
            message: this.errorText,
            retryText: '重新加载',
            onRetry: () => { this.loadEnterprises(false) }
          })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding(AppSpacing.MD)
      } else {
        this.companyList()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  // 企业列表：支持下拉刷新 + 触底无限加载
  @Builder
  companyList() {
    Refresh({ refreshing: this.isRefreshing, promptText: '下拉刷新...' }) {
      List({ space: AppSpacing.SM }) {
        // 顶部统计
        ListItem() {
          Row() {
            Text('共 ' + this.totalCount + ' 家已认证企业')
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.TEXT_MUTED)
            Blank()
          }
          .width('100%')
          .padding({ top: AppSpacing.XS, bottom: AppSpacing.SM })
        }

        if (this.enterprises.length === 0 && !this.isLoading) {
          ListItem() {
            Column() {
              EmptyView({
                message: '暂无符合条件的企业',
                icon: $r('sys.symbol.building')
              })
            }
            .width('100%')
            .padding({ top: AppSpacing.XL, bottom: AppSpacing.XL })
          }
        }

        ForEach(this.enterprises, (item: EnterpriseListItem) => {
          this.enterpriseItem(item)
        }, (item: EnterpriseListItem): string => item.id.toString())

        // 流式加载更多底部提示
        if (this.enterprises.length > 0) {
          ListItem() {
            LoadMoreFooter({
              loading: this.isLoading && !this.isRefreshing && this.hasMore,
              hasMore: this.hasMore,
              finishedText: '已展示全部企业'
            })
          }
        }
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
      .edgeEffect(EdgeEffect.Spring)
      .onReachEnd(() => {
        if (this.hasMore && !this.isLoading) {
          this.loadEnterprises(true)
        }
      })
    }
    .layoutWeight(1)
    .width('100%')
    .onRefreshing(() => {
      this.isRefreshing = true
      this.loadEnterprises(false)
    })
  }

  // 单个企业卡片
  @Builder
  enterpriseItem(item: EnterpriseListItem) {
    ListItem() {
      StandardCard({
        onClickAction: () => { this.showEnterprise(item) },
        accessibilityLabel: item.companyName
      }) {
        Row({ space: AppSpacing.MD }) {
          // Logo
          Stack() {
            Text(this.companyInitials(item.companyName))
              .fontSize(AppFontSize.ICON_LG)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.BG_CARD)
          }
          .width(AppSpacing.ICON_XL)
          .height(AppSpacing.ICON_XL)
          .borderRadius(AppRadius.MD)
          .backgroundColor(AppColors.PRIMARY)

          // 信息
          Column({ space: AppSpacing.XS }) {
            Text(item.companyName || '企业')
              .fontSize(AppFontSize.MD)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT_PRIMARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')

            Row({ space: AppSpacing.XS }) {
              if (item.industry) {
                this.infoChip(item.industry)
              }
              this.infoChip('已认证')
            }
            .width('100%')

            Text(item.description || '暂无企业简介')
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.TEXT_SECONDARY)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .lineHeight(AppSpacing.BUTTON_HEIGHT_XS)
              .width('100%')
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

  // 企业筛选底部面板：参考首页 FilterSheet，使用地区三按钮 + 行业两按钮联级选择
  @Builder
  companyFilterSheet() {
    Column() {
      FilterSheetHeader({
        title: '筛选企业',
        showReset: false
      })

      Scroll() {
        Column({ space: AppSpacing.LG }) {
          // ===== 所在地区 =====
          Column({ space: AppSpacing.SM }) {
            Text('所在地区')
              .fontSize(AppFilter.SECTION_TITLE_FONT_SIZE)
              .fontWeight(AppFilter.SECTION_TITLE_FONT_WEIGHT)
              .fontColor(AppColors.TEXT_PRIMARY)
              .width('100%')

            Row({ space: AppFilter.CHOICE_CHIP_SPACE }) {
              this.SelectorButton(
                this.regionPath[0] || '',
                '省 / 直辖市',
                () => { this.openRegionPicker() }
              )
              this.SelectorButton(
                this.regionPath[1] || '',
                '城市',
                () => { this.openRegionPicker() }
              )
              this.SelectorButton(
                this.regionPath[2] || '',
                '区县',
                () => { this.openRegionPicker() }
              )
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            if (this.regionPath.length > 0) {
              this.FilterChip(this.regionPath.join(' / ') + ' ' + (this.selectedRegionId ? '' : ''), () => {
                this.regionPath = []
                this.applyFilters()
              })
            }
          }
          .width('100%')

          // ===== 所属行业 =====
          Column({ space: AppSpacing.SM }) {
            Text('所属行业')
              .fontSize(AppFilter.SECTION_TITLE_FONT_SIZE)
              .fontWeight(AppFilter.SECTION_TITLE_FONT_WEIGHT)
              .fontColor(AppColors.TEXT_PRIMARY)
              .width('100%')

            Row({ space: AppFilter.CHOICE_CHIP_SPACE }) {
              this.SelectorButton(
                this.categoryPath[0] || '',
                '行业大类',
                () => { this.openCategoryPicker() }
              )
              this.SelectorButton(
                this.categoryPath[1] || '',
                '子类',
                () => { this.openCategoryPicker() }
              )
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            if (this.categoryPath.length > 0) {
              this.FilterChip(this.categoryPath.join(' / ') + ' ' + (this.selectedIndustry ? '' : ''), () => {
                this.categoryPath = []
                this.applyFilters()
              })
            }
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM_PLUS, bottom: AppSpacing.MD })
      }
      .scrollBar(BarState.Auto)

      // 底部重置筛选按钮
      Button('重置筛选')
        .width('100%')
        .height(AppSpacing.INPUT_HEIGHT)
        .backgroundColor(AppColors.DANGER)
        .fontColor('#FFFFFF')
        .fontSize(AppFontSize.MD)
        .fontWeight(FontWeight.Medium)
        .borderRadius(AppRadius.LG)
        .margin({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.MD })
        .onClick(() => {
          this.resetFilters()
          this.showFilterSheet = false
        })
    }
    .width('100%')
    .backgroundColor(AppColors.BG_CARD)
  }

  @Builder
  SelectorButton(label: string, placeholder: string, onClick: () => void) {
    Button(label || placeholder, { type: ButtonType.Capsule })
      .height(AppFilter.CHOICE_CHIP_HEIGHT)
      .fontSize(AppFilter.CHOICE_CHIP_FONT_SIZE)
      .fontColor(label ? AppColors.PRIMARY : AppColors.TEXT_MUTED)
      .backgroundColor(label ? AppColors.SELECTED_BG : AppColors.INPUT_BG)
      .layoutWeight(1)
      .onClick(onClick)
      .stateStyles({
        pressed: { .opacity(0.85) }
      })
      .animation({ duration: 180 })
  }

  @Builder
  FilterChip(label: string, onClose: () => void) {
    Row() {
      Text(label)
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text('×')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_MUTED)
        .margin({ left: AppSpacing.XS })
        .onClick(() => {
          onClose()
        })
    }
    .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
    .backgroundColor(AppColors.SELECTED_BG)
    .borderRadius(AppRadius.MD)
    .margin({ top: AppSpacing.SM })
  }
}

// 保留独立页面入口，内部复用 CompanyDiscovery
@Entry
@Component
struct CompanyPage {
  build() {
    Stack() {
      CompanyDiscovery({ showBack: true })
    }
    .width('100%')
    .height('100%')
  }
}
