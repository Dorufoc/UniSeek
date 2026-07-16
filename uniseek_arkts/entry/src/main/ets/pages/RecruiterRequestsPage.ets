import { router } from '@kit.ArkUI';
import { RecruiterService } from '../services/RecruiterService';
import {
  RecruiterRequestVO,
  APPLICATION_STATUS_LABELS
} from '../services/RecruiterTypes';

@CustomDialog
struct InterviewDialog {
  controller?: CustomDialogController
  requestName?: string
  onConfirm?: (time: string, location: string) => void
  onCancel?: () => void

  @State timeText: string = ''
  @State locationText: string = ''

  build() {
    Column() {
      Row() {
        Text('安排面试')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
        Text('取消')
          .fontSize(15)
          .fontColor('#999999')
          .onClick(() => { this.onCancel?.() })
      }
      .width('100%')
      .padding({ bottom: 16 })

      Text('为 ' + (this.requestName || '') + ' 安排面试')
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')
        .margin({ bottom: 16 })

      TextInput({ placeholder: '面试时间（如 2026-07-20 10:00）', text: this.timeText })
        .onChange((value: string) => { this.timeText = value })
        .width('100%')
        .height(44)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .margin({ bottom: 12 })

      TextInput({ placeholder: '面试地点', text: this.locationText })
        .onChange((value: string) => { this.locationText = value })
        .width('100%')
        .height(44)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .margin({ bottom: 20 })

      Row() {
        Row().layoutWeight(1)
        Text('确定')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .borderRadius(20)
          .padding({ left: 28, right: 28, top: 10, bottom: 10 })
          .onClick(() => {
            this.onConfirm?.(this.timeText, this.locationText)
          })
      }
      .width('100%')
      .padding({ top: 16 })
    }
    .padding(20)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}

@CustomDialog
struct RejectDialog {
  controller?: CustomDialogController
  requestName?: string
  onConfirm?: (reason: string) => void
  onCancel?: () => void

  @State reasonText: string = ''

  build() {
    Column() {
      Row() {
        Text('淘汰候选人')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
        Text('取消')
          .fontSize(15)
          .fontColor('#999999')
          .onClick(() => { this.onCancel?.() })
      }
      .width('100%')
      .padding({ bottom: 16 })

      Text('确认淘汰 ' + (this.requestName || '') + '？')
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')
        .margin({ bottom: 16 })

      TextInput({ placeholder: '淘汰原因（可选）', text: this.reasonText })
        .onChange((value: string) => { this.reasonText = value })
        .width('100%')
        .height(44)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .margin({ bottom: 20 })

      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .padding({ left: 28, right: 28, top: 10, bottom: 10 })
          .onClick(() => { this.onCancel?.() })
        Blank().width(16)
        Text('确认淘汰')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#FF4444')
          .borderRadius(20)
          .padding({ left: 28, right: 28, top: 10, bottom: 10 })
          .onClick(() => {
            this.onConfirm?.(this.reasonText)
          })
      }
      .width('100%')
      .padding({ top: 16 })
      .justifyContent(FlexAlign.Center)
    }
    .padding(20)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}

@Component
struct RequestCard {
  request: RecruiterRequestVO = {
    id: 0, applicantId: 0, applicantName: '', applicantAvatar: '',
    applicantAge: 0, applicantSchool: '', applicantMajor: '',
    applicantEducation: '', applicantExperience: '', applicantSkills: '',
    applicantRegion: '', applicantType: '', applicantSalary: '',
    jobTitle: '', status: 0, interviewTime: '',
    interviewLocation: '', rejectReason: '', createTime: ''
  }
  onInterview?: (req: RecruiterRequestVO) => void
  onReject?: (req: RecruiterRequestVO) => void

  statusColor(): string {
    const map: Record<number, string> = {
      0: '#FF9500',
      1: '#007AFF',
      2: '#8E8E93',
      3: '#34C759',
      4: '#FF4444',
      5: '#8E8E93'
    }
    return map[this.request.status] || '#8E8E93'
  }

  build() {
    Column() {
      Row() {
        Column()
          .width(44).height(44)
          .backgroundColor('#E0E0E0')
          .borderRadius(22)

        Column() {
          Row() {
            Text(this.request.applicantName)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A1A')

            Text(this.request.applicantAge + '岁')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ left: 8 })
          }
          .alignItems(VerticalAlign.Center)

          Text(this.request.applicantSchool + ' · ' + this.request.applicantMajor)
            .fontSize(13)
            .fontColor('#666666')
            .margin({ top: 2 })

          Row() {
            Text(this.request.applicantEducation)
              .fontSize(11)
              .fontColor('#999999')
              .backgroundColor('#F5F5F5')
              .borderRadius(4)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            Text(this.request.applicantExperience)
              .fontSize(11)
              .fontColor('#999999')
              .backgroundColor('#F5F5F5')
              .borderRadius(4)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .margin({ left: 6 })
          }
          .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 12 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Text(this.request.applicantSkills)
        .fontSize(12)
        .fontColor('#999999')
        .lineHeight(18)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ top: 8 })

      Row() {
        Text('期望薪资 ' + this.request.applicantSalary)
          .fontSize(12)
          .fontColor('#FF6B35')
          .fontWeight(FontWeight.Medium)

        Blank()

        Text(APPLICATION_STATUS_LABELS[this.request.status])
          .fontSize(12)
          .fontColor(this.statusColor())
      }
      .width('100%')
      .margin({ top: 4 })

      Row() {
        Text('投递职位：' + this.request.jobTitle)
          .fontSize(12)
          .fontColor('#999999')
        Blank()
        Text(this.request.createTime)
          .fontSize(11)
          .fontColor('#BBBBBB')
      }
      .width('100%')
      .margin({ top: 2 })

      if (this.request.status === 1 && this.request.interviewTime) {
        Row() {
          Text('面试安排：' + this.request.interviewTime + ' ' + this.request.interviewLocation)
            .fontSize(12)
            .fontColor('#007AFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .margin({ top: 4 })
      }

      if (this.request.status === 4 && this.request.rejectReason) {
        Row() {
          Text('淘汰原因：' + this.request.rejectReason)
            .fontSize(12)
            .fontColor('#FF4444')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .margin({ top: 4 })
      }

      if (this.request.status === 0) {
        Row() {
          Button('面试')
            .height(32)
            .backgroundColor('#007AFF')
            .borderRadius(16)
            .fontColor('#FFFFFF')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              this.onInterview?.(this.request)
            })

          Blank().width(12)

          Button('不合适')
            .height(32)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .fontColor('#FF4444')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .border({ width: 1, color: '#FF4444' })
            .onClick(() => {
              this.onReject?.(this.request)
            })
        }
        .width('100%')
        .margin({ top: 10 })
        .justifyContent(FlexAlign.End)
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ top: 10 })
  }
}

@Entry
@Component
struct RecruiterRequestsPage {
  @State requestList: RecruiterRequestVO[] = []
  @State isLoading: boolean = true
  @State filterStatus: number = -1

  aboutToAppear(): void {
    this.loadRequests()
  }

  loadRequests(): void {
    this.isLoading = true
    RecruiterService.getIncomingRequests().then((list: RecruiterRequestVO[]) => {
      this.requestList = list
      this.isLoading = false
    })
  }

  get filteredList(): RecruiterRequestVO[] {
    if (this.filterStatus === -1) {
      return this.requestList
    }
    const result: RecruiterRequestVO[] = []
    for (const req of this.requestList) {
      if (req.status === this.filterStatus) {
        result.push(req)
      }
    }
    return result
  }

  handleInterview(req: RecruiterRequestVO): void {
    let dialog = new CustomDialogController({
      builder: InterviewDialog({
        requestName: req.applicantName,
        onConfirm: (time: string, location: string) => {
          dialog.close()
          RecruiterService.processRequest(req.id, {
            status: 1,
            interviewTime: time,
            interviewLocation: location,
            rejectReason: '',
            hrNote: ''
          }).then(() => {
            req.status = 1
            req.interviewTime = time
            req.interviewLocation = location
            this.requestList = [...this.requestList]
          })
        },
        onCancel: () => {
          dialog.close()
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Bottom
    })
    dialog.open()
  }

  handleReject(req: RecruiterRequestVO): void {
    let dialog = new CustomDialogController({
      builder: RejectDialog({
        requestName: req.applicantName,
        onConfirm: (reason: string) => {
          dialog.close()
          RecruiterService.processRequest(req.id, {
            status: 4,
            interviewTime: '',
            interviewLocation: '',
            rejectReason: reason,
            hrNote: ''
          }).then(() => {
            req.status = 4
            req.rejectReason = reason
            this.requestList = [...this.requestList]
          })
        },
        onCancel: () => {
          dialog.close()
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Bottom
    })
    dialog.open()
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.left_arrow'))
          .width(24).height(24)
          .fillColor('#333333')
          .onClick(() => { router.back() })
        Text('请求处理')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('')
          .width(24)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFF')

      Scroll() {
        Row() {
          this.filterTab('全部', -1)
          this.filterTab('待处理', 0)
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

      if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.filteredList.length === 0) {
        Column() {
          Text('暂无请求')
            .fontSize(14)
            .fontColor('#999999')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column() {
            ForEach(this.filteredList, (req: RecruiterRequestVO) => {
              RequestCard({
                request: req,
                onInterview: (r: RecruiterRequestVO) => { this.handleInterview(r) },
                onReject: (r: RecruiterRequestVO) => { this.handleReject(r) }
              })
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
