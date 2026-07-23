import { router, promptAction } from '@kit.ArkUI';
import { JobData } from '../services/ChatTypes';
import { FavoriteService } from '../services/FavoriteService';
import { JobCard } from './tab/seeker/HomePage';
import { AppColors, AppSpacing, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';

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
        onBack: () => router.back()
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
        Column({ space: AppSpacing.SM }) {
          Text(this.errorText)
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_SECONDARY)
          Button('重新加载', { type: ButtonType.Capsule })
            .height(40)
            .fontSize(AppFontSize.SM)
            .fontColor('#FFFFFF')
            .backgroundColor(AppColors.PRIMARY)
            .onClick((): void => { void this.loadFavorites() })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.jobs.length === 0) {
        Column({ space: AppSpacing.SM }) {
          Text('暂无收藏')
            .fontSize(AppFontSize.MD)
            .fontColor(AppColors.TEXT_MUTED)
          Button('去发现职位', { type: ButtonType.Capsule })
            .height(40)
            .fontSize(AppFontSize.SM)
            .fontColor('#FFFFFF')
            .backgroundColor(AppColors.PRIMARY)
            .onClick((): void => { router.back() })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.jobs, (job: JobData) => {
            ListItem() {
              Column() {
                JobCard({ job: job })
                Button('取消收藏', { type: ButtonType.Capsule })
                  .height(32)
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
      promptAction.showToast({ message: '已取消收藏' })
    }).catch((): void => {
      promptAction.showToast({ message: '取消收藏失败，请稍后重试' })
    })
  }
}
