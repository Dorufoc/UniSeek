// 聊天会话列表页 - 招聘方端
// 参考微信/QQ/钉钉等即时通讯工具，采用清晰的头像 + 两行信息卡片式列表。

import { ChatService } from '../../../services/ChatService';
import { ChatSessionVO } from '../../../services/ChatTypes';
import { ChatWebSocketService } from '../../../services/ChatWebSocketService';
import { AppColors, AppFontSize, AppSpacing } from '../../../common/AppStyles';
import { ChatSessionList } from '../../../components/chat/ChatSessionList';

@Component
export struct RecruiterChatTab {
  @State sessions: ChatSessionVO[] = []
  @State isLoading: boolean = true
  @State errorText: string = ''

  aboutToAppear(): void {
    // 注册新消息回调，收到推送时刷新会话列表
    ChatWebSocketService.getInstance().connect()
    ChatWebSocketService.getInstance().setOnSessionMessageCallback(() => {
      this.loadSessions()
    })
    this.loadSessions()
  }

  aboutToDisappear(): void {
    ChatWebSocketService.getInstance().removeOnSessionMessageCallback()
  }

  onPageShow(): void {
    this.loadSessions()
  }

  private loadSessions(): void {
    this.isLoading = true
    this.errorText = ''
    ChatService.getSessions().then((list: ChatSessionVO[]): void => {
      this.sessions = list || []
      this.isLoading = false
    }).catch((): void => {
      this.sessions = []
      this.errorText = '会话列表加载失败，请检查网络后重试'
      this.isLoading = false
    })
  }

  private navigateToDetail(session: ChatSessionVO): void {
    try {
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/ChatDetailPage',
        params: {
          applicationId: session.applicationId,
          counterpartName: session.counterpartName,
          counterpartAvatar: session.counterpartAvatar
        }
      })
    } catch (err) {
      console.error('跳转聊天详情失败: ' + String(err))
    }
  }

  build() {
    Column() {
      // 页面标题栏
      Row() {
        Text('消息')
          .fontSize(AppFontSize.XL)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
      }
      .width('100%')
      .height(AppSpacing.BUTTON_HEIGHT_MD)
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      ChatSessionList({
        sessions: this.sessions,
        isLoading: this.isLoading,
        errorText: this.errorText,
        counterpartTag: '求职者',
        onRetry: () => { this.loadSessions() },
        onItemClick: (session: ChatSessionVO) => { this.navigateToDetail(session) }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
