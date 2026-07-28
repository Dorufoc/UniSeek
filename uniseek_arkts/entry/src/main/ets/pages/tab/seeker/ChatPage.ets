// 聊天会话列表页 - 求职者端
// 参考微信/QQ/钉钉等即时通讯工具，采用清晰的头像 + 两行信息卡片式列表。

import { ChatService } from '../../../services/ChatService';
import { ChatSessionVO } from '../../../services/ChatTypes';
import { ChatWebSocketService, WsNewMessageData } from '../../../services/ChatWebSocketService';
import { AppColors, AppFontSize, AppSpacing } from '../../../common/AppStyles';
import { ChatSessionList } from '../../../components/chat/ChatSessionList';

@Component
export struct ChatPage {
  @State sessions: ChatSessionVO[] = []
  @State isLoading: boolean = true
  @State isRefreshing: boolean = false
  @State errorText: string = ''

  // 本组件 WebSocket 监听器的唯一标识，避免与招聘方消息列表互相覆盖
  private readonly pageListenerId: string = 'chat_list_seeker_' + Date.now().toString()

  aboutToAppear(): void {
    // 注册新消息回调，收到推送时实时更新会话列表
    ChatWebSocketService.getInstance().connect()
    ChatWebSocketService.getInstance().addSessionMessageListener(this.pageListenerId, (data: WsNewMessageData) => {
      this.handleNewMessage(data)
    })
    this.loadSessions()
  }

  aboutToDisappear(): void {
    ChatWebSocketService.getInstance().removeSessionMessageListener(this.pageListenerId)
  }

  onPageShow(): void {
    this.loadSessions()
  }

  private async loadSessions(): Promise<void> {
    this.isLoading = true
    this.errorText = ''
    try {
      const list: ChatSessionVO[] = await ChatService.getSessions()
      this.sessions = (list || []).sort((a: ChatSessionVO, b: ChatSessionVO): number =>
        new Date(b.lastMessageTime).getTime() - new Date(a.lastMessageTime).getTime()
      )
    } catch {
      this.sessions = []
      this.errorText = '会话列表加载失败，请检查网络后重试'
    } finally {
      this.isLoading = false
    }
  }

  private async refreshSessions(): Promise<void> {
    if (this.isLoading || this.isRefreshing) {
      return
    }
    this.isRefreshing = true
    try {
      await this.loadSessions()
    } finally {
      this.isRefreshing = false
    }
  }

  private handleNewMessage(data: WsNewMessageData): void {
    const idx: number = this.sessions.findIndex((s: ChatSessionVO): boolean =>
      s.applicationId === data.applicationId
    )
    if (idx >= 0) {
      let preview: string = data.content
      if (data.messageType === 1) {
        preview = '[图片]'
      } else if (data.messageType === 2) {
        preview = '[文件]'
      }
      const original = this.sessions[idx]
      const updated: ChatSessionVO = {
        applicationId: original.applicationId,
        taskId: original.taskId,
        taskTitle: original.taskTitle,
        taskStatus: original.taskStatus,
        applicationStatus: original.applicationStatus,
        counterpartId: original.counterpartId,
        counterpartName: original.counterpartName,
        counterpartAvatar: original.counterpartAvatar,
        counterpartCompany: original.counterpartCompany,
        enterpriseId: original.enterpriseId,
        canSend: original.canSend,
        lastMessage: preview,
        lastMessageTime: data.sendTime,
        unreadCount: original.unreadCount + 1
      }
      const sorted: ChatSessionVO[] = [...this.sessions]
      sorted[idx] = updated
      sorted.sort((a: ChatSessionVO, b: ChatSessionVO): number =>
        new Date(b.lastMessageTime).getTime() - new Date(a.lastMessageTime).getTime()
      )
      this.sessions = sorted
    } else {
      this.loadSessions()
    }
  }

  private navigateToDetail(session: ChatSessionVO): void {
    if (session.unreadCount > 0) {
      session.unreadCount = 0
      // 重新赋值触发 @State 刷新，红点立即消失
      this.sessions = [...this.sessions]
      // 异步同步后端已读，失败不影响本地体验
      ChatService.markSessionRead(session.applicationId).catch((err: Error) => {
        console.error('标记会话已读失败: ' + String(err))
      })
    }

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
        refreshing: this.isRefreshing,
        errorText: this.errorText,
        onRefresh: () => { this.refreshSessions() },
        counterpartTag: '招聘方',
        onRetry: () => { this.loadSessions() },
        onItemClick: (session: ChatSessionVO) => { this.navigateToDetail(session) }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
