import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';
import { SearchHistoryService, SearchMode } from '../services/SearchHistoryService';

const DEFAULT_SHOW = 8;

@Entry
@Component
struct RecruiterSearchPage {
  @State searchText: string = ''
  @State searchHistory: string[] = []
  @State showAll: boolean = false
  @State isDeleting: boolean = false

  private getAbilityContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext
  }

  async onPageShow(): Promise<void> {
    await this.loadHistory()
  }

  private async loadHistory(): Promise<void> {
    this.searchHistory = await SearchHistoryService.load(this.getAbilityContext(), SearchMode.TALENT)
  }

  private displayHistory(): string[] {
    return this.showAll ? this.searchHistory : this.searchHistory.slice(0, DEFAULT_SHOW)
  }

  private async handleSearch(): Promise<void> {
    const text = this.searchText.trim()
    if (!text) {
      promptAction.showToast({ message: '请输入关键字', duration: 2000 })
      return
    }
    this.searchHistory = await SearchHistoryService.add(this.getAbilityContext(), SearchMode.TALENT, text)
    this.executeSearch()
  }

  private async triggerSearch(keyword: string): Promise<void> {
    this.searchText = keyword
    this.searchHistory = await SearchHistoryService.add(this.getAbilityContext(), SearchMode.TALENT, keyword)
    this.executeSearch()
  }

  private async deleteKeyword(keyword: string): Promise<void> {
    this.searchHistory = await SearchHistoryService.remove(this.getAbilityContext(), SearchMode.TALENT, keyword)
    if (this.searchHistory.length === 0) {
      this.isDeleting = false
      this.showAll = false
    }
  }

  private async clearAllHistory(): Promise<void> {
    await SearchHistoryService.clear(this.getAbilityContext(), SearchMode.TALENT)
    this.searchHistory = []
    this.isDeleting = false
    this.showAll = false
  }

  private executeSearch(): void {
    const text = this.searchText.trim()
    if (!text) {
      return
    }
    try {
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/TalentSearchResultsPage',
        params: { keyword: text }
      })
    } catch (e) {
      console.error('[RecruiterSearchPage] 跳转人才搜索结果页失败: ' + (e as Error).message)
    }
  }

  @Builder
  historyChip(keyword: string) {
    Row() {
      Text(keyword)
        .fontSize(AppFontSize.SM)
        .fontColor(this.isDeleting ? AppColors.TEXT_SECONDARY : AppColors.TEXT_PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)

      if (this.isDeleting) {
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(12)
            .fontColor([AppColors.DANGER])
        }
        .width(20)
        .height(20)
        .backgroundColor(AppColors.ERROR_BG)
        .margin({ left: AppSpacing.XS })
        .onClick(() => {
          this.deleteKeyword(keyword)
        })
      }
    }
    .height(36)
    .padding({
      left: AppSpacing.MD,
      right: this.isDeleting ? AppSpacing.SM : AppSpacing.MD
    })
    .backgroundColor(this.isDeleting ? AppColors.BG_CARD : AppColors.INPUT_BG)
    .borderRadius(AppRadius.PILL)
    .constraintSize({ minWidth: 60, maxWidth: 200 })
    .onClick(() => {
      if (!this.isDeleting) {
        this.triggerSearch(keyword)
      }
    })
    .gesture(
      LongPressGesture({ duration: 500 })
        .onAction(() => {
          this.deleteKeyword(keyword)
        })
    )
    .stateStyles({
      pressed: {
        .backgroundColor(AppColors.SELECTED_BG)
      }
    })
    .animation({ duration: 180 })
    .margin({ right: AppSpacing.SM, bottom: AppSpacing.SM })
  }

  @Builder
  hotChip(keyword: string) {
    Row() {
      Text(keyword)
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .height(36)
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
    .backgroundColor(AppColors.PRIMARY_ALPHA_6)
    .borderRadius(AppRadius.PILL)
    .constraintSize({ minWidth: 60, maxWidth: 200 })
    .onClick(() => {
      this.triggerSearch(keyword)
    })
    .stateStyles({
      pressed: {
        .backgroundColor(AppColors.PRIMARY_ALPHA_8)
      }
    })
    .animation({ duration: 180 })
    .margin({ right: AppSpacing.SM, bottom: AppSpacing.SM })
  }

  build() {
    Column() {
      NavBar({
        title: '人才搜索',
        showBack: true
      })

      Scroll() {
        Column() {
          // 搜索输入与搜索按钮
          Row() {
            TextInput({
              placeholder: '搜索人才姓名、技能或学校',
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

          // 搜索历史标题与编辑操作
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

          // 搜索历史内容
          if (this.searchHistory.length > 0) {
            Column() {
              Flex({
                wrap: FlexWrap.Wrap,
                direction: FlexDirection.Row,
                justifyContent: FlexAlign.Start,
                alignItems: ItemAlign.Center
              }) {
                ForEach(this.displayHistory(), (keyword: string) => {
                  this.historyChip(keyword)
                }, (keyword: string): string => keyword)
              }
              .width('100%')

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
            .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
          } else {
            Column() {
              SymbolGlyph($r('sys.symbol.clock'))
                .fontSize(42)
                .fontColor([AppColors.TEXT_MUTED])
                .margin({ bottom: AppSpacing.SM })

              Text('暂无搜索历史')
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.TEXT_MUTED)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .margin({ top: AppSpacing.XL, bottom: AppSpacing.XL })
          }

          // 热搜区域
          Column() {
            Row() {
              Text('热门搜索')
                .fontSize(AppFontSize.MD)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT_PRIMARY)

              Blank()
            }
            .width('100%')

            Flex({
              wrap: FlexWrap.Wrap,
              direction: FlexDirection.Row,
              justifyContent: FlexAlign.Start,
              alignItems: ItemAlign.Center
            }) {
              ForEach(SearchHistoryService.getTalentHotKeywords(), (keyword: string) => {
                this.hotChip(keyword)
              }, (keyword: string): string => keyword)
            }
            .width('100%')
            .margin({ top: AppSpacing.SM })
          }
          .width('100%')
          .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
          .margin({ top: AppSpacing.LG })
        }
        .width('100%')
        .padding({ bottom: AppSpacing.LG })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .align(Alignment.TopStart)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
