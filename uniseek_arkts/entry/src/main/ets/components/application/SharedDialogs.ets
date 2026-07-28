// 招聘方处理投递时共用的 CustomDialog：
// 面试邀请、淘汰、完成结算。
// 供 RecruiterRequestsPage 与 ApplicationStatusBar 复用。

import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../../common/AppStyles'

/**
 * 面试邀请弹窗。
 * 使用原生 showDatePickerDialog 选择日期时间，并填写面试地点。
 */
@CustomDialog
export struct InterviewDialog {
  controller?: CustomDialogController
  applicantName?: string = ''
  onConfirm?: (time: string, location: string) => void

  @State timeText: string = ''
  @State locationText: string = ''

  private padTimePart(value: number): string {
    return value < 10 ? '0' + String(value) : String(value)
  }

  private formatDateTime(value: Date): string {
    return String(value.getFullYear()) + '-' +
      this.padTimePart(value.getMonth() + 1) + '-' +
      this.padTimePart(value.getDate()) + 'T' +
      this.padTimePart(value.getHours()) + ':' +
      this.padTimePart(value.getMinutes()) + ':' +
      this.padTimePart(value.getSeconds())
  }

  private chooseInterviewTime(): void {
    const now = new Date()
    const selected = new Date(now.getTime() + 60 * 60 * 1000)
    this.getUIContext().showDatePickerDialog({
      start: now,
      end: new Date(now.getFullYear() + 2, 11, 31, 23, 59, 59),
      selected: selected,
      showTime: true,
      useMilitaryTime: true,
      dateTimeOptions: { hour: '2-digit', minute: '2-digit' },
      onDateAccept: (value: Date): void => {
        this.timeText = this.formatDateTime(value)
      }
    })
  }

  build() {
    Column() {
      Row() {
        Text('发送面试邀请')
          .fontSize(AppFontSize.LG)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ bottom: AppSpacing.MD })

      Text('为 ' + (this.applicantName || '候选人') + ' 安排面试')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: AppSpacing.MD })

      // 面试时间选择器
      Button({ type: ButtonType.Normal }) {
        Row() {
          Text(this.timeText || '选择面试时间')
            .fontSize(AppFontSize.MD)
            .fontColor(this.timeText ? AppColors.TEXT_PRIMARY : AppColors.TEXT_MUTED)
            .layoutWeight(1)
            .textAlign(TextAlign.Start)
          SymbolGlyph($r('sys.symbol.calendar'))
            .fontSize(AppFontSize.ICON_MD)
            .fontColor([AppColors.TEXT_SECONDARY])
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
        .onClick(() => { this.chooseInterviewTime() })
        .width('100%')
        .height(AppSpacing.BUTTON_HEIGHT_MD)
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
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

      Row() {
        Button('取消', { type: ButtonType.Capsule })
          .height(AppSpacing.BUTTON_HEIGHT)
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_SECONDARY)
          .backgroundColor(AppColors.INPUT_BG)
          .layoutWeight(1)
          .onClick(() => { this.controller?.close() })
          .stateStyles({
            pressed: {
              .scale({ x: 0.98, y: 0.98 })
              .opacity(0.9)
            }
          })
          .animation({ duration: 180 })

        Blank().width(AppSpacing.MD)

        Button('确认发送', { type: ButtonType.Capsule })
          .height(AppSpacing.BUTTON_HEIGHT)
          .fontSize(AppFontSize.MD)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor(AppColors.PRIMARY)
          .layoutWeight(1)
          .onClick(() => {
            if (!this.timeText.trim() || !this.locationText.trim()) {
              this.getUIContext().getPromptAction().showToast({ message: '请填写面试时间和地点' })
              return
            }
            this.onConfirm?.(this.timeText.trim(), this.locationText.trim())
            this.controller?.close()
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
    }
    .padding(AppSpacing.LG)
    .width('100%')
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius({ topLeft: AppRadius.XL, topRight: AppRadius.XL })
  }
}

/**
 * 淘汰候选人弹窗。
 * 必填淘汰原因（会通知求职者），内部备注可选。
 */
@CustomDialog
export struct RejectDialog {
  controller?: CustomDialogController
  applicantName?: string = ''
  onConfirm?: (reason: string, note: string) => void

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
          .onClick(() => { this.controller?.close() })
      }
      .width('100%')
      .padding({ bottom: AppSpacing.MD })

      Text('确认淘汰 ' + (this.applicantName || '该候选人') + '？')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: AppSpacing.MD })

      TextInput({ placeholder: '淘汰原因（必填，将通知求职者）', text: this.reasonText })
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
          .onClick(() => { this.controller?.close() })
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
            if (!this.reasonText.trim()) {
              this.getUIContext().getPromptAction().showToast({ message: '请填写淘汰原因' })
              return
            }
            this.onConfirm?.(this.reasonText.trim(), this.noteText.trim())
            this.controller?.close()
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
    }
    .padding(AppSpacing.LG)
    .width('100%')
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius({ topLeft: AppRadius.XL, topRight: AppRadius.XL })
  }
}

/**
 * 完成结算弹窗。
 * HR 备注选填。
 */
@CustomDialog
export struct CompleteDialog {
  controller?: CustomDialogController
  applicantName?: string = ''
  onConfirm?: (note: string) => void

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
          .onClick(() => { this.controller?.close() })
      }
      .width('100%')
      .padding({ bottom: AppSpacing.MD })

      Text('为 ' + (this.applicantName || '该候选人') + ' 记录结算说明')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: AppSpacing.MD })

      TextArea({ placeholder: '结算备注（选填）', text: this.noteText })
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
          this.onConfirm?.(this.noteText.trim())
          this.controller?.close()
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
