import { JobData } from '../services/ChatTypes';
import { FavoriteService } from '../services/FavoriteService';
import { JobCard } from '../components/JobCard';
import { AppColors, AppSpacing, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';
import { EmptyView } from '../components/EmptyView';
import { ErrorView } from '../components/ErrorView';

@Entry
@Component
struct FavoritesPage {
  @State jobs: JobData[] = []
  @State isLoading: boolean = true
  @State errorText: string = ''

  onPageShow(): void {
    this.loadFavorites()
  }

  async loadFavorites(): Promise<void> {
    this.isLoading = true
    this.errorText = ''
    try {
      this.jobs = await FavoriteService.getFavorites()
    } catch (e) {
      console.error('加载收藏失败', e)
      this.jobs = []
      this.errorText = '收藏列表加载失败，请检查网络后重试'
    }
    this.isLoading = false
  }

  build() {
    Column() {
      NavBar({
        title: '我的收藏',
        showBack: true,
        onBack: () => this.getUIContext().getRouter().back()
      })

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(32)
            .height(32)
            .color(AppColors.PRIMARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      else if (this.errorText) {
        Column() {
          ErrorView({
            message: this.errorText,
            retryText: '重新加载',
            onRetry: () => { void this.loadFavorites() }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding(AppSpacing.MD)
      } else if (this.jobs.length === 0) {
        Column() {
          EmptyView({
            message: '暂无收藏职位',
            actionText: '去发现职位',
            onAction: () => { this.getUIContext().getRouter().back() }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding(AppSpacing.MD)
      } else {
        List({ space: AppSpacing.SM }) {
          ForEach(this.jobs, (job: JobData) => {
            ListItem() {
              Column() {
                JobCard({ job: job })
                Button('取消收藏', { type: ButtonType.Capsule })
                  .height(AppSpacing.BUTTON_HEIGHT_MINI)
                  .fontSize(AppFontSize.XS)
                  .fontColor(AppColors.DANGER)
                  .backgroundColor(AppColors.ERROR_BG)
                  .margin({ top: AppSpacing.XS, right: AppSpacing.MD })
                  .alignSelf(ItemAlign.End)
                  .onClick((): void => { this.removeFavorite(job) })
              }
              .margin({ top: AppSpacing.SM })
            }
          }, (job: JobData) => job.id)
        }
        .layoutWeight(1)
        .width('100%')
        .padding(AppSpacing.MD)
        .backgroundColor(AppColors.BG_PAGE)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  private removeFavorite(job: JobData): void {
    const taskId: number = Number(job.id)
    if (taskId <= 0) {
      return
    }
    FavoriteService.removeFavorite(taskId).then((): void => {
      this.jobs = this.jobs.filter((item: JobData): boolean => item.id !== job.id)
      this.getUIContext().getPromptAction().showToast({ message: '已取消收藏' })
    }).catch((): void => {
      this.getUIContext().getPromptAction().showToast({ message: '取消收藏失败，请稍后重试' })
    })
  }
}

