import { router } from '@kit.ArkUI'
import { AppColors, AppFontSize, AppRadius, AppSpacing } from '../common/AppStyles'
import { NavBar } from '../common/NavBar'
import { CategoryNode, DataService, RegionNode } from '../services/DataService'
import { EnterpriseDiscoveryService, EnterpriseListItem } from '../services/EnterpriseDiscoveryService'
import { TaskVO } from '../services/ChatTypes'

const PAGE_SIZE = 15

interface RegionOption {
  id: number
  name: string
}

@Entry
@Component
struct CompanyPage {
  @State keyword: string = ''
  @State enterprises: EnterpriseListItem[] = []
  @State categories: CategoryNode[] = []
  @State regions: RegionNode[] = []
  @State regionOptions: RegionOption[] = []
  @State selectedIndustry: string = ''
  @State selectedRegionId: number = 0
  @State selectedRegionName: string = '地区'
  @State sortBy: string = ''
  @State sortOrder: string = 'desc'
  @State page: number = 1
  @State totalPages: number = 1
  @State totalCount: number = 0
  @State isLoading: boolean = true
  @State errorText: string = ''
  @State showRegionPanel: boolean = false
  @State selectedEnterprise: EnterpriseListItem | null = null
  @State enterpriseJobs: TaskVO[] = []
  @State isLoadingJobs: boolean = false

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    if (params && params['keyword']) {
      this.keyword = params['keyword']
    }
    this.loadFilters()
    const enterpriseId = params && params['enterpriseId'] ? Number(params['enterpriseId']) : 0
    if (enterpriseId > 0) {
      this.loadEnterpriseById(enterpriseId)
    } else {
      this.loadEnterprises()
    }
  }

  private async loadFilters(): Promise<void> {
    this.categories = await DataService.getCategoryTree()
    this.regions = await DataService.getRegionTree()
    this.regionOptions = this.flattenRegions(this.regions, '')
  }

  private flattenRegions(nodes: RegionNode[], prefix: string): RegionOption[] {
    const result: RegionOption[] = []
    for (const node of nodes) {
      const fullName = prefix ? prefix + ' / ' + node.name : node.name
      result.push({ id: node.id, name: fullName })
      if (node.children && node.children.length > 0) {
        result.push(...this.flattenRegions(node.children, fullName))
      }
    }
    return result
  }

  private async loadEnterpriseById(enterpriseId: number): Promise<void> {
    try {
      const enterprise = await EnterpriseDiscoveryService.getEnterprise(enterpriseId)
      this.showEnterprise(enterprise)
    } catch {
      this.errorText = '企业信息加载失败，请返回后重试'
      this.loadEnterprises()
    }
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
        regionId: this.selectedRegionId > 0 ? this.selectedRegionId : undefined,
        sortBy: this.sortBy,
        sortOrder: this.sortOrder
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

  private selectRegion(region: RegionOption): void {
    this.selectedRegionId = region.id
    this.selectedRegionName = region.name
    this.showRegionPanel = false
    this.page = 1
    this.loadEnterprises()
  }

  private clearRegion(): void {
    this.selectedRegionId = 0
    this.selectedRegionName = '地区'
    this.showRegionPanel = false
    this.page = 1
    this.loadEnterprises()
  }

  private setSort(field: string): void {
    if (this.sortBy === field) {
      this.sortOrder = this.sortOrder === 'desc' ? 'asc' : 'desc'
    } else {
      this.sortBy = field
      this.sortOrder = 'desc'
    }
    this.page = 1
    this.loadEnterprises()
  }

  private async showEnterprise(item: EnterpriseListItem): Promise<void> {
    this.selectedEnterprise = item
    this.enterpriseJobs = []
    this.isLoadingJobs = true
    try {
      this.enterpriseJobs = await EnterpriseDiscoveryService.getPublishedJobs(item.id)
    } catch {
      this.enterpriseJobs = []
    }
    this.isLoadingJobs = false
  }

  private goBackToList(): void {
    this.selectedEnterprise = null
    this.enterpriseJobs = []
  }

  private goToJob(taskId: number): void {
    router.pushUrl({ url: 'pages/JobDetailPage', params: { jobId: taskId } })
  }

  private salaryText(job: TaskVO): string {
    if (job.salaryMin === 0 && job.salaryMax === 0) {
      return '面议'
    }
    const unit = job.salaryUnit === 0 ? '/日' : job.salaryUnit === 1 ? '/时' : '/月'
    return '￥' + job.salaryMin + '-' + job.salaryMax + unit
  }

  private jobTypeText(jobType: number): string {
    if (jobType === 1) {
      return '全职'
    }
    if (jobType === 2) {
      return '兼职'
    }
    if (jobType === 3) {
      return '实习'
    }
    return '职位'
  }

  @Builder filterChip(label: string, active: boolean, onClick: () => void) {
    Button() {
      Text(label)
        .fontSize(AppFontSize.XS)
        .fontColor(active ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
        .maxLines(1)
    }
    .height(32)
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
    .backgroundColor(active ? AppColors.SELECTED_BG : AppColors.INPUT_BG)
    .borderRadius(AppRadius.FULL)
    .onClick(onClick)
    .animation({ duration: 180 })
  }

  @Builder sortButton(label: string, field: string) {
    Button() {
      Text(label + (this.sortBy === field ? (this.sortOrder === 'desc' ? ' ↓' : ' ↑') : ''))
        .fontSize(AppFontSize.XS)
        .fontColor(this.sortBy === field ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
    }
    .height(34)
    .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
    .backgroundColor(this.sortBy === field ? AppColors.SELECTED_BG : Color.Transparent)
    .borderRadius(AppRadius.SM)
    .onClick(() => this.setSort(field))
  }

  @Builder enterpriseItem(item: EnterpriseListItem) {
    Row({ space: AppSpacing.MD }) {
      Stack() {
        Text((item.companyName || '企').charAt(0))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      .width(56)
      .height(56)
      .borderRadius(AppRadius.MD)
      .backgroundColor(AppColors.PRIMARY)

      Column({ space: AppSpacing.XS }) {
        Text(item.companyName || '企业')
          .fontSize(AppFontSize.MD)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: AppSpacing.XS }) {
          if (item.industry) {
            Text(item.industry)
              .fontSize(11)
              .fontColor(AppColors.PRIMARY)
              .backgroundColor(AppColors.SELECTED_BG)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .borderRadius(AppRadius.SM)
          }
          Text('已认证')
            .fontSize(11)
              .fontColor(AppColors.SUCCESS)
              .backgroundColor(AppColors.SELECTED_BG)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(AppRadius.SM)
        }

        Text(item.description || '暂无企业简介')
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.TEXT_SECONDARY)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(18)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor([AppColors.TEXT_MUTED])
    }
    .width('100%')
    .padding(AppSpacing.MD)
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius(AppRadius.MD)
    .onClick(() => this.showEnterprise(item))
    .stateStyles({ pressed: { .backgroundColor(AppColors.SELECTED_BG).scale({ x: 0.99, y: 0.99 }) } })
    .animation({ duration: 180 })
  }

  @Builder companyList() {
    Column() {
      Row() {
        Text('共 ' + this.totalCount + ' 家已认证企业')
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.TEXT_MUTED)
        Blank()
        this.sortButton('默认', '')
        this.sortButton('岗位', 'jobCount')
        this.sortButton('薪资', 'avgSalary')
      }
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.SM })

      if (this.isLoading) {
        LoadingProgress()
          .width(32)
          .height(32)
          .margin({ top: 88 })
          .color(AppColors.PRIMARY)
      } else if (this.errorText) {
        Column({ space: AppSpacing.SM }) {
          Text(this.errorText).fontSize(AppFontSize.SM).fontColor(AppColors.TEXT_SECONDARY)
          Button('重新加载')
            .fontSize(AppFontSize.SM)
            .backgroundColor(AppColors.PRIMARY)
            .fontColor('#FFFFFF')
            .onClick(() => this.loadEnterprises())
        }
        .width('100%')
        .margin({ top: 88 })
      } else if (this.enterprises.length === 0) {
        Column({ space: AppSpacing.SM }) {
          SymbolGlyph($r('sys.symbol.building'))
            .fontSize(36)
            .fontColor([AppColors.TEXT_MUTED])
          Text('暂无符合条件的企业').fontSize(AppFontSize.MD).fontColor(AppColors.TEXT_SECONDARY)
          Text('调整筛选条件后再试').fontSize(AppFontSize.XS).fontColor(AppColors.TEXT_MUTED)
        }
        .width('100%')
        .margin({ top: 88 })
      } else {
        Column({ space: AppSpacing.SM }) {
          ForEach(this.enterprises, (item: EnterpriseListItem) => {
            this.enterpriseItem(item)
          }, (item: EnterpriseListItem) => item.id.toString())
        }
        .width('100%')
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.XS })

        if (this.totalPages > 1) {
          Row({ space: AppSpacing.MD }) {
            Button('上一页')
              .enabled(this.page > 1)
              .onClick(() => { this.page -= 1; this.loadEnterprises() })
            Text(this.page + ' / ' + this.totalPages)
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.TEXT_SECONDARY)
            Button('下一页')
              .enabled(this.page < this.totalPages)
              .onClick(() => { this.page += 1; this.loadEnterprises() })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding(AppSpacing.LG)
        }
      }
    }
    .width('100%')
  }

  @Builder jobItem(job: TaskVO) {
    Column({ space: AppSpacing.XS }) {
      Row() {
        Text(job.title)
          .fontSize(AppFontSize.MD)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Text(this.salaryText(job))
          .fontSize(AppFontSize.SM)
          .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.DANGER)
      }
      Row({ space: AppSpacing.SM }) {
        Text(this.jobTypeText(job.jobType)).fontSize(AppFontSize.XS).fontColor(AppColors.PRIMARY)
        Text(job.regionName || job.address || '地点待定').fontSize(AppFontSize.XS).fontColor(AppColors.TEXT_SECONDARY)
        Text((job.applicationCount || 0) + ' 人投递').fontSize(AppFontSize.XS).fontColor(AppColors.TEXT_MUTED)
      }
    }
    .width('100%')
    .padding(AppSpacing.MD)
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius(AppRadius.MD)
    .onClick(() => this.goToJob(job.id))
    .stateStyles({ pressed: { .backgroundColor(AppColors.SELECTED_BG) } })
  }

  @Builder companyDetail() {
    if (this.selectedEnterprise) {
      Column() {
        NavBar({ title: '企业详情', showBack: true, onBack: () => this.goBackToList() })
        Scroll() {
          Column({ space: AppSpacing.LG }) {
            Row({ space: AppSpacing.MD }) {
              Stack() {
                Text((this.selectedEnterprise.companyName || '企').charAt(0))
                  .fontSize(30)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
              }
              .width(72)
              .height(72)
              .borderRadius(AppRadius.LG)
              .backgroundColor(AppColors.PRIMARY)
              Column({ space: AppSpacing.SM }) {
                Text(this.selectedEnterprise.companyName || '企业')
                  .fontSize(AppFontSize.XL)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppColors.TEXT_PRIMARY)
                if (this.selectedEnterprise.industry) {
                  Text(this.selectedEnterprise.industry)
                    .fontSize(AppFontSize.XS)
                    .fontColor(AppColors.PRIMARY)
                    .backgroundColor(AppColors.SELECTED_BG)
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                    .borderRadius(AppRadius.SM)
                }
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding(AppSpacing.LG)
            .backgroundColor(AppColors.BG_CARD)
            .borderRadius(AppRadius.LG)

            Text(this.selectedEnterprise.description || '暂无企业简介')
              .width('100%')
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.TEXT_SECONDARY)
              .lineHeight(22)
              .padding(AppSpacing.LG)
              .backgroundColor(AppColors.BG_CARD)
              .borderRadius(AppRadius.LG)

            Text('招聘中的职位')
              .fontSize(AppFontSize.LG)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT_PRIMARY)
              .width('100%')

            if (this.isLoadingJobs) {
              LoadingProgress().width(28).height(28).color(AppColors.PRIMARY)
            } else if (this.enterpriseJobs.length === 0) {
              Text('该企业暂无招聘中的职位')
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.TEXT_MUTED)
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(AppSpacing.XL)
            } else {
              Column({ space: AppSpacing.SM }) {
                ForEach(this.enterpriseJobs, (job: TaskVO) => {
                  this.jobItem(job)
                }, (job: TaskVO) => job.id.toString())
              }
              .width('100%')
            }
          }
          .width('100%')
          .padding(AppSpacing.MD)
        }
        .layoutWeight(1)
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.BG_PAGE)
    }
  }

  @Builder regionPanel() {
    if (this.showRegionPanel) {
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.28)')
          .onClick(() => this.showRegionPanel = false)
        Column({ space: AppSpacing.SM }) {
          Row() {
            Text('选择地区').fontSize(AppFontSize.MD).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
            Blank()
            Button('不限', { type: ButtonType.Capsule })
              .height(32)
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.PRIMARY)
              .backgroundColor(AppColors.SELECTED_BG)
              .onClick((): void => this.clearRegion())
          }
          .width('100%')
          List() {
            ForEach(this.regionOptions, (region: RegionOption) => {
              ListItem() {
                Text(region.name)
                  .width('100%')
                  .height(48)
                  .fontSize(AppFontSize.SM)
                  .fontColor(AppColors.TEXT_PRIMARY)
                  .padding({ left: AppSpacing.SM })
                  .onClick(() => this.selectRegion(region))
              }
            }, (region: RegionOption) => region.id.toString())
          }
          .height(260)
          .width('100%')
        }
        .width('100%')
        .padding(AppSpacing.LG)
        .backgroundColor(AppColors.BG_CARD)
        .borderRadius({ topLeft: AppRadius.LG, topRight: AppRadius.LG })
        .align(Alignment.Bottom)
        .transition({ opacity: 0, translate: { y: 24 } })
        .animation({ duration: 220 })
      }
      .width('100%')
      .height('100%')
    }
  }

  build() {
    Stack() {
      if (this.selectedEnterprise) {
        this.companyDetail()
      } else {
        Column() {
          NavBar({ title: '企业发现', showBack: true, onBack: () => router.back() })
          Row() {
            TextInput({ placeholder: '搜索企业名称', text: this.keyword })
              .layoutWeight(1)
              .height(42)
              .backgroundColor(AppColors.INPUT_BG)
              .borderRadius(AppRadius.MD)
              .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
              .onChange((value: string) => this.keyword = value)
            Button('搜索')
              .height(42)
              .margin({ left: AppSpacing.SM })
              .backgroundColor(AppColors.PRIMARY)
              .fontColor('#FFFFFF')
              .onClick(() => this.search())
          }
          .width('100%')
          .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM })

          Scroll() {
            Row({ space: AppSpacing.SM }) {
              this.filterChip(this.selectedRegionName, this.selectedRegionId > 0, () => this.showRegionPanel = true)
              this.filterChip('全部行业', this.selectedIndustry.length === 0, () => this.selectIndustry(''))
              ForEach(this.categories, (category: CategoryNode) => {
                this.filterChip(category.name, this.selectedIndustry === category.name, () => this.selectIndustry(category.name))
              }, (category: CategoryNode) => category.id.toString())
            }
            .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.SM })
          }
          .width('100%')
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)

          Scroll() {
            this.companyList()
          }
          .layoutWeight(1)
          .width('100%')
        }
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.BG_PAGE)
      }
      this.regionPanel()
    }
    .width('100%')
    .height('100%')
  }
}
