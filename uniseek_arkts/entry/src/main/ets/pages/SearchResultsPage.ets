import { router } from '@kit.ArkUI';
import { ApiClient } from '../services/ApiClient';
import { JobData, TaskVO, mapTaskToJobData } from '../services/ChatTypes';
import { PageResult } from '../services/ResumeService';
import { JobCard } from './tab/seeker/HomePage';

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
      Row() {
        Text('←')
          .fontSize(20)
          .fontColor('#333333')
          .onClick(() => {
            router.back()
          })

        Text('搜索：' + this.keyword)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ left: 12 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .alignItems(VerticalAlign.Center)

      if (this.isLoading) {
        LoadingProgress()
          .width(32)
          .height(32)
          .margin({ top: 100 })
          .color('#007AFF')
      } else if (this.results.length === 0) {
        Column() {
          Text('未找到相关职位')
            .fontSize(16)
            .fontColor('#999999')
          Text('试试其他关键词')
            .fontSize(14)
            .fontColor('#BBBBBB')
            .margin({ top: 8 })
        }
        .width('100%')
        .margin({ top: 80 })
        .alignItems(HorizontalAlign.Center)
      } else {
        Column() {
          Row() {
            Text('共 ' + this.totalCount + ' 条结果')
              .fontSize(13)
              .fontColor('#999999')
              .margin({ bottom: 8 })
          }
          .width('100%')
          .padding({ left: 16 })

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
    .backgroundColor('#FFFFFF')
  }
}
