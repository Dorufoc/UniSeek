import { JobData } from '../../../services/ChatTypes';
import { AppColors, AppSpacing } from '../../../common/AppStyles';
import { JobFeedCard } from './JobFeedCard';
import { TabDataState } from './JobFeedTypes'

@Component
export struct JobFeedList {
  jobType: number = 1
  @Prop @Watch('onTabDataChanged') tabData: Record<number, TabDataState> = {}
  loadMore: (jobType: number) => void = () => {}
  onRefresh: (jobType: number) => void = () => {}
  @State isRefreshing: boolean = false

  /**
   * 监听 tabData 变化，当下拉刷新加载完成时关闭刷新指示器
   */
  onTabDataChanged(): void {
    const state = this.tabData[this.jobType]
    if (this.isRefreshing && state && !state.loading) {
      this.isRefreshing = false
    }
  }

  build() {
    Refresh({ refreshing: $$this.isRefreshing, promptText: '下拉刷新...' }) {
      List() {
        // 职位卡片列表
        ForEach(this.tabData[this.jobType]?.jobs || [], (job: JobData): void => {
          ListItem() {
            JobFeedCard({ job: job })
          }
        }, (job: JobData): string => job.id)

        // 加载中状态
        if (this.tabData[this.jobType]?.loading) {
          ListItem() {
            Row() {
              LoadingProgress()
                .width(24).height(24)
              Text('加载中...')
                .fontSize(14)
                .fontColor(AppColors.TEXT_MUTED)
                .margin({ left: AppSpacing.SM })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding(AppSpacing.MD)
          }
        } else if (this.tabData[this.jobType]?.errorText) {
          ListItem() {
            Column({ space: AppSpacing.SM }) {
              Text(this.tabData[this.jobType]?.errorText || '职位列表加载失败')
                .fontSize(14)
                .fontColor(AppColors.TEXT_SECONDARY)
              Button('重新加载', { type: ButtonType.Capsule })
                .height(36)
                .fontSize(14)
                .fontColor('#FFFFFF')
                .backgroundColor(AppColors.PRIMARY)
                .onClick((): void => { this.onRefresh(this.jobType) })
            }
            .width('100%')
            .padding(AppSpacing.LG)
            .alignItems(HorizontalAlign.Center)
          }
        } else if ((this.tabData[this.jobType]?.jobs.length ?? 0) === 0) {
          // 空状态
          ListItem() {
            Text('暂无职位')
              .fontSize(14)
              .fontColor(AppColors.TEXT_MUTED)
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(AppSpacing.LG)
          }
        } else if (!this.tabData[this.jobType]?.hasMore && (this.tabData[this.jobType]?.jobs.length ?? 0) > 0) {
          // 全部加载完提示
          ListItem() {
            Text('已全部展示')
              .fontSize(14)
              .fontColor(AppColors.TEXT_MUTED)
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(AppSpacing.MD)
          }
        }
      }
      .layoutWeight(1)
      .width('100%')
      .margin({ top: 4 })
      .onReachEnd(() => { this.loadMore(this.jobType) })
    }
    .onRefreshing(() => {
      this.onRefresh(this.jobType)
    })
  }
}
