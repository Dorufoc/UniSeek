import { RecruiterHomeTab } from './tab/recruiter/RecruiterHomeTab'
import { RecruiterChatTab } from './tab/recruiter/RecruiterChatTab'
import { RecruiterProfileTab } from './tab/recruiter/RecruiterProfileTab'

@Entry
@Component
struct RecruiterHomePage {
  @State currentIndex: number = 0

  @Builder tabHome() {
    this.tabItem('首页', $r('app.media.home'), 0)
  }

  @Builder tabChat() {
    this.tabItem('消息', $r('app.media.chat'), 1)
  }

  @Builder tabProfile() {
    this.tabItem('我的', $r('app.media.mine'), 2)
  }

  @Builder tabItem(label: string, icon: Resource, index: number) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === index ? '#007AFF' : '#999999')
      Text(label)
        .fontSize(10)
        .fontColor(this.currentIndex === index ? '#007AFF' : '#999999')
        .margin({ top: 4 })
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        RecruiterHomeTab()
      }
      .tabBar(this.tabHome)

      TabContent() {
        RecruiterChatTab()
      }
      .tabBar(this.tabChat)

      TabContent() {
        RecruiterProfileTab()
      }
      .tabBar(this.tabProfile)
    }
    .animationDuration(0)
    .scrollable(false)
    .onChange((index: number) => {
      this.currentIndex = index
    })
    .width('100%')
    .height('100%')
  }
}
