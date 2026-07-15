import { router } from '@kit.ArkUI';
import { ChatService } from '../services/ChatService';
import { ChatMessageVO } from '../services/ChatTypes';

@Entry
@Component
struct ChatDetailPage {
  @State messages: ChatMessageVO[] = []
  @State inputText: string = ''
  @State counterpartName: string = ''
  @State counterpartAvatar: string = ''
  @State applicationId: number = 0

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>
    this.counterpartName = params['counterpartName'] as string
    this.counterpartAvatar = params['counterpartAvatar'] as string
    this.applicationId = params['applicationId'] as number

    ChatService.getMessages(this.applicationId).then((msgs) => {
      this.messages = msgs
    })
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.left_arrow'))
          .width(24)
          .height(24)
          .fillColor('#333333')
          .onClick(() => { router.back() })
        Text(this.counterpartName)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 24 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          ForEach(this.messages, (msg: ChatMessageVO) => {
            if (msg.senderId === 0) {
              this.myMessageItem(msg)
            } else {
              this.otherMessageItem(msg)
            }
          }, (msg: ChatMessageVO) => msg.id.toString())
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      }
      .layoutWeight(1)
      .width('100%')

      Row() {
        TextInput({ placeholder: '输入消息...', text: this.inputText })
          .onChange((value: string) => {
            this.inputText = value
          })
          .layoutWeight(1)
          .height(40)
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .padding({ left: 16 })

        Button('发送')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .borderRadius(20)
          .height(40)
          .padding({ left: 20, right: 20 })
          .margin({ left: 8 })
          .onClick(() => {
            this.handleSend()
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }

  @Builder myMessageItem(msg: ChatMessageVO) {
    Column() {
      Text(msg.content)
        .fontSize(15)
        .fontColor('#FFFFFF')
        .backgroundColor('#007AFF')
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .maxLines(100)
      Text(msg.sendTime)
        .fontSize(11)
        .fontColor('#999999')
        .margin({ top: 4 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.End)
    .margin({ bottom: 12 })
  }

  @Builder otherMessageItem(msg: ChatMessageVO) {
    Row() {
      Image(this.counterpartAvatar ? this.counterpartAvatar : $r('app.media.theme'))
        .width(36)
        .height(36)
        .borderRadius(18)
        .margin({ right: 10 })

      Column() {
        Text(msg.content)
          .fontSize(15)
          .fontColor('#333333')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .maxLines(100)
        Text(msg.sendTime)
          .fontSize(11)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .margin({ bottom: 12 })
  }

  handleSend() {
    const text = this.inputText.trim()
    if (!text) {
      return
    }
    this.inputText = ''

    ChatService.sendMessage(this.applicationId, text).then((msg) => {
      if (msg) {
        this.messages.push(msg)
      }
    })
  }
}
