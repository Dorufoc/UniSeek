// LicenseUploader.ets — 营业执照上传组件
// 职责：空态展示上传入口 / 已上传态展示缩略图、预览与删除

import { AppColors, AppFontSize, AppRadius, AppSpacing } from '../../common/AppStyles';
import { ServerConfig } from '../../services/ServerConfig';
import { ApiClient } from '../../services/ApiClient';

@Component
export struct LicenseUploader {
  @Prop @Watch('onUrlChanged') url: string = ''
  @Prop uploading: boolean = false
  @State imageError: boolean = false
  onUpload?: () => void
  onRemove?: () => void
  onPreview?: () => void

  private onUrlChanged(): void {
    // URL 变化后重置图片错误状态，等待新的加载结果
    this.imageError = false
  }

  private getDisplayUrl(): string {
    return ServerConfig.toHttpUrl(ApiClient.BASE_URL, this.url)
  }

  build() {
    Column() {
      Text('营业执照')
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')

      if (this.url) {
        Row({ space: AppSpacing.SM }) {
          Image(this.getDisplayUrl())
            .width(72)
            .height(54)
            .objectFit(ImageFit.Cover)
            .borderRadius(AppRadius.SM)
            .alt($r('sys.symbol.picture'))
            .onError(() => {
              this.imageError = true
            })

          Column() {
            Text('营业执照')
              .fontSize(AppFontSize.SM)
              .fontColor(this.imageError ? AppColors.DANGER : AppColors.TEXT_PRIMARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
            if (this.imageError) {
              Text('图片加载失败，请检查网络或重新上传')
                .fontSize(AppFontSize.XXS)
                .fontColor(AppColors.DANGER)
                .margin({ top: AppSpacing.XS })
                .width('100%')
            } else {
              Text('请上传 JPG、JPEG、PNG 或 WebP 图片，不超过 5MB')
                .fontSize(AppFontSize.XXS)
                .fontColor(AppColors.TEXT_MUTED)
                .margin({ top: AppSpacing.XS })
                .width('100%')
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button('预览', { type: ButtonType.Capsule })
            .height(AppSpacing.BUTTON_HEIGHT_MINI)
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.PRIMARY)
            .backgroundColor(AppColors.SELECTED_BG)
            .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
            .onClick(() => {
              this.onPreview?.()
            })

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
        .margin({ top: AppSpacing.XS })
        .alignItems(VerticalAlign.Center)
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
            Text('请上传 JPG、JPEG、PNG 或 WebP 图片，不超过 5MB')
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
