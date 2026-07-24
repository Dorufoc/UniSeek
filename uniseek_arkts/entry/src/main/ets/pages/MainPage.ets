import { HomePage } from './tab/seeker/HomePage'
import { ChatPage } from './tab/seeker/ChatPage'
import { ProfilePage } from './tab/seeker/ProfilePage'
import { CompanyDiscovery } from './CompanyPage'
import { AppFontSize, AppSpacing } from '../common/AppStyles';

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0

  @Builder tabHome() {
    this.tabItem('首页', $r('sys.symbol.house'), 0)
  }

  @Builder tabCompany() {
    this.tabItem('企业', $r('sys.symbol.building'), 1)
  }

  @Builder tabChat() {
    this.tabItem('聊天', $r('sys.symbol.message'), 2)
  }

  @Builder tabProfile() {
    this.tabItem('我的', $r('sys.symbol.person'), 3)
  }

  @Builder tabItem(label: string, icon: Resource, index: number) {
    Column() {
      SymbolGlyph(icon)
        .fontSize(AppFontSize.XXL)
        .fontColor([this.currentIndex === index ? $r('sys.color.brand') : $r('sys.color.icon_tertiary')])
        .symbolEffect(new BounceSymbolEffect(EffectScope.WHOLE, EffectDirection.DOWN), this.currentIndex === index)
      Text(label)
        .fontSize(AppFontSize.XXS)
        .fontColor(this.currentIndex === index ? $r('sys.color.brand') : $r('sys.color.icon_tertiary'))
        .margin({ top: 4 })
    }
    .width('100%')
    .height(AppSpacing.BOTTOM_ACTION_HEIGHT)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .accessibilityText(label)
  }

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        HomePage()
      }
      .tabBar(this.tabHome)

      TabContent() {
        CompanyDiscovery({ showBack: false })
      }
      .tabBar(this.tabCompany)

      TabContent() {
        ChatPage()
      }
      .tabBar(this.tabChat)

      TabContent() {
        ProfilePage()
      }
      .tabBar(this.tabProfile)
    }
    .animationDuration(200)
    .scrollable(false)
    .onChange((index: number) => {
      this.currentIndex = index
    })
    .width('100%')
    .height('100%')
  }
}
