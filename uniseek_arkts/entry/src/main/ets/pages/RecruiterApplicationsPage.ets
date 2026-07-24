import { RecruiterService } from '../services/RecruiterService';
import {
  RecruiterApplicationVO,
  APPLICATION_STATUS_LABELS,
  ResumeCardData
} from '../services/RecruiterTypes';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';
import { EmptyView } from '../components/EmptyView';
import { ErrorView } from '../components/ErrorView';
import { StandardCard } from '../common/StandardCard';

interface ApplicationResumeSnapshot {
  realName: string
  birthDate: string
  education: string
  school: string
  graduationDate: string
  skills: string
  experience: string
  attachmentUrl: string
}

@Entry
@Component
struct RecruiterApplicationsPage {
  @State jobTitle: string = ''
  @State applicationList: RecruiterApplicationVO[] = []
  @State filterStatus: number = -1
  @State isLoading: boolean = true
  @State errorText: string = ''
  private jobId: number = 0

  @State noJobContext: boolean = false

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>
    if (params['jobId']) {
      this.jobId = parseInt(params['jobId'])
    }
    if (params['jobTitle']) {
      this.jobTitle = params['jobTitle']
    }
    if (this.jobId > 0) {
      this.loadApplications()
    } else {
      this.noJobContext = true
      this.isLoading = false
    }
  }

  loadApplications(): void {
    this.isLoading = true
    this.errorText = ''
    RecruiterService.getJobApplications(this.jobId).then((list: RecruiterApplicationVO[]): void => {
      this.applicationList = list || []
      this.isLoading = false
    }).catch((): void => {
      this.applicationList = []
      this.errorText = '投递记录加载失败，请检查网络后重试'
      this.isLoading = false
    })
  }

  private openResume(application: RecruiterApplicationVO): void {
    const snapshot: ApplicationResumeSnapshot = this.parseResumeSnapshot(application.resumeSnapshot)
    const resume: ResumeCardData = {
      id: String(application.applicantId),
      name: application.applicantName || snapshot.realName,
      age: this.getAge(snapshot.birthDate),
      avatar: application.applicantAvatar,
      education: snapshot.education,
      school: snapshot.school,
      major: '',
      experience: snapshot.experience,
      skills: snapshot.skills,
      region: '',
      type: '',
      category: '',
      expectedSalary: '',
      description: snapshot.experience,
      attachmentUrl: application.attachmentUrl || snapshot.attachmentUrl,
      graduationDate: snapshot.graduationDate
    }
    this.getUIContext().getRouter().pushUrl({ url: 'pages/ResumeDetailPage', params: { resumeData: JSON.stringify(resume) } })
  }

  private parseResumeSnapshot(value?: string): ApplicationResumeSnapshot {
    const empty: ApplicationResumeSnapshot = {
      realName: '', birthDate: '', education: '', school: '', graduationDate: '', skills: '', experience: '', attachmentUrl: ''
    }
    if (!value) {
      return empty
    }
    try {
      const parsed = JSON.parse(value) as ApplicationResumeSnapshot
      return parsed
    } catch {
      return empty
    }
  }

  private getAge(birthDate: string): number {
    if (birthDate.length < 4) {
      return 0
    }
    const year: number = Number(birthDate.substring(0, 4))
    const currentYear: number = new Date().getFullYear()
    return year >= 1900 && year <= currentYear ? currentYear - year : 0
  }

  get filteredList(): RecruiterApplicationVO[] {
    const applicationList: RecruiterApplicationVO[] = this.applicationList
    const filterStatus: number = this.filterStatus
    if (filterStatus === -1) {
      return applicationList
    }
    const result: RecruiterApplicationVO[] = []
    for (const app of applicationList) {
      if (app.status === filterStatus) {
        result.push(app)
      }
    }
    return result
  }

  build() {
    Column() {
      NavBar({
        title: this.jobTitle || '投递管理',
        showBack: true,
        onBack: () => this.getUIContext().getRouter().back()
      })

      this.filterTabs()

      if (this.noJobContext) {
        EmptyView({ message: '请从职位列表中选择一个职位查看投递' })
          .width('100%')
          .layoutWeight(1)
      } else if (this.isLoading) {
        Column() {
          LoadingProgress().width(32).height(32).color(AppColors.PRIMARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.errorText) {
        ErrorView({
          message: this.errorText,
          retryText: '重新加载',
          onRetry: () => { this.loadApplications() }
        })
          .width('100%')
          .layoutWeight(1)
      } else if (this.filteredList.length === 0) {
        EmptyView({ message: '暂无投递记录' })
          .width('100%')
          .layoutWeight(1)
      } else {
        Scroll() {
          Column() {
            ForEach(this.filteredList, (app: RecruiterApplicationVO) => {
              ApplicationCard({ app: app, onViewResume: (item: RecruiterApplicationVO): void => { this.openResume(item) } })
              .transition(TransitionEffect.asymmetric(
                TransitionEffect.opacity(0).combine(TransitionEffect.translate({ y: 20 })),
                TransitionEffect.opacity(1)
              ))
            }, (app: RecruiterApplicationVO): string => app.id.toString())
          }
          .padding(AppSpacing.MD)
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  @Builder
  filterTabs(): void {
    Scroll() {
      Row() {
        this.filterTab('全部', -1)
        this.filterTab('已投递', 0)
        this.filterTab('待面试', 1)
        this.filterTab('已录用', 3)
        this.filterTab('已淘汰', 4)
      }
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .backgroundColor(AppColors.BG_CARD)
    .padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })
  }

  @Builder
  filterTab(label: string, status: number): void {
    Button(label, { type: ButtonType.Capsule })
      .height(AppSpacing.BUTTON_HEIGHT_MINI)
      .fontSize(AppFontSize.SM)
      .fontColor(this.filterStatus === status ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
      .backgroundColor(this.filterStatus === status ? AppColors.PRIMARY : AppColors.INPUT_BG)
      .padding({ left: AppSpacing.LG, right: AppSpacing.LG, top: AppSpacing.XS, bottom: AppSpacing.XS })
      .margin({ right: AppSpacing.SM })
      .onClick(() => {
        this.filterStatus = status
      })
      .animation({
        duration: 200
      })
  }

}

@Component
struct ApplicationCard {
  app: RecruiterApplicationVO = {
    id: 0, taskId: 0, applicantId: 0, applicantName: '',
    applicantAvatar: '', status: 0, interviewTime: '',
    interviewLocation: '', rejectReason: '', createTime: ''
  }
  onViewResume?: (app: RecruiterApplicationVO) => void

  build() {
    StandardCard({
      onClickAction: () => { this.onViewResume?.(this.app) }
    }) {
      Column() {
        Row() {
          Stack() {
            Text(this.app.applicantName ? this.app.applicantName.charAt(0) : '?')
              .fontSize(AppFontSize.MD)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.BG_CARD)
          }
          .width(AppSpacing.ICON_LG)
          .height(AppSpacing.ICON_LG)
          .borderRadius(AppRadius.PILL)
          .backgroundColor(AppColors.PRIMARY)

          Column() {
            Text(this.app.applicantName)
              .fontSize(AppFontSize.MD)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_PRIMARY)

            Text(APPLICATION_STATUS_LABELS[this.app.status])
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.PRIMARY)
              .margin({ top: 2 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: AppSpacing.SM })

          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(AppFontSize.MD)
            .fontColor([AppColors.TEXT_MUTED])
        }
        .width('100%')

        Text(this.app.createTime)
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.TEXT_MUTED)
          .width('100%')
          .margin({ top: AppSpacing.XS })
          .textAlign(TextAlign.End)
      }
      .width('100%')
    }
  }
}
