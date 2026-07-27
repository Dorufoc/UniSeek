import { RecruiterApplicationVO, APPLICATION_STATUS_LABELS } from '../../services/RecruiterTypes'
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../../common/AppStyles'
import { StandardCard } from '../../common/StandardCard'

@Component
export struct PoolApplicationCard {
  @Prop app: RecruiterApplicationVO = {
    id: 0, taskId: 0, applicantId: 0, applicantName: '', applicantAvatar: '',
    status: 0, interviewTime: '', interviewLocation: '', rejectReason: '', createTime: ''
  }
  @Prop jobTitle: string = ''
  onViewResume?: (app: RecruiterApplicationVO) => void

  private formatRequestTime(timeText?: string): string {
    if (!timeText) {
      return ''
    }
    return timeText.split('T')[0] || timeText.split(' ')[0] || timeText
  }

  private statusColor(status: number): ResourceColor {
    switch (status) {
      case 3:
        return AppColors.SUCCESS
      case 4:
        return AppColors.DANGER
      case 1:
        return AppColors.WARNING
      default:
        return AppColors.INFO
    }
  }

  private statusBgColor(status: number): ResourceColor {
    switch (status) {
      case 3:
        return AppColors.SUCCESS_BG
      case 4:
        return AppColors.ERROR_BG
      case 1:
        return AppColors.WARNING_BG
      default:
        return AppColors.SELECTED_BG
    }
  }

  @Builder
  statusBadge(status: number) {
    Text(APPLICATION_STATUS_LABELS[status] ?? '未知')
      .fontSize(AppFontSize.XS)
      .fontColor(this.statusColor(status))
      .backgroundColor(this.statusBgColor(status))
      .borderRadius(AppRadius.PILL)
      .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XS, bottom: AppSpacing.XS })
  }

  build() {
    StandardCard({
      onClickAction: () => { this.onViewResume?.(this.app) },
      accessibilityLabel: (this.app.applicantName || '匿名求职者') + ' 的简历'
    }) {
      Row({ space: AppSpacing.SM }) {
        Column() {
          if (this.app.applicantAvatar) {
            Image(this.app.applicantAvatar)
              .width('100%')
              .height('100%')
              .borderRadius(AppRadius.FULL)
              .objectFit(ImageFit.Cover)
          } else {
            SymbolGlyph($r('sys.symbol.person'))
              .fontSize(AppFontSize.ICON_MD)
              .fontColor([AppColors.TEXT_MUTED])
          }
        }
        .width(AppSpacing.ICON_XL)
        .height(AppSpacing.ICON_XL)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.FULL)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Text(this.app.applicantName || '匿名求职者')
            .fontSize(AppFontSize.MD)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.jobTitle || '未知职位')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_SECONDARY)
            .margin({ top: AppSpacing.XS })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.formatRequestTime(this.app.createTime))
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.TEXT_MUTED)
            .margin({ top: AppSpacing.XS })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        this.statusBadge(this.app.status)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
  }
}
