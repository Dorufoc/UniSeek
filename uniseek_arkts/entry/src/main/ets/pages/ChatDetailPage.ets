// ChatDetailPage.ets — 聊天详情页
// 与 Vue 端 Messages.vue 右侧聊天面板样式 100% 对齐
// 设计系统参考：AppStyles.ets

import { router, promptAction, curves } from '@kit.ArkUI';
import { ChatService } from '../services/ChatService';
import { ChatMessageVO } from '../services/ChatTypes';
import { ChatWebSocketService, WsNewMessageData } from '../services/ChatWebSocketService';
import { UserSession } from '../services/UserSession';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { picker } from '@kit.CoreFileKit';

@Entry
@Component
struct ChatDetailPage {
  @State messages: ChatMessageVO[] = []
  @State inputText: string = ''
  @State counterpartName: string = ''
  @State counterpartAvatar: string = ''
  @State applicationId: number = 0
  @State isSending: boolean = false

  // ==================== 阶段 2：富媒体与交互状态 ====================

  @State showActionMenu: boolean = false   // 操作菜单可见性
  @State showLightbox: boolean = false      // 图片 Lightbox 可见性
  @State lightboxImageUrl: string = ''      // 当前预览图片 URL
  @State hasMoreMessages: boolean = true    // 是否还有更多历史消息
  @State isLoadingMore: boolean = false     // 是否正在加载更多
  @State isSendingImage: boolean = false    // 是否正在发送图片
  @State isSendingResume: boolean = false   // 是否正在发送简历

  // ==================== 生命周期 ====================

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>
    this.counterpartName = params['counterpartName'] as string
    this.counterpartAvatar = params['counterpartAvatar'] as string
    this.applicationId = params['applicationId'] as number
    this.loadMessages()

    // 连接 WebSocket 并注册新消息回调
    ChatWebSocketService.getInstance().connect()
    ChatWebSocketService.getInstance().setOnNewMessageCallback((data: WsNewMessageData) => {
      if (data.applicationId === this.applicationId) {
        const newMsg: ChatMessageVO = {
          id: data.messageId,
          senderId: data.senderId,
          messageType: data.messageType,
          content: data.content,
          isRead: data.isRead,
          sendTime: data.sendTime,
          senderName: data.senderName,
          senderAvatar: data.senderAvatar
        }
        this.messages.push(newMsg)
      }
    })
  }

  aboutToDisappear(): void {
    ChatWebSocketService.getInstance().disconnect()
  }

  onPageShow(): void {
    this.loadMessages()
  }

  // ==================== 数据加载 ====================

  loadMessages(): void {
    if (this.applicationId <= 0) {
      return
    }
    this.hasMoreMessages = true
    this.showActionMenu = false
    this.showLightbox = false
    ChatService.getMessages(this.applicationId).then((msgs: ChatMessageVO[]) => {
      // API 返回降序（最新在前），反转后升序（最旧在前），方便后续 prepend
      if (msgs.length < 20) {
        this.hasMoreMessages = false
      }
      this.messages = msgs.reverse()
    })
    ChatService.markSessionRead(this.applicationId)
  }

  // ==================== 工具方法 ====================

  // 时间格式化：将 ISO 时间转为 yyyy-MM-dd HH:mm 格式
  formatTime(dateStr: string): string {
    if (!dateStr) {
      return ''
    }
    const noT = dateStr.replace('T', ' ')
    return noT.substring(0, 16)
  }

  // 从 URL 中提取文件名（含截断逻辑）
  getAttachmentName(url: string): string {
    if (!url) {
      return '简历附件'
    }
    const name = url.substring(url.lastIndexOf('/') + 1) || '简历附件'
    if (name.length > 30) {
      return name.substring(0, 27) + '...'
    }
    return name
  }

  // ==================== 历史消息加载 ====================

  loadMoreMessages(): void {
    if (this.isLoadingMore || !this.hasMoreMessages || this.messages.length === 0) {
      return
    }
    this.isLoadingMore = true
    // 最旧消息的 ID 作为 beforeId
    const oldestId = this.messages[0].id
    ChatService.getMessages(this.applicationId, oldestId, 20).then((msgs: ChatMessageVO[]) => {
      if (msgs.length < 20) {
        this.hasMoreMessages = false
      }
      if (msgs.length > 0) {
        // API 返回降序，反转后升序再 prepend
        const reversedMsgs = msgs.reverse()
        this.messages = [...reversedMsgs, ...this.messages]
      }
      this.isLoadingMore = false
    }).catch(() => {
      this.isLoadingMore = false
    })
  }

  // ==================== 发送消息 ====================

  handleSend(): void {
    const text = this.inputText.trim()
    if (!text || this.isSending) {
      return
    }
    this.isSending = true
    this.inputText = ''
    ChatService.sendMessage(this.applicationId, text).then((msg: ChatMessageVO | null) => {
      if (msg) {
        this.messages.push(msg)
      }
      this.isSending = false
    }).catch(() => {
      // 发送失败，恢复状态
      this.isSending = false
    })
  }

  // 发送图片：打开图片选择器 -> 上传 -> 发送图片消息
  handleSendImage(): void {
    if (this.isSendingImage) {
      return
    }
    this.showActionMenu = false
    this.isSendingImage = true
    // 使用 PhotoViewPicker 选择图片
    const photoPicker = new picker.PhotoViewPicker()
    photoPicker.select({ maxSelectNumber: 1 }).then((result: picker.PhotoSelectResult) => {
      if (!result.photoUris || result.photoUris.length === 0) {
        this.isSendingImage = false
        return
      }
      const imageUri = result.photoUris[0]
      // 上传图片
      ChatService.uploadImage(imageUri).then((url: string) => {
        if (!url) {
          promptAction.showToast({ message: '图片上传失败' })
          this.isSendingImage = false
          return
        }
        // 发送图片消息（messageType=1）
        ChatService.sendMessageWithType(this.applicationId, 1, url).then((msg: ChatMessageVO) => {
          this.messages.push(msg)
          this.isSendingImage = false
        }).catch(() => {
          promptAction.showToast({ message: '图片发送失败' })
          this.isSendingImage = false
        })
      }).catch(() => {
        promptAction.showToast({ message: '图片上传失败' })
        this.isSendingImage = false
      })
    }).catch(() => {
      // 用户取消选择
      this.isSendingImage = false
    })
  }

  // 发送简历附件：选择文件 -> 上传 -> 发送简历消息
  handleSendResume(): void {
    if (this.isSendingResume) {
      return
    }
    this.showActionMenu = false
    this.isSendingResume = true
    // 使用 DocumentViewPicker 选择文件
    const docPicker = new picker.DocumentViewPicker()
    docPicker.select({ maxSelectNumber: 1 }).then((uris: string[]) => {
      if (!uris || uris.length === 0) {
        this.isSendingResume = false
        return
      }
      const fileUri = uris[0]
      // 上传文件
      ChatService.uploadFile(fileUri).then((url: string) => {
        if (!url) {
          promptAction.showToast({ message: '文件上传失败' })
          this.isSendingResume = false
          return
        }
        // 发送简历消息（messageType=2）
        ChatService.sendMessageWithType(this.applicationId, 2, url).then((msg: ChatMessageVO) => {
          this.messages.push(msg)
          this.isSendingResume = false
        }).catch(() => {
          promptAction.showToast({ message: '简历发送失败' })
          this.isSendingResume = false
        })
      }).catch(() => {
        promptAction.showToast({ message: '文件上传失败' })
        this.isSendingResume = false
      })
    }).catch(() => {
      // 用户取消选择
      this.isSendingResume = false
    })
  }

  // ==================== 主构建 ====================

  build() {
    Stack() {
      // ========== 主内容层 ==========
      Column() {
        // 自定义导航栏
        this.customHeader()

        // 消息列表
        Scroll() {
          Column({ space: 20 }) {
            // 加载更多按钮（位于列表顶部）
            if (this.hasMoreMessages && this.messages.length > 0) {
              this.loadMoreButton()
            }

            ForEach(this.messages, (msg: ChatMessageVO) => {
              if (msg.senderId === UserSession.userId) {
                this.myMessageItem(msg)
              } else {
                this.otherMessageItem(msg)
              }
            }, (msg: ChatMessageVO) => msg.id.toString())
          }
          .width('100%')
          .padding({ left: 32, right: 32, top: 28, bottom: 28 })
        }
        .layoutWeight(1)
        .width('100%')

        // 输入区域
        this.inputArea()
      }
      .width('100%')
      .height('100%')
      .linearGradient({
        angle: 180,
        colors: [['#fafbfc', 0], ['#f5f7fa', 1]]
      })

      // ========== 操作菜单遮罩层 ==========
      if (this.showActionMenu) {
        this.actionMenuOverlay()
      }

      // ========== 图片预览 Lightbox ==========
      if (this.showLightbox) {
        this.lightboxOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 自定义导航栏 ====================

  @Builder customHeader() {
    Column() {
      Row() {
        // 返回按钮
        Text('<')
          .fontSize(22)
          .fontColor('#1a1a2e')
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            router.back()
          })

        // 中间标题区
        Column() {
          // 对方名称
          Text(this.counterpartName || '聊天')
            .fontSize(17)
            .fontColor('#1a1a2e')
            .fontWeight(FontWeight.Bold)
            .letterSpacing(-0.41)
          // 副标题（占位，后续从 session 加载职位名）
          Text('')
            .fontSize(13)
            .fontColor('#8b95a7')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .padding({ top: 20, bottom: 20, left: 28, right: 28 })

      // 底部装饰线
      Row()
        .width('100%')
        .height(1)
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [['rgba(0,0,0,0)', 0], ['rgba(23,98,251,0.1)', 0.5], ['rgba(0,0,0,0)', 1]]
        })
    }
    .width('100%')
    .linearGradient({
      angle: 180,
      colors: [['#ffffff', 0], ['#fafbfc', 1]]
    })
  }

  // ==================== 头像组件 ====================

  @Builder avatarComponent(name: string, size?: number) {
    Stack() {
      // 渐变圆形背景
      Circle()
        .width(size ?? 40)
        .height(size ?? 40)
        .linearGradient({
          angle: 135,
          colors: [['#1762FB', 0], ['#5856d6', 1]]
        })
        .shadow({ radius: 8, color: 'rgba(23,98,251,0.2)', offsetX: 0, offsetY: 2 })
        .stateStyles({
          pressed: {
            .shadow({ radius: 12, color: 'rgba(23,98,251,0.3)', offsetX: 0, offsetY: 0 })
          }
        })

      // 名字首字符
      Text((name || '?').charAt(0))
        .fontSize(15)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)
    }
    .width(size ?? 40)
    .height(size ?? 40)
    .borderRadius((size ?? 40) / 2)
    .clip(true) // 确保内容裁切为圆形
  }

  // ==================== 我方消息气泡 ====================

  @Builder myMessageItem(msg: ChatMessageVO) {
    Row() {
      Blank()
        .layoutWeight(1)
      
      Row({ space: 12 }) {
        // 消息内容
        Column() {
          // 发送者名称
          Text(msg.senderName || '我')
            .fontSize(12.5)
            .fontColor('#8b95a7')
            .fontWeight(500)
            .margin({ bottom: 6 })

          // 根据 messageType 渲染不同类型
          if (msg.messageType === 1) {
            this.imageMessageItem(msg)
          } else if (msg.messageType === 2) {
            this.resumeMessageItem(msg)
          } else {
            Text(msg.content)
              .fontSize(14.5)
              .fontColor('#FFFFFF')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .borderRadius({ topLeft: 18, topRight: 6, bottomLeft: 18, bottomRight: 18 })
              .maxLines(100)
              .lineHeight(23)
              .linearGradient({
                angle: 135,
                colors: [['#1762FB', 0], ['#2d7bff', 1]]
              })
              .shadow({ radius: 16, color: 'rgba(23,98,251,0.25)', offsetX: 0, offsetY: 4 })
              .stateStyles({
                pressed: {
                  .translate({ y: -1 })
                  .shadow({ radius: 20, color: 'rgba(23,98,251,0.3)', offsetX: 0, offsetY: 6 })
                }
              })
              .animation({ duration: 200 })
          }

          Text(this.formatTime(msg.sendTime))
            .fontSize(11)
            .fontColor('#a0aab8')
            .opacity(0.8)
            .padding({ left: 4, right: 4 })
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.End)
        .constraintSize({ maxWidth: '70%' })

        // 头像（右侧）
        this.avatarComponent(msg.senderName || '我')
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .transition({ opacity: 0, translate: { y: 12 } })
    .animation({ duration: 300, curve: curves.cubicBezier(0.4, 0, 0.2, 1) })
  }

  // ==================== 对方消息气泡 ====================

  @Builder otherMessageItem(msg: ChatMessageVO) {
    Row() {
      Row({ space: 12 }) {
        // 头像（左侧）
        this.avatarComponent(msg.senderName || this.counterpartName)

        // 消息内容
        Column() {
          Text(msg.senderName || this.counterpartName)
            .fontSize(12.5)
            .fontColor('#8b95a7')
            .fontWeight(500)
            .margin({ bottom: 6 })

          if (msg.messageType === 1) {
            this.imageMessageItem(msg)
          } else if (msg.messageType === 2) {
            this.resumeMessageItem(msg)
          } else {
            Text(msg.content)
              .fontSize(14.5)
              .fontColor('#1a1a2e')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .borderRadius({ topLeft: 6, topRight: 18, bottomLeft: 18, bottomRight: 18 })
              .maxLines(100)
              .lineHeight(23)
              .backgroundColor('#ffffff')
              .shadow({ radius: 12, color: 'rgba(0,0,0,0.06)', offsetX: 0, offsetY: 2 })
              .stateStyles({
                pressed: {
                  .translate({ y: -1 })
                  .shadow({ radius: 16, color: 'rgba(0,0,0,0.08)', offsetX: 0, offsetY: 4 })
                }
              })
              .animation({ duration: 200 })
          }

          Text(this.formatTime(msg.sendTime))
            .fontSize(11)
            .fontColor('#a0aab8')
            .opacity(0.8)
            .padding({ left: 4, right: 4 })
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .constraintSize({ maxWidth: '70%' })
      }
      
      Blank()
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .transition({ opacity: 0, translate: { y: 12 } })
    .animation({ duration: 300, curve: curves.cubicBezier(0.4, 0, 0.2, 1) })
  }

  // ==================== 图片消息（messageType=1） ====================

  @Builder imageMessageItem(msg: ChatMessageVO) {
    // 图片直接显示，无气泡背景/阴影
    Image(msg.content)
      .constraintSize({ maxHeight: 320 })
      .width('100%')
      .borderRadius(14)
      .objectFit(ImageFit.Cover)
      .backgroundColor('#f0f2f5')
      .onClick(() => {
        // 打开 Lightbox 预览
        this.lightboxImageUrl = msg.content
        this.showLightbox = true
      })
      .animation({ duration: 200 })
  }

  // ==================== 简历附件消息（messageType=2） ====================

  @Builder resumeMessageItem(msg: ChatMessageVO) {
    Column() {
      // 顶部信息区：图标 + 文件名 + 标签
      Row() {
        // 文件图标
        Text('📄')
          .fontSize(28)
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)

        // 文件名 + 标签
        Column() {
          // 文件名
          Text(this.getAttachmentName(msg.content))
            .fontSize(13.5)
            .fontColor('#1a1a2e')
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 标签
          Text('简历附件')
            .fontSize(12)
            .fontColor('#6b7585')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 8 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 操作按钮区
      Row() {
        // 预览按钮
        Button() {
          Text('预览')
            .fontSize(13)
            .fontColor('#1762FB')
            .fontWeight(FontWeight.Medium)
        }
        .height(36)
        .padding({ left: 16, right: 16 })
        .borderRadius(8)
        .backgroundColor('rgba(23,98,251,0.08)')
        .onClick(() => {
          // 预览 PDF（可通过路由或打开链接）
          promptAction.showToast({ message: '预览功能开发中' })
        })

        // 下载按钮
        Button() {
          Text('下载')
            .fontSize(13)
            .fontColor('#1762FB')
            .fontWeight(FontWeight.Medium)
        }
        .height(36)
        .padding({ left: 16, right: 16 })
        .borderRadius(8)
        .backgroundColor('rgba(23,98,251,0.08)')
        .margin({ left: 8 })
        .onClick(() => {
          // 下载文件
          promptAction.showToast({ message: '下载功能开发中' })
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .margin({ top: 10 })
    }
    .width('100%')
    .padding(14)
    .borderRadius({ topLeft: 6, topRight: 18, bottomLeft: 18, bottomRight: 18 })
    .linearGradient({
      angle: 135,
      colors: [['#f5f5ff', 0], ['#eef2ff', 1]]
    })
    .borderWidth(1)
    .borderColor('rgba(23,98,251,0.1)')
  }

  // ==================== 加载更多按钮 ====================

  @Builder loadMoreButton() {
    Button() {
      if (this.isLoadingMore) {
        Text('加载中...')
          .fontSize(13)
          .fontColor('#a0aab8')
      } else {
        Text('加载更多')
          .fontSize(13)
          .fontColor('#1762FB')
          .fontWeight(FontWeight.Medium)
      }
    }
    .width('100%')
    .height(44)
    .backgroundColor('transparent')
    .borderRadius(8)
    .enabled(!this.isLoadingMore)
    .onClick(() => {
      this.loadMoreMessages()
    })
    .stateStyles({
      pressed: {
        .backgroundColor('rgba(23,98,251,0.06)')
      }
    })
    .animation({ duration: 200 })
  }

  // ==================== 操作菜单遮罩层 ====================

  @Builder actionMenuOverlay() {
    Stack() {
      // 暗色遮罩：点击关闭菜单，淡入淡出
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.3)')
        .onClick(() => {
          this.showActionMenu = false
        })
        .transition({ opacity: 0 })

      // 菜单面板（位于输入区域上方）
      Column() {
        // 发送图片
        Row() {
          Text('️')
            .fontSize(20)
            .margin({ right: 12 })
          Text('发送图片')
            .fontSize(15)
            .fontColor('#1a1a2e')
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
        .borderRadius(10)
        .onClick(() => {
          this.handleSendImage()
        })
        .stateStyles({
          pressed: {
            .backgroundColor('#f5f7fa')
          }
        })

        // 发送简历
        Row() {
          Text('📄')
            .fontSize(20)
            .margin({ right: 12 })
          Text('发送简历')
            .fontSize(15)
            .fontColor('#1a1a2e')
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
        .borderRadius(10)
        .onClick(() => {
          this.handleSendResume()
        })
        .stateStyles({
          pressed: {
            .backgroundColor('#f5f7fa')
          }
        })
      }
      .width(180)
      .padding(8)
      .backgroundColor('#ffffff')
      .borderRadius(12)
      .shadow({ radius: 16, color: 'rgba(0,0,0,0.12)', offsetX: 0, offsetY: 4 })
      .margin({ left: 28, bottom: 100 })
      // 菜单弹出动画：从下方 8px + scale(0.96) 淡入，250ms，与 Vue 端 menuSlideUp 一致
      .transition({ opacity: 0, translate: { y: 8 }, scale: { x: 0.96, y: 0.96 } })
      .animation({ duration: 250, curve: curves.cubicBezier(0.4, 0, 0.2, 1) })
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 图片预览 Lightbox ====================

  @Builder lightboxOverlay() {
    Stack() {
      // 暗色 overlay 淡入，与 Vue 端 lightboxFadeIn 一致
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.9)')
        .onClick(() => {
          this.showLightbox = false
          this.lightboxImageUrl = ''
        })
        .transition({ opacity: 0 })
        .animation({ duration: 300, curve: curves.cubicBezier(0.4, 0, 0.2, 1) })

      // 图片 zoom in 动画，与 Vue 端 lightboxZoomIn 一致
      Image(this.lightboxImageUrl)
        .objectFit(ImageFit.Contain)
        .constraintSize({ maxWidth: '90%', maxHeight: '90%' })
        .borderRadius(8)
        .hitTestBehavior(HitTestMode.Block)
        .transition({ opacity: 0, scale: { x: 0.9, y: 0.9 } })
        .animation({ duration: 300, curve: curves.cubicBezier(0.4, 0, 0.2, 1) })

      // 关闭按钮淡入
      Text('✕')
        .fontSize(24)
        .fontColor('#ffffff')
        .position({ x: '95%', y: 40 })
        .onClick(() => {
          this.showLightbox = false
          this.lightboxImageUrl = ''
        })
        .transition({ opacity: 0 })
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 输入区域 ====================

  @Builder inputArea() {
    Column() {
      Row({ space: 12 }) {
        // 加号按钮
        Button() {
          Text('+')
            .fontSize(22)
            .fontColor('#6b7585')
            .fontWeight(FontWeight.Medium)
        }
        .width(48)
        .height(48)
        .padding(0)
        .borderRadius(14)
        .border({ width: 1.5, color: '#e8ecf1' })
        .backgroundColor('#fafbfc')
        .stateStyles({
          pressed: {
            .backgroundColor('#1762FB')
            .rotate({ angle: 45 })
          }
        })
        .animation({ duration: 200, curve: curves.cubicBezier(0.4, 0, 0.2, 1) })
        .onClick(() => {
          this.showActionMenu = !this.showActionMenu
        })

        // 输入框
        TextInput({ placeholder: '请输入消息...', text: this.inputText })
          .onChange((value: string) => {
            this.inputText = value
          })
          .layoutWeight(1)
          .height(48)
          .borderRadius(14)
          .padding({ left: 16, right: 16 })
          .fontSize(14.5)
          .fontColor('#1a1a2e')
          .placeholderColor('#a0aab8')
          .backgroundColor('#fafbfc')
          .border({ width: 1.5, color: '#e8ecf1' })
          .stateStyles({
            focused: {
              .borderColor('#1762FB')
              .backgroundColor('#ffffff')
              .shadow({ radius: 4, color: 'rgba(23,98,251,0.08)', offsetX: 0, offsetY: 0 })
            }
          })

        // 发送按钮
        Button() {
          Text(this.isSending ? '...' : '发送')
            .fontSize(14.5)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        .height(48)
        .constraintSize({ minWidth: 80 })
        .padding({ left: 24, right: 24 })
        .borderRadius(14)
        .linearGradient({
          angle: 135,
          colors: [['#1762FB', 0], ['#2d7bff', 1]]
        })
        .shadow({ radius: 12, color: 'rgba(23,98,251,0.25)', offsetX: 0, offsetY: 4 })
        .enabled(!this.isSending && this.inputText.trim().length > 0)
        .onClick(() => {
          this.handleSend()
        })
        .stateStyles({
          pressed: {
            // pressed 态上移 2px + 阴影增强，与 Vue 端 bar-send-btn:hover 一致
            .translate({ y: -2 })
            .shadow({ radius: 20, color: 'rgba(23,98,251,0.35)', offsetX: 0, offsetY: 8 })
          }
        })
        .animation({ duration: 200, curve: curves.cubicBezier(0.4, 0, 0.2, 1) })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 28, right: 28, top: 16, bottom: 20 })
    .backgroundColor('#ffffff')
    .borderWidth({ top: 1 })
    .borderColor({ top: 'rgba(0,0,0,0.04)' })
  }
}
