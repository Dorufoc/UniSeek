import { router } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';
import { ResumeData, ResumeService } from '../services/ResumeService';


const PREF_NAME = 'recruiter_search_history_db';
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
struct RecruiterSearchPage {
  @State searchText: string = ''
  @State searchHistory: string[] = []
  @State showAll: boolean = false
  @State isDeleting: boolean = false
  @State results: ResumeData[] = []
  @State loading: boolean = false
  @State searched: boolean = false
  @State errorText: string = ''

  aboutToAppear(): void {
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
    let idx = this.searchHistory.indexOf(trimmed)
    if (idx !== -1) {
      this.searchHistory.splice(idx, 1)
    }
    this.searchHistory.unshift(trimmed)
    if (this.searchHistory.length > MAX_HISTORY) {
      this.searchHistory = this.searchHistory.slice(0, MAX_HISTORY)
    }
    this.saveHistory()
  }

  removeFromHistory(index: number): void {
    this.searchHistory.splice(index, 1)
    this.saveHistory()
  }

  clearAllHistory(): void {
    this.searchHistory = []
    this.isDeleting = false
    this.saveHistory()
  }

  triggerSearch(text: string): void {
    this.searchText = text
    this.searchResumes(text)
  }

  async searchResumes(keyword: string): Promise<void> {
    this.loading = true
    this.searched = true
    this.errorText = ''
    try {
      const result = await ResumeService.searchPublishedResumes(keyword || undefined, 1, 50)
      this.results = result.records
    } catch {
      this.results = []
      this.errorText = '搜索失败，请检查网络后重试'
    } finally {
      this.loading = false
    }
  }

  handleSearch(): void {
    const text: string = this.searchText.trim()
    if (text) {
      this.addToHistory(text)
    }
    this.searchResumes(text)
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
        title: '搜索简历',
        showBack: true,
        onBack: () => router.back()
      })

      Row() {
        TextInput({ placeholder: '寻找人才...', text: this.searchText })
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
      if (this.searched) {
        Column() {
          Row() {
            Text(this.loading ? '正在搜索' : '搜索结果')
              .fontSize(AppFontSize.MD)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT_PRIMARY)
            Blank()
            if (!this.loading && !this.errorText) {
              Text(String(this.results.length) + ' 位人才')
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.TEXT_MUTED)
            }
          }
          .width('100%')
          .margin({ bottom: AppSpacing.SM })

          if (this.loading) {
            Column() {
              LoadingProgress()
                .width(28)
                .height(28)
                .color(AppColors.PRIMARY)
              Text('正在匹配人才')
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.TEXT_MUTED)
                .margin({ top: AppSpacing.SM })
            }
            .width('100%')
            .padding({ top: AppSpacing.XL, bottom: AppSpacing.XL })
          } else if (this.errorText) {
            Text(this.errorText)
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.DANGER)
              .width('100%')
              .padding(AppSpacing.MD)
              .backgroundColor(AppColors.ERROR_BG)
              .borderRadius(AppRadius.SM)
          } else if (this.results.length === 0) {
            Column() {
              SymbolGlyph($r('sys.symbol.person'))
                .fontSize(32)
                .fontColor([AppColors.TEXT_MUTED])
              Text('暂无匹配的人才')
                .fontSize(AppFontSize.MD)
                .fontColor(AppColors.TEXT_SECONDARY)
                .margin({ top: AppSpacing.SM })
            }
            .width('100%')
            .padding({ top: AppSpacing.XL, bottom: AppSpacing.XL })
          } else {
            List({ space: AppSpacing.SM }) {
              ForEach(this.results, (resume: ResumeData) => {
                ListItem() {
                  Row() {
                    Column() {
                      Text((resume.realName || '求').substring(0, 1))
                        .fontSize(AppFontSize.LG)
                        .fontWeight(FontWeight.Medium)
                        .fontColor('#FFFFFF')
                    }
                    .width(44)
                    .height(44)
                    .justifyContent(FlexAlign.Center)
                    .backgroundColor(AppColors.PRIMARY)
                    .borderRadius(22)

                    Column() {
                      Row() {
                        Text(resume.realName || '未实名')
                          .fontSize(AppFontSize.MD)
                          .fontWeight(FontWeight.Medium)
                          .fontColor(AppColors.TEXT_PRIMARY)
                        Text(resume.education || '学历未填')
                          .fontSize(AppFontSize.XS)
                          .fontColor(AppColors.TEXT_MUTED)
                          .margin({ left: AppSpacing.SM })
                      }
                      .width('100%')
                      Text((resume.school || '院校未填') + ' · ' + (resume.skills || '暂无技能标签'))
                        .fontSize(AppFontSize.SM)
                        .fontColor(AppColors.TEXT_SECONDARY)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width('100%')
                        .margin({ top: AppSpacing.XS })
                    }
                    .layoutWeight(1)
                    .margin({ left: AppSpacing.MD })

                    SymbolGlyph($r('sys.symbol.chevron_right'))
                      .fontSize(16)
                      .fontColor([AppColors.TEXT_MUTED])
                  }
                  .width('100%')
                  .padding(AppSpacing.MD)
                  .backgroundColor(AppColors.BG_CARD)
                  .borderRadius(AppRadius.MD)
                  .onClick(() => {
                    router.pushUrl({
                      url: 'pages/ResumeDetailPage',
                      params: {
                        resumeData: JSON.stringify({
                          id: String(resume.userId),
                          name: resume.realName || '未实名',
                          age: 0,
                          avatar: '',
                          education: resume.education || '',
                          school: resume.school || '',
                          major: '',
                          experience: resume.experience || '',
                          skills: resume.skills || '',
                          region: '',
                          type: '',
                          category: '',
                          expectedSalary: '面议',
                          description: resume.experience || '',
                          attachmentUrl: resume.attachmentUrl || ''
                        })
                      }
                    })
                  })
                  .stateStyles({
                    pressed: {
                      .backgroundColor(AppColors.SELECTED_BG)
                    }
                  })
                }
              }, (resume: ResumeData) => String(resume.userId))
            }
            .layoutWeight(1)
            .width('100%')
          }
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.LG })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
