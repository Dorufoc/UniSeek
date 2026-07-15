import { router } from '@kit.ArkUI';
import { ChatService } from '../../../services/ChatService';
import { ChatSessionVO } from '../../../services/ChatTypes';

@Component
export struct RecruiterChatTab {
  @State sessions: ChatSessionVO[] = []

  aboutToAppear(): void {
    ChatService.getSessions().then((list: ChatSessionVO[]) => {
      this.sessions = list
    })
  }

  build() {
    Column() {
      Text('消息')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width('100%')
        .padding({ left: 16, top: 12, bottom: 8 })

      if (this.sessions.length === 0) {
        Column() {
          Text('暂无会话')
            .fontSize(16)
            .fontColor('#999999')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.sessions, (session: ChatSessionVO) => {
            ListItem() {
              RecruiterSessionItem({ session: session })
            }
          }, (session: ChatSessionVO) => session.applicationId.toString())
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}

@Component
struct RecruiterSessionItem {
  session: ChatSessionVO = { applicationId: 0, taskId: 0, taskTitle: '', taskStatus: 0, applicationStatus: 0, counterpartId: 0, counterpartName: '', counterpartAvatar: '', lastMessage: '', lastMessageTime: '', unreadCount: 0 }

  build() {
    Row() {
      Image(this.session.counterpartAvatar ? this.session.counterpartAvatar : $r('app.media.theme'))
        .width(48)
        .height(48)
        .borderRadius(24)
        .margin({ right: 12 })

      Column() {
        Row() {
          Text(this.session.counterpartName)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .layoutWeight(1)

          Text(this.session.lastMessageTime)
            .fontSize(12)
            .fontColor('#999999')
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Row() {
          Text(this.session.lastMessage)
            .fontSize(14)
            .fontColor('#666666')
            .lineHeight(20)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (this.session.unreadCount > 0) {
            Text(this.session.unreadCount.toString())
              .fontSize(11)
              .fontColor('#FFFFFF')
              .backgroundColor('#FF4444')
              .borderRadius(10)
              .width(20)
              .height(20)
              .textAlign(TextAlign.Center)
              .margin({ left: 6 })
          } else {
            Row().width(20).height(20).margin({ left: 6 })
          }
        }
        .width('100%')
        .margin({ top: 4 })
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($r('app.media.right_arrow'))
        .width(16)
        .height(16)
        .fillColor('#CCCCCC')
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      router.pushUrl({
        url: 'pages/ChatDetailPage',
        params: {
          applicationId: this.session.applicationId,
          counterpartName: this.session.counterpartName,
          counterpartAvatar: this.session.counterpartAvatar
        }
      })
    })
  }
}
