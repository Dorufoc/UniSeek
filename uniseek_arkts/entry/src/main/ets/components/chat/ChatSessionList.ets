// 聊天会话列表包装组件
// 统一处理加载、错误、空状态，并以 HMOS List + 缩进分割线渲染会话项。

import { ChatSessionVO } from '../../services/ChatTypes';
import { AppColors, AppSpacing, AppChat } from '../../common/AppStyles';
import { EmptyView } from '../EmptyView';
import { ErrorView } from '../ErrorView';
import { ChatSessionItem } from './ChatSessionItem';

@Component
export struct ChatSessionList {
  @Prop sessions: ChatSessionVO[] = []
  @Prop isLoading: boolean = true
  @Prop errorText: string = ''
  @Prop counterpartTag: string = ''
  onRetry?: () => void
  onItemClick?: (session: ChatSessionVO) => void

  build() {
    if (this.isLoading) {
      Column() {
        LoadingProgress()
          .width(AppSpacing.ICON_MD)
          .height(AppSpacing.ICON_MD)
          .color(AppColors.PRIMARY)
      }
      .layoutWeight(1)
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else if (this.errorText) {
      ErrorView({
        message: this.errorText,
        retryText: '重新加载',
        onRetry: () => { this.onRetry?.() }
      })
        .width('100%')
        .layoutWeight(1)
    } else if (this.sessions.length === 0) {
      EmptyView({ message: '暂无会话', icon: $r('sys.symbol.message') })
        .width('100%')
        .layoutWeight(1)
    } else {
      List() {
        ForEach(
          this.sessions,
          (session: ChatSessionVO) => {
            ListItem() {
              ChatSessionItem({
                session: session,
                tagText: this.counterpartTag,
                onItemClick: () => {
                  this.onItemClick?.(session)
                }
              })
            }
            .transition({ opacity: 0, translate: { y: AppChat.LIST_ENTER_TRANSLATE_Y } })
          },
          (session: ChatSessionVO) => session.applicationId.toString()
        )
      }
      .layoutWeight(1)
      .width('100%')
      .listDirection(Axis.Vertical)
      .divider({
        strokeWidth: AppSpacing.DIVIDER_THICKNESS,
        color: AppColors.BORDER,
        startMargin: AppChat.SESSION_LIST_DIVIDER_INSET,
        endMargin: 0
      })
    }
  }
}
