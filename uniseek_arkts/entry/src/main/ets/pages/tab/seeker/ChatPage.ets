// 聊天会话列表页 - 求职者端
// 对齐 Vue Messages.vue 左侧会话列表面板样式

import { router } from '@kit.ArkUI';
import { ChatService } from '../../../services/ChatService';
import { ChatSessionVO } from '../../../services/ChatTypes';
import { ChatWebSocketService } from '../../../services/ChatWebSocketService';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../../../common/AppStyles';

@Component
export struct ChatPage {
  @State sessions: ChatSessionVO[] = []
  @State selectedSessionId: number = -1
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
    this.selectedSessionId = -1
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

  // 格式化会话时间：当天显示 HH:mm，昨天显示"昨天"，更早显示 MM-DD
  formatSessionTime(dateStr: string): string {
    if (!dateStr) {
      return ''
    }
    const d: Date = new Date(dateStr)
    const now: Date = new Date()
    const diff: number = now.getTime() - d.getTime()
    const oneDay: number = 86400000
    if (diff < oneDay && diff >= 0) {
      return dateStr.substring(11, 16) // HH:mm
    }
    if (diff < 2 * oneDay && diff >= 0) {
      return '昨天'
    }
    return dateStr.substring(5, 10) // MM-DD
  }

  // 格式化未读数：超过 99 显示 99+
  formatUnreadCount(count: number): string {
    if (count > 99) {
      return '99+'
    }
    return count.toString()
  }

  build() {
    Column() {
      Text('消息')
        .fontSize(AppFontSize.XL)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')
        .padding({ left: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.XS })

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(32).height(32).color(AppColors.PRIMARY)
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.errorText) {
        this.errorState()
      } else if (this.sessions.length === 0) {
        this.emptyState()
      } else {
        List() {
          ForEach(this.sessions, (session: ChatSessionVO) => {
            ListItem() {
              this.sessionItem(session)
            }
            .transition({ opacity: 0, translate: { y: 12 } })
          }, (session: ChatSessionVO) => session.applicationId.toString())
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_CARD)
  }

  // 空状态保持安静，避免无业务意义的循环动效分散注意力
  @Builder emptyState() {
    Column() {
      SymbolGlyph($r('sys.symbol.message'))
        .fontSize(48)
        .fontColor([AppColors.TEXT_MUTED])


      Text('暂无会话')
        .fontSize(14)
        .fontColor(AppColors.TEXT_MUTED)
        .margin({ top: AppSpacing.MD })
    }
    .width('100%')
    .padding(80)
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder errorState() {
    Column({ space: AppSpacing.SM }) {
      Text(this.errorText).fontSize(AppFontSize.SM).fontColor(AppColors.TEXT_SECONDARY)
      Button('重新加载', { type: ButtonType.Capsule })
        .height(40)
        .fontSize(AppFontSize.SM)
        .fontColor('#FFFFFF')
        .backgroundColor(AppColors.PRIMARY)
        .onClick((): void => { this.loadSessions() })
    }
    .layoutWeight(1)
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // 会话项构建器：包含选中态装饰线、公司标签、时间格式化、未读红点
  @Builder sessionItem(session: ChatSessionVO) {
    Stack() {
      // 选中态背景（始终渲染，通过透明度控制 200ms 过渡）
      Row()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.SELECTED_BG)
        .borderRadius(AppRadius.XL)
        .opacity(session.applicationId === this.selectedSessionId ? 1 : 0)
        .animation({ duration: 180 })

      // 主内容区域
      Row() {
        // 头像
        Image(session.counterpartAvatar ? session.counterpartAvatar : $r('app.media.theme'))
          .width(48)
          .height(48)
          .borderRadius(AppRadius.FULL)
          .margin({ right: AppSpacing.SM })

        Column() {
          // 第一行：对端名称 + 公司标签 + 时间
          Row() {
            Row() {
              Text(session.counterpartName)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppColors.TEXT_PRIMARY)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              // 公司标签：@公司名，蓝色，hover 下划线
              if (session.counterpartCompany) {
                Text('@' + session.counterpartCompany)
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(AppColors.PRIMARY)
                  .margin({ left: 4 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  // hover 效果（运行时无鼠标交互，暂不启用）
              }
            }
            .layoutWeight(1)
            .alignItems(VerticalAlign.Center)

            // 格式化后的时间
            Text(this.formatSessionTime(session.lastMessageTime))
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.TEXT_MUTED)
              .fontWeight(FontWeight.Medium)
              .flexShrink(0)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 第二行：消息预览 + 未读红点
          Row() {
            Text(session.lastMessage)
              .fontSize(13.5)
              .fontColor(AppColors.TEXT_SECONDARY)
              .lineHeight(20)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)

            // 未读红点：渐变背景 + 呼吸动画
            if (session.unreadCount > 0) {
              Text(this.formatUnreadCount(session.unreadCount))
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFFFFF')
                .textAlign(TextAlign.Center)
                .padding({ left: 6, right: 6 })
                .height(20)
                .borderRadius(10)
                .backgroundColor(AppColors.DANGER)
                .margin({ left: AppSpacing.XS })
            }
          }
          .width('100%')
          .margin({ top: AppSpacing.XS })
          .alignItems(VerticalAlign.Center)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 右侧箭头
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(AppFontSize.MD)
          .fontColor([AppColors.TEXT_MUTED])
          .margin({ left: AppSpacing.XS })
      }
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.SM })
      .alignItems(VerticalAlign.Center)

      // 选中态蓝色竖条，作为列表当前项的轻量提示
      Column() {
        Column()
          .width(3)
          .height(24)
          .borderRadius({ topRight: 3, bottomRight: 3 })
          .backgroundColor(AppColors.PRIMARY)
      }
      .width(3)
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .position({ x: 0 })
      .opacity(session.applicationId === this.selectedSessionId ? 1 : 0)
      .animation({ duration: 180 })
    }
    .width('100%')
    .onClick(() => {
      this.selectedSessionId = session.applicationId
      router.pushUrl({
        url: 'pages/ChatDetailPage',
        params: {
          applicationId: session.applicationId,
          counterpartName: session.counterpartName,
          counterpartAvatar: session.counterpartAvatar
        }
      })
    })
    .stateStyles({
      pressed: {
        .backgroundColor(AppColors.SELECTED_BG)
      }
    })
  }
}
