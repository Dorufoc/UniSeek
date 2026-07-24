// AttachmentCard.ets — 简历/文件附件卡片组件

import { AppColors, AppFontSize, AppRadius, AppSpacing, AppChat } from '../../common/AppStyles';
import { getAttachmentName } from './ChatMessageUtils';

@Component
export struct AttachmentCard {
  @Prop url: string = '';
  @Prop isSelf: boolean = false;
  @Prop isHandling: boolean = false;
  onPreview?: () => void;
  onDownload?: () => void;

  build() {
    Column() {
      // 顶部信息区：文件图标 + 文件名 + 标签
      Row() {
        SymbolGlyph($r('sys.symbol.doc'))
          .fontSize(AppFontSize.XXL)
          .fontColor([AppColors.PRIMARY])
          .width(AppSpacing.BUTTON_HEIGHT)
          .height(AppSpacing.BUTTON_HEIGHT)

        Column() {
          Text(getAttachmentName(this.url))
            .fontSize(AppFontSize.LABEL)
            .fontColor(AppColors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text('简历附件')
            .fontSize(AppChat.ATTACHMENT_TAG_FONT)
            .fontColor(AppColors.TEXT_SECONDARY)
            .margin({ top: AppSpacing.XXS })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: AppSpacing.SM })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 操作按钮区：预览 / 下载
      Row() {
        Button() {
          Text(this.isHandling ? '处理中...' : '预览')
            .fontSize(AppChat.ATTACHMENT_BUTTON_FONT)
            .fontColor(AppColors.PRIMARY)
            .fontWeight(FontWeight.Medium)
        }
        .height(AppSpacing.BUTTON_HEIGHT_SM)
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
        .borderRadius(AppRadius.MD)
        .backgroundColor(AppColors.SELECTED_BG)
        .enabled(!this.isHandling)
        .onClick(() => {
          this.onPreview?.();
        })

        Button() {
          Text(this.isHandling ? '处理中...' : '下载')
            .fontSize(AppChat.ATTACHMENT_BUTTON_FONT)
            .fontColor(AppColors.PRIMARY)
            .fontWeight(FontWeight.Medium)
        }
        .height(AppSpacing.BUTTON_HEIGHT_SM)
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
        .borderRadius(AppRadius.MD)
        .backgroundColor(AppColors.SELECTED_BG)
        .margin({ left: AppSpacing.SM })
        .enabled(!this.isHandling)
        .onClick(() => {
          this.onDownload?.();
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .margin({ top: AppSpacing.SM_GAP })
    }
    .width('100%')
    .padding(AppSpacing.CARD_PADDING)
    .borderRadius({
      topLeft: this.isSelf ? AppRadius.BUBBLE : AppChat.BUBBLE_OTHER_SHARP_CORNER,
      topRight: this.isSelf ? AppChat.BUBBLE_SELF_SHARP_CORNER : AppRadius.BUBBLE,
      bottomLeft: AppRadius.BUBBLE,
      bottomRight: AppRadius.BUBBLE
    })
    .backgroundColor(AppColors.BG_CARD)
    .borderWidth(1)
    .borderColor(AppColors.BORDER)
  }
}
