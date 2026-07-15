import { router } from '@kit.ArkUI';
import { RecruiterService } from '../services/RecruiterService';
import {
  RecruiterApplicationVO,
  APPLICATION_STATUS_LABELS
} from '../services/RecruiterTypes';

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
      this.topBar()

      this.filterTabs()

      if (this.noJobContext) {
        Column() {
          Text('请从职位列表中选择一个职位查看投递')
            .fontSize(14)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.filteredList.length === 0) {
        Column() {
          Text('暂无投递记录')
            .fontSize(14)
            .fontColor('#999999')
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
            })
          }
          .padding(16)
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  topBar(): void {
    Row() {
      Image($r('app.media.left_arrow'))
        .width(24).height(24)
        .fillColor('#333333')
        .onClick(() => { router.back() })
      Text(this.jobTitle)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text('')
        .width(24)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
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
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  filterTab(label: string, status: number): void {
    Text(label)
      .fontSize(14)
      .fontColor(this.filterStatus === status ? '#FFFFFF' : '#666666')
      .backgroundColor(this.filterStatus === status ? '#007AFF' : '#F5F5F5')
      .borderRadius(16)
      .padding({ left: 20, right: 20, top: 6, bottom: 6 })
      .margin({ right: 8 })
      .onClick(() => {
        this.filterStatus = status
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
          .backgroundColor('#E0E0E0')
          .borderRadius(20)

        Column() {
          Text(this.app.applicantName)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')

          Text(APPLICATION_STATUS_LABELS[this.app.status])
            .fontSize(12)
            .fontColor('#007AFF')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })

        Image($r('app.media.right_arrow'))
          .width(16).height(16)
          .fillColor('#CCCCCC')
      }
      .width('100%')

      Text(this.app.createTime)
        .fontSize(12)
        .fontColor('#999999')
        .width('100%')
        .margin({ top: 6 })
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ top: 8 })
  }
}
