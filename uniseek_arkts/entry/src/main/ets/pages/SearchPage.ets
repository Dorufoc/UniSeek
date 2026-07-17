import { router } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';

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
        .fontSize(14)
        .fontColor('#333333')
      if (this.isDeleting) {
        Text('✕')
          .fontSize(11)
          .fontColor('#FF4444')
          .margin({ left: 6 })
          .onClick(() => {
            this.removeFromHistory(index)
          })
      }
    }
    .height(36)
    .padding({ left: 20, right: 20 })
    .backgroundColor(Color.Transparent)
    .borderRadius(16)
    .onClick(() => {
      if (!this.isDeleting) {
        this.triggerSearch(text)
      }
    })
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(20)
          .fontColor('#333333')
          .onClick(() => {
            router.back()
          })

        TextInput({ placeholder: '搜索职位、公司...', text: this.searchText })
          .onChange((value: string) => {
            this.searchText = value
          })
          .height(40)
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .padding({ left: 16 })
          .margin({ left: 12 })
          .layoutWeight(1)

        Button('搜索')
          .height(40)
          .backgroundColor('#007AFF')
          .borderRadius(20)
          .fontColor('#FFFFFF')
          .fontSize(14)
          .margin({ left: 8 })
          .onClick(() => {
            this.handleSearch()
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      Row() {
        Text('搜索历史')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        if (this.isDeleting) {
          Row() {
            Text('全部删除')
              .fontSize(14)
              .fontColor('#FF4444')
              .onClick(() => {
                this.clearAllHistory()
              })
            Blank().width(16)
            Text('完成')
              .fontSize(14)
              .fontColor('#007AFF')
              .onClick(() => {
                this.isDeleting = false
              })
          }
        } else if (this.searchHistory.length > 0) {
          Text('编辑')
            .fontSize(14)
            .fontColor('#007AFF')
            .onClick(() => {
              this.isDeleting = true
            })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .margin({ top: 20 })

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
            Text(this.showAll ? '收起' : '展开更多')
              .fontSize(14)
              .fontColor('#007AFF')
              .width('100%')
              .textAlign(TextAlign.Center)
              .margin({ top: 8 })
              .onClick(() => {
                this.showAll = !this.showAll
              })
          }
        }
        .width('100%')
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .padding({ top: 12 })
  }
}
