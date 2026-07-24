import { HomePage } from './tab/seeker/HomePage'
import { ChatPage } from './tab/seeker/ChatPage'
import { ProfilePage } from './tab/seeker/ProfilePage'
import { CompanyDiscovery } from './CompanyPage'
import { AppFontSize, AppSpacing } from '../common/AppStyles';
import { ChatWebSocketService } from '../services/ChatWebSocketService'

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0
  @State totalUnreadCount: number = 0

  private unreadCountCallback: (count: number) => void = (count: number) => {
    this.totalUnreadCount = count
  }

  aboutToAppear(): void {
    // 注册未读数监听并建立 WebSocket，连接成功后由服务端推送事件驱动刷新
    ChatWebSocketService.getInstance().addOnUnreadCountChanged(this.unreadCountCallback)
    ChatWebSocketService.getInstance().connect()
    ChatWebSocketService.getInstance().refreshUnreadCount()
  }

  aboutToDisappear(): void {
    ChatWebSocketService.getInstance().removeOnUnreadCountChanged(this.unreadCountCallback)
    ChatWebSocketService.getInstance().disconnect()
  }

  onPageShow(): void {
    // 从聊天详情等子页面返回时兜底刷新一次
    ChatWebSocketService.getInstance().refreshUnreadCount()
  }

  @Builder tabHome() {
    this.tabItem('首页', $r('sys.symbol.house'), 0)
  }

  @Builder tabCompany() {
    this.tabItem('企业', $r('sys.symbol.building'), 1)
  }

  @Builder tabChat() {
    Column() {
      if (this.totalUnreadCount > 0) {
        Badge({
          value: this.totalUnreadCount.toString(),
          position: BadgePosition.RightTop,
          style: {
            badgeSize: 16,
            badgeColor: '#FF4D4F',
            fontSize: 10
          }
        }) {
          SymbolGlyph($r('sys.symbol.message'))
            .fontSize(AppFontSize.XXL)
            .fontColor([this.currentIndex === 2 ? $r('sys.color.brand') : $r('sys.color.icon_tertiary')])
            .symbolEffect(new BounceSymbolEffect(EffectScope.WHOLE, EffectDirection.DOWN), this.currentIndex === 2)
        }
      } else {
        SymbolGlyph($r('sys.symbol.message'))
          .fontSize(AppFontSize.XXL)
          .fontColor([this.currentIndex === 2 ? $r('sys.color.brand') : $r('sys.color.icon_tertiary')])
          .symbolEffect(new BounceSymbolEffect(EffectScope.WHOLE, EffectDirection.DOWN), this.currentIndex === 2)
      }

      Text('聊天')
        .fontSize(AppFontSize.XXS)
        .fontColor(this.currentIndex === 2 ? $r('sys.color.brand') : $r('sys.color.icon_tertiary'))
        .margin({ top: 4 })
    }
    .width('100%')
    .height(AppSpacing.BOTTOM_ACTION_HEIGHT)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .accessibilityText('聊天')
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
      if (index === 2) {
        // 切换到聊天 Tab 时主动刷新一次未读数
        ChatWebSocketService.getInstance().refreshUnreadCount()
      }
    })
    .width('100%')
    .height('100%')
  }
}
