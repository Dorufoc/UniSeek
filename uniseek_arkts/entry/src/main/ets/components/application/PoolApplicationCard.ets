// 简历池 / 面试安排列表中的候选人卡片。
// 展示头像、基本信息、技能经历、状态标签与可执行操作，与 Vue ResumePool 卡片对齐。

import { RecruiterApplicationVO, ApplicationActionConfig } from '../../services/RecruiterTypes'
import { ApplicationActionPolicy } from '../../common/BusinessPolicies'
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../../common/AppStyles'
import { StandardCard } from '../../common/StandardCard'

interface ResumeSnapshot {
  realName?: string
  gender?: number
  birthDate?: string
  education?: string
  school?: string
  skills?: string
  experience?: string
  attachmentUrl?: string
}

@Component
export struct PoolApplicationCard {
  @Prop app: RecruiterApplicationVO = {
    id: 0, taskId: 0, applicantId: 0, applicantName: '', applicantAvatar: '',
    status: 0, interviewTime: '', interviewLocation: '', rejectReason: '', createTime: ''
  }
  @Prop showInterviewDetail: boolean = false
  onViewResume?: (app: RecruiterApplicationVO) => void
  onInterview?: (app: RecruiterApplicationVO) => void
  onReject?: (app: RecruiterApplicationVO) => void
  onComplete?: (app: RecruiterApplicationVO) => void
  onMarkStatus?: (app: RecruiterApplicationVO, targetStatus: number, label: string) => void

  private parseSnapshot(): ResumeSnapshot {
    if (!this.app.resumeSnapshot) {
      return {}
    }
    try {
      return JSON.parse(this.app.resumeSnapshot) as ResumeSnapshot
    } catch {
      return {}
    }
  }

  private getAge(birthDate?: string): number {
    if (!birthDate || birthDate.length < 4) {
      return 0
    }
    const year = Number(birthDate.substring(0, 4))
    const currentYear = new Date().getFullYear()
    return year >= 1900 && year <= currentYear ? currentYear - year : 0
  }

  private formatDateTime(timeText?: string): string {
    if (!timeText) {
      return ''
    }
    return timeText.replace('T', ' ').substring(0, 16)
  }

  private statusColor(): ResourceColor {
    switch (this.app.status) {
      case 0:
        return AppColors.INFO
      case 1:
      case 2:
        return AppColors.WARNING
      case 3:
      case 5:
        return AppColors.SUCCESS
      case 4:
        return AppColors.DANGER
      default:
        return AppColors.TEXT_MUTED
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

  private genderText(): string {
    const snapshot = this.parseSnapshot()
    if (snapshot.gender === 0) {
      return '男'
    }
    if (snapshot.gender === 1) {
      return '女'
    }
    return '-'
  }

  private handleAction(action: ApplicationActionConfig): void {
    if (action.requiresDialog === 'interview') {
      this.onInterview?.(this.app)
      return
    }
    if (action.requiresDialog === 'reject') {
      this.onReject?.(this.app)
      return
    }
    if (action.requiresDialog === 'complete') {
      this.onComplete?.(this.app)
      return
    }
    this.onMarkStatus?.(this.app, action.targetStatus, action.label)
  }

  private getStatusLabel(): string {
    const labels: Record<number, string> = {
      0: '已投递', 1: '待面试', 2: '待定', 3: '已录用', 4: '已淘汰', 5: '已完成'
    }
    return labels[this.app.status] ?? '未知'
  }

  private statusBgColor(): ResourceColor {
    switch (this.app.status) {
      case 0:
        return AppColors.SELECTED_BG ?? AppColors.PRIMARY_ALPHA_6
      case 1:
      case 2:
        return AppColors.WARNING_BG
      case 3:
      case 5:
        return AppColors.SUCCESS_BG
      case 4:
        return AppColors.ERROR_BG
      default:
        return AppColors.INPUT_BG
    }
  }

  private actionList(): ApplicationActionConfig[] {
    return ApplicationActionPolicy.getActions(this.app.status)
  }

  @Builder
  actionButtons(): void {
    if (this.actionList().length > 0) {
      Row({ space: AppSpacing.SM }) {
        this.viewResumeButton()
        ForEach(this.actionList(), (action: ApplicationActionConfig) => {
          this.actionButton(action.label, this.variantColor(action.variant), this.isFilled(action.variant), () => { this.handleAction(action) })
        }, (action: ApplicationActionConfig) => action.label)
      }
      .width('100%')
      .margin({ top: AppSpacing.SM })
      .justifyContent(FlexAlign.End)
    }
  }

  @Builder
  viewResumeButton(): void {
    Button({ type: ButtonType.Capsule }) {
      Text('查看简历')
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
    }
      .height(AppSpacing.BUTTON_HEIGHT_MINI)
      .backgroundColor(AppColors.BG_CARD)
      .border({ width: 1, color: AppColors.TEXT_MUTED })
      .onClick(() => { this.onViewResume?.(this.app) })
      .stateStyles({
        pressed: {
          .scale({ x: 0.97, y: 0.97 })
          .opacity(0.9)
        }
      })
      .animation({ duration: 150 })
  }

  @Builder
  actionButton(label: string, color: ResourceColor, filled: boolean, onClick: () => void): void {
    Button({ type: ButtonType.Capsule }) {
      Text(label)
        .fontSize(AppFontSize.XS)
        .fontColor(filled ? '#FFFFFF' : color)
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
      .height(AppSpacing.BUTTON_HEIGHT_MINI)
      .backgroundColor(filled ? color : AppColors.BG_CARD)
      .border({ width: 1, color: color })
      .onClick(onClick)
      .stateStyles({
        pressed: {
          .scale({ x: 0.97, y: 0.97 })
          .opacity(0.9)
        }
      })
      .animation({ duration: 150 })
  }

  build() {
    Column() {
      StandardCard({
        onClickAction: () => { this.onViewResume?.(this.app) }
      }) {
      Column() {
        // 头像 + 姓名 + 状态
        Row() {
          Stack() {
            Text(this.app.applicantName ? this.app.applicantName.charAt(0) : '?')
              .fontSize(AppFontSize.MD)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.BG_CARD)
          }
          .width(44)
          .height(44)
          .borderRadius(AppRadius.FULL)
          .backgroundColor(AppColors.PRIMARY)

          Column() {
            Row() {
              Text(this.app.applicantName || '未知姓名')
                .fontSize(AppFontSize.MD)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT_PRIMARY)
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Text(this.getStatusLabel())
                .fontSize(AppFontSize.XS)
                .fontColor(this.statusColor())
                .padding({ left: AppSpacing.XS, right: AppSpacing.XS, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
                .backgroundColor(this.statusBgColor())
                .borderRadius(AppRadius.SM)
            }
            .width('100%')

            Row() {
              Text('性别：' + this.genderText())
                .fontSize(AppFontSize.XS)
                .fontColor(AppColors.TEXT_SECONDARY)
              Text(' · ')
                .fontSize(AppFontSize.XS)
                .fontColor(AppColors.TEXT_MUTED)
              Text('学历：' + (this.parseSnapshot().education || '-'))
                .fontSize(AppFontSize.XS)
                .fontColor(AppColors.TEXT_SECONDARY)
              Text(' · ')
                .fontSize(AppFontSize.XS)
                .fontColor(AppColors.TEXT_MUTED)
              Text('院校：' + (this.parseSnapshot().school || '-'))
                .fontSize(AppFontSize.XS)
                .fontColor(AppColors.TEXT_SECONDARY)
              if (this.getAge(this.parseSnapshot().birthDate) > 0) {
                Text(' · ' + this.getAge(this.parseSnapshot().birthDate) + '岁')
                  .fontSize(AppFontSize.XS)
                  .fontColor(AppColors.TEXT_SECONDARY)
              }
            }
            .width('100%')
            .margin({ top: AppSpacing.XXS })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: AppSpacing.SM })
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        if (this.parseSnapshot().skills) {
          Text('技能：' + this.parseSnapshot().skills)
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.TEXT_SECONDARY)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .margin({ top: AppSpacing.XS })
        }

        if (this.parseSnapshot().experience) {
          Text('经历：' + this.parseSnapshot().experience)
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.TEXT_SECONDARY)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .margin({ top: AppSpacing.XXS })
        }

        if (this.app.status === 4 && this.app.rejectReason) {
          Text('淘汰原因：' + this.app.rejectReason)
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.DANGER)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .margin({ top: AppSpacing.XS })
        }

        if (this.showInterviewDetail && this.app.interviewTime) {
          Column() {
            Text('面试时间：' + this.formatDateTime(this.app.interviewTime))
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.TEXT_PRIMARY)
              .width('100%')
            if (this.app.interviewLocation) {
              Text('面试地点：' + this.app.interviewLocation)
                .fontSize(AppFontSize.XS)
                .fontColor(AppColors.TEXT_SECONDARY)
                .width('100%')
                .margin({ top: AppSpacing.XXS })
            }
          }
          .width('100%')
          .padding(AppSpacing.SM)
          .backgroundColor(AppColors.PRIMARY_ALPHA_6)
          .borderRadius(AppRadius.SM)
          .margin({ top: AppSpacing.XS })
        }

        Text('投递时间：' + this.formatDateTime(this.app.createTime))
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.TEXT_MUTED)
          .width('100%')
          .margin({ top: AppSpacing.XS })

        // 操作区
        this.actionButtons()
      }
      .width('100%')
    }
    }
  }}
