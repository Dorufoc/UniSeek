import { router } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';

const PREF_NAME = 'search_history_db';
const PREF_KEY = 'searchHistory';
const MAX_HISTORY = 20;
const DEFAULT_SHOW = 6;

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

  onPageShow(): void {
    this.loadHistory()
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
    router.pushUrl({ url: 'pages/SearchResultsPage', params: { keyword: text } })
  }

  handleSearch(): void {
    let text = this.searchText.trim()
    if (!text) {
      return
    }
    this.addToHistory(text)
    router.pushUrl({ url: 'pages/SearchResultsPage', params: { keyword: text } })
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
        showBack: false
      })

      Row() {
        TextInput({ placeholder: '搜索职位、公司...', text: this.searchText })
          .onChange((value: string) => {
            this.searchText = value
          })
          .height(40)
          .backgroundColor(AppColors.INPUT_BG)
          .borderRadius(AppRadius.FULL)
          .padding({ left: AppSpacing.MD })
          .margin({ left: AppSpacing.SM })
          .layoutWeight(1)

        Button({ type: ButtonType.Capsule }) {
          Text('搜索')
            .fontSize(AppFontSize.SM)
            .fontColor('#FFFFFF')
        }
          .height(40)
          .backgroundColor(AppColors.PRIMARY)
          .margin({ left: AppSpacing.SM })
          .onClick(() => {
            this.handleSearch()
          })
          .stateStyles({
            pressed: {
              .scale({ x: 0.97, y: 0.97 })
              .opacity(0.9)
              .backgroundColor(AppColors.PRIMARY_HOVER)
            },
            normal: {
              .scale({ x: 1, y: 1 })
              .opacity(1)
              .backgroundColor(AppColors.PRIMARY)
            }
          })
          .animation({
            duration: 200
          })
      }
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
      .alignItems(VerticalAlign.Center)

      Button() {
        Row({ space: AppSpacing.XS }) {
          SymbolGlyph($r('sys.symbol.building'))
            .fontSize(16)
            .fontColor([AppColors.PRIMARY])
          Text('找企业')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.PRIMARY)
        }
      }
      .height(36)
      .margin({ left: AppSpacing.MD, top: AppSpacing.MD })
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
      .backgroundColor(AppColors.SELECTED_BG)
      .borderRadius(AppRadius.FULL)
      .onClick(() => {
        router.pushUrl({ url: 'pages/CompanyPage', params: { keyword: this.searchText.trim() } })
      })

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
