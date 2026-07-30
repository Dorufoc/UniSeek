// ChatDetailPage.ets — 聊天详情页
// 与 Vue 端 Messages.vue 右侧聊天面板样式 100% 对齐
// 设计系统参考：AppStyles.ets

import { ChatService } from '../services/ChatService';
import { ChatMessageVO, ChatSessionVO } from '../services/ChatTypes';
import { ResumeService, ResumeData } from '../services/ResumeService';
import { getResumeAttachmentContent } from '../components/chat/ChatMessageUtils';
import { ChatWebSocketService, WsChatDetailEvent } from '../services/ChatWebSocketService';
import { UserSession } from '../services/UserSession';
import { ApplicationStatusBar } from '../components/application/ApplicationStatusBar';
import { RecruiterService } from '../services/RecruiterService';
import { ResumeCardData } from '../services/RecruiterTypes';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { KeyboardAvoidMode } from '@kit.ArkUI';
import { AppColors, AppFontSize, AppSpacing } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';
import { ChatMessagePolicy, ChatSendGuard } from '../common/BusinessPolicies';
import { mapWsNewMessageToChatMessageVO } from '../common/ChatProtocolMappers';
import { ErrorView } from '../components/ErrorView';
import { ChatMessageList, ChatMessageListController } from '../components/chat/ChatMessageList';
import { MessageInputBar, INPUT_BAR_HEIGHT } from '../components/chat/MessageInputBar';
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
  @State sessionType: string = ''
  @State taskTitle: string = ''
  @State applicationStatus: number = -1
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

  // 同步拦截连续点击，避免 UI 状态刷新前并发发起重复请求
  private readonly sendGuard: ChatSendGuard = new ChatSendGuard()

  // 聊天列表控制器：用于主动滚动到底部
  @State chatListController: ChatMessageListController = new ChatMessageListController()

  // 进入页面前的键盘避让模式，用于离开页面时恢复
  private keyboardAvoidModeBackup: KeyboardAvoidMode = KeyboardAvoidMode.OFFSET

  // 本页 WebSocket 监听器的唯一标识，避免页面切换时覆盖或误删其他监听者
  private readonly pageListenerId: string = 'chat_detail_' + Date.now().toString()

  // ==================== 生命周期 ====================

  aboutToAppear(): void {
    const uiContext = this.getUIContext()
    this.keyboardAvoidModeBackup = uiContext.getKeyboardAvoidMode()
    uiContext.setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE)

    const params = uiContext.getRouter().getParams() as Record<string, Object>
    this.counterpartName = params['counterpartName'] as string
    this.counterpartAvatar = params['counterpartAvatar'] as string
    this.applicationId = params['applicationId'] as number
    const rawSessionType: Object | undefined = params['sessionType']
    if (rawSessionType !== undefined && rawSessionType !== null) {
      this.sessionType = rawSessionType.toString()
    }
    this.loadSessionInfo()
    this.loadMessages()

    // 连接 WebSocket 并按 listenerId 注册详情事件监听
    ChatWebSocketService.getInstance().connect()
    ChatWebSocketService.getInstance().addDetailMessageListener(this.pageListenerId, (event: WsChatDetailEvent) => {
      this.onDetailMessageEvent(event)
    })
  }

  aboutToDisappear(): void {
    // 移除本页监听器，防止页面离开后回调仍被触发或影响其他页面
    ChatWebSocketService.getInstance().removeDetailMessageListener(this.pageListenerId)
    this.getUIContext().setKeyboardAvoidMode(this.keyboardAvoidModeBackup)
  }

  onPageShow(): void {
    // 页面重新显示时确保连接并重新订阅：场景包括从后台切回、其他页面返回、连接重建后
    ChatWebSocketService.getInstance().connect()
    ChatWebSocketService.getInstance().addDetailMessageListener(this.pageListenerId, (event: WsChatDetailEvent) => {
      this.onDetailMessageEvent(event)
    })
    this.silentSync()
  }

  // 滚动消息列表到底部
  private scrollToBottomOfList(): void {
    setTimeout(() => {
      this.chatListController.scrollToBottom()
    }, 0)
  }

  private appendMessageIfNeeded(message: ChatMessageVO): void {
    if (this.messages.some((item: ChatMessageVO): boolean => item.id === message.id)) {
      return
    }
    this.messages = this.messages.concat([message])
    this.scrollToBottomOfList()
  }

  private mergeLoadedMessages(loadedMessages: ChatMessageVO[]): ChatMessageVO[] {
    const merged: ChatMessageVO[] = loadedMessages.slice()
    for (const current of this.messages) {
      if (!merged.some((item: ChatMessageVO): boolean => item.id === current.id)) {
        merged.push(current)
      }
    }
    merged.sort((left: ChatMessageVO, right: ChatMessageVO): number => left.id - right.id)
    return merged
  }

  /** 将空会话类型统一视为投递会话，确保直聊与投递会话不会互相串扰。 */
  private normalizeSessionType(type?: string): string {
    if (type !== undefined && type !== null && type.trim().length > 0) {
      return type.trim()
    }
    return 'application'
  }

  // 处理 WebSocket 详情页事件：NEW_MESSAGE 去重追加并同步 canSend，SEND_ACK 仅保证不重复追加
  private onDetailMessageEvent(event: WsChatDetailEvent): void {
    if (event.type === 'SEND_ACK') {
      // 自己发送成功的消息已在 sendMessage 回调中追加，ACK 不再重复追加
      return
    }

    const data = event.data
    if (data.applicationId !== this.applicationId) {
      return
    }
    if (this.normalizeSessionType(data.sessionType) !== this.normalizeSessionType(this.sessionType)) {
      return
    }
    // 只追加对方消息；自己发送的消息由 sendMessage 成功回调处理，避免重复与状态错乱
    if (data.senderId === UserSession.userId) {
      return
    }
    const existingIds: number[] = this.messages.map((message: ChatMessageVO): number => message.id)
    if (ChatMessagePolicy.shouldAppend(data.messageId, data.senderId, UserSession.userId, existingIds)) {
      const newMsg: ChatMessageVO = mapWsNewMessageToChatMessageVO(data)
      this.appendMessageIfNeeded(newMsg)
      this.loadSessionInfo()
      this.markSessionRead()
    }
  }

  // 页面重新显示或重新订阅时执行的静默同步：不展示 loading，合并消息避免重复覆盖
  private silentSync(): void {
    if (this.applicationId <= 0) {
      return
    }
    this.loadSessionInfo()
    ChatService.getMessages(this.applicationId, undefined, 20, this.sessionType).then((msgs: ChatMessageVO[]) => {
      if (msgs.length < 20) {
        this.hasMore = false
      }
      this.messages = this.mergeLoadedMessages(msgs.reverse())
    }).catch(() => {
      // 静默同步失败不打扰用户
    })
  }

  // ==================== 数据加载 ====================

  loadSessionInfo(): void {
    if (this.applicationId <= 0) {
      return
    }
    ChatService.getSessionDetail(this.applicationId, this.sessionType).then((session: ChatSessionVO) => {
      this.counterpartName = session.counterpartName || this.counterpartName
      this.counterpartAvatar = session.counterpartAvatar || this.counterpartAvatar
      this.counterpartCompany = session.counterpartCompany || ''
      this.enterpriseId = session.enterpriseId || 0
      this.taskTitle = session.taskTitle || ''
      this.applicationStatus = session.applicationStatus ?? -1
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
    ChatService.markSessionRead(this.applicationId, this.sessionType).catch(() => {
      // 标记已读失败不影响当前消息列表展示，静默失败
    })
  }

  // 获取投递详情并跳转到简历详情页
  private openResumeDetail(): void {
    const promptAction = this.getUIContext().getPromptAction()
    RecruiterService.getApplicationById(this.applicationId).then((app) => {
      if (!app) {
        promptAction.showToast({ message: '暂无简历数据' })
        return
      }
      let snapshot: Record<string, string> = {}
      if (app.resumeSnapshot) {
        try {
          snapshot = JSON.parse(app.resumeSnapshot) as Record<string, string>
        } catch {
          snapshot = {}
        }
      }
      const getAge = (birthDate?: string): number => {
        if (!birthDate || birthDate.length < 4) return 0
        const year = Number(birthDate.substring(0, 4))
        const curYear = new Date().getFullYear()
        return (year >= 1900 && year <= curYear) ? curYear - year : 0
      }
      const resumeData: ResumeCardData = {
        id: String(app.applicantId),
        name: app.applicantName || snapshot['realName'] || '匿名求职者',
        age: getAge(snapshot['birthDate']),
        avatar: app.applicantAvatar || '',
        education: snapshot['education'] || '',
        school: snapshot['school'] || '',
        major: '',
        experience: snapshot['experience'] || '',
        skills: snapshot['skills'] || '',
        region: '',
        type: '',
        category: '',
        expectedSalary: '',
        description: '',
        attachmentUrl: app.attachmentUrl || snapshot['attachmentUrl'] || '',
        applicationId: app.id,
        applicationStatus: app.status,
        jobTitle: this.taskTitle,
        createTime: app.createTime
      }
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/ResumeDetailPage',
        params: { resumeData: JSON.stringify(resumeData) }
      })
    }).catch(() => {
      promptAction.showToast({ message: '获取简历失败' })
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
    ChatService.getMessages(this.applicationId, undefined, 20, this.sessionType).then((msgs: ChatMessageVO[]) => {
      // API 返回降序（最新在前），反转后升序（最旧在前），方便后续 prepend
      if (msgs.length < 20) {
        this.hasMore = false
      }
      this.messages = this.mergeLoadedMessages(msgs.reverse())
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
    ChatService.getMessages(this.applicationId, oldestId, 20, this.sessionType).then((msgs: ChatMessageVO[]) => {
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
    if (!this.sendGuard.tryAcquire()) {
      return
    }
    this.isSending = true
    this.inputText = ''
    ChatService.sendMessage(this.applicationId, text, this.sessionType).then((msg: ChatMessageVO | null) => {
      if (msg) {
        this.appendMessageIfNeeded(msg)
        this.loadSessionInfo()
        this.scrollToBottomOfList()
      }
      this.isSending = false
    }).catch(() => {
      this.isSending = false
    }).finally(() => {
      this.sendGuard.release()
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
    if (!this.sendGuard.tryAcquire()) {
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
        this.sendGuard.release()
        return
      }
      const imageUri = result.photoUris[0]
      this.handleImageUpload(imageUri).then((url: string) => {
        if (!url) {
          this.getUIContext().getPromptAction().showToast({ message: '图片上传失败' })
          this.isSendingImage = false
          this.sendGuard.release()
          return
        }
        ChatService.sendMessageWithType(this.applicationId, 1, url, this.sessionType).then((msg: ChatMessageVO) => {
          this.appendMessageIfNeeded(msg)
          this.isSendingImage = false
          this.loadSessionInfo()
          this.scrollToBottomOfList()
          this.sendGuard.release()
        }).catch(() => {
          this.getUIContext().getPromptAction().showToast({ message: '图片发送失败' })
          this.isSendingImage = false
          this.sendGuard.release()
        })
      }).catch(() => {
        this.getUIContext().getPromptAction().showToast({ message: '图片上传失败' })
        this.isSendingImage = false
        this.sendGuard.release()
      })
    }).catch(() => {
      this.isSendingImage = false
      this.sendGuard.release()
    })
  }

  // 发送个人资料中已经保存的简历附件。
  async handleSendResume(): Promise<void> {
    if (this.isSendingResume) {
      return
    }
    if (!this.canSendMessage()) {
      this.getUIContext().getPromptAction().showToast({ message: 'HR 未回复前，您只能发送一条消息' })
      return
    }
    if (!this.sendGuard.tryAcquire()) {
      return
    }
    this.showActionMenu = false
    this.isSendingResume = true
    try {
      const resume: ResumeData | null = await ResumeService.getMyResume()
      const content: string = getResumeAttachmentContent(resume)
      if (content.length === 0) {
        this.getUIContext().getPromptAction().showToast({ message: '请先在个人简历中上传附件简历' })
        return
      }
      const msg: ChatMessageVO = await ChatService.sendMessageWithType(this.applicationId, 2, content, this.sessionType)
      this.appendMessageIfNeeded(msg)
      this.loadSessionInfo()
      this.scrollToBottomOfList()
    } catch {
      this.getUIContext().getPromptAction().showToast({ message: '简历发送失败，请重试' })
    } finally {
      this.isSendingResume = false
      this.sendGuard.release()
    }
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

        // 限制发送提示横幅：求职者被限制时显示在顶栏下方
        if (!this.canSendMessage()) {
          Row({ space: AppSpacing.SM }) {
            SymbolGlyph($r('sys.symbol.info_circle'))
              .fontSize(AppFontSize.ICON_MD)
              .fontColor([AppColors.WARNING])

            Text('HR 未回复前，您只能发送一条消息')
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.WARNING)
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .height(AppSpacing.BUTTON_HEIGHT_SM)
          .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
          .backgroundColor(AppColors.WARNING_BG)
          .alignItems(VerticalAlign.Center)
        }

        // HR 操作栏：在顶栏下方固定显示切换求职者状态的按钮
        if (UserSession.role === 1 && this.applicationId > 0 && this.applicationStatus >= 0) {
          // 查看个人简介按钮行
          Row() {
            Button({ type: ButtonType.Capsule }) {
              Text('查看个人简介')
                .fontSize(14)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Medium)
            }
            .height(36)
            .width('90%')
            .backgroundColor('#1762FB')
            .onClick(() => {
              this.openResumeDetail()
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 6, bottom: 2 })

          ApplicationStatusBar({
            applicationId: this.applicationId,
            currentStatus: this.applicationStatus,
            applicantName: this.counterpartName,
            onStatusChanged: (status: number): void => {
              this.applicationStatus = status
              // 状态变更后后端会生成一条系统消息存入数据库，需重新加载消息列表以显示该消息
              this.loadMessages()
            }
          })
        }

// 中部消息区：占满顶栏与底栏之间的剩余空间，键盘弹起时自动压缩
        Column() {
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
              onResumeDownload: (url: string) => { this.downloadAttachment(url) }
            })
          }
        }
        .width('100%')
        .layoutWeight(1)

        // 底部固定输入栏：高度恒定，键盘弹起时整体随键盘上移
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
        .height(INPUT_BAR_HEIGHT)
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
      onSendResume: () => { this.handleSendResume() },
      showSendResume: UserSession.role !== 1
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
