import { JobData } from '../../../services/ChatTypes';
import { AppSpacing } from '../../../common/AppStyles';
import { JobFeedCard } from '../../../components/JobFeedCard';
import { EmptyView } from '../../../components/EmptyView';
import { ErrorView } from '../../../components/ErrorView';
import { LoadMoreFooter } from '../../../components/LoadMoreFooter';
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
    Refresh({ refreshing: this.isRefreshing, promptText: '下拉刷新...' }) {
      List({ space: AppSpacing.SM }) {
        ForEach(this.tabData[this.jobType]?.jobs || [], (job: JobData): void => {
          ListItem() {
            JobFeedCard({ job: job })
          }
        }, (job: JobData): string => job.id)

        if (this.tabData[this.jobType]?.loading && (this.tabData[this.jobType]?.jobs || []).length === 0) {
          // 首次加载占位，已在下拉刷新控件中展示，避免空白
          ListItem() {
            Column().width('100%').height(1)
          }
        } else if (this.tabData[this.jobType]?.errorText) {
          ListItem() {
            ErrorView({
              message: this.tabData[this.jobType]?.errorText ?? '',
              onRetry: () => { this.onRefresh(this.jobType) }
            })
          }
        } else if ((this.tabData[this.jobType]?.jobs || []).length === 0) {
          ListItem() {
            EmptyView({
              message: '暂无职位',
              icon: $r('sys.symbol.magnifyingglass')
            })
          }
        }

        if ((this.tabData[this.jobType]?.jobs || []).length > 0) {
          ListItem() {
            LoadMoreFooter({
              loading: this.tabData[this.jobType]?.loading && (this.tabData[this.jobType]?.jobs || []).length > 0,
              hasMore: this.tabData[this.jobType]?.hasMore ?? true
            })
          }
        }
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM })
      .onReachEnd(() => { this.loadMore(this.jobType) })
    }
    .onRefreshing(() => {
      this.onRefresh(this.jobType)
    })
  }
}
