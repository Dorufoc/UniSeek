// 聊天会话列表页 - 招聘方端
// 对齐 Vue Messages.vue 左侧会话列表面板样式

import { router, curves } from '@kit.ArkUI';
import { ChatService } from '../../../services/ChatService';
import { ChatSessionVO } from '../../../services/ChatTypes';
import { ChatWebSocketService } from '../../../services/ChatWebSocketService';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../../../common/AppStyles';

@Component
export struct RecruiterChatTab {
  @State sessions: ChatSessionVO[] = []
  @State selectedSessionId: number = -1
  // 空状态图标浮动动画偏移量
  @State iconFloatY: number = 0
  // 未读红点呼吸动画缩放
  @State pulseScale: number = 1

  private floatInterval: number = -1
  private pulseInterval: number = -1

  aboutToAppear(): void {
    this.startAnimations()
    // 注册新消息回调，收到推送时刷新会话列表
    ChatWebSocketService.getInstance().setOnNewMessageCallback(() => {
      ChatService.getSessions().then((list: ChatSessionVO[]) => {
        this.sessions = list
      })
    })
  }

  aboutToDisappear(): void {
    this.stopAnimations()
    ChatWebSocketService.getInstance().removeOnNewMessageCallback()
  }

  onPageShow(): void {
    this.selectedSessionId = -1
    ChatService.getSessions().then((list: ChatSessionVO[]) => {
      this.sessions = list
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

  // 启动动画
  startAnimations(): void {
    // 空状态图标浮动动画（3s 周期，上下浮动 8px）
    this.floatInterval = setInterval(() => {
      animateTo({ duration: 1500, curve: curves.cubicBezier(0.4, 0, 0.2, 1) }, () => {
        this.iconFloatY = -8
      })
      setTimeout(() => {
        animateTo({ duration: 1500, curve: curves.cubicBezier(0.4, 0, 0.2, 1) }, () => {
          this.iconFloatY = 0
        })
      }, 1500)
    }, 3000)

    // 未读红点呼吸动画（2s 周期，scale 1 ↔ 1.05）
    this.pulseInterval = setInterval(() => {
      animateTo({ duration: 1000, curve: curves.cubicBezier(0.4, 0, 0.2, 1) }, () => {
        this.pulseScale = 1.05
      })
      setTimeout(() => {
        animateTo({ duration: 1000, curve: curves.cubicBezier(0.4, 0, 0.2, 1) }, () => {
          this.pulseScale = 1
        })
      }, 1000)
    }, 2000)
  }

  // 停止动画
  stopAnimations(): void {
    if (this.floatInterval > -1) {
      clearInterval(this.floatInterval)
      this.floatInterval = -1
    }
    if (this.pulseInterval > -1) {
      clearInterval(this.pulseInterval)
      this.pulseInterval = -1
    }
  }

  build() {
    Column() {
      Text('消息')
        .fontSize(AppFontSize.XL)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')
        .padding({ left: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.XS })

      if (this.sessions.length === 0) {
        this.emptyState()
      } else {
        List() {
          ForEach(this.sessions, (session: ChatSessionVO) => {
            ListItem() {
              this.sessionItem(session)
            }
            .transition({ opacity: 0, translate: { y: 20 } })
            .transition({ opacity: 1 })
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

  // 空状态：带浮动图标动画
  @Builder emptyState() {
    Column() {
      SymbolGlyph($r('sys.symbol.message'))
        .fontSize(48)
        .fontColor(['#d0d5dd'])
        .translate({ y: this.iconFloatY })
        .animation({ duration: 1500, curve: curves.cubicBezier(0.4, 0, 0.2, 1) })

      Text('暂无会话')
        .fontSize(14)
        .fontColor('#8b95a7')
        .margin({ top: AppSpacing.MD })
    }
    .width('100%')
    .padding(80)
    .layoutWeight(1)
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
        .backgroundColor('#EBF5FF')
        .borderRadius(AppRadius.XL)
        .opacity(session.applicationId === this.selectedSessionId ? 1 : 0)
        .animation({ duration: 200, curve: curves.cubicBezier(0.4, 0, 0.2, 1) })

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
                .fontColor('#1a1a2e')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              // 公司标签：@公司名，蓝色，hover 下划线
              if (session.counterpartCompany) {
                Text('@' + session.counterpartCompany)
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1762FB')
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
              .fontColor('#a0aab8')
              .fontWeight(FontWeight.Medium)
              .flexShrink(0)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 第二行：消息预览 + 未读红点
          Row() {
            Text(session.lastMessage)
              .fontSize(13.5)
              .fontColor('#6b7585')
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
                .linearGradient({
                  direction: GradientDirection.Bottom,
                  colors: [['#ff4757', 0.0], ['#ff6b81', 1.0]]
                })
                .shadow({
                  radius: 6,
                  color: 'rgba(255, 71, 87, 0.3)',
                  offsetX: 0,
                  offsetY: 2
                })
                .scale({ x: this.pulseScale, y: this.pulseScale })
                .margin({ left: AppSpacing.XS })
            } else {
              Row().width(20).height(20).margin({ left: AppSpacing.XS })
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

      // 选中态蓝色竖条（渐变 3px，绝对定位在左侧，200ms 过渡）
      Column() {
        Column()
          .width(3)
          .height(24)
          .borderRadius({ topRight: 3, bottomRight: 3 })
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [['#1762FB', 0.0], ['#2d7bff', 1.0]]
          })
      }
      .width(3)
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .position({ x: 0 })
      .opacity(session.applicationId === this.selectedSessionId ? 1 : 0)
      .animation({ duration: 200, curve: curves.cubicBezier(0.4, 0, 0.2, 1) })
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
