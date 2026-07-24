// ChatDetailPage.ets — 聊天详情页
// 与 Vue 端 Messages.vue 右侧聊天面板样式 100% 对齐
// 设计系统参考：AppStyles.ets

import { ChatService } from '../services/ChatService';
import { ChatMessageVO, ChatSessionVO } from '../services/ChatTypes';
import { ChatWebSocketService, WsNewMessageData } from '../services/ChatWebSocketService';
import { UserSession } from '../services/UserSession';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { picker } from '@kit.CoreFileKit';
import { AppColors, AppFontSize, AppSpacing } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';
import { ChatMessagePolicy } from '../common/BusinessPolicies';
import { ErrorView } from '../components/ErrorView';
import { ChatMessageList, ChatMessageListController } from '../components/chat/ChatMessageList';
import { MessageInputBar } from '../components/chat/MessageInputBar';
import { ActionMenuOverlay } from '../components/chat/ActionMenuOverlay';
import { LightboxOverlay } from '../components/chat/LightboxOverlay';

@Entry
@Component
struct ChatDetailPage {
  @State messages: ChatMessageVO[] = []
  @State inputText: string = ''
  @State counterpartName: string = ''
  @State counterpartAvatar: string = ''
  @State counterpartCompany: string = ''
  @State enterpriseId: number = 0
  @State applicationId: number = 0
  @State taskTitle: string = ''
  @State isSending: boolean = false
  @State isLoadingMessages: boolean = true
  @State messageError: string = ''

  // ==================== 阶段 2：富媒体与交互状态 ====================

  @State canSend: boolean = true
  @State showActionMenu: boolean = false   // 操作菜单可见性
  @State showLightbox: boolean = false      // 图片 Lightbox 可见性
  @State lightboxImageUrl: string = ''      // 当前预览图片 URL
  @State hasMore: boolean = true            // 是否还有更多历史消息
  @State isLoadingMore: boolean = false     // 是否正在加载更多
  @State isSendingImage: boolean = false    // 是否正在发送图片
  @State isSendingResume: boolean = false   // 是否正在发送简历
  @State isHandlingAttachment: boolean = false // 是否正在处理附件

  // 聊天列表控制器：用于主动滚动到底部
  @State chatListController: ChatMessageListController = new ChatMessageListController()

  // ==================== 生命周期 ====================

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, Object>
    this.counterpartName = params['counterpartName'] as string
    this.counterpartAvatar = params['counterpartAvatar'] as string
    this.applicationId = params['applicationId'] as number
    this.loadSessionInfo()
    this.loadMessages()

    // 连接 WebSocket 并注册新消息回调
    ChatWebSocketService.getInstance().connect()
    ChatWebSocketService.getInstance().setOnDetailMessageCallback((data: WsNewMessageData) => {
      const existingIds: number[] = this.messages.map((message: ChatMessageVO): number => message.id)
      if (data.applicationId === this.applicationId &&
        ChatMessagePolicy.shouldAppend(data.messageId, data.senderId, UserSession.userId, existingIds)) {
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
      this.messages = this.messages.concat([newMsg])
      this.scrollToBottomOfList()
      }
    })
  }

  aboutToDisappear(): void {
    ChatWebSocketService.getInstance().removeOnDetailMessageCallback()
  }

  onPageShow(): void {
    this.loadMessages()
    this.loadSessionInfo()
  }

  // 滚动消息列表到底部
  private scrollToBottomOfList(): void {
    setTimeout(() => {
      this.chatListController.scrollToBottom()
    }, 0)
  }

  // ==================== 数据加载 ====================

  loadSessionInfo(): void {
    if (this.applicationId <= 0) {
      return
    }
    ChatService.getSessionDetail(this.applicationId).then((session: ChatSessionVO) => {
      this.counterpartName = session.counterpartName || this.counterpartName
      this.counterpartAvatar = session.counterpartAvatar || this.counterpartAvatar
      this.counterpartCompany = session.counterpartCompany || ''
      this.enterpriseId = session.enterpriseId || 0
      this.taskTitle = session.taskTitle || ''
      this.canSend = session.canSend !== false
    }).catch(() => {
      this.canSend = true
    })
  }

  canSendMessage(): boolean {
    return UserSession.role !== 0 || this.canSend
  }

  // 将会话中的对方未读消息标记为已读
  markSessionRead(): void {
    if (this.applicationId <= 0) {
      return
    }
    ChatService.markSessionRead(this.applicationId).catch(() => {
      // 标记已读失败不影响当前消息列表展示，静默失败
    })
  }

  loadMessages(): void {
    if (this.applicationId <= 0) {
      return
    }
    this.hasMore = true
    this.isLoadingMessages = this.messages.length === 0
    this.messageError = ''
    this.showActionMenu = false
    this.showLightbox = false
    this.markSessionRead()
    ChatService.getMessages(this.applicationId).then((msgs: ChatMessageVO[]) => {
      // API 返回降序（最新在前），反转后升序（最旧在前），方便后续 prepend
      if (msgs.length < 20) {
        this.hasMore = false
      }
      this.messages = msgs.reverse()
      this.isLoadingMessages = false
      this.scrollToBottomOfList()
    }).catch(() => {
      this.isLoadingMessages = false
      if (this.messages.length === 0) {
        this.messageError = '消息加载失败，请检查网络后重试'
      }
    })
  }

  // ==================== 附件操作 ====================

  previewAttachment(url: string): void {
    if (!url || this.isHandlingAttachment) {
      return
    }
    this.isHandlingAttachment = true
    ChatService.previewAttachment(url).then(() => {
      this.isHandlingAttachment = false
    }).catch(() => {
      this.isHandlingAttachment = false
      this.getUIContext().getPromptAction().showToast({ message: '附件预览失败，请重试' })
    })
  }

  downloadAttachment(url: string): void {
    if (!url || this.isHandlingAttachment) {
      return
    }
    this.isHandlingAttachment = true
    ChatService.downloadAttachment(url).then(() => {
      this.isHandlingAttachment = false
      this.getUIContext().getPromptAction().showToast({ message: '附件已下载到应用文件' })
    }).catch(() => {
      this.isHandlingAttachment = false
      this.getUIContext().getPromptAction().showToast({ message: '附件下载失败，请重试' })
    })
  }

  // ==================== 历史消息加载 ====================

  loadMoreMessages(): void {
    if (this.isLoadingMore || !this.hasMore || this.messages.length === 0) {
      return
    }
    this.isLoadingMore = true
    // 最旧消息的 ID 作为 beforeId
    const oldestId = this.messages[0].id
    ChatService.getMessages(this.applicationId, oldestId, 20).then((msgs: ChatMessageVO[]) => {
      if (msgs.length < 20) {
        this.hasMore = false
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
    if (!this.canSendMessage()) {
      this.getUIContext().getPromptAction().showToast({ message: 'HR 未回复前，您只能发送一条消息' })
      return
    }
    this.isSending = true
    this.inputText = ''
    ChatService.sendMessage(this.applicationId, text).then((msg: ChatMessageVO | null) => {
      if (msg) {
        this.messages = this.messages.concat([msg])
        this.loadSessionInfo()
        this.scrollToBottomOfList()
      }
      this.isSending = false
    }).catch(() => {
      this.isSending = false
    })
  }

  // 上传本地图片并返回图片 URL
  handleImageUpload(uri: string): Promise<string> {
    return ChatService.uploadImage(uri)
  }

  // 发送图片：打开图片选择器 -> 上传 -> 发送图片消息
  handleSendImage(): void {
    if (this.isSendingImage) {
      return
    }
    if (!this.canSendMessage()) {
      this.getUIContext().getPromptAction().showToast({ message: 'HR 未回复前，您只能发送一条消息' })
      return
    }
    this.showActionMenu = false
    this.isSendingImage = true
    const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions()
    photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
    photoSelectOptions.maxSelectNumber = 1
    const photoPicker = new photoAccessHelper.PhotoViewPicker()
    photoPicker.select(photoSelectOptions).then((result: photoAccessHelper.PhotoSelectResult) => {
      if (!result.photoUris || result.photoUris.length === 0) {
        this.isSendingImage = false
        return
      }
      const imageUri = result.photoUris[0]
      this.handleImageUpload(imageUri).then((url: string) => {
        if (!url) {
          this.getUIContext().getPromptAction().showToast({ message: '图片上传失败' })
          this.isSendingImage = false
          return
        }
        ChatService.sendMessageWithType(this.applicationId, 1, url).then((msg: ChatMessageVO) => {
          this.messages = this.messages.concat([msg])
          this.isSendingImage = false
          this.loadSessionInfo()
          this.scrollToBottomOfList()
        }).catch(() => {
          this.getUIContext().getPromptAction().showToast({ message: '图片发送失败' })
          this.isSendingImage = false
        })
      }).catch(() => {
        this.getUIContext().getPromptAction().showToast({ message: '图片上传失败' })
        this.isSendingImage = false
      })
    }).catch(() => {
      this.isSendingImage = false
    })
  }

  // 发送简历附件：选择文件 -> 上传 -> 发送简历消息
  handleSendResume(): void {
    if (this.isSendingResume) {
      return
    }
    if (!this.canSendMessage()) {
      this.getUIContext().getPromptAction().showToast({ message: 'HR 未回复前，您只能发送一条消息' })
      return
    }
    this.showActionMenu = false
    this.isSendingResume = true
    const docPicker = new picker.DocumentViewPicker()
    docPicker.select({ maxSelectNumber: 1 }).then((uris: string[]) => {
      if (!uris || uris.length === 0) {
        this.isSendingResume = false
        return
      }
      ChatService.uploadFile(uris[0]).then((url: string) => {
        if (!url) {
          this.getUIContext().getPromptAction().showToast({ message: '文件上传失败' })
          this.isSendingResume = false
          return
        }
        ChatService.sendMessageWithType(this.applicationId, 2, url).then((msg: ChatMessageVO) => {
          this.messages = this.messages.concat([msg])
          this.isSendingResume = false
          this.loadSessionInfo()
          this.scrollToBottomOfList()
        }).catch(() => {
          this.getUIContext().getPromptAction().showToast({ message: '简历发送失败' })
          this.isSendingResume = false
        })
      }).catch(() => {
        this.getUIContext().getPromptAction().showToast({ message: '文件上传失败' })
        this.isSendingResume = false
      })
    }).catch(() => {
      this.isSendingResume = false
    })
  }

  // ==================== 主构建 ====================

  build() {
    Stack() {
      // ========== 主内容层 ==========
      Column() {
        // 统一导航栏
        Column() {
          NavBar({
            showBack: true,
            centerContent: () => {
              this.chatHeaderCenter(this.counterpartName,
                this.counterpartCompany ?? '',
                this.taskTitle,
                this.enterpriseId)
            }
          })
        }
        .width('100%')
        .borderWidth({ bottom: 1 })
        .borderColor({ bottom: AppColors.BORDER })

        // 消息列表区域
        if (this.isLoadingMessages && this.messages.length === 0) {
          Column({ space: AppSpacing.SM }) {
            LoadingProgress()
              .width(AppSpacing.ICON_MD)
              .height(AppSpacing.ICON_MD)
              .color(AppColors.PRIMARY)
            Text('正在加载消息')
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.TEXT_MUTED)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else if (this.messageError && this.messages.length === 0) {
          ErrorView({
            message: this.messageError,
            retryText: '重新加载',
            onRetry: () => { this.loadMessages() }
          })
            .width('100%')
            .layoutWeight(1)
        } else {
          ChatMessageList({
            messages: $messages,
            controller: this.chatListController,
            counterpartName: this.counterpartName,
            counterpartAvatar: this.counterpartAvatar,
            isLoadingMore: this.isLoadingMore,
            hasMore: this.hasMore,
            isAttachmentHandling: this.isHandlingAttachment,
            onLoadMore: () => { this.loadMoreMessages() },
            onImageClick: (url: string) => {
              this.lightboxImageUrl = url
              this.showLightbox = true
            },
            onResumePreview: (url: string) => { this.previewAttachment(url) },
            onResumeDownload: (url: string) => { this.downloadAttachment(url) }
          })
        }

        // 输入区域：宽度占屏幕 90% 并居中
        Row() {
          MessageInputBar({
            inputText: $inputText,
            canSend: this.canSendMessage(),
            isSending: this.isSending,
            onSend: () => { this.handleSend() },
            onToggleMenu: () => { this.showActionMenu = !this.showActionMenu }
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.BG_PAGE)

      // ========== 图片预览 Lightbox ==========
      if (this.showLightbox) {
        LightboxOverlay({
          imageUrl: this.lightboxImageUrl,
          onClose: () => {
            this.showLightbox = false
            this.lightboxImageUrl = ''
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .bindSheet($$this.showActionMenu, this.actionMenuBuilder(), {
      height: 180,
      dragBar: true,
      showClose: true,
      backgroundColor: AppColors.BG_CARD
    })
  }

  // ==================== 底部操作抽屉 ====================

  @Builder
  actionMenuBuilder() {
    ActionMenuOverlay({
      onSendImage: () => { this.handleSendImage() },
      onSendResume: () => { this.handleSendResume() }
    })
  }

  // ==================== 导航栏中间内容 ====================

  @Builder chatHeaderCenter(name: string, company: string, title: string, id: number) {
    Column() {
      Row() {
        Text(name || '聊天')
          .fontSize(AppFontSize.LG)
          .fontColor(AppColors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
        if (company.length > 0) {
          Text('@' + company)
            .fontSize(AppFontSize.LG)
            .fontColor(AppColors.PRIMARY)
            .fontWeight(FontWeight.Bold)
            .onClick(() => {
              if (id > 0) {
                this.getUIContext().getRouter().pushUrl({
                  url: 'pages/CompanyDetailPage',
                  params: { enterpriseId: id }
                })
              }
            })
        }
      }
      .alignItems(VerticalAlign.Center)

      Text(title || '职位沟通')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_MUTED)
    }
    .alignItems(HorizontalAlign.Center)
  }
}
