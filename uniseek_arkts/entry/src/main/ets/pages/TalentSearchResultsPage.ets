import { AppColors, AppFontSize, AppRadius, AppSpacing } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';
import { EmptyView } from '../components/EmptyView';
import { ErrorView } from '../components/ErrorView';
import { LoadMoreFooter } from '../components/LoadMoreFooter';
import { ResumeService, ResumeData } from '../services/ResumeService';

const PAGE_SIZE = 20;

@Entry
@Component
struct TalentSearchResultsPage {
  @State keyword: string = ''
  @State results: ResumeData[] = []
  @State recommended: ResumeData[] = []
  @State isLoading: boolean = true
  @State isLoadingMore: boolean = false
  @State isLoadingRecommended: boolean = false
  @State currentPage: number = 1
  @State totalPages: number = 0
  @State totalCount: number = 0
  @State errorText: string = ''

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>
    if (params && params['keyword']) {
      this.keyword = params['keyword']
    }
    void this.loadResults(true)
  }

  private hasNextPage(): boolean {
    return this.currentPage < this.totalPages
  }

  private async loadResults(reset: boolean): Promise<void> {
    if (reset) {
      this.isLoading = true
      this.currentPage = 1
      this.errorText = ''
      this.recommended = []
    } else {
      this.isLoadingMore = true
    }

    const targetPage: number = reset ? 1 : this.currentPage + 1
    try {
      const result = await ResumeService.searchPublishedResumes(
        this.keyword.trim() || undefined,
        targetPage,
        PAGE_SIZE
      )
      const nextRecords: ResumeData[] = result.records
      this.results = reset ? nextRecords : this.results.concat(nextRecords)
      this.totalCount = result.total
      this.currentPage = result.page
      this.totalPages = result.totalPages

      if (reset && this.results.length === 0) {
        void this.loadRecommended()
      }
    } catch {
      if (reset) {
        this.results = []
        this.totalCount = 0
        this.totalPages = 0
        this.errorText = '人才搜索失败，请检查网络后重试'
      }
    }
    this.isLoading = false
    this.isLoadingMore = false
  }

  private async loadRecommended(): Promise<void> {
    if (this.recommended.length > 0 || this.isLoadingRecommended) {
      return
    }
    this.isLoadingRecommended = true
    try {
      const result = await ResumeService.searchPublishedResumes(undefined, 1, 10)
      this.recommended = result.records
    } catch {
      this.recommended = []
    }
    this.isLoadingRecommended = false
  }

  private handleSearch(): void {
    const text = this.keyword.trim()
    if (!text) {
      return
    }
    void this.loadResults(true)
  }

  private buildResumeCardParams(resume: ResumeData): string {
    return JSON.stringify({
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
      attachmentUrl: resume.attachmentUrl || '',
      graduationDate: '',
      gender: resume.gender ?? -1,
      birthDate: resume.birthDate || '',
      applicationId: 0,
      applicationStatus: -1,
      jobTitle: '',
      createTime: ''
    })
  }

  private openResumeDetail(resume: ResumeData): void {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/ResumeDetailPage',
      params: {
        resumeData: this.buildResumeCardParams(resume)
      }
    })
  }

  @Builder
  TalentCard(resume: ResumeData) {
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
      .borderRadius(AppRadius.FULL)

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
        .fontSize(AppFontSize.MD)
        .fontColor([AppColors.TEXT_MUTED])
    }
    .width('100%')
    .padding(AppSpacing.MD)
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius(AppRadius.MD)
    .onClick(() => {
      this.openResumeDetail(resume)
    })
    .stateStyles({
      pressed: {
        .backgroundColor(AppColors.SELECTED_BG)
      }
    })
    .animation({ duration: 180 })
  }

  @Builder
  RecommendedSection() {
    Column() {
      Row() {
        Text('推荐人才')
          .fontSize(AppFontSize.MD)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Blank()
      }
      .width('100%')
      .margin({ bottom: AppSpacing.SM })

      if (this.isLoadingRecommended) {
        Row() {
          LoadingProgress()
            .width(AppSpacing.ICON_SM)
            .height(AppSpacing.ICON_SM)
            .color(AppColors.PRIMARY)
          Text('正在加载推荐人才')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
            .margin({ left: AppSpacing.SM })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: AppSpacing.XL, bottom: AppSpacing.XL })
      } else if (this.recommended.length === 0) {
        Text('暂无推荐人才')
          .fontSize(AppFontSize.SM)
          .fontColor(AppColors.TEXT_MUTED)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: AppSpacing.LG, bottom: AppSpacing.LG })
      } else {
        Column({ space: AppSpacing.SM }) {
          ForEach(this.recommended, (resume: ResumeData) => {
            this.TalentCard(resume)
          }, (resume: ResumeData): string => String(resume.userId))
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.LG })
  }

  build() {
    Column() {
      NavBar({
        title: '人才搜索结果',
        showBack: true
      })

      // 顶部搜索栏
      Row({ space: AppSpacing.SM }) {
        TextInput({
          text: this.keyword,
          placeholder: '搜索人才姓名、技能或学校'
        })
          .layoutWeight(1)
          .height(AppSpacing.BUTTON_HEIGHT)
          .backgroundColor(AppColors.INPUT_BG)
          .borderRadius(AppRadius.FULL)
          .padding({ left: AppSpacing.MD })
          .fontSize(AppFontSize.SM)
          .onChange((value: string): void => { this.keyword = value })
          .onSubmit((): void => { this.handleSearch() })
      }
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.SM })

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(AppSpacing.ICON_MD)
            .height(AppSpacing.ICON_MD)
            .color(AppColors.PRIMARY)
          Text('正在搜索人才')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
            .margin({ top: AppSpacing.SM })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.errorText) {
        Column() {
          ErrorView({
            message: this.errorText,
            retryText: '重新搜索',
            onRetry: () => { void this.loadResults(true) }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding(AppSpacing.MD)
      } else if (this.results.length === 0) {
        Scroll() {
          Column() {
            EmptyView({
              message: '搜索不到结果',
              icon: $r('sys.symbol.magnifyingglass')
            })

            this.RecommendedSection()
          }
          .width('100%')
          .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.XL })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollable(ScrollDirection.Vertical)
        .align(Alignment.TopStart)
      } else {
        List({ space: AppSpacing.SM }) {
          ListItem() {
            Row() {
              Text('共 ' + this.totalCount + ' 位人才')
                .fontSize(AppFontSize.XS)
                .fontColor(AppColors.TEXT_MUTED)
              Blank()
            }
            .width('100%')
          }

          ForEach(this.results, (resume: ResumeData) => {
            ListItem() {
              this.TalentCard(resume)
            }
          }, (resume: ResumeData): string => String(resume.userId))

          ListItem() {
            LoadMoreFooter({
              loading: this.isLoadingMore,
              hasMore: this.hasNextPage(),
              finishedText: '已展示全部 ' + this.totalCount + ' 位人才'
            })
          }
        }
        .width('100%')
        .layoutWeight(1)
        .padding(AppSpacing.MD)
        .onReachEnd((): void => {
          if (this.hasNextPage() && !this.isLoadingMore) {
            void this.loadResults(false)
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
