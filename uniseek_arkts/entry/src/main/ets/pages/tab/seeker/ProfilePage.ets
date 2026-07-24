import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { AuthService, UserVO } from '../../../services/AuthService';
import { UserService, UserStats } from '../../../services/UserService';
import { ChatService } from '../../../services/ChatService';
import { ApiClient } from '../../../services/ApiClient';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../../../common/AppStyles';
import { StandardCard } from '../../../common/StandardCard';

/** 个人中心菜单项定义。 */
interface ProfileMenuItem {
  key: string
  icon: Resource
  label: string
  desc?: string
  hint?: string
  color: ResourceColor
}

@Component
export struct ProfilePage {
  private isLoading: boolean = true
  @State nickname: string = ''
  @State phone: string = ''
  @State email: string = ''
  @State avatarUri: string = ''
  @State role: number = 0
  @State isVerified: boolean = false
  @State stats: UserStats = {
    applications: 0,
    interviews: 0,
    favorites: 0,
    receivedResumes: 0,
    hired: 0
  }
  @State loadErrorText: string = ''
  @State uploading: boolean = false
  @State showAbout: boolean = false

  aboutToAppear(): void {
    this.loadCachedProfile()
    this.reloadProfile(true)
  }

  onPageShow(): void {
    if (!this.isLoading) {
      this.reloadProfile(false)
    }
  }

  /** 进入页面时优先展示本地缓存数据，避免无网络时整页空白。 */
  private loadCachedProfile(): void {
    const cachedUser = AuthService.getCachedCurrentUser()
    if (cachedUser) {
      this.applyUser(cachedUser)
    }
    const cachedAuth = AuthService.getCachedRealNameStatus()
    if (cachedAuth) {
      this.isVerified = cachedAuth.status === 1
    }
  }

  private async reloadProfile(showLoading: boolean): Promise<void> {
    this.loadErrorText = ''
    if (showLoading) {
      this.isLoading = true
    }
    await Promise.all([
      this.loadUser(),
      this.loadStats(),
      this.loadAuthStatus()
    ])
    this.isLoading = false
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
    this.role = user.role
    AuthService.applyUserInfo(user.id, user.role, user.nickname, user.avatarUrl)
  }

  private async loadStats(): Promise<void> {
    try {
      const stats = await UserService.getStats()
      this.stats = {
        applications: stats.applications || 0,
        interviews: stats.interviews || 0,
        favorites: stats.favorites || 0,
        receivedResumes: stats.receivedResumes || 0,
        hired: stats.hired || 0
      }
    } catch {
      this.loadErrorText = '个人统计加载失败'
    }
  }

  private async loadAuthStatus(): Promise<void> {
    try {
      const auth = await AuthService.getRealNameStatus()
      this.isVerified = auth.status === 1
    } catch {
      // 保留本地缓存的实名认证状态，避免离线时显示为未认证
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

  private maskEmail(value: string): string {
    if (!value) {
      return '未绑定'
    }
    const atIndex = value.indexOf('@')
    if (atIndex <= 0) {
      return value
    }
    const name = value.substring(0, atIndex)
    const domain = value.substring(atIndex)
    const prefix = name.length > 2 ? name.substring(0, 2) : name
    return prefix + '***' + domain
  }

  private roleLabel(): string {
    if (this.role === 99) {
      return '超级管理员'
    }
    if (this.role >= 9) {
      return '管理员'
    }
    if (this.role === 1) {
      return '企业 HR'
    }
    return '求职者'
  }

  private roleColor(): ResourceColor {
    if (this.role === 99 || this.role >= 9) {
      return AppColors.WARNING
    }
    if (this.role === 1) {
      return AppColors.SUCCESS
    }
    return AppColors.PRIMARY
  }

  private roleBgColor(): ResourceColor {
    if (this.role === 99 || this.role >= 9) {
      return AppColors.WARNING_BG
    }
    if (this.role === 1) {
      return AppColors.SUCCESS_BG
    }
    return AppColors.SELECTED_BG
  }

  private primaryActionText(): string {
    if (this.role >= 9) {
      return '进入管理面板'
    }
    if (this.role === 1) {
      return '编辑企业信息'
    }
    return '编辑简历'
  }

  private primaryActionTarget(): string {
    if (this.role >= 9) {
      return 'pages/SettingsPage'
    }
    if (this.role === 1) {
      return 'pages/RecruiterEnterprisePage'
    }
    return 'pages/ResumePage'
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
      case 'resume':
        router.pushUrl({ url: 'pages/ResumePage' })
        break
      case 'applications':
        router.pushUrl({ url: 'pages/SubmittedPage', params: { tab: 'applications' } })
        break
      case 'interviews':
        router.pushUrl({ url: 'pages/SubmittedPage', params: { tab: 'interviews' } })
        break
      case 'favorites':
        router.pushUrl({ url: 'pages/FavoritesPage' })
        break
      case 'enterprise':
        router.pushUrl({ url: 'pages/RecruiterEnterprisePage' })
        break
      case 'postedJobs':
        router.pushUrl({ url: 'pages/RecruiterPublishJobPage' })
        break
      case 'resumePool':
        router.pushUrl({ url: 'pages/RecruiterApplicationsPage' })
        break
      case 'interviewManage':
        router.pushUrl({ url: 'pages/RecruiterRequestsPage' })
        break
      case 'admin':
        this.getUIContext().getPromptAction().showToast({ message: '管理员请在 PC 后台操作', duration: 2000 })
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

  private async logout(): Promise<void> {
    await AuthService.logout()
    this.getUIContext().getRouter().replaceUrl({ url: 'pages/LoginPage' })
  }

  private roleMenus(): ProfileMenuItem[] {
    if (this.role >= 9) {
      return [
        { key: 'admin', icon: $r('sys.symbol.gearshape'), label: '管理面板', color: AppColors.WARNING }
      ]
    }
    if (this.role === 1) {
      return [
        { key: 'enterprise', icon: $r('sys.symbol.building'), label: '企业信息', color: AppColors.SUCCESS },
        { key: 'postedJobs', icon: $r('sys.symbol.briefcase'), label: '发布职位', color: AppColors.SUCCESS },
        { key: 'resumePool', icon: $r('sys.symbol.folder'), label: '简历池', color: AppColors.SUCCESS },
        { key: 'interviewManage', icon: $r('sys.symbol.video'), label: '面试安排', color: AppColors.SUCCESS }
      ]
    }
    return [
      { key: 'resume', icon: $r('sys.symbol.doc_text'), label: '我的简历', color: AppColors.PRIMARY },
      { key: 'applications', icon: $r('sys.symbol.doc_text'), label: '投递记录', color: AppColors.PRIMARY },
      { key: 'interviews', icon: $r('sys.symbol.message'), label: '面试邀请', color: AppColors.PRIMARY }
    ]
  }

  private roleMenuColumnsTemplate(): string {
    return this.roleMenus().map(() => '1fr').join(' ')
  }

  private accountMenus(): ProfileMenuItem[] {
    return [
      { key: 'account', icon: $r('sys.symbol.lock'), label: '账号管理', hint: '修改密码、绑定手机', color: AppColors.TEXT_SECONDARY },
      { key: 'realNameAuth', icon: $r('sys.symbol.checkmark'), label: '实名认证', hint: this.isVerified ? '已认证' : '未认证', color: this.isVerified ? AppColors.SUCCESS : AppColors.TEXT_SECONDARY },
      { key: 'about', icon: $r('sys.symbol.gearshape'), label: '关于 UniSeek', hint: '版本 V1.0', color: AppColors.TEXT_SECONDARY },
      { key: 'logout', icon: $r('sys.symbol.power'), label: '退出登录', color: AppColors.DANGER }
    ]
  }

  build() {
    Stack() {
      Scroll() {
        Column({ space: AppSpacing.LG }) {
          this.userHeader()
          this.errorBanner()
          this.statsSection()
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
    Column() {
      Row({ space: AppSpacing.MD }) {
        // 左侧头像
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
        .onClick(() => { this.selectAvatar() })

        // 右侧姓名 + 角色
        Column({ space: AppSpacing.XS }) {
          Text(this.nickname || '未设置昵称')
            .fontSize(AppFontSize.XL)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          Text(this.roleLabel())
            .fontSize(AppFontSize.XS)
            .fontColor(this.roleColor())
            .backgroundColor(this.roleBgColor())
            .borderRadius(AppRadius.PILL)
            .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)
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
  statsSection() {
    StandardCard() {
      if (this.role === 1) {
        Row() {
          this.statItem(this.stats.receivedResumes || 0, '收到简历', 'resumePool')
          this.divider()
          this.statItem(this.stats.hired || 0, '已录取', 'interviewManage')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
      } else {
        Row() {
          this.statItem(this.stats.applications || 0, '已投简历', 'applications')
          this.divider()
          this.statItem(this.stats.interviews || 0, '面试邀请', 'interviews')
          this.divider()
          this.statItem(this.stats.favorites || 0, '收藏职位', 'favorites')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
      }
    }
  }

  @Builder
  statItem(value: number, label: string, targetKey: string) {
    Column({ space: AppSpacing.XS }) {
      Text(value.toString())
        .fontSize(AppFontSize.XXL)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.PRIMARY)
      Text(label)
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_MUTED)
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
    .onClick(() => { this.handleMenuClick(targetKey) })
    .stateStyles({ pressed: { .opacity(0.72) } })
  }

  @Builder
  divider() {
    Column()
      .width(0.5)
      .height(AppSpacing.LG)
      .backgroundColor(AppColors.BORDER)
  }

  @Builder
  roleMenuSection() {
    Column({ space: AppSpacing.MD }) {
      Text(this.role >= 9 ? '系统管理' : (this.role === 1 ? '招聘管理' : '求职管理'))
        .fontSize(AppFontSize.MD)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')

      Grid() {
        ForEach(this.roleMenus(), (item: ProfileMenuItem) => {
          GridItem() {
            this.gridItem(item)
          }
        }, (item: ProfileMenuItem): string => item.key)
      }
      .columnsTemplate(this.roleMenuColumnsTemplate())
      .columnsGap(AppSpacing.SM)
      .rowsGap(AppSpacing.SM)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  gridItem(item: ProfileMenuItem) {
    Column({ space: AppSpacing.SM }) {
      Stack() {
        SymbolGlyph(item.icon)
          .fontSize(AppFontSize.ICON_LG)
          .fontColor([item.color])
      }
      .width(AppSpacing.ICON_XL)
      .height(AppSpacing.ICON_XL)
      .borderRadius(AppRadius.MD)
      .backgroundColor(this.iconBg(item.color))

      Text(item.label)
        .fontSize(AppFontSize.SM)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
    }
    .width('100%')
    .padding(AppSpacing.MD)
    .borderRadius(AppRadius.MD)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(AppColors.BG_CARD)
    .onClick(() => { this.handleMenuClick(item.key) })
    .stateStyles({ pressed: { .backgroundColor(AppColors.INPUT_BG) } })
  }

  private iconBg(color: ResourceColor): ResourceColor {
    if (this.role === 1) {
      return 'rgba(16, 185, 129, 0.08)'
    }
    if (this.role >= 9) {
      return 'rgba(245, 158, 11, 0.08)'
    }
    return AppColors.PRIMARY_ALPHA_8
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
        ForEach(this.accountMenus(), (item: ProfileMenuItem) => {
          ListItem() {
            this.accountListRow(item)
          }
          .backgroundColor(AppColors.BG_CARD)
          .stateStyles({ pressed: { .backgroundColor(AppColors.INPUT_BG) } })
          .onClick(() => { this.handleMenuClick(item.key) })
        }, (item: ProfileMenuItem): string => item.key)
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
  accountListRow(item: ProfileMenuItem) {
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
      if (item.hint) {
        Text(item.hint)
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.TEXT_MUTED)
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
