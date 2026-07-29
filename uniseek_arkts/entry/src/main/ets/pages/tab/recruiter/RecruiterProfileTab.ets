import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { AuthService, UserVO, RealNameStatus } from '../../../services/AuthService';
import { UserService } from '../../../services/UserService';
import { ChatService } from '../../../services/ChatService';
import { ApiClient } from '../../../services/ApiClient';
import { UserSession } from '../../../services/UserSession';
import { RecruiterService } from '../../../services/RecruiterService';
import { RecruiterEnterpriseVO } from '../../../services/RecruiterTypes';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../../../common/AppStyles';

/** 招聘管理菜单项定义。 */
interface RecruiterMenuItem {
  key: string
  icon: Resource
  label: string
  desc?: string
  color: ResourceColor
}

@Component
export struct RecruiterProfileTab {
  private isLoading: boolean = false
  private isReloading: boolean = false
  private pendingRefresh: boolean = false
  // 用于避免 aboutToAppear 与首次 onPageShow 重复发起请求；从子页面返回时该标识已为 false，可正常刷新
  private isFirstPageShow: boolean = true
  // 通过 AppStorage 监听页面返回与 Tab 切换事件，刷新个人资料
  @StorageLink('profileRefreshTrigger') @Watch('onRefreshTrigger') profileRefreshTrigger: number = 0

  @State nickname: string = ''
  @State phone: string = ''
  @State email: string = ''
  @State avatarUri: string = ''
  @State isVerified: boolean = false
  @State enterpriseAuditStatus: number = -1
  @State loadErrorText: string = ''
  @State uploading: boolean = false
  @State showAbout: boolean = false
  aboutToAppear(): void {
    // 首次进入由 aboutToAppear 触发加载；onPageShow 首次到达时通过 isFirstPageShow 跳过，避免重复请求
    this.isFirstPageShow = true
    this.refreshFromCacheThenNetwork()
  }

  onPageShow(): void {
    // 从子页面返回时需要刷新；首次进入时与 aboutToAppear 重复，直接跳过
    if (this.isFirstPageShow) {
      this.isFirstPageShow = false
      return
    }
    this.refreshFromCacheThenNetwork()
  }

  private onRefreshTrigger(): void {
    // Tab 切换到我的页面时，先同步缓存再后台刷新
    this.refreshFromCacheThenNetwork()
  }

  /** 先展示本地缓存，再发起后台网络刷新，避免返回个人中心时等待网络导致头像/昵称不更新。 */
  private refreshFromCacheThenNetwork(): void {
    this.loadCachedProfile()
    this.reloadProfile(false)
  }

  /** 进入页面时优先展示本地缓存数据，避免无网络时整页空白。
   * 仅当缓存用户 ID 与当前登录用户一致时才使用缓存，防止切换账号后显示旧账号信息。
   * 实名认证状态由 loadAuthStatus 独立优先获取，不依赖本地缓存。
   */
  private loadCachedProfile(): void {
    const cachedUser = AuthService.getCachedCurrentUser()
    if (cachedUser && cachedUser.id === UserSession.userId) {
      this.applyUser(cachedUser)
    }
    const cachedEnterprise = RecruiterService.getCachedEnterpriseInfo()
    if (cachedEnterprise) {
      this.enterpriseAuditStatus = cachedEnterprise.auditStatus
    }
  }

  private async reloadProfile(showLoading: boolean): Promise<void> {
    // 避免并发请求覆盖结果，但记录 pending 状态：页面返回或 Tab 切换时若请求仍在进行，
    // 等上一轮完成后会自动再刷新一次，防止刷新被静默跳过。
    if (this.isReloading) {
      this.pendingRefresh = true
      return
    }
    this.isReloading = true
    this.pendingRefresh = false
    this.loadErrorText = ''
    this.isLoading = showLoading
    try {
      // 实名认证状态独立优先获取，不依赖 Promise.all，避免被其他请求阻塞或跳过
      await this.loadAuthStatus()
      await Promise.all([
        this.loadUser(),
        this.loadEnterprise()
      ])
    } finally {
      this.isLoading = false
      this.isReloading = false
      if (this.pendingRefresh) {
        this.pendingRefresh = false
        this.reloadProfile(false)
      }
    }
  }

  private async loadUser(): Promise<void> {
    try {
      const user: UserVO = await AuthService.getCurrentUser()
      this.applyUser(user)
    } catch {
      // 保留本地缓存的个人信息，仅提示刷新失败
      this.loadErrorText = '个人信息加载失败，请检查网络'
    }
  }

  private applyUser(user: UserVO): void {
    this.nickname = user.nickname || ''
    this.phone = user.phone || ''
    this.email = user.email || ''
    this.avatarUri = user.avatarUrl || ''
    AuthService.applyUserInfo(user.id, user.role, user.nickname, user.avatarUrl)
  }

  private async loadAuthStatus(): Promise<void> {
    try {
      // 直接发起 API 调用，绕过 AuthService 缓存与 Promise 去重机制，确保获取最新状态
      const auth = await ApiClient.get<RealNameStatus>('/api/auth/real-name/status')
      this.isVerified = auth.isAuth
    } catch {
      this.isVerified = false
    }
  }

  private async loadEnterprise(): Promise<void> {
    try {
      const info: RecruiterEnterpriseVO | null = await RecruiterService.getEnterpriseInfo()
      if (info) {
        this.enterpriseAuditStatus = info.auditStatus
      }
    } catch {
      // 保留本地缓存的企业认证状态
    }
  }

  private avatarSource(): Resource | string {
    if (!this.avatarUri) {
      return $r('app.media.theme')
    }
    if (this.avatarUri.startsWith('http')) {
      return this.avatarUri
    }
    return ApiClient.BASE_URL + (this.avatarUri.startsWith('/') ? this.avatarUri : '/' + this.avatarUri)
  }

  private maskPhone(value: string): string {
    if (value.length < 7) {
      return value || '未绑定'
    }
    return value.slice(0, 3) + '****' + value.slice(-4)
  }

  private async selectAvatar(): Promise<void> {
    if (this.uploading) {
      return
    }
    try {
      const picker = new photoAccessHelper.PhotoViewPicker()
      const result: photoAccessHelper.PhotoSelectResult = await picker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      })
      if (result.photoUris.length === 0) {
        return
      }
      this.uploading = true
      const url: string = await ChatService.uploadImage(result.photoUris[0])
      const user: UserVO = await UserService.updateProfile({ avatarUrl: url })
      this.applyUser(user)
      this.getUIContext().getPromptAction().showToast({ message: '头像更新成功', duration: 1800 })
    } catch {
      this.getUIContext().getPromptAction().showToast({ message: '头像上传失败，请重试', duration: 1800 })
    } finally {
      this.uploading = false
    }
  }

  private handleMenuClick(key: string): void {
    const router = this.getUIContext().getRouter()
    switch (key) {
      case 'enterprise':
        router.pushUrl({ url: 'pages/RecruiterEnterprisePage' })
        break
      case 'postedJobs':
        if (this.enterpriseAuditStatus !== 1) {
          this.getUIContext().getPromptAction().showToast({ message: '企业资质审核通过后方可发布职位', duration: 2000 })
          return
        }
        router.pushUrl({ url: 'pages/RecruiterPublishJobPage' })
        break
      case 'resumePool':
        router.pushUrl({ url: 'pages/RecruiterRequestsPage' })
        break
      case 'interviewManage':
        router.pushUrl({ url: 'pages/RecruiterRequestsPage' })
        break
      case 'account':
        router.pushUrl({ url: 'pages/ProfileDetailPage' })
        break
      case 'realNameAuth':
        router.pushUrl({ url: 'pages/RealNameAuthPage' })
        break
      case 'about':
        this.showAbout = true
        break
      case 'logout':
        this.confirmLogout()
        break
      default:
        break
    }
  }

  private confirmLogout(): void {
    this.getUIContext().getPromptAction().showDialog({
      title: '退出登录',
      message: '确定要退出登录吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '退出登录', color: '#ef4444' }
      ]
    }).then((res) => {
      if (res.index === 1) {
        this.logout()
      }
    }).catch(() => {})
  }

  private logout(): void {
    AuthService.logoutAndRedirect(this.getUIContext().getRouter())
  }

  private roleMenus(): RecruiterMenuItem[] {
    return [
      { key: 'enterprise', icon: $r('sys.symbol.building'), label: '企业信息', color: AppColors.SUCCESS },
      { key: 'postedJobs', icon: $r('sys.symbol.briefcase'), label: '发布职位', color: AppColors.SUCCESS },
      { key: 'resumePool', icon: $r('sys.symbol.folder'), label: '简历池', color: AppColors.SUCCESS },
      { key: 'interviewManage', icon: $r('sys.symbol.video'), label: '面试安排', color: AppColors.SUCCESS }
    ]
  }

  private menuColumnsTemplate(): string {
    return this.roleMenus().map(() => '1fr').join(' ')
  }

  private accountMenus(): RecruiterMenuItem[] {
    return [
      { key: 'account', icon: $r('sys.symbol.lock'), label: '账号管理', color: AppColors.TEXT_SECONDARY },
      { key: 'realNameAuth', icon: $r('sys.symbol.checkmark'), label: '实名认证', color: this.isVerified ? AppColors.SUCCESS : AppColors.TEXT_SECONDARY },
      { key: 'about', icon: $r('sys.symbol.gearshape'), label: '关于 UniSeek', color: AppColors.TEXT_SECONDARY },
      { key: 'logout', icon: $r('sys.symbol.power'), label: '退出登录', color: AppColors.DANGER }
    ]
  }

  build() {
    Stack() {
      Scroll() {
        Column({ space: AppSpacing.LG }) {
          this.userHeader()
          this.errorBanner()
          this.roleMenuSection()
          this.accountSection()
        }
        .width('100%')
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: AppSpacing.XL })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
    .bindSheet($$this.showAbout, this.aboutSheet(), {
      height: SheetSize.MEDIUM,
      dragBar: true,
      showClose: true,
      backgroundColor: AppColors.BG_PAGE
    })
  }

  @Builder
  userHeader() {
    Column({ space: AppSpacing.SM }) {
      Row({ space: AppSpacing.MD }) {
        // 头像（点击更换）
        Stack() {
          Image(this.avatarSource())
            .width(64)
            .height(64)
            .borderRadius(32)
            .objectFit(ImageFit.Cover)

          if (this.uploading) {
            Column() {
              LoadingProgress()
                .width(AppSpacing.ICON_MD)
                .height(AppSpacing.ICON_MD)
                .color(AppColors.PRIMARY)
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .backgroundColor('rgba(255,255,255,0.7)')
            .borderRadius(32)
          }
        }

        // 昵称、角色、手机号
        Column({ space: AppSpacing.XS }) {
          Text(this.nickname || '未设置昵称')
            .fontSize(AppFontSize.XL)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          Text('企业 HR')
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.SUCCESS)
            .backgroundColor(AppColors.SUCCESS_BG)
            .borderRadius(AppRadius.PILL)
            .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.XXS, bottom: AppSpacing.XXS })

          Text(this.maskPhone(this.phone))
            .fontSize(AppFontSize.XS)
            .fontColor('rgba(255,255,255,0.85)')
            .width('100%')
            .margin({ top: AppSpacing.XXS })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(AppFontSize.MD)
          .fontColor(['#FFFFFF'])
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(AppSpacing.MD)
    .borderRadius(AppRadius.LG)
    .linearGradient({
      angle: 135,
      colors: [['#1762FB', 0.0], [AppColors.PRIMARY_LIGHT, 1.0]]
    })
    .onClick(() => { this.getUIContext().getRouter().pushUrl({ url: 'pages/ProfileDetailPage' }) })
    .stateStyles({ pressed: { .opacity(0.92) } })
  }

  @Builder
  errorBanner() {
    if (this.loadErrorText) {
      Row({ space: AppSpacing.SM }) {
        Text(this.loadErrorText)
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.DANGER)
          .layoutWeight(1)
        Button('重试', { type: ButtonType.Capsule })
          .height(AppSpacing.BUTTON_HEIGHT_MINI)
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.PRIMARY)
          .backgroundColor(AppColors.SELECTED_BG)
          .onClick(() => { this.reloadProfile(false) })
      }
      .width('100%')
      .padding(AppSpacing.MD)
      .backgroundColor(AppColors.ERROR_BG)
      .borderRadius(AppRadius.LG)
    }
  }

  @Builder
  roleMenuSection() {
    Column({ space: AppSpacing.MD }) {
      Text('招聘管理')
        .fontSize(AppFontSize.MD)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')

      Grid() {
        ForEach(this.roleMenus(), (item: RecruiterMenuItem) => {
          GridItem() {
            this.gridItem(item)
          }
        }, (item: RecruiterMenuItem): string => item.key)
      }
      .columnsTemplate(this.menuColumnsTemplate())
      .columnsGap(AppSpacing.SM)
      .rowsGap(AppSpacing.SM)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  gridItem(item: RecruiterMenuItem) {
    Column({ space: AppSpacing.SM }) {
      Stack() {
        SymbolGlyph(item.icon)
          .fontSize(AppFontSize.ICON_LG)
          .fontColor([item.color])
      }
      .width(AppSpacing.ICON_XL)
      .height(AppSpacing.ICON_XL)
      .borderRadius(AppRadius.MD)
      .backgroundColor(this.iconBg())

      Text(item.label)
        .fontSize(AppFontSize.SM)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
    }
    .width('100%')
    // 横向内边距收缩，避免 4 列宫格中单格宽度过小导致文字被截断；保持竖向呼吸感
    .padding({ left: AppSpacing.XS, right: AppSpacing.XS, top: AppSpacing.MD, bottom: AppSpacing.MD })
    .borderRadius(AppRadius.MD)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(AppColors.BG_CARD)
    .onClick(() => { this.handleMenuClick(item.key) })
    .stateStyles({ pressed: { .backgroundColor(AppColors.INPUT_BG) } })
  }

  private iconBg(): ResourceColor {
    return 'rgba(16, 185, 129, 0.08)'
  }

  @Builder
  accountSection() {
    Column({ space: AppSpacing.SM }) {
      Text('账户设置')
        .fontSize(AppFontSize.MD)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')

      List({ space: 0 }) {
        ForEach(this.accountMenus(), (item: RecruiterMenuItem) => {
          ListItem() {
            this.accountListRow(item)
          }
          .backgroundColor(AppColors.BG_CARD)
          .stateStyles({ pressed: { .backgroundColor(AppColors.INPUT_BG) } })
          .onClick(() => { this.handleMenuClick(item.key) })
        }, (item: RecruiterMenuItem): string => item.key === 'realNameAuth'
          ? item.key + '_' + this.isVerified.toString()
          : item.key)
      }
      .width('100%')
      .divider({
        strokeWidth: AppSpacing.DIVIDER_THICKNESS,
        color: AppColors.BORDER,
        startMargin: AppSpacing.ICON_LG
      })
      .edgeEffect(EdgeEffect.None)
      .scrollBar(BarState.Off)
    }
    .width('100%')
  }

  @Builder
  accountListRow(item: RecruiterMenuItem) {
    Row({ space: AppSpacing.MD }) {
      // 左侧图标：统一浅灰圆角底，退出登录用红色弱底
      Stack() {
        SymbolGlyph(item.icon)
          .fontSize(AppFontSize.ICON_LG)
          .fontColor([item.key === 'logout' ? AppColors.DANGER : item.color])
      }
      .width(AppSpacing.ICON_LG)
      .height(AppSpacing.ICON_LG)
      .borderRadius(AppRadius.MD)
      .backgroundColor(item.key === 'logout' ? 'rgba(239, 68, 68, 0.10)' : AppColors.INPUT_BG)

      // 标题
      Text(item.label)
        .fontSize(AppFontSize.MD)
        .fontColor(item.key === 'logout' ? AppColors.DANGER : AppColors.TEXT_PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)

      // 右侧辅助文案
      if (item.key === 'realNameAuth') {
        Text(this.isVerified ? '已认证' : '未认证')
          .fontSize(AppFontSize.XS)
          .fontColor(this.isVerified ? AppColors.SUCCESS : AppColors.TEXT_MUTED)
          .maxLines(1)
          .margin({ right: AppSpacing.XS })
      }

      // 右箭头
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(AppFontSize.MD)
        .fontColor([AppColors.TEXT_MUTED])
    }
    .width('100%')
    .height(AppSpacing.LIST_ITEM_HEIGHT)
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  aboutSheet() {
    Column({ space: AppSpacing.MD }) {
      Column({ space: AppSpacing.SM }) {
        Image($r('app.media.theme'))
          .width(64)
          .height(64)
          .borderRadius(AppRadius.LG)
        Text('UniSeek')
          .fontSize(AppFontSize.XXL)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text('智能兼职招聘平台')
          .fontSize(AppFontSize.SM)
          .fontColor(AppColors.TEXT_SECONDARY)
        Text('版本 V1.0')
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.TEXT_MUTED)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .margin({ top: AppSpacing.LG, bottom: AppSpacing.LG })

      Text('UniSeek 是一款面向大学生与企业的兼职招聘平台，覆盖职位搜索、简历投递、即时通讯、企业认证、数据统计等能力。')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_SECONDARY)
        .lineHeight(AppSpacing.BUTTON_HEIGHT_MD)
        .width('100%')

      Button('知道了', { type: ButtonType.Capsule })
        .width('100%')
        .height(AppSpacing.BUTTON_HEIGHT)
        .fontSize(AppFontSize.MD)
        .fontColor('#FFFFFF')
        .backgroundColor(AppColors.PRIMARY)
        .margin({ top: AppSpacing.MD })
        .onClick(() => { this.showAbout = false })
    }
    .width('100%')
    .padding(AppSpacing.MD)
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius({ topLeft: AppRadius.XL, topRight: AppRadius.XL })
  }
}
