// StatusBanner.ets — 企业资质审核状态横幅
// 职责：以高辨识度色块 + Symbol 图标展示当前认证状态

import { AppColors, AppFontSize, AppRadius, AppSpacing } from '../../common/AppStyles';
import { AUDIT_STATUS_LABELS } from '../../services/RecruiterTypes';

const STATUS_DESCRIPTIONS: Record<number, string> = {
  0: '审核中，请耐心等待',
  1: '已认证，可发布职位',
  2: '已被驳回，请修改后重新提交'
}

const STATUS_COLORS: Record<number, ResourceColor> = {
  0: AppColors.WARNING,
  1: AppColors.SUCCESS,
  2: AppColors.DANGER
}

const STATUS_BG_COLORS: Record<number, ResourceColor> = {
  0: AppColors.WARNING_BG,
  1: AppColors.SUCCESS_BG,
  2: AppColors.ERROR_BG
}

const STATUS_SYMBOLS: Resource[] = [
  $r('sys.symbol.clock'),
  $r('sys.symbol.checkmark_circle_fill'),
  $r('sys.symbol.exclamationmark_triangle_fill')
]

@Component
export struct StatusBanner {
  @Prop status: number = 0

  build() {
    Row({ space: AppSpacing.SM }) {
      SymbolGlyph(STATUS_SYMBOLS[this.status] ?? STATUS_SYMBOLS[0])
        .fontSize(AppFontSize.ICON_MD)
        .fontColor([STATUS_COLORS[this.status] ?? AppColors.WARNING])

      Column() {
        Text(AUDIT_STATUS_LABELS[this.status] ?? '审核中')
          .fontSize(AppFontSize.SM)
          .fontWeight(FontWeight.Medium)
          .fontColor(STATUS_COLORS[this.status] ?? AppColors.WARNING)
        Text(STATUS_DESCRIPTIONS[this.status] ?? STATUS_DESCRIPTIONS[0])
          .fontSize(AppFontSize.XS)
          .fontColor(STATUS_COLORS[this.status] ?? AppColors.WARNING)
          .margin({ top: AppSpacing.XS })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(AppSpacing.MD)
    .backgroundColor(STATUS_BG_COLORS[this.status] ?? AppColors.WARNING_BG)
    .borderRadius(AppRadius.MD)
    .alignItems(VerticalAlign.Center)
  }
}
