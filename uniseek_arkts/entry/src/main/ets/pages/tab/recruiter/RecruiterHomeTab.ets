import { router } from '@kit.ArkUI'
import { AppColors, AppFontSize, AppRadius, AppShadow, AppSpacing } from '../../../common/AppStyles'
import { PageLoadPolicy, TalentFilterPolicy } from '../../../common/BusinessPolicies'
import { ResumeCardData } from '../../../services/RecruiterTypes'
import { ResumeData, ResumeService } from '../../../services/ResumeService'

const TALENT_FILTERS: string[] = ['全部', '有附件简历', '在校生', '有工作经验']

@Component
export struct RecruiterHomeTab {
  @State resumes: ResumeCardData[] = []
  @State selectedFilter: string = '全部'
  @State isLoading: boolean = true
  @State isLoadingMore: boolean = false
  @State errorText: string = ''
  @State currentPage: number = 1
  @State totalPages: number = 0

  @Builder
  resumeCard(resume: ResumeCardData) {
    Row({ space: AppSpacing.SM }) {
      Column() {
        Text(resume.name || '匿名候选人')
          .fontSize(AppFontSize.MD)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(resume.school || resume.education || '暂未填写教育经历')
          .fontSize(AppFontSize.SM)
          .fontColor(AppColors.TEXT_SECONDARY)
          .margin({ top: AppSpacing.XS })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (resume.skills) {
          Text(resume.skills)
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.TEXT_MUTED)
            .margin({ top: AppSpacing.XS })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
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
    .border({ width: 1, color: AppColors.BORDER })
    .borderRadius(AppRadius.MD)
    .shadow(AppShadow.SM)
    .onClick((): void => {
      router.pushUrl({ url: 'pages/ResumeDetailPage', params: { resumeData: JSON.stringify(resume) } })
    })
    .stateStyles({ pressed: { .backgroundColor(AppColors.SELECTED_BG).scale({ x: 0.99, y: 0.99 }) } })
  }

  aboutToAppear(): void {
    void this.loadResumes(true)
  }

  private mapResume(resume: ResumeData): ResumeCardData {
    return {
      id: String(resume.userId || resume.id),
      name: resume.realName || '',
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
      expectedSalary: '',
      description: resume.experience || '',
      attachmentUrl: resume.attachmentUrl || '',
      graduationDate: resume.graduationDate || ''
    }
  }

  private async loadResumes(reset: boolean): Promise<void> {
    if (reset) {
      this.isLoading = true
      this.errorText = ''
      this.currentPage = 1
    } else {
      this.isLoadingMore = true
    }
    const targetPage: number = reset ? 1 : this.currentPage + 1
    try {
      const result = await ResumeService.searchPublishedResumes(
        undefined, targetPage, 20, TalentFilterPolicy.normalize(this.selectedFilter))
      const nextRecords: ResumeCardData[] = result.records.map((resume: ResumeData): ResumeCardData => this.mapResume(resume))
      this.resumes = reset ? nextRecords : this.resumes.concat(nextRecords)
      this.currentPage = result.page
      this.totalPages = result.totalPages
    } catch {
      if (reset) {
        this.resumes = []
        this.totalPages = 0
        this.errorText = '人才列表加载失败，请检查网络后重试'
      }
    }
    this.isLoading = false
    this.isLoadingMore = false
  }

  private selectFilter(filter: string): void {
    if (this.selectedFilter === filter) {
      return
    }
    this.selectedFilter = filter
    void this.loadResumes(true)
  }

  build() {
    Column() {
      Row() {
        Text('人才发现')
          .fontSize(AppFontSize.LG)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
        Button({ type: ButtonType.Capsule }) {
          SymbolGlyph($r('sys.symbol.magnifyingglass')).fontSize(18).fontColor([AppColors.TEXT_SECONDARY])
        }
        .width(40)
        .height(40)
        .backgroundColor(AppColors.INPUT_BG)
        .accessibilityText('搜索人才')
        .onClick((): void => { router.pushUrl({ url: 'pages/RecruiterSearchPage' }) })
      }
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD })

      Scroll() {
        Row({ space: AppSpacing.SM }) {
          ForEach(TALENT_FILTERS, (filter: string) => {
            Button(filter, { type: ButtonType.Capsule })
              .height(32)
              .fontSize(AppFontSize.XS)
              .fontColor(this.selectedFilter === filter ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
              .backgroundColor(this.selectedFilter === filter ? AppColors.PRIMARY : AppColors.INPUT_BG)
              .onClick((): void => { this.selectFilter(filter) })
          }, (filter: string): string => filter)
        }
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })

      if (this.isLoading) {
        LoadingProgress().width(32).height(32).color(AppColors.PRIMARY).margin({ top: 96 })
      } else if (this.errorText) {
        Column({ space: AppSpacing.SM }) {
          Text(this.errorText).fontSize(AppFontSize.SM).fontColor(AppColors.TEXT_SECONDARY)
          Button('重新加载', { type: ButtonType.Capsule })
            .height(40)
            .backgroundColor(AppColors.PRIMARY)
            .fontColor('#FFFFFF')
            .onClick((): void => { void this.loadResumes(true) })
        }
        .width('100%')
        .margin({ top: 96 })
        .alignItems(HorizontalAlign.Center)
      } else if (this.resumes.length === 0) {
        Column({ space: AppSpacing.SM }) {
          Text('暂无可查看的人才').fontSize(AppFontSize.MD).fontColor(AppColors.TEXT_SECONDARY)
          Text('调整筛选条件后再试').fontSize(AppFontSize.XS).fontColor(AppColors.TEXT_MUTED)
        }
        .width('100%')
        .margin({ top: 96 })
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: AppSpacing.SM }) {
          ForEach(this.resumes, (resume: ResumeCardData) => {
            ListItem() { this.resumeCard(resume) }
          }, (resume: ResumeCardData): string => resume.id)
          if (PageLoadPolicy.hasNext(this.currentPage, this.totalPages)) {
            ListItem() {
              Button(this.isLoadingMore ? '加载中...' : '加载更多', { type: ButtonType.Capsule })
                .width('100%')
                .height(40)
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.PRIMARY)
                .backgroundColor(AppColors.SELECTED_BG)
                .enabled(!this.isLoadingMore)
                .onClick((): void => { void this.loadResumes(false) })
            }
          }
        }
        .layoutWeight(1)
        .width('100%')
        .padding(AppSpacing.MD)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
