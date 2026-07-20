import { router } from '@kit.ArkUI';
import { ApiClient } from '../services/ApiClient';
import { JobData, TaskVO, mapTaskToJobData } from '../services/ChatTypes';
import { PageResult } from '../services/ResumeService';
import { JobCard } from './tab/seeker/HomePage';
import { AppColors, AppSpacing, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';

@Entry
@Component
struct SearchResultsPage {
  @State keyword: string = ''
  @State results: JobData[] = []
  @State isLoading: boolean = true
  @State totalCount: number = 0

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    if (params && params['keyword']) {
      this.keyword = params['keyword']
      this.loadResults()
    }
  }

  async loadResults(): Promise<void> {
    this.isLoading = true
    try {
      const result = await ApiClient.get<PageResult<TaskVO>>('/api/tasks', [
        ['keyword', this.keyword],
        ['page', '1'],
        ['pageSize', '100']
      ])
      this.totalCount = result.total
      this.results = result.records.map((task: TaskVO) => mapTaskToJobData(task))
    } catch (e) {
      console.error('搜索失败', e)
    } finally {
      this.isLoading = false
    }
  }

  build() {
    Column() {
      NavBar({
        title: '搜索结果',
        showBack: true,
        onBack: () => router.back()
      })

      if (this.isLoading) {
        LoadingProgress()
          .width(32)
          .height(32)
          .margin({ top: 100 })
          .color(AppColors.PRIMARY)
      } else if (this.results.length === 0) {
        Column() {
          Text('未找到相关职位')
            .fontSize(AppFontSize.MD)
            .fontColor(AppColors.TEXT_MUTED)
          Text('试试其他关键词')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
            .margin({ top: AppSpacing.SM })
        }
        .width('100%')
        .margin({ top: 80 })
        .alignItems(HorizontalAlign.Center)
      } else {
        Column() {
          Row() {
            Text('共 ' + this.totalCount + ' 条结果')
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.TEXT_MUTED)
              .margin({ bottom: AppSpacing.SM })
          }
          .width('100%')
          .padding({ left: AppSpacing.MD })

          List() {
            ForEach(this.results, (job: JobData) => {
              ListItem() {
                JobCard({ job: job })
              }
            }, (job: JobData) => job.id)
          }
          .width('100%')
          .layoutWeight(1)
        }
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
