import { router } from '@kit.ArkUI';
import { RecruiterService } from '../services/RecruiterService';
import {
  RecruiterRequestVO,
  APPLICATION_STATUS_LABELS
} from '../services/RecruiterTypes';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';
import { ApplicationNotePolicy } from '../common/BusinessPolicies'

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
        Button('取消', { type: ButtonType.Normal })
          .height(32)
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_MUTED)
          .backgroundColor(Color.Transparent)
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
          Button('确定', { type: ButtonType.Capsule })
            .height(40)
            .fontSize(AppFontSize.MD)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .backgroundColor(AppColors.PRIMARY)
            .padding({ left: 28, right: 28 })
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
  onConfirm?: (reason: string, note: string) => void
  onCancel?: () => void

  @State reasonText: string = ''
  @State noteText: string = ''

  build() {
    Column() {
      Row() {
        Text('淘汰候选人')
          .fontSize(AppFontSize.LG)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
        Button('取消', { type: ButtonType.Normal })
          .height(32)
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_MUTED)
          .backgroundColor(Color.Transparent)
          .onClick(() => { this.onCancel?.() })
      }
      .width('100%')
      .padding({ bottom: AppSpacing.MD })

      Text('确认淘汰 ' + (this.requestName || '') + '？')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: AppSpacing.MD })

      TextInput({ placeholder: '淘汰原因（必填）', text: this.reasonText })
        .onChange((value: string) => { this.reasonText = value })
        .width('100%')
        .height(44)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .margin({ bottom: AppSpacing.SM })

      TextArea({ placeholder: '内部备注（必填，仅招聘方可见）', text: this.noteText })
        .onChange((value: string) => { this.noteText = value })
        .width('100%')
        .height(88)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .padding(AppSpacing.SM)
        .margin({ bottom: AppSpacing.LG })

      Row() {
        Button('取消', { type: ButtonType.Capsule })
          .height(40)
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_SECONDARY)
          .backgroundColor(AppColors.INPUT_BG)
          .padding({ left: 28, right: 28 })
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
        Button('确认淘汰', { type: ButtonType.Capsule })
          .height(40)
          .fontSize(AppFontSize.MD)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor(AppColors.DANGER)
          .padding({ left: 28, right: 28 })
          .onClick(() => {
            this.onConfirm?.(this.reasonText, this.noteText)
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

@CustomDialog
struct CompleteDialog {
  controller?: CustomDialogController
  requestName?: string
  onConfirm?: (note: string) => void
  onCancel?: () => void

  @State noteText: string = ''

  build() {
    Column() {
      Row() {
        Text('完成结算')
          .fontSize(AppFontSize.LG)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
        Button('取消', { type: ButtonType.Normal })
          .height(32)
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_MUTED)
          .backgroundColor(Color.Transparent)
          .onClick((): void => { this.onCancel?.() })
      }
      .width('100%')
      .padding({ bottom: AppSpacing.MD })

      Text('为 ' + (this.requestName || '') + ' 记录结算说明')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: AppSpacing.MD })

      TextArea({ placeholder: '结算备注（必填）', text: this.noteText })
        .onChange((value: string): void => { this.noteText = value })
        .width('100%')
        .height(96)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .padding(AppSpacing.SM)

      Button('确认完成', { type: ButtonType.Capsule })
        .width('100%')
        .height(40)
        .fontSize(AppFontSize.MD)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .backgroundColor(AppColors.SUCCESS)
        .margin({ top: AppSpacing.LG })
        .onClick((): void => { this.onConfirm?.(this.noteText) })
        .stateStyles({ pressed: { .opacity(0.85).scale({ x: 0.98, y: 0.98 }) } })
        .animation({ duration: 180 })
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
    interviewLocation: '', rejectReason: '', createTime: '', attachmentUrl: ''
  }
  onInterview?: (req: RecruiterRequestVO) => void
  onReject?: (req: RecruiterRequestVO) => void
  onSimpleStatus?: (req: RecruiterRequestVO, status: number) => void
  onComplete?: (req: RecruiterRequestVO) => void
  onViewResume?: (req: RecruiterRequestVO) => void

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

            if (this.request.applicantAge > 0) {
              Text(this.request.applicantAge + '岁')
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.TEXT_SECONDARY)
                .margin({ left: AppSpacing.SM })
            }
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
      .onClick(() => {
        this.onViewResume?.(this.request)
      })

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
            .onClick(() => {
              this.onInterview?.(this.request)
            })
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

          this.statusAction('待定', AppColors.WARNING, () => {
            this.onSimpleStatus?.(this.request, 2)
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
      if (this.request.status === 1 || this.request.status === 2) {
        Row() {
          if (this.request.status === 2) {
            this.statusAction('安排面试', AppColors.PRIMARY, () => {
              this.onInterview?.(this.request)
            })
          }
          this.statusAction('录用', AppColors.SUCCESS, () => {
            this.onSimpleStatus?.(this.request, 3)
          })
          if (this.request.status === 1) {
            this.statusAction('待定', AppColors.WARNING, () => {
              this.onSimpleStatus?.(this.request, 2)
            })
          }
          this.statusAction('不合适', AppColors.DANGER, () => {
            this.onReject?.(this.request)
          })
        }
        .width('100%')
        .margin({ top: AppSpacing.SM })
        .justifyContent(FlexAlign.End)
      }
      if (this.request.status === 3) {
        Row() {
          this.statusAction('完成结算', AppColors.SUCCESS, () => {
            this.onComplete?.(this.request)
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

  @Builder
  statusAction(label: string, color: string, onClick: () => void): void {
    Button({ type: ButtonType.Capsule }) {
      Text(label)
        .fontSize(AppFontSize.XS)
        .fontColor(color === AppColors.PRIMARY || color === AppColors.SUCCESS ? '#FFFFFF' : color)
    }
      .height(32)
      .backgroundColor(color === AppColors.PRIMARY || color === AppColors.SUCCESS ? color : AppColors.BG_CARD)
      .border({ width: 1, color: color })
      .margin({ left: AppSpacing.XS })
      .onClick(onClick)
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
      .animation({ duration: 180 })
  }
}

@Entry
@Component
struct RecruiterRequestsPage {
  @State requestList: RecruiterRequestVO[] = []
  @State isLoading: boolean = true
  @State errorText: string = ''
  @State filterStatus: number = -1

  aboutToAppear(): void {
    this.loadRequests()
  }

  loadRequests(): void {
    this.isLoading = true
    this.errorText = ''
    RecruiterService.getIncomingRequests().then((list: RecruiterRequestVO[]) => {
      this.requestList = list
      this.isLoading = false
    }).catch(() => {
      this.isLoading = false
      this.errorText = '请求记录加载失败，请检查网络后重试'
    })
  }

  get filteredList(): RecruiterRequestVO[] {
    const filterStatus = this.filterStatus
    const requestList = this.requestList
    if (filterStatus === -1) {
      return requestList
    }
    const result: RecruiterRequestVO[] = []
    for (const req of requestList) {
      if (req.status === filterStatus) {
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
          if (!time.trim() || !location.trim()) {
            this.getUIContext().getPromptAction().showToast({ message: '请填写面试时间和地点' })
            return
          }
          dialog.close()
          RecruiterService.processRequest(req.id, {
            status: 1,
            interviewTime: time,
            interviewLocation: location,
            rejectReason: '',
            hrNote: ''
          }).then((success: boolean) => {
            if (!success) {
              return
            }
            req.status = 1
            req.interviewTime = time
            req.interviewLocation = location
            this.requestList = [...this.requestList]
            this.getUIContext().getPromptAction().showToast({ message: '面试安排已保存' })
          }).catch(() => {
            this.getUIContext().getPromptAction().showToast({ message: '面试安排失败，请稍后重试' })
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
        onConfirm: (reason: string, note: string): void => {
          if (!ApplicationNotePolicy.isValid(reason) || !ApplicationNotePolicy.isValid(note)) {
            this.getUIContext().getPromptAction().showToast({ message: '请填写淘汰原因和内部备注' })
            return
          }
          dialog.close()
          RecruiterService.processRequest(req.id, {
            status: 4,
            interviewTime: '',
            interviewLocation: '',
            rejectReason: reason,
            hrNote: note
          }).then((success: boolean) => {
            if (!success) {
              return
            }
            req.status = 4
            req.rejectReason = reason
            this.requestList = [...this.requestList]
            this.getUIContext().getPromptAction().showToast({ message: '候选人状态已更新' })
          }).catch(() => {
            this.getUIContext().getPromptAction().showToast({ message: '操作失败，请稍后重试' })
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

  confirmSimpleStatus(req: RecruiterRequestVO, status: number, label: string): void {
    this.getUIContext().showAlertDialog({
      message: '确定将 ' + req.applicantName + ' 标记为' + label + '吗？',
      confirm: {
        value: '确定',
        action: (): void => { this.updateSimpleStatus(req, status) }
      },
      cancel: (): void => {}
    })
  }

  updateSimpleStatus(req: RecruiterRequestVO, status: number): void {
    RecruiterService.processRequest(req.id, {
      status: status,
      interviewTime: req.interviewTime || '',
      interviewLocation: req.interviewLocation || '',
      rejectReason: '',
      hrNote: ''
    }).then((success: boolean) => {
      if (!success) {
        this.getUIContext().getPromptAction().showToast({ message: '操作失败，请稍后重试' })
        return
      }
      req.status = status
      this.requestList = [...this.requestList]
      this.getUIContext().getPromptAction().showToast({ message: '操作成功' })
    }).catch(() => {
      this.getUIContext().getPromptAction().showToast({ message: '操作失败，请稍后重试' })
    })
  }

  confirmComplete(req: RecruiterRequestVO): void {
    let dialog = new CustomDialogController({
      builder: CompleteDialog({
        requestName: req.applicantName,
        onConfirm: (note: string): void => {
          if (!ApplicationNotePolicy.isValid(note)) {
            this.getUIContext().getPromptAction().showToast({ message: '请填写结算备注' })
            return
          }
          dialog.close()
          RecruiterService.completeApplication(req.id, note).then((success: boolean) => {
            if (!success) {
              this.getUIContext().getPromptAction().showToast({ message: '结算失败，请稍后重试' })
              return
            }
            req.status = 5
            this.requestList = [...this.requestList]
            this.getUIContext().getPromptAction().showToast({ message: '结算已完成' })
          }).catch(() => {
            this.getUIContext().getPromptAction().showToast({ message: '结算失败，请稍后重试' })
          })
        },
        onCancel: (): void => { dialog.close() }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Bottom
    })
    dialog.open()
  }
  openResume(req: RecruiterRequestVO): void {
    router.pushUrl({
      url: 'pages/ResumeDetailPage',
      params: {
        resumeData: JSON.stringify({
          id: String(req.applicantId), name: req.applicantName, age: req.applicantAge,
          avatar: req.applicantAvatar, education: req.applicantEducation,
          school: req.applicantSchool, major: req.applicantMajor,
          experience: req.applicantExperience, skills: req.applicantSkills,
          region: req.applicantRegion, type: req.applicantType, category: '',
          expectedSalary: req.applicantSalary, description: '', attachmentUrl: req.attachmentUrl
        })
      }
    })
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
          this.filterTab('待定', 2)
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
          LoadingProgress()
            .width(28)
            .height(28)
            .color(AppColors.PRIMARY)
          Text('正在加载请求记录')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
            .margin({ top: AppSpacing.SM })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.errorText) {
        Column() {
          SymbolGlyph($r('sys.symbol.exclamationmark_circle'))
            .fontSize(32)
            .fontColor([AppColors.DANGER])
          Text(this.errorText)
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_SECONDARY)
            .textAlign(TextAlign.Center)
            .margin({ top: AppSpacing.SM, bottom: AppSpacing.MD })
          Button('重新加载', { type: ButtonType.Capsule })
            .height(40)
            .fontSize(AppFontSize.SM)
            .fontColor('#FFFFFF')
            .backgroundColor(AppColors.PRIMARY)
            .onClick(() => {
              this.loadRequests()
            })
        }
        .layoutWeight(1)
        .padding({ left: AppSpacing.LG, right: AppSpacing.LG })
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
                onReject: (r: RecruiterRequestVO) => { this.handleReject(r) },
                onSimpleStatus: (r: RecruiterRequestVO, status: number) => { this.confirmSimpleStatus(r, status, status === 3 ? '已录用' : '待定') },
                onComplete: (r: RecruiterRequestVO) => { this.confirmComplete(r) },
                onViewResume: (r: RecruiterRequestVO) => { this.openResume(r) }
              })
              .transition(TransitionEffect.asymmetric(
                TransitionEffect.opacity(0).combine(TransitionEffect.translate({ y: 20 })),
                TransitionEffect.opacity(1)
              ))
            }, (req: RecruiterRequestVO) => req.id.toString())
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
    Button(label, { type: ButtonType.Capsule })
      .height(34)
      .fontSize(AppFontSize.SM)
      .fontColor(this.filterStatus === status ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
      .backgroundColor(this.filterStatus === status ? AppColors.PRIMARY : AppColors.INPUT_BG)
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
      .margin({ right: AppSpacing.SM })
      .onClick(() => {
        this.filterStatus = status
      })
      .stateStyles({
        pressed: {
          .scale({ x: 0.97, y: 0.97 })
          .opacity(0.88)
        },
        normal: {
          .scale({ x: 1, y: 1 })
          .opacity(1)
        }
      })
      .animation({ duration: 180 })
  }
}
