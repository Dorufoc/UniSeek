import { router } from '@kit.ArkUI';
import { RecruiterService } from '../services/RecruiterService';
import {
  RecruiterApplicationVO,
  APPLICATION_STATUS_LABELS
} from '../services/RecruiterTypes';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';

@Entry
@Component
struct RecruiterApplicationsPage {
  @State jobTitle: string = ''
  @State applicationList: RecruiterApplicationVO[] = []
  @State filterStatus: number = -1
  @State isLoading: boolean = true
  private jobId: number = 0

  @State noJobContext: boolean = false

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
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
    RecruiterService.getJobApplications(this.jobId).then((list: RecruiterApplicationVO[]) => {
      this.applicationList = list
      this.isLoading = false
    })
  }

  get filteredList(): RecruiterApplicationVO[] {
    if (this.filterStatus === -1) {
      return this.applicationList
    }
    const result: RecruiterApplicationVO[] = []
    for (const app of this.applicationList) {
      if (app.status === this.filterStatus) {
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
        onBack: () => router.back()
      })

      this.filterTabs()

      if (this.noJobContext) {
        Column() {
          Text('请从职位列表中选择一个职位查看投递')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.filteredList.length === 0) {
        Column() {
          Text('暂无投递记录')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column() {
            ForEach(this.filteredList, (app: RecruiterApplicationVO) => {
              ApplicationCard({ app: app })
              .transition(TransitionEffect.asymmetric(
                TransitionEffect.opacity(0).combine(TransitionEffect.translate({ y: 20 })),
                TransitionEffect.opacity(1)
              ))
            })
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
    Text(label)
      .fontSize(AppFontSize.SM)
      .fontColor(this.filterStatus === status ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
      .backgroundColor(this.filterStatus === status ? AppColors.PRIMARY : AppColors.INPUT_BG)
      .borderRadius(AppRadius.XL)
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

  build() {
    Column() {
      Row() {
        Column()
          .width(40).height(40)
          .backgroundColor(AppColors.INPUT_BG)
          .borderRadius(20)

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
    .padding(AppSpacing.SM)
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius(AppRadius.LG)
    .margin({ top: AppSpacing.SM })
    .stateStyles({
      pressed: {
        .backgroundColor(AppColors.SELECTED_BG)
      }
    })
  }
}
