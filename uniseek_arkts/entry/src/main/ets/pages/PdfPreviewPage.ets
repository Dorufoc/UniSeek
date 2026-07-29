import { webview } from '@kit.ArkWeb'
import { ChatService } from '../services/ChatService'
import { AppColors, AppFontSize, AppSpacing } from '../common/AppStyles'
import { NavBar } from '../common/NavBar'

@Entry
@Component
struct PdfPreviewPage {
  @State private localPdfPath: string = ''
  @State private loadError: string = ''
  @State private isLoading: boolean = true
  private readonly webController: webview.WebviewController = new webview.WebviewController()

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>
    const attachmentUrl: string = params && params['attachmentUrl'] ? params['attachmentUrl'] : ''
    if (!attachmentUrl) {
      this.loadError = '附件地址为空'
      this.isLoading = false
      return
    }
    ChatService.downloadAttachment(attachmentUrl).then((path: string) => {
      this.localPdfPath = path
      this.isLoading = false
    }).catch(() => {
      this.loadError = '附件下载失败，请检查网络后重试'
      this.isLoading = false
    })
  }

  build() {
    Column() {
      NavBar({ title: '简历附件', showBack: true })
      if (this.isLoading) {
        Column({ space: AppSpacing.SM }) {
          LoadingProgress()
            .width(AppSpacing.ICON_MD)
            .height(AppSpacing.ICON_MD)
            .color(AppColors.PRIMARY)
          Text('正在加载简历附件...')
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
          Button('返回')
            .onClick(() => { this.getUIContext().getRouter().back() })
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Web({
          src: this.localPdfPath,
          controller: this.webController
        })
          .fileAccess(true)
          .domStorageAccess(true)
          .width('100%')
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
