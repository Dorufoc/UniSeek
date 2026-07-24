import { preferences } from '@kit.ArkData';
import { SegmentButton, SegmentButtonOptions } from '@kit.ArkUI';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';

const PREF_NAME = 'search_history_db';
const PREF_KEY = 'searchHistory';
const MAX_HISTORY = 20;
const DEFAULT_SHOW = 6;

// 搜索模式：0 职位，1 公司
const SEARCH_MODE_JOB = 0;
const SEARCH_MODE_COMPANY = 1;

interface HistoryRow {
  left: string
  leftIdx: number
  right: string | undefined
  rightIdx: number
}

@Entry
@Component
struct SearchPage {
  @State searchText: string = ''
  @State searchHistory: string[] = []
  @State showAll: boolean = false
  @State isDeleting: boolean = false

  // 分段按钮：搜索职位 / 搜索公司
  @State selectedModeIndexes: number[] = [SEARCH_MODE_JOB]
  @State modeOptions: SegmentButtonOptions = SegmentButtonOptions.capsule({
    buttons: [{ text: '职位' }, { text: '公司' }],
    multiply: false,
    selectedBackgroundColor: AppColors.PRIMARY,
    backgroundColor: AppColors.INPUT_BG,
    selectedFontColor: AppColors.BG_CARD,
    fontColor: AppColors.TEXT_SECONDARY,
    fontSize: AppFontSize.SM,
    selectedFontSize: AppFontSize.SM
  })

  onPageShow(): void {
    this.loadHistory()
    const params = this.getUIContext().getRouter().getParams() as Record<string, string | undefined>
    // 从哪个分区进入搜索页，分段按钮默认选中哪个
    if (params && params['from'] === 'company') {
      this.selectedModeIndexes = [SEARCH_MODE_COMPANY]
    } else {
      this.selectedModeIndexes = [SEARCH_MODE_JOB]
    }
    // 从首页搜索入口传入的关键词自动填入并记录历史
    const keyword = params ? params['keyword'] : undefined
    if (keyword && keyword.trim().length > 0) {
      this.searchText = keyword.trim()
      this.addToHistory(this.searchText)
    }
  }

  loadHistory(): void {
    let pref = preferences.getPreferencesSync(getContext(), { name: PREF_NAME })
    let json = pref.getSync(PREF_KEY, '[]') as string
    try {
      this.searchHistory = JSON.parse(json)
    } catch {
      this.searchHistory = []
    }
  }

  saveHistory(): void {
    let pref = preferences.getPreferencesSync(getContext(), { name: PREF_NAME })
    pref.putSync(PREF_KEY, JSON.stringify(this.searchHistory))
    pref.flushSync()
  }

  addToHistory(text: string): void {
    let trimmed = text.trim()
    if (!trimmed) {
      return
    }
    let copy = this.searchHistory.slice()
    let idx = copy.indexOf(trimmed)
    if (idx !== -1) {
      copy.splice(idx, 1)
    }
    copy.unshift(trimmed)
    if (copy.length > MAX_HISTORY) {
      copy = copy.slice(0, MAX_HISTORY)
    }
    this.searchHistory = copy
    this.saveHistory()
  }

  removeFromHistory(index: number): void {
    let copy = this.searchHistory.slice()
    copy.splice(index, 1)
    this.searchHistory = copy
    this.saveHistory()
  }

  clearAllHistory(): void {
    this.searchHistory = []
    this.isDeleting = false
    this.saveHistory()
  }

  triggerSearch(text: string): void {
    this.searchText = text
    this.addToHistory(text)
    this.executeSearch()
  }

  handleSearch(): void {
    let text = this.searchText.trim()
    if (!text) {
      return
    }
    this.addToHistory(text)
    this.executeSearch()
  }

  private executeSearch(): void {
    const text = this.searchText.trim()
    if (this.selectedModeIndexes[0] === SEARCH_MODE_COMPANY) {
      // 搜索公司：进入企业发现页（带关键词）
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/CompanyPage',
        params: { keyword: text }
      })
    } else {
      // 搜索职位：进入搜索结果页
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/SearchResultsPage',
        params: { keyword: text }
      })
    }
  }

  getDisplayList(): string[] {
    return this.showAll ? this.searchHistory : this.searchHistory.slice(0, DEFAULT_SHOW)
  }

  getRowData(): HistoryRow[] {
    let items = this.getDisplayList()
    let result: HistoryRow[] = []
    for (let i = 0; i < items.length; i += 2) {
      result.push({
        left: items[i],
        leftIdx: i,
        right: i + 1 < items.length ? items[i + 1] : undefined,
        rightIdx: i + 1
      } as HistoryRow)
    }
    return result
  }

  @Builder historyCell(text: string, index: number) {
    Row() {
      Text(text)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_PRIMARY)
      if (this.isDeleting) {
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(14)
            .fontColor([AppColors.DANGER])
        }
          .width(28)
          .height(28)
          .backgroundColor(AppColors.ERROR_BG)
          .margin({ left: AppSpacing.XS })
          .onClick(() => {
            this.removeFromHistory(index)
          })
      }
    }
    .height(36)
    .padding({ left: AppSpacing.LG, right: AppSpacing.LG })
    .backgroundColor(Color.Transparent)
    .borderRadius(AppRadius.XL)
    .onClick(() => {
      if (!this.isDeleting) {
        this.triggerSearch(text)
      }
    })
    .stateStyles({
      pressed: {
        .backgroundColor(AppColors.SELECTED_BG)
      }
    })
  }

  build() {
    Column() {
      NavBar({
        title: '搜索',
        showBack: true
      })

      // 搜索输入与搜索按钮：重新分配尺寸，避免按钮被挤压
      Row() {
        TextInput({
          placeholder: this.selectedModeIndexes[0] === SEARCH_MODE_COMPANY ? '搜索企业名称' : '搜索职位、公司或技能',
          text: this.searchText
        })
          .onChange((value: string) => {
            this.searchText = value
          })
          .onSubmit(() => {
            this.handleSearch()
          })
          .height(AppSpacing.BUTTON_HEIGHT_MD)
          .backgroundColor(AppColors.INPUT_BG)
          .borderRadius(AppRadius.FULL)
          .padding({ left: AppSpacing.MD })
          .layoutWeight(1)

        Button('搜索', { type: ButtonType.Capsule })
          .width(80)
          .height(AppSpacing.BUTTON_HEIGHT_MD)
          .fontSize(AppFontSize.SM)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor(AppColors.PRIMARY)
          .margin({ left: AppSpacing.SM })
          .onClick(() => {
            this.handleSearch()
          })
      }
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
      .alignItems(VerticalAlign.Center)

      // 分段按钮：职位 / 公司
      Row() {
        SegmentButton({
          options: this.modeOptions,
          selectedIndexes: $selectedModeIndexes
        })
      }
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM })
      .justifyContent(FlexAlign.Center)

      Row() {
        Text('搜索历史')
          .fontSize(AppFontSize.MD)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)

        Blank()

        if (this.isDeleting) {
          Row({ space: AppSpacing.XS }) {
            Button('全部删除', { type: ButtonType.Capsule })
              .height(32)
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.DANGER)
              .backgroundColor(AppColors.ERROR_BG)
              .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
              .onClick(() => {
                this.clearAllHistory()
              })
            Button('完成', { type: ButtonType.Capsule })
              .height(32)
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.PRIMARY)
              .backgroundColor(AppColors.SELECTED_BG)
              .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
              .onClick(() => {
                this.isDeleting = false
              })
          }
        } else if (this.searchHistory.length > 0) {
          Button('编辑', { type: ButtonType.Capsule })
            .height(32)
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.PRIMARY)
            .backgroundColor(AppColors.SELECTED_BG)
            .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
            .onClick(() => {
              this.isDeleting = true
            })
        }
      }
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
      .margin({ top: AppSpacing.LG })

      if (this.searchHistory.length > 0) {
        Column({ space: 8 }) {
          ForEach(this.getRowData(), (row: HistoryRow) => {
            Row() {
              Column() {
                this.historyCell(row.left, row.leftIdx)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Blank().width(4)

              if (row.right) {
                Column() {
                  this.historyCell(row.right, row.rightIdx)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              } else {
                Blank().layoutWeight(1)
              }
            }
            .width('100%')
          }, (row: HistoryRow) => {
            return row.leftIdx.toString()
          })

          if (this.searchHistory.length > DEFAULT_SHOW) {
            Button({ type: ButtonType.Normal }) {
              Row({ space: AppSpacing.XS }) {
                Text(this.showAll ? '收起' : '展开更多')
                  .fontSize(AppFontSize.SM)
                  .fontColor(AppColors.PRIMARY)
                SymbolGlyph(this.showAll ? $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down'))
                  .fontSize(14)
                  .fontColor([AppColors.PRIMARY])
              }
            }
              .width('100%')
              .height(36)
              .backgroundColor(Color.Transparent)
              .margin({ top: AppSpacing.SM })
              .onClick(() => {
                this.showAll = !this.showAll
              })
          }
        }
        .width('100%')
        .margin({ top: AppSpacing.SM })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
