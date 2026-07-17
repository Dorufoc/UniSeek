import { router } from '@kit.ArkUI';
import { JobData } from '../services/ChatTypes';
import { FavoriteService } from '../services/FavoriteService';
import { JobCard } from './tab/seeker/HomePage';

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
      Row() {
        Image($r('app.media.left_arrow'))
          .width(20)
          .height(20)
          .fillColor('#333333')
          .onClick(() => {
            router.back()
          })
        Text('收藏')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ left: 12 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .alignItems(VerticalAlign.Center)

      if (this.jobs.length === 0) {
        Column() {
          Text('暂无收藏')
            .fontSize(16)
            .fontColor('#999999')
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
              .margin({ top: 8 })
            }
          }, (job: JobData) => job.id)
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor('#F8F8F8')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
