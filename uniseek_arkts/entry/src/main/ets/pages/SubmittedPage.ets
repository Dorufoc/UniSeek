import { router } from '@kit.ArkUI';
import { JobData } from '../services/ChatTypes';
import { RecordService } from '../services/RecordService';
import { JobCard } from './tab/seeker/HomePage';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';

@Entry
@Component
struct SubmittedPage {
  @State activeTab: number = 0
  @State viewedJobs: JobData[] = []
  @State chattedJobs: JobData[] = []

  aboutToAppear(): void {
    this.viewedJobs = RecordService.getViewedJobs()
    this.chattedJobs = RecordService.getChattedJobs()
  }

  currentJobs(): JobData[] {
    if (this.activeTab === 0) {
      return this.viewedJobs
    }
    if (this.activeTab === 1) {
      return this.chattedJobs
    }
    return []
  }

  build() {
    Column() {
      NavBar({
        title: '已投递',
        showBack: true,
        onBack: () => router.back()
      })

      Row() {
        this.tabItem('看过', 0)
        this.tabItem('沟通过', 1)
        this.tabItem('面试', 2)
      }
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.SM })
      .backgroundColor(AppColors.BG_CARD)

      if (this.currentJobs().length === 0) {
        Column() {
          Text('暂无记录')
            .fontSize(AppFontSize.MD)
            .fontColor(AppColors.TEXT_MUTED)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.currentJobs(), (job: JobData) => {
            ListItem() {
              Column() {
                JobCard({ job: job })
              }
              .margin({ top: AppSpacing.SM })
            }
          }, (job: JobData) => job.id)
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor(AppColors.BG_PAGE)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  @Builder tabItem(label: string, index: number) {
    Text(label)
      .fontSize(AppFontSize.SM)
      .fontColor(this.activeTab === index ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
      .backgroundColor(this.activeTab === index ? AppColors.PRIMARY : AppColors.INPUT_BG)
      .borderRadius(AppRadius.XL)
      .padding({ left: AppSpacing.LG, right: AppSpacing.LG, top: AppSpacing.SM, bottom: AppSpacing.SM })
      .margin({ right: AppSpacing.SM })
      .onClick(() => {
        this.activeTab = index
      })
      .animation({
        duration: 200
      })
  }
}
