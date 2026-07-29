import { pdfService, pdfViewManager, PdfView } from '@kit.PDFKit'
import { fileIo, picker } from '@kit.CoreFileKit'
import { ChatService } from '../services/ChatService'
import { AppColors, AppFontSize, AppSpacing } from '../common/AppStyles'
import { NavBar } from '../common/NavBar'

@Entry
@Component
struct PdfPreviewPage {
  @State private loadError: string = ''
  @State private isLoading: boolean = true
  @State private useFallback: boolean = false
  @State private isSaving: boolean = false
  private pdfController: pdfViewManager.PdfController = new pdfViewManager.PdfController()
  private localFilePath: string = ''

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>
    const attachmentUrl: string = params && params['attachmentUrl'] ? params['attachmentUrl'] : ''
    if (!attachmentUrl) {
      this.loadError = '附件地址为空'
      this.isLoading = false
      return
    }
    void this.loadPdf(attachmentUrl)
  }

  private async loadPdf(url: string): Promise<void> {
    try {
      const localPath: string = await ChatService.downloadAttachment(url)
      this.localFilePath = localPath
      const result: pdfService.ParseResult = await this.pdfController.loadDocument(localPath)
      if (result !== pdfService.ParseResult.PARSE_SUCCESS) {
        this.loadError = 'PDF解析失败'
        this.isLoading = false
        return
      }
      this.isLoading = false
    } catch (error) {
      if (this.localFilePath) {
        this.useFallback = true
        this.isLoading = false
      } else {
        const message: string = error instanceof Error ? error.message : 'PDF加载失败'
        this.loadError = message
        this.isLoading = false
      }
    }
  }

  private async saveToFiles(): Promise<void> {
    if (!this.localFilePath) {
      return
    }
    this.isSaving = true
    try {
      const documentPicker = new picker.DocumentViewPicker(getContext())
      const options: picker.DocumentSaveOptions = new picker.DocumentSaveOptions()
      options.newFileNames = ['简历.pdf']
      const uris: string[] = await documentPicker.save(options)
      if (uris.length === 0) {
        this.isSaving = false
        return
      }
      const destUri: string = uris[0]
      const srcFile = fileIo.openSync(this.localFilePath, fileIo.OpenMode.READ_ONLY)
      const destFile = fileIo.openSync(destUri, fileIo.OpenMode.WRITE_ONLY)
      const stat = fileIo.statSync(this.localFilePath)
      const totalSize = stat.size
      const buf = new ArrayBuffer(totalSize)
      fileIo.readSync(srcFile.fd, buf)
      fileIo.writeSync(destFile.fd, buf)
      fileIo.closeSync(srcFile)
      fileIo.closeSync(destFile)
      this.getUIContext().getPromptAction().showToast({ message: '文件已保存成功' })
    } catch (e) {
      this.getUIContext().getPromptAction().showToast({ message: '保存失败，请重试' })
    } finally {
      this.isSaving = false
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
          Text('正在加载PDF...')
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
      } else if (this.useFallback) {
        Column({ space: AppSpacing.MD }) {
          Text('当前环境不支持PDF原生预览')
            .fontSize(AppFontSize.MD)
            .fontColor(AppColors.TEXT_SECONDARY)
            .textAlign(TextAlign.Center)
          Text('文件已下载完成，可保存至手机存储后查看')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
            .textAlign(TextAlign.Center)
          Button() {
            if (this.isSaving) {
              LoadingProgress()
                .width(AppSpacing.ICON_SM)
                .height(AppSpacing.ICON_SM)
                .color(Color.White)
            } else {
              Text('保存到文件')
                .fontColor(Color.White)
            }
          }
          .width('80%')
          .height(AppSpacing.BUTTON_HEIGHT_MD)
          .backgroundColor(AppColors.PRIMARY)
          .borderRadius(8)
          .onClick(() => {
            if (!this.isSaving) {
              void this.saveToFiles()
            }
          })
          Button('返回')
            .width('80%')
            .height(AppSpacing.BUTTON_HEIGHT_MD)
            .backgroundColor(AppColors.BG_CARD)
            .fontColor(AppColors.TEXT_PRIMARY)
            .borderRadius(8)
            .onClick(() => this.goBack())
        }
        .layoutWeight(1)
        .width('100%')
        .padding(AppSpacing.MD)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        PdfView({ controller: this.pdfController })
          .width('100%')
          .height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
