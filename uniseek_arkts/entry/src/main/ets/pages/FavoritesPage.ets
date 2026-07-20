import { router } from '@kit.ArkUI';
import { JobData } from '../services/ChatTypes';
import { FavoriteService } from '../services/FavoriteService';
import { JobCard } from './tab/seeker/HomePage';
import { AppColors, AppSpacing, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';

@Entry
@Component
struct FavoritesPage {
  @State jobs: JobData[] = []

  onPageShow(): void {
    this.loadFavorites()
  }

  async loadFavorites(): Promise<void> {
    try {
      this.jobs = await FavoriteService.getFavorites()
    } catch (e) {
      console.error('加载收藏失败', e)
      this.jobs = []
    }
  }

  build() {
    Column() {
      NavBar({
        title: '我的收藏',
        showBack: true,
        onBack: () => router.back()
      })

      if (this.jobs.length === 0) {
        Column() {
          Text('暂无收藏')
            .fontSize(AppFontSize.MD)
            .fontColor(AppColors.TEXT_MUTED)
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
}
