import { AppColors, AppFontSize, AppRadius, AppSpacing } from '../common/AppStyles'
import { NavBar } from '../common/NavBar'
import { StandardCard } from '../common/StandardCard'
import { EmptyView } from '../components/EmptyView'
import { ErrorView } from '../components/ErrorView'
import { CategoryNode, DataService, RegionNode } from '../services/DataService'
import { EnterpriseDiscoveryService, EnterpriseListItem } from '../services/EnterpriseDiscoveryService'
import { FilterBar } from '../tab/seeker/FilterBar'
import { FilterSheetHeader } from '../components/filter/FilterSheetHeader'
import { SelectorOptionItem } from '../components/filter/SelectorOptionItem'
import { SelectorOption } from '../components/filter/SelectorSheet'

const PAGE_SIZE = 15

@Component
export struct CompanyDiscovery {
  @Prop showBack: boolean = true

  @State keyword: string = ''
  @State enterprises: EnterpriseListItem[] = []
  @State categories: CategoryNode[] = []
  @State regions: RegionNode[] = []
  @State regionOptions: SelectorOption[] = []
  @State industryOptions: SelectorOption[] = []
  @State selectedIndustry: string = ''
  @State selectedRegionId: number = 0
  @State selectedRegionName: string = '地区'
  @State page: number = 1
  @State totalPages: number = 1
  @State totalCount: number = 0
  @State isLoading: boolean = true
  @State errorText: string = ''
  @State showFilterSheet: boolean = false

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>
    if (params && params['keyword']) {
      this.keyword = params['keyword']
    }
    // 支持由外部/Tab调用时隐藏返回按钮
    if (params && params['showBack'] !== undefined) {
      this.showBack = params['showBack'] !== 'false'
    }
    this.loadFilters()
    this.loadEnterprises()
  }

  private async loadFilters(): Promise<void> {
    this.categories = await DataService.getCategoryTree()
    this.regions = await DataService.getRegionTree()
    this.regionOptions = this.flattenRegions(this.regions, '')
    this.industryOptions = this.flattenCategories(this.categories, '')
  }

  private flattenRegions(nodes: RegionNode[], prefix: string): SelectorOption[] {
    const result: SelectorOption[] = []
    for (const node of nodes) {
      const fullName = prefix ? prefix + ' / ' + node.name : node.name
      result.push({ id: node.id, label: fullName })
      if (node.children && node.children.length > 0) {
        for (const child of node.children) {
          const childOptions = this.flattenRegions([child], fullName)
          for (const option of childOptions) {
            result.push(option)
          }
        }
      }
    }
    return result
  }

  private flattenCategories(nodes: CategoryNode[], prefix: string): SelectorOption[] {
    const result: SelectorOption[] = []
    for (const node of nodes) {
      const label = prefix ? prefix + ' / ' + node.name : node.name
      result.push({ id: node.id, label: label })
      if (node.children && node.children.length > 0) {
        for (const child of node.children) {
          const childOptions = this.flattenCategories([child], label)
          for (const option of childOptions) {
            result.push(option)
          }
        }
      }
    }
    return result
  }

  private async loadEnterprises(): Promise<void> {
    this.isLoading = true
    this.errorText = ''
    try {
      const result = await EnterpriseDiscoveryService.getEnterprises({
        page: this.page,
        pageSize: PAGE_SIZE,
        keyword: this.keyword.trim(),
        industry: this.selectedIndustry,
        regionId: this.selectedRegionId > 0 ? this.selectedRegionId : undefined
      })
      this.enterprises = result.records || []
      this.totalCount = result.total || 0
      this.totalPages = result.totalPages > 0 ? result.totalPages : 1
    } catch {
      this.enterprises = []
      this.totalCount = 0
      this.totalPages = 1
      this.errorText = '企业列表加载失败，请检查网络后重试'
    }
    this.isLoading = false
  }

  private search(): void {
    this.page = 1
    this.loadEnterprises()
  }

  private selectIndustry(industry: string): void {
    this.selectedIndustry = this.selectedIndustry === industry ? '' : industry
    this.page = 1
    this.loadEnterprises()
  }

  private selectRegion(option: SelectorOption): void {
    this.selectedRegionId = Number(option.id)
    this.selectedRegionName = option.label
    this.page = 1
    this.loadEnterprises()
  }

  private clearRegion(): void {
    this.selectedRegionId = 0
    this.selectedRegionName = '地区'
    this.page = 1
    this.loadEnterprises()
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
    return this.selectedRegionId > 0 || this.selectedIndustry.length > 0
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
      height: SheetSize.LARGE,
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
      } else if (this.errorText !== '' && this.enterprises.length === 0) {
        Column() {
          ErrorView({
            message: this.errorText,
            retryText: '重新加载',
            onRetry: () => { this.loadEnterprises() }
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

  // 企业列表：使用 List + StandardCard 呈现
  @Builder
  companyList() {
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

      if (this.enterprises.length === 0) {
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

      // 分页
      if (this.totalPages > 1) {
        ListItem() {
          Row({ space: AppSpacing.MD }) {
            Button('上一页', { type: ButtonType.Capsule })
              .height(AppSpacing.BUTTON_HEIGHT_SM)
              .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
              .fontSize(AppFontSize.SM)
              .fontColor(this.page > 1 ? '#FFFFFF' : AppColors.TEXT_MUTED)
              .backgroundColor(this.page > 1 ? AppColors.PRIMARY : AppColors.INPUT_BG)
              .enabled(this.page > 1)
              .onClick(() => { this.page -= 1; this.loadEnterprises() })

            Text(this.page + ' / ' + this.totalPages)
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.TEXT_SECONDARY)

            Button('下一页', { type: ButtonType.Capsule })
              .height(AppSpacing.BUTTON_HEIGHT_SM)
              .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
              .fontSize(AppFontSize.SM)
              .fontColor(this.page < this.totalPages ? '#FFFFFF' : AppColors.TEXT_MUTED)
              .backgroundColor(this.page < this.totalPages ? AppColors.PRIMARY : AppColors.INPUT_BG)
              .enabled(this.page < this.totalPages)
              .onClick(() => { this.page += 1; this.loadEnterprises() })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: AppSpacing.MD, bottom: AppSpacing.XL })
        }
      }
    }
    .layoutWeight(1)
    .width('100%')
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
    .edgeEffect(EdgeEffect.Spring)
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

  // 企业筛选底部面板：集中选择地区与行业
  @Builder
  companyFilterSheet() {
    Column() {
      FilterSheetHeader({
        title: '筛选企业',
        showReset: true,
        onReset: () => {
          this.clearRegion()
          this.selectIndustry('')
          this.showFilterSheet = false
        }
      })

      Text('地区')
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM })

      Scroll() {
        Column({ space: AppSpacing.XS }) {
          SelectorOptionItem({
            label: '全部地区',
            selected: this.selectedRegionId === 0,
            onItemClick: () => {
              this.clearRegion()
              this.showFilterSheet = false
            }
          })
          ForEach(this.regionOptions, (option: SelectorOption) => {
            SelectorOptionItem({
              label: option.label,
              selected: this.selectedRegionId === Number(option.id),
              onItemClick: () => {
                this.selectRegion(option)
                this.showFilterSheet = false
              }
            })
          }, (option: SelectorOption): string => String(option.id))
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)

      Text('行业')
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD })

      Scroll() {
        Column({ space: AppSpacing.XS }) {
          SelectorOptionItem({
            label: '全部行业',
            selected: this.selectedIndustry.length === 0,
            onItemClick: () => {
              this.selectIndustry('')
              this.showFilterSheet = false
            }
          })
          ForEach(this.industryOptions, (option: SelectorOption) => {
            SelectorOptionItem({
              label: option.label,
              selected: this.selectedIndustry === option.label,
              onItemClick: () => {
                this.selectIndustry(option.label)
                this.showFilterSheet = false
              }
            })
          }, (option: SelectorOption): string => String(option.id))
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_CARD)
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
