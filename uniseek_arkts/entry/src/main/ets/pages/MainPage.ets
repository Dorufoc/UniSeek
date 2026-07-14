import { HomePage } from './tab/HomePage'
import { ChatPage } from './tab/ChatPage'
import { ProfilePage } from './tab/ProfilePage'

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0

  @Builder tabHome() {
    this.tabItem('首页', $r('app.media.home'), 0)
  }

  @Builder tabChat() {
    this.tabItem('聊天', $r('app.media.communicate'), 1)
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
        HomePage()
      }
      .tabBar(this.tabHome)

      TabContent() {
        ChatPage()
      }
      .tabBar(this.tabChat)

      TabContent() {
        ProfilePage()
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
