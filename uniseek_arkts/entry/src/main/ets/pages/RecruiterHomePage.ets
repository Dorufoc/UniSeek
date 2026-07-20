import { RecruiterHomeTab } from './tab/recruiter/RecruiterHomeTab'
import { RecruiterChatTab } from './tab/recruiter/RecruiterChatTab'
import { RecruiterProfileTab } from './tab/recruiter/RecruiterProfileTab'
import { AppColors } from '../common/AppStyles';
import { router } from '@kit.ArkUI';

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
