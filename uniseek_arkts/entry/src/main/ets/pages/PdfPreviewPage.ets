import { ChatService } from '../services/ChatService'
import { AppColors, AppFontSize, AppSpacing } from '../common/AppStyles'
import { NavBar } from '../common/NavBar'

@Entry
@Component
struct PdfPreviewPage {
  @State private loadError: string = ''
  @State private isLoading: boolean = true
  @State private isPreviewStarted: boolean = false

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>
    const attachmentUrl: string = params && params['attachmentUrl'] ? params['attachmentUrl'] : ''
    if (!attachmentUrl) {
      this.loadError = '附件地址为空'
      this.isLoading = false
      return
    }
    void this.openPreview(attachmentUrl)
  }

  private async openPreview(attachmentUrl: string): Promise<void> {
    try {
      await ChatService.previewAttachment(attachmentUrl)
      this.isPreviewStarted = true
    } catch (error) {
      const message: string = error instanceof Error ? error.message : '附件预览失败'
      this.loadError = message
    } finally {
      this.isLoading = false
    }
  }

  private goBack(): void {
    this.getUIContext().getRouter().back()
  }

  build() {
    Column() {
      NavBar({ title: '简历附件', showBack: true, onBack: () => this.goBack() })
      if (this.isLoading) {
        Column({ space: AppSpacing.SM }) {
          LoadingProgress()
            .width(AppSpacing.ICON_MD)
            .height(AppSpacing.ICON_MD)
            .color(AppColors.PRIMARY)
          Text('正在打开系统预览...')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.loadError) {
        Column({ space: AppSpacing.MD }) {
          Text(this.loadError)
            .fontSize(AppFontSize.MD)
            .fontColor(AppColors.TEXT_SECONDARY)
            .textAlign(TextAlign.Center)
          Button('返回')
            .onClick(() => this.goBack())
        }
        .layoutWeight(1)
        .width('100%')
        .padding(AppSpacing.MD)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.isPreviewStarted) {
        Column({ space: AppSpacing.MD }) {
          Text('系统预览已打开')
            .fontSize(AppFontSize.MD)
            .fontColor(AppColors.TEXT_PRIMARY)
          Text('关闭系统预览后，可点击返回回到上一页')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
            .textAlign(TextAlign.Center)
          Button('返回')
            .onClick(() => this.goBack())
        }
        .layoutWeight(1)
        .width('100%')
        .padding(AppSpacing.MD)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
