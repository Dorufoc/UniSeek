// LicenseUploader.ets — 营业执照上传组件
// 职责：空态展示上传入口 / 已上传态展示缩略图、预览与删除

import { AppColors, AppFontSize, AppRadius, AppSpacing } from '../../common/AppStyles';

@Component
export struct LicenseUploader {
  @Prop url: string = ''
  @Prop uploading: boolean = false
  onUpload?: () => void
  onRemove?: () => void
  onPreview?: () => void

  build() {
    Column() {
      Text('营业执照')
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')

      if (this.url) {
        Row({ space: AppSpacing.SM }) {
          Image(this.url)
            .width(72)
            .height(54)
            .objectFit(ImageFit.Cover)
            .borderRadius(AppRadius.SM)
            .alt($r('sys.symbol.picture'))

          Column() {
            Text('营业执照已上传，点击查看')
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.PRIMARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text('支持 JPG、PNG、GIF、WebP 格式，不超过 10MB')
              .fontSize(AppFontSize.XXS)
              .fontColor(AppColors.TEXT_MUTED)
              .margin({ top: AppSpacing.XS })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button('删除', { type: ButtonType.Capsule })
            .height(AppSpacing.BUTTON_HEIGHT_MINI)
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.DANGER)
            .backgroundColor(AppColors.ERROR_BG)
            .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
            .onClick(() => {
              this.onRemove?.()
            })
        }
        .width('100%')
        .height(AppSpacing.INPUT_HEIGHT)
        .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
        .backgroundColor(AppColors.SELECTED_BG)
        .borderRadius(AppRadius.SM)
        .margin({ top: AppSpacing.XS })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.onPreview?.()
        })
        .stateStyles({
          pressed: {
            .backgroundColor(AppColors.PRIMARY_ALPHA_6)
          }
        })
        .animation({ duration: 150 })
      } else {
        Column({ space: AppSpacing.SM }) {
          if (this.uploading) {
            LoadingProgress()
              .width(AppSpacing.ICON_MD)
              .height(AppSpacing.ICON_MD)
              .color(AppColors.PRIMARY)
            Text('正在上传营业执照')
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.TEXT_MUTED)
          } else {
            SymbolGlyph($r('sys.symbol.picture'))
              .fontSize(AppFontSize.ICON_LG)
              .fontColor([AppColors.TEXT_MUTED])
            Text('点击上传营业执照')
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.TEXT_SECONDARY)
            Text('支持 JPG、PNG、GIF、WebP 格式，不超过 10MB')
              .fontSize(AppFontSize.XXS)
              .fontColor(AppColors.TEXT_MUTED)
          }
        }
        .width('100%')
        .height(120)
        .margin({ top: AppSpacing.XS })
        .padding(AppSpacing.MD)
        .backgroundColor(AppColors.INPUT_BG)
        .border({ width: 2, color: AppColors.BORDER, style: BorderStyle.Dashed })
        .borderRadius(AppRadius.SM)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .enabled(!this.uploading)
        .onClick(() => {
          this.onUpload?.()
        })
        .stateStyles({
          pressed: {
            .backgroundColor(AppColors.PRIMARY_ALPHA_6)
          }
        })
        .animation({ duration: 150 })
      }
    }
    .width('100%')
  }
}
