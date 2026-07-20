import { HomePage } from './tab/seeker/HomePage'
import { ChatPage } from './tab/seeker/ChatPage'
import { ProfilePage } from './tab/seeker/ProfilePage'
import { AppColors } from '../common/AppStyles';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0

  @Builder tabHome() {
    this.tabItem('首页', $r('sys.symbol.house'), 0)
  }

  @Builder tabChat() {
    this.tabItem('聊天', $r('sys.symbol.message'), 1)
  }

  @Builder tabProfile() {
    this.tabItem('我的', $r('sys.symbol.person'), 2)
  }

  @Builder tabItem(label: string, icon: Resource, index: number) {
    Column() {
      SymbolGlyph(icon)
        .fontSize(24)
        .fontColor([this.currentIndex === index ? AppColors.PRIMARY : AppColors.TEXT_MUTED])
      Text(label)
        .fontSize(10)
        .fontColor(this.currentIndex === index ? AppColors.PRIMARY : AppColors.TEXT_MUTED)
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
