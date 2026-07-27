// 顶部「新投递通知铃铛」组件。
// 红点展示未读数，点击弹出通知列表，支持单条已读与全部已读。

import { NotificationService } from '../services/NotificationService'
import { NotificationVO } from '../services/RecruiterTypes'
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles'

@CustomDialog
struct NotificationListDialog {
  controller?: CustomDialogController
  onLoad?: () => Promise<NotificationVO[]>
  onMarkRead?: (id: number) => Promise<boolean>
  onMarkAll?: () => Promise<boolean>
  onItemClick?: (item: NotificationVO) => void

  @State notifications: NotificationVO[] = []
  @State isLoading: boolean = true

  aboutToAppear(): void {
    this.refresh()
  }

  private refresh(): void {
    this.isLoading = true
    this.onLoad?.()
      .then((list: NotificationVO[]) => {
        this.notifications = list ?? []
        this.isLoading = false
      })
      .catch(() => {
        this.notifications = []
        this.isLoading = false
      })
  }

  private handleMarkAll(): void {
    this.onMarkAll?.().then((ok: boolean) => {
      if (!ok) {
        return
      }
      for (const item of this.notifications) {
        item.isRead = 1
      }
      this.notifications = [...this.notifications]
    }).catch(() => {
      // 静默失败，不阻断操作
    })
  }

  private handleItemClick(item: NotificationVO): void {
    if (item.isRead !== 0) {
      this.onItemClick?.(item)
      return
    }
    this.onMarkRead?.(item.id).then((ok: boolean) => {
      if (ok) {
        item.isRead = 1
        this.notifications = [...this.notifications]
      }
      this.onItemClick?.(item)
    }).catch(() => {
      // 即使标记失败也允许跳转
      this.onItemClick?.(item)
    })
  }

  private formatTime(timeText?: string): string {
    if (!timeText) {
      return ''
    }
    return timeText.replace('T', ' ').substring(0, 16)
  }

  build() {
    Column() {
      // 弹窗标题栏
      Row() {
        Text('新投递通知')
          .fontSize(AppFontSize.LG)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
        if (this.notifications.length > 0) {
          Button('全部已读', { type: ButtonType.Normal })
            .height(AppSpacing.BUTTON_HEIGHT_MINI)
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.PRIMARY)
            .backgroundColor(Color.Transparent)
            .onClick(() => { this.handleMarkAll() })
        }
      }
      .width('100%')
      .padding({ bottom: AppSpacing.MD })

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(AppSpacing.ICON_MD)
            .height(AppSpacing.ICON_MD)
            .color(AppColors.PRIMARY)
          Text('加载中...')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
            .margin({ top: AppSpacing.SM })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.notifications.length === 0) {
        Column() {
          SymbolGlyph($r('sys.symbol.bell_slash'))
            .fontSize(AppFontSize.ICON_LG)
            .fontColor([AppColors.TEXT_MUTED])
          Text('暂无新投递通知')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
            .margin({ top: AppSpacing.SM })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column() {
            ForEach(this.notifications, (item: NotificationVO) => {
              Column() {
                Row() {
                  Text(item.title)
                    .fontSize(AppFontSize.MD)
                    .fontWeight(item.isRead === 0 ? FontWeight.Bold : FontWeight.Regular)
                    .fontColor(AppColors.TEXT_PRIMARY)
                    .layoutWeight(1)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  if (item.isRead === 0) {
                    Stack()
                      .width(8)
                      .height(8)
                      .borderRadius(AppRadius.PILL)
                      .backgroundColor(AppColors.DANGER)
                      .margin({ left: AppSpacing.XS })
                  }
                }
                .width('100%')

                Text(item.content)
                  .fontSize(AppFontSize.SM)
                  .fontColor(AppColors.TEXT_SECONDARY)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                  .margin({ top: AppSpacing.XXS })

                Text(this.formatTime(item.createTime))
                  .fontSize(AppFontSize.XS)
                  .fontColor(AppColors.TEXT_MUTED)
                  .width('100%')
                  .margin({ top: AppSpacing.XXS })
              }
              .width('100%')
              .padding(AppSpacing.MD)
              .backgroundColor(AppColors.BG_CARD)
              .borderRadius(AppRadius.MD)
              .margin({ bottom: AppSpacing.SM })
              .onClick(() => { this.handleItemClick(item) })
              .stateStyles({
                pressed: {
                  .backgroundColor(AppColors.INPUT_BG)
                }
              })
              .animation({ duration: 150 })
            }, (item: NotificationVO): string => item.id.toString())
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }

      Button('关闭', { type: ButtonType.Capsule })
        .width('100%')
        .height(AppSpacing.BUTTON_HEIGHT)
        .fontSize(AppFontSize.MD)
        .fontColor(AppColors.TEXT_SECONDARY)
        .backgroundColor(AppColors.INPUT_BG)
        .margin({ top: AppSpacing.SM })
        .onClick(() => { this.controller?.close() })
    }
    .padding(AppSpacing.LG)
    .width('100%')
    .height(480)
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius({ topLeft: AppRadius.XL, topRight: AppRadius.XL })
  }
}

@Component
export struct NotificationBell {
  @State unreadCount: number = 0
  private listController?: CustomDialogController
  onNavigateToApplication?: (applicationId: number) => void

  aboutToAppear(): void {
    this.refreshUnreadCount()
  }

  onPageShow(): void {
    // 从其他页面返回时刷新未读数
    this.refreshUnreadCount()
  }

  private refreshUnreadCount(): void {
    NotificationService.getUnreadCount().then((count: number) => {
      this.unreadCount = count
    }).catch(() => {
      this.unreadCount = 0
    })
  }

  private async loadNotifications(): Promise<NotificationVO[]> {
    return await NotificationService.getNewDeliveries(1, 50)
  }

  private async handleMarkRead(id: number): Promise<boolean> {
    const ok = await NotificationService.markRead(id)
    if (ok && this.unreadCount > 0) {
      this.unreadCount--
    }
    return ok
  }

  private async handleMarkAll(): Promise<boolean> {
    const ok = await NotificationService.markAllRead()
    if (ok) {
      this.unreadCount = 0
    }
    return ok
  }

  private openList(): void {
    this.listController = new CustomDialogController({
      builder: NotificationListDialog({
        onLoad: (): Promise<NotificationVO[]> => this.loadNotifications(),
        onMarkRead: (id: number): Promise<boolean> => this.handleMarkRead(id),
        onMarkAll: (): Promise<boolean> => this.handleMarkAll(),
        onItemClick: (item: NotificationVO): void => {
          this.listController?.close()
          if (item.bizId > 0) {
            this.onNavigateToApplication?.(item.bizId)
          }
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.TopEnd,
      offset: { dx: -AppSpacing.MD, dy: AppSpacing.BUTTON_HEIGHT_MD },
      customStyle: true
    })
    this.listController.open()
  }

  build() {
    Button({ type: ButtonType.Circle }) {
      if (this.unreadCount > 0) {
        Badge({
          value: this.unreadCount > 99 ? '99+' : String(this.unreadCount),
          position: BadgePosition.RightTop,
          style: { badgeSize: 16, badgeColor: '#FF4D4F', fontSize: 10 }
        }) {
          SymbolGlyph($r('sys.symbol.bell'))
            .fontSize(AppFontSize.ICON_LG)
            .fontColor([AppColors.TEXT_PRIMARY])
        }
      } else {
        SymbolGlyph($r('sys.symbol.bell'))
          .fontSize(AppFontSize.ICON_LG)
          .fontColor([AppColors.TEXT_PRIMARY])
      }
    }
    .width(40)
    .height(40)
    .backgroundColor(AppColors.BG_CARD)
    .onClick(() => { this.openList() })
    .stateStyles({
      pressed: {
        .backgroundColor(AppColors.INPUT_BG)
        .scale({ x: 0.95, y: 0.95 })
      }
    })
    .animation({ duration: 150 })
  }
}
