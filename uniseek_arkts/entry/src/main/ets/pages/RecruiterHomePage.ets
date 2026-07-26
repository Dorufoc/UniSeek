import { RecruiterHomeTab } from './tab/recruiter/RecruiterHomeTab'
import { RecruiterChatTab } from './tab/recruiter/RecruiterChatTab'
import { RecruiterProfileTab } from './tab/recruiter/RecruiterProfileTab'
import { AppFontSize, AppSpacing } from '../common/AppStyles';

@Entry
@Component
struct RecruiterHomePage {
  @State currentIndex: number = 0
  // 用于通知我的 Tab 页刷新数据
  @State profileRefreshTrigger: number = 0

  @Builder tabHome() {
    this.tabItem('首页', $r('sys.symbol.house'), 0)
  }

  @Builder tabChat() {
    this.tabItem('消息', $r('sys.symbol.message'), 1)
  }

  @Builder tabProfile() {
    this.tabItem('我的', $r('sys.symbol.person'), 2)
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
        RecruiterHomeTab()
      }
      .tabBar(this.tabHome)

      TabContent() {
        RecruiterChatTab()
      }
      .tabBar(this.tabChat)

      TabContent() {
        RecruiterProfileTab({ refreshTrigger: this.profileRefreshTrigger })
      }
      .tabBar(this.tabProfile)
    }
    .animationDuration(200)
    .scrollable(false)
    .onChange((index: number) => {
      this.currentIndex = index
      // 切换到我的 Tab 时，触发 RecruiterProfileTab 刷新数据
      if (index === 2) {
        this.profileRefreshTrigger++
      }
    })
    .width('100%')
    .height('100%')
  }

  onPageShow(): void {
    // 从子页面返回时，如果当前在我的 Tab，触发刷新
    if (this.currentIndex === 2) {
      this.profileRefreshTrigger++
    }
  }
}
