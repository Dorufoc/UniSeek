// 投递状态操作栏：用于简历详情页、聊天详情页底部。
// 复用 SharedDialogs 中的面试和淘汰弹窗。

import { RecruiterService } from '../../services/RecruiterService'
import { APPLICATION_STATUS_LABELS, ApplicationActionConfig, RecruiterUpdateStatusRequest } from '../../services/RecruiterTypes'
import { UserSession } from '../../services/UserSession'
import { ApplicationActionPolicy } from '../../common/BusinessPolicies'
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../../common/AppStyles'
import { InterviewDialog, RejectDialog } from './SharedDialogs'

@Component
export struct ApplicationStatusBar {
  @Prop applicationId: number
  @Prop currentStatus: number
  @Prop applicantName: string = ''
  onStatusChanged?: (status: number) => void

  @State isLoading: boolean = false

  private actionList(): ApplicationActionConfig[] {
    return ApplicationActionPolicy.getActions(this.currentStatus)
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

  private handleAction(action: ApplicationActionConfig): void {
    if (this.isLoading) {
      return
    }
    if (action.requiresDialog === 'interview') {
      this.openInterviewDialog()
      return
    }
    if (action.requiresDialog === 'reject') {
      this.openRejectDialog()
      return
    }
    const promptAction = this.getUIContext().getPromptAction()
    promptAction.showDialog({
      message: '确认将状态改为「' + APPLICATION_STATUS_LABELS[action.targetStatus] + '」？',
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '确认', color: '#1762FB' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        void this.updateStatus(action.targetStatus)
      }
    }).catch(() => {
      // 取消时静默处理
    })
  }

  private openInterviewDialog(): void {
    let dialog: CustomDialogController
    dialog = new CustomDialogController({
      builder: InterviewDialog({
        applicantName: this.applicantName,
        onConfirm: (time: string, location: string): void => {
          void this.updateStatus(1, {
            interviewTime: time,
            interviewLocation: location
          })
          dialog.close()
        },
        onCancel: (): void => {
          dialog.close()
        }
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true
    })
    dialog.open()
  }

  private openRejectDialog(): void {
    const dialog = new CustomDialogController({
      builder: RejectDialog({
        applicantName: this.applicantName,
        onConfirm: (reason: string, note: string): void => {
          void this.updateStatus(4, {
            rejectReason: reason,
            hrNote: note
          })
        }
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true
    })
    dialog.open()
  }

  private async updateStatus(target: number, extra: Partial<RecruiterUpdateStatusRequest> = {}): Promise<void> {
    if (this.applicationId <= 0 || this.isLoading) {
      return
    }
    this.isLoading = true
    const promptAction = this.getUIContext().getPromptAction()
    try {
      const ok = await RecruiterService.updateApplicationStatus(this.applicationId, {
        status: target,
        interviewTime: extra.interviewTime ?? '',
        interviewLocation: extra.interviewLocation ?? '',
        rejectReason: extra.rejectReason ?? '',
        hrNote: extra.hrNote ?? ''
      })
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
          ForEach(this.actionList(), (action: ApplicationActionConfig) => {
            this.actionButton(
              action.label,
              this.variantColor(action.variant),
              this.isFilled(action.variant),
              () => { this.handleAction(action) }
            )
          }, (action: ApplicationActionConfig): string => String(action.targetStatus))
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
