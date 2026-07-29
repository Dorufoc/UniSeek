import { RecruiterHomeTab } from './tab/recruiter/RecruiterHomeTab'
import { RecruiterChatTab } from './tab/recruiter/RecruiterChatTab'
import { RecruiterProfileTab } from './tab/recruiter/RecruiterProfileTab'
import { AppFontSize, AppSpacing } from '../common/AppStyles';

@Entry
@Component
struct RecruiterHomePage {
  @State currentIndex: number = 0

  aboutToAppear(): void {
    // 确保个人页监听 key 在组件创建前存在默认值
    AppStorage.setOrCreate<number>('profileRefreshTrigger', 0)
    AppStorage.setOrCreate<number>('recruiterHomeRefreshTrigger', 0)
  }

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
      if (index === 0) {
        AppStorage.setOrCreate<number>('recruiterHomeRefreshTrigger', Date.now())
      }
      // 切换到我的 Tab 时，无条件触发个人资料刷新信号
      if (index === 2) {
        AppStorage.setOrCreate<number>('profileRefreshTrigger', Date.now())
      }
    })
    .width('100%')
    .height('100%')
  }

  onPageShow(): void {
    // 从子页面返回时刷新招聘首页的统计和待办数据
    AppStorage.setOrCreate<number>('recruiterHomeRefreshTrigger', Date.now())
    // 从子页面返回时，无条件触发个人资料刷新信号
    AppStorage.setOrCreate<number>('profileRefreshTrigger', Date.now())
  }
}
