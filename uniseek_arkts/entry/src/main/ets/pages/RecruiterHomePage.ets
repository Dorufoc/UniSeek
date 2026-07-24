import { RecruiterHomeTab } from './tab/recruiter/RecruiterHomeTab'
import { RecruiterChatTab } from './tab/recruiter/RecruiterChatTab'
import { RecruiterProfileTab } from './tab/recruiter/RecruiterProfileTab'
import { AppFontSize, AppSpacing } from '../common/AppStyles';

@Entry
@Component
struct RecruiterHomePage {
  @State currentIndex: number = 0

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
        RecruiterProfileTab()
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
