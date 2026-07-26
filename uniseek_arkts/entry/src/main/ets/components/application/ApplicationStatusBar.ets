import { RecruiterService } from '../../services/RecruiterService'
import { APPLICATION_STATUS_LABELS, RecruiterUpdateStatusRequest } from '../../services/RecruiterTypes'
import { UserSession } from '../../services/UserSession'
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../../common/AppStyles'

interface StatusAction {
  target: number
  label: string
  variant: 'primary' | 'success' | 'warning' | 'danger'
  requiresDialog?: 'interview' | 'reject' | 'complete'
}

@CustomDialog
struct InterviewDialog {
  controller?: CustomDialogController
  applicantName?: string = ''
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
          .height(AppSpacing.BUTTON_HEIGHT_MINI)
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_MUTED)
          .backgroundColor(Color.Transparent)
          .onClick(() => { this.onCancel?.() })
      }
      .width('100%')
      .padding({ bottom: AppSpacing.MD })

      Text('为 ' + (this.applicantName || '候选人') + ' 安排面试')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: AppSpacing.MD })

      TextInput({ placeholder: '面试时间（如 2026-07-30 10:00）', text: this.timeText })
        .onChange((value: string) => { this.timeText = value })
        .width('100%')
        .height(AppSpacing.BUTTON_HEIGHT_MD)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .margin({ bottom: AppSpacing.SM })

      TextInput({ placeholder: '面试地点', text: this.locationText })
        .onChange((value: string) => { this.locationText = value })
        .width('100%')
        .height(AppSpacing.BUTTON_HEIGHT_MD)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .margin({ bottom: AppSpacing.LG })

      Button('确定', { type: ButtonType.Capsule })
        .width('100%')
        .height(AppSpacing.BUTTON_HEIGHT)
        .fontSize(AppFontSize.MD)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor(AppColors.PRIMARY)
        .onClick(() => {
          this.onConfirm?.(this.timeText, this.locationText)
        })
        .stateStyles({
          pressed: {
            .scale({ x: 0.98, y: 0.98 })
            .opacity(0.9)
          },
          normal: {
            .scale({ x: 1, y: 1 })
            .opacity(1)
          }
        })
        .animation({ duration: 180 })
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
  applicantName?: string = ''
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
          .height(AppSpacing.BUTTON_HEIGHT_MINI)
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_MUTED)
          .backgroundColor(Color.Transparent)
          .onClick(() => { this.onCancel?.() })
      }
      .width('100%')
      .padding({ bottom: AppSpacing.MD })

      Text('确认淘汰 ' + (this.applicantName || '该候选人') + '？')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: AppSpacing.MD })

      TextInput({ placeholder: '淘汰原因（必填）', text: this.reasonText })
        .onChange((value: string) => { this.reasonText = value })
        .width('100%')
        .height(AppSpacing.BUTTON_HEIGHT_MD)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .margin({ bottom: AppSpacing.SM })

      TextArea({ placeholder: '内部备注（选填，仅招聘方可见）', text: this.noteText })
        .onChange((value: string) => { this.noteText = value })
        .width('100%')
        .height(88)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .padding(AppSpacing.SM)
        .margin({ bottom: AppSpacing.LG })

      Row() {
        Button('取消', { type: ButtonType.Capsule })
          .height(AppSpacing.BUTTON_HEIGHT)
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_SECONDARY)
          .backgroundColor(AppColors.INPUT_BG)
          .layoutWeight(1)
          .onClick(() => { this.onCancel?.() })
          .stateStyles({
            pressed: {
              .scale({ x: 0.98, y: 0.98 })
              .opacity(0.9)
            }
          })
          .animation({ duration: 180 })

        Blank().width(AppSpacing.MD)

        Button('确认淘汰', { type: ButtonType.Capsule })
          .height(AppSpacing.BUTTON_HEIGHT)
          .fontSize(AppFontSize.MD)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor(AppColors.DANGER)
          .layoutWeight(1)
          .onClick(() => {
            this.onConfirm?.(this.reasonText, this.noteText)
          })
          .stateStyles({
            pressed: {
              .scale({ x: 0.98, y: 0.98 })
              .opacity(0.9)
            }
          })
          .animation({ duration: 180 })
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
struct CompleteDialog {
  controller?: CustomDialogController
  applicantName?: string = ''
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
          .height(AppSpacing.BUTTON_HEIGHT_MINI)
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_MUTED)
          .backgroundColor(Color.Transparent)
          .onClick(() => { this.onCancel?.() })
      }
      .width('100%')
      .padding({ bottom: AppSpacing.MD })

      Text('为 ' + (this.applicantName || '该候选人') + ' 记录结算说明')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: AppSpacing.MD })

      TextArea({ placeholder: '结算备注（必填）', text: this.noteText })
        .onChange((value: string) => { this.noteText = value })
        .width('100%')
        .height(96)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .padding(AppSpacing.SM)
        .margin({ bottom: AppSpacing.LG })

      Button('确认完成', { type: ButtonType.Capsule })
        .width('100%')
        .height(AppSpacing.BUTTON_HEIGHT)
        .fontSize(AppFontSize.MD)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .backgroundColor(AppColors.SUCCESS)
        .onClick(() => {
          this.onConfirm?.(this.noteText)
        })
        .stateStyles({
          pressed: {
            .scale({ x: 0.98, y: 0.98 })
            .opacity(0.9)
          }
        })
        .animation({ duration: 180 })
    }
    .padding(AppSpacing.LG)
    .width('100%')
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius({ topLeft: AppRadius.XL, topRight: AppRadius.XL })
  }
}

@Component
export struct ApplicationStatusBar {
  @Prop applicationId: number
  @Prop currentStatus: number
  @Prop applicantName: string = ''
  onStatusChanged?: (status: number) => void

  @State isLoading: boolean = false

  private interviewController: CustomDialogController = new CustomDialogController({
    builder: InterviewDialog({
      applicantName: this.applicantName,
      onConfirm: (time: string, location: string): void => { this.handleInterviewConfirm(time, location) }
    }),
    alignment: DialogAlignment.Center
  })

  private rejectController: CustomDialogController = new CustomDialogController({
    builder: RejectDialog({
      applicantName: this.applicantName,
      onConfirm: (reason: string, note: string): void => { this.handleRejectConfirm(reason, note) }
    }),
    alignment: DialogAlignment.Center
  })

  private completeController: CustomDialogController = new CustomDialogController({
    builder: CompleteDialog({
      applicantName: this.applicantName,
      onConfirm: (note: string): void => { this.handleCompleteConfirm(note) }
    }),
    alignment: DialogAlignment.Center
  })

  private actionList(): StatusAction[] {
    const status = this.currentStatus ?? -1
    switch (status) {
      case 0:
        return [
          { target: 1, label: '邀请面试', variant: 'primary', requiresDialog: 'interview' },
          { target: 2, label: '待定', variant: 'warning' },
          { target: 4, label: '淘汰', variant: 'danger', requiresDialog: 'reject' }
        ]
      case 1:
        return [
          { target: 3, label: '录用', variant: 'success' },
          { target: 2, label: '待定', variant: 'warning' },
          { target: 4, label: '淘汰', variant: 'danger', requiresDialog: 'reject' }
        ]
      case 2:
        return [
          { target: 1, label: '安排面试', variant: 'primary', requiresDialog: 'interview' },
          { target: 3, label: '录用', variant: 'success' },
          { target: 4, label: '淘汰', variant: 'danger', requiresDialog: 'reject' }
        ]
      case 3:
        return [
          { target: 5, label: '完成结算', variant: 'success', requiresDialog: 'complete' }
        ]
      default:
        return []
    }
  }

  private variantColor(variant: string): ResourceColor {
    switch (variant) {
      case 'primary':
        return AppColors.PRIMARY
      case 'success':
        return AppColors.SUCCESS
      case 'warning':
        return AppColors.WARNING
      case 'danger':
        return AppColors.DANGER
      default:
        return AppColors.TEXT_MUTED
    }
  }

  private isFilled(variant: string): boolean {
    return variant === 'primary' || variant === 'success'
  }

  private handleAction(action: StatusAction): void {
    if (this.isLoading) {
      return
    }
    if (action.requiresDialog === 'interview') {
      this.interviewController.open()
      return
    }
    if (action.requiresDialog === 'reject') {
      this.rejectController.open()
      return
    }
    if (action.requiresDialog === 'complete') {
      this.completeController.open()
      return
    }

    const promptAction = this.getUIContext().getPromptAction()
    promptAction.showDialog({
      message: `确认将状态改为「${APPLICATION_STATUS_LABELS[action.target]}」？`,
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '确认', color: '#1762FB' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        void this.updateStatus(action.target)
      }
    }).catch(() => {
      // 取消时静默处理
    })
  }

  private async updateStatus(target: number, extra: Partial<RecruiterUpdateStatusRequest> = {}): Promise<void> {
    if (this.applicationId <= 0 || this.isLoading) {
      return
    }
    this.isLoading = true
    const promptAction = this.getUIContext().getPromptAction()
    try {
      let ok = false
      if (target === 5) {
        ok = await RecruiterService.completeApplication(this.applicationId, extra.hrNote ?? '')
      } else {
        const data: RecruiterUpdateStatusRequest = {
          status: target,
          interviewTime: extra.interviewTime ?? '',
          interviewLocation: extra.interviewLocation ?? '',
          rejectReason: extra.rejectReason ?? '',
          hrNote: extra.hrNote ?? ''
        }
        ok = await RecruiterService.processRequest(this.applicationId, data)
      }
      if (ok) {
        promptAction.showToast({ message: '操作成功' })
        this.onStatusChanged?.(target)
      } else {
        promptAction.showToast({ message: '操作失败，请重试' })
      }
    } catch {
      promptAction.showToast({ message: '操作失败，请重试' })
    }
    this.isLoading = false
  }

  private handleInterviewConfirm(time: string, location: string): void {
    if (!time.trim() || !location.trim()) {
      this.getUIContext().getPromptAction().showToast({ message: '请填写面试时间和地点' })
      return
    }
    void this.updateStatus(1, {
      interviewTime: time.trim(),
      interviewLocation: location.trim()
    })
  }

  private handleRejectConfirm(reason: string, note: string): void {
    if (!reason.trim()) {
      this.getUIContext().getPromptAction().showToast({ message: '请填写淘汰原因' })
      return
    }
    void this.updateStatus(4, {
      rejectReason: reason.trim(),
      hrNote: note.trim()
    })
  }

  private handleCompleteConfirm(note: string): void {
    if (!note.trim()) {
      this.getUIContext().getPromptAction().showToast({ message: '请填写结算备注' })
      return
    }
    void this.updateStatus(5, {
      hrNote: note.trim()
    })
  }

  @Builder
  actionButton(label: string, color: ResourceColor, filled: boolean, onClick: () => void) {
    Button({ type: ButtonType.Capsule }) {
      Text(label)
        .fontSize(AppFontSize.SM)
        .fontColor(filled ? '#FFFFFF' : color)
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .height(AppSpacing.BUTTON_HEIGHT_SM)
    .layoutWeight(1)
    .backgroundColor(filled ? color : AppColors.BG_CARD)
    .border({ width: 1, color: color })
    .onClick(onClick)
    .stateStyles({
      pressed: {
        .scale({ x: 0.97, y: 0.97 })
        .opacity(0.9)
      }
    })
    .animation({ duration: 180 })
  }

  private isVisible(): boolean {
    return UserSession.role === 1 && this.applicationId > 0 && this.actionList().length > 0
  }

  build() {
    Column() {
      if (this.isVisible()) {
        Row({ space: AppSpacing.SM }) {
          ForEach(this.actionList(), (action: StatusAction) => {
            this.actionButton(
              action.label,
              this.variantColor(action.variant),
              this.isFilled(action.variant),
              () => { this.handleAction(action) }
            )
          }, (action: StatusAction): string => String(action.target))
        }
        .width('90%')
        .height(AppSpacing.BUTTON_HEIGHT_SM)
      }
    }
    .width('100%')
    .height(this.isVisible() ? 64 : 0)
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
    .backgroundColor(AppColors.BG_PAGE)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
