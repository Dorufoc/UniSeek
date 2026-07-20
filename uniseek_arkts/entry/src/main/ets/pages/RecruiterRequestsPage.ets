import { router } from '@kit.ArkUI';
import { RecruiterService } from '../services/RecruiterService';
import {
  RecruiterRequestVO,
  APPLICATION_STATUS_LABELS
} from '../services/RecruiterTypes';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';

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
          .fontSize(AppFontSize.LG)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
        Text('取消')
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_MUTED)
          .onClick(() => { this.onCancel?.() })
      }
      .width('100%')
      .padding({ bottom: AppSpacing.MD })

      Text('为 ' + (this.requestName || '') + ' 安排面试')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: AppSpacing.MD })

      TextInput({ placeholder: '面试时间（如 2026-07-20 10:00）', text: this.timeText })
        .onChange((value: string) => { this.timeText = value })
        .width('100%')
        .height(44)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .margin({ bottom: AppSpacing.SM })

      TextInput({ placeholder: '面试地点', text: this.locationText })
        .onChange((value: string) => { this.locationText = value })
        .width('100%')
        .height(44)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .margin({ bottom: AppSpacing.LG })

      Row() {
        Row().layoutWeight(1)
          Text('确定')
            .fontSize(AppFontSize.MD)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .backgroundColor(AppColors.PRIMARY)
            .borderRadius(AppRadius.FULL)
            .padding({ left: 28, right: 28, top: AppSpacing.SM, bottom: AppSpacing.SM })
            .onClick(() => {
              this.onConfirm?.(this.timeText, this.locationText)
            })
            .stateStyles({
              pressed: {
                .scale({ x: 0.97, y: 0.97 })
                .opacity(0.9)
              },
              normal: {
                .scale({ x: 1, y: 1 })
                .opacity(1)
              }
            })
            .animation({
              duration: 200
            })
        }
        .width('100%')
        .padding({ top: AppSpacing.MD })
      }
      .padding(AppSpacing.LG)
      .width('100%')
      .backgroundColor(AppColors.BG_CARD)
      .borderRadius({ topLeft: AppRadius.XL, topRight: AppRadius.XL })
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
          .fontSize(AppFontSize.LG)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
        Text('取消')
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_MUTED)
          .onClick(() => { this.onCancel?.() })
      }
      .width('100%')
      .padding({ bottom: AppSpacing.MD })

      Text('确认淘汰 ' + (this.requestName || '') + '？')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: AppSpacing.MD })

      TextInput({ placeholder: '淘汰原因（可选）', text: this.reasonText })
        .onChange((value: string) => { this.reasonText = value })
        .width('100%')
        .height(44)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .margin({ bottom: AppSpacing.LG })

      Row() {
        Text('取消')
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_SECONDARY)
          .backgroundColor(AppColors.INPUT_BG)
          .borderRadius(AppRadius.FULL)
          .padding({ left: 28, right: 28, top: AppSpacing.SM, bottom: AppSpacing.SM })
          .onClick(() => { this.onCancel?.() })
          .stateStyles({
            pressed: {
              .scale({ x: 0.97, y: 0.97 })
              .opacity(0.9)
            },
            normal: {
              .scale({ x: 1, y: 1 })
              .opacity(1)
            }
          })
          .animation({
            duration: 200
          })
        Blank().width(16)
        Text('确认淘汰')
          .fontSize(AppFontSize.MD)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor(AppColors.DANGER)
          .borderRadius(AppRadius.FULL)
          .padding({ left: 28, right: 28, top: AppSpacing.SM, bottom: AppSpacing.SM })
          .onClick(() => {
            this.onConfirm?.(this.reasonText)
          })
          .stateStyles({
            pressed: {
              .scale({ x: 0.97, y: 0.97 })
              .opacity(0.9)
            },
            normal: {
              .scale({ x: 1, y: 1 })
              .opacity(1)
            }
          })
          .animation({
            duration: 200
          })
      }
      .width('100%')
      .padding({ top: AppSpacing.MD })
      .justifyContent(FlexAlign.Center)
    }
    .padding(AppSpacing.LG)
    .width('100%')
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius({ topLeft: AppRadius.XL, topRight: AppRadius.XL })
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
      0: AppColors.WARNING,
      1: AppColors.PRIMARY,
      2: AppColors.TEXT_MUTED,
      3: AppColors.SUCCESS,
      4: AppColors.DANGER,
      5: AppColors.TEXT_MUTED
    }
    return map[this.request.status] || AppColors.TEXT_MUTED
  }

  build() {
    Column() {
      Row() {
        Column()
          .width(44).height(44)
          .backgroundColor(AppColors.INPUT_BG)
          .borderRadius(22)

        Column() {
          Row() {
            Text(this.request.applicantName)
              .fontSize(AppFontSize.MD)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT_PRIMARY)

            Text(this.request.applicantAge + '岁')
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.TEXT_SECONDARY)
              .margin({ left: AppSpacing.SM })
          }
          .alignItems(VerticalAlign.Center)

          Text(this.request.applicantSchool + ' · ' + this.request.applicantMajor)
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.TEXT_SECONDARY)
            .margin({ top: 2 })

          Row() {
            Text(this.request.applicantEducation)
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.TEXT_MUTED)
              .backgroundColor(AppColors.INPUT_BG)
              .borderRadius(AppRadius.SM)
              .padding({ left: AppSpacing.XS, right: AppSpacing.XS, top: 2, bottom: 2 })
            Text(this.request.applicantExperience)
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.TEXT_MUTED)
              .backgroundColor(AppColors.INPUT_BG)
              .borderRadius(AppRadius.SM)
              .padding({ left: AppSpacing.XS, right: AppSpacing.XS, top: 2, bottom: 2 })
              .margin({ left: AppSpacing.XS })
          }
          .margin({ top: AppSpacing.XS })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: AppSpacing.SM })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Text(this.request.applicantSkills)
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_MUTED)
        .lineHeight(18)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ top: AppSpacing.SM })

      Row() {
        Text('期望薪资 ' + this.request.applicantSalary)
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.WARNING)
          .fontWeight(FontWeight.Medium)

        Blank()

        Text(APPLICATION_STATUS_LABELS[this.request.status])
          .fontSize(AppFontSize.XS)
          .fontColor(this.statusColor())
      }
      .width('100%')
      .margin({ top: AppSpacing.XS })

      Row() {
        Text('投递职位：' + this.request.jobTitle)
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.TEXT_MUTED)
        Blank()
        Text(this.request.createTime)
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.TEXT_MUTED)
      }
      .width('100%')
      .margin({ top: 2 })

      if (this.request.status === 1 && this.request.interviewTime) {
        Row() {
          Text('面试安排：' + this.request.interviewTime + ' ' + this.request.interviewLocation)
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .margin({ top: AppSpacing.XS })
      }

      if (this.request.status === 4 && this.request.rejectReason) {
        Row() {
          Text('淘汰原因：' + this.request.rejectReason)
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.DANGER)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .margin({ top: AppSpacing.XS })
      }

      if (this.request.status === 0) {
        Row() {
          Button({ type: ButtonType.Capsule }) {
            Text('面试')
              .fontSize(AppFontSize.XS)
              .fontColor('#FFFFFF')
          }
            .height(32)
            .backgroundColor(AppColors.PRIMARY)
            .stateStyles({
              pressed: {
                .scale({ x: 0.97, y: 0.97 })
                .opacity(0.9)
                .backgroundColor(AppColors.PRIMARY_HOVER)
              },
              normal: {
                .scale({ x: 1, y: 1 })
                .opacity(1)
                .backgroundColor(AppColors.PRIMARY)
              }
            })
            .animation({
              duration: 200
            })

          Blank().width(AppSpacing.SM)

          Button({ type: ButtonType.Capsule }) {
            Text('不合适')
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.DANGER)
          }
            .height(32)
            .backgroundColor(AppColors.BG_CARD)
            .border({ width: 1, color: AppColors.DANGER })
            .onClick(() => {
              this.onReject?.(this.request)
            })
            .stateStyles({
              pressed: {
                .scale({ x: 0.97, y: 0.97 })
                .opacity(0.9)
              },
              normal: {
                .scale({ x: 1, y: 1 })
                .opacity(1)
              }
            })
            .animation({
              duration: 200
            })
        }
        .width('100%')
        .margin({ top: AppSpacing.SM })
        .justifyContent(FlexAlign.End)
      }
    }
    .width('100%')
    .padding(AppSpacing.SM)
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius(AppRadius.LG)
    .margin({ top: AppSpacing.SM })
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
      NavBar({
        title: '请求处理',
        showBack: true,
        onBack: () => router.back()
      })

      Scroll() {
        Row() {
          this.filterTab('全部', -1)
          this.filterTab('待处理', 0)
          this.filterTab('待面试', 1)
          this.filterTab('已录用', 3)
          this.filterTab('已淘汰', 4)
        }
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .backgroundColor(AppColors.BG_CARD)
      .padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })

      if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.filteredList.length === 0) {
        Column() {
          Text('暂无请求')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
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
              .transition(TransitionEffect.asymmetric(
                TransitionEffect.opacity(0).combine(TransitionEffect.translate({ y: 20 })),
                TransitionEffect.opacity(1)
              ))
            })
          }
          .padding(AppSpacing.MD)
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  @Builder
  filterTab(label: string, status: number): void {
    Text(label)
      .fontSize(AppFontSize.SM)
      .fontColor(this.filterStatus === status ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
      .backgroundColor(this.filterStatus === status ? AppColors.PRIMARY : AppColors.INPUT_BG)
      .borderRadius(AppRadius.XL)
      .padding({ left: AppSpacing.LG, right: AppSpacing.LG, top: AppSpacing.XS, bottom: AppSpacing.XS })
      .margin({ right: AppSpacing.SM })
      .onClick(() => {
        this.filterStatus = status
      })
      .animation({
        duration: 200
      })
  }
}
