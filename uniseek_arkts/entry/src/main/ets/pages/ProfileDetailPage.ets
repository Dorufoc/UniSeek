import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { AuthService, UserVO } from '../services/AuthService';
import { ChatService } from '../services/ChatService';
import { ApiClient } from '../services/ApiClient';
import { UserService } from '../services/UserService';
import { UserSession } from '../services/UserSession';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';
import { CustomContentDialog } from '@kit.ArkUI';

@Entry
@Component
struct ProfileDetailPage {
  @State loading: boolean = true
  @State saving: boolean = false
  @State uploading: boolean = false
  @State username: string = ''
  @State phone: string = ''
  @State email: string = ''
  @State avatarUri: string = ''
  @State errorText: string = ''
  @State successText: string = ''

  // 编辑资料弹窗状态
  @State editTitle: string = ''
  @State editPlaceholder: string = ''
  @State editValue: string = ''
  @State editPassword: string = ''
  @State editInputType: InputType = InputType.Normal
  @State editMaxLength: number = 100
  @State editingField: string = ''

  // 修改密码弹窗状态
  @State oldPassword: string = ''
  @State newPassword: string = ''
  @State confirmPassword: string = ''

  // 编辑资料弹窗：使用系统原生 CustomContentDialog，内部仅使用 TextInput 原生输入框
  editDialogController: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: this.editTitle,
      contentBuilder: () => { this.buildEditContent() },
      buttons: [
        {
          value: '取消',
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => { }
        },
        {
          value: '保存',
          buttonStyle: ButtonStyleMode.TEXTUAL,
          role: ButtonRole.ERROR,
          action: () => { this.onEditDialogSave() }
        }
      ]
    })
  })

  // 修改密码弹窗
  passwordDialogController: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: '修改密码',
      contentBuilder: () => { this.buildPasswordContent() },
      buttons: [
        {
          value: '取消',
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => { }
        },
        {
          value: '确认修改',
          buttonStyle: ButtonStyleMode.TEXTUAL,
          role: ButtonRole.ERROR,
          action: () => { this.onPasswordDialogSave() }
        }
      ]
    })
  })

  aboutToAppear(): void {
    this.loadProfile(true)
  }

  async loadProfile(showLoading: boolean): Promise<void> {
    if (showLoading) {
      this.loading = true
    }
    this.errorText = ''
    try {
      const user: UserVO = await AuthService.getCurrentUser()
      this.applyUser(user)
    } catch (error) {
      this.errorText = this.getErrorMessage(error)
    } finally {
      this.loading = false
    }
  }

  applyUser(user: UserVO): void {
    this.username = user.nickname || ''
    this.phone = user.phone || ''
    this.email = user.email || ''
    this.avatarUri = user.avatarUrl || ''
    AuthService.applyUserInfo(user.id, user.role, this.username, this.avatarUri)
  }

  getErrorMessage(error: Error): string {
    if (error instanceof Error && error.message) {
      return error.message
    }
    return '请求失败，请稍后重试'
  }

  formatPhone(value: string): string {
    if (value.length < 7) {
      return value || '未绑定'
    }
    return value.slice(0, 3) + '****' + value.slice(-4)
  }

  formatEmail(value: string): string {
    if (!value) {
      return '未绑定'
    }
    const atIndex: number = value.indexOf('@')
    if (atIndex <= 0) {
      return value
    }
    const name: string = value.substring(0, atIndex)
    const domain: string = value.substring(atIndex + 1)
    const prefix: string = name.length > 2 ? name.substring(0, 2) : name
    return prefix + '***@' + domain
  }

  getFieldValue(field: string): string {
    if (field === 'username') {
      return this.username
    }
    if (field === 'phone') {
      return this.phone
    }
    if (field === 'email') {
      return this.email
    }
    return ''
  }

  // 编辑资料弹窗内容区：仅使用系统原生 TextInput
  @Builder
  buildEditContent(): void {
    Column({ space: AppSpacing.MD }) {
      TextInput({ placeholder: this.editPlaceholder, text: this.editValue })
        .type(this.editInputType)
        .maxLength(this.editMaxLength)
        .height(AppSpacing.INPUT_HEIGHT_STANDARD)
        .width('100%')
        .onChange((value: string) => {
          this.editValue = value
        })

      if (this.editingField === 'phone' || this.editingField === 'email') {
        TextInput({ placeholder: '请输入当前登录密码', text: this.editPassword })
          .type(InputType.Password)
          .maxLength(20)
          .height(AppSpacing.INPUT_HEIGHT_STANDARD)
          .width('100%')
          .onChange((value: string) => {
            this.editPassword = value
          })
      }
    }
    .width('100%')
  }

  // 修改密码弹窗内容区
  @Builder
  buildPasswordContent(): void {
    Column({ space: AppSpacing.MD }) {
      TextInput({ placeholder: '原密码', text: this.oldPassword })
        .type(InputType.Password)
        .maxLength(20)
        .height(AppSpacing.INPUT_HEIGHT_STANDARD)
        .width('100%')
        .onChange((value: string) => {
          this.oldPassword = value
        })

      TextInput({ placeholder: '新密码（6-20位）', text: this.newPassword })
        .type(InputType.Password)
        .maxLength(20)
        .height(AppSpacing.INPUT_HEIGHT_STANDARD)
        .width('100%')
        .onChange((value: string) => {
          this.newPassword = value
        })

      TextInput({ placeholder: '确认新密码', text: this.confirmPassword })
        .type(InputType.Password)
        .maxLength(20)
        .height(AppSpacing.INPUT_HEIGHT_STANDARD)
        .width('100%')
        .onChange((value: string) => {
          this.confirmPassword = value
        })
    }
    .width('100%')
  }

  // 打开单个资料项编辑弹窗
  openEditDialog(field: string): void {
    this.errorText = ''
    this.successText = ''
    this.editingField = field
    this.editPassword = ''

    if (field === 'username') {
      this.editTitle = '修改昵称'
      this.editPlaceholder = '请输入昵称'
      this.editValue = this.username
      this.editInputType = InputType.Normal
      this.editMaxLength = 20
    } else if (field === 'phone') {
      this.editTitle = '修改手机号'
      this.editPlaceholder = '请输入手机号'
      this.editValue = ''
      this.editInputType = InputType.PhoneNumber
      this.editMaxLength = 11
    } else if (field === 'email') {
      this.editTitle = '修改邮箱'
      this.editPlaceholder = '请输入邮箱'
      this.editValue = ''
      this.editInputType = InputType.Email
      this.editMaxLength = 40
    } else {
      return
    }

    this.editDialogController.open()
  }

  openPasswordDialog(): void {
    this.errorText = ''
    this.successText = ''
    this.oldPassword = ''
    this.newPassword = ''
    this.confirmPassword = ''
    this.passwordDialogController.open()
  }

  onEditDialogSave(): void {
    void this.saveField(this.editingField, this.editValue.trim(), this.editPassword)
  }

  onPasswordDialogSave(): void {
    void this.savePassword(this.oldPassword, this.newPassword, this.confirmPassword)
  }

  async saveField(field: string, value: string, password: string): Promise<void> {
    if (this.saving) {
      return
    }
    if (!value) {
      this.errorText = '请输入要保存的内容'
      return
    }
    if (field === 'username' && (value.length < 1 || value.length > 20)) {
      this.errorText = '昵称长度需为 1-20 个字符'
      return
    }
    if (field === 'phone' && !/^1[3-9][0-9]{9}$/.test(value)) {
      this.errorText = '请输入正确的手机号'
      return
    }
    if (field === 'email' && !/^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/.test(value)) {
      this.errorText = '请输入正确的邮箱地址'
      return
    }
    if ((field === 'phone' || field === 'email') && password.length < 6) {
      this.errorText = '请输入当前登录密码'
      return
    }

    this.saving = true
    this.errorText = ''
    try {
      if (field === 'username') {
        const user: UserVO = await UserService.updateProfile({ nickname: value })
        this.applyUser(user)
      } else if (field === 'phone') {
        await AuthService.updatePhone(value, password)
        await this.loadProfile(false)
      } else if (field === 'email') {
        await AuthService.updateEmail(value, password)
        await this.loadProfile(false)
      }
      this.successText = '资料更新成功'
      this.editDialogController.close()
      this.getUIContext().getPromptAction().showToast({ message: '资料更新成功', duration: 1800 })
    } catch (error) {
      this.errorText = this.getErrorMessage(error)
    } finally {
      this.saving = false
    }
  }

  async savePassword(oldPassword: string, newPassword: string, confirmPassword: string): Promise<void> {
    if (this.saving) {
      return
    }
    if (oldPassword.length < 6) {
      this.errorText = '原密码至少需要 6 位'
      return
    }
    if (newPassword.length < 6 || newPassword.length > 20) {
      this.errorText = '新密码长度需为 6-20 位'
      return
    }
    if (newPassword !== confirmPassword) {
      this.errorText = '两次输入的新密码不一致'
      return
    }
    if (newPassword === oldPassword) {
      this.errorText = '新密码不能与原密码相同'
      return
    }

    this.saving = true
    this.errorText = ''
    try {
      await AuthService.changePassword(oldPassword, newPassword, confirmPassword)
      this.getUIContext().getPromptAction().showToast({ message: '密码修改成功，请重新登录', duration: 2200 })
      AuthService.logoutAndRedirect(this.getUIContext().getRouter())
    } catch (error) {
      this.errorText = this.getErrorMessage(error)
    } finally {
      this.saving = false
    }
  }

  async selectAvatar(): Promise<void> {
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
      this.errorText = ''
      const url: string = await ChatService.uploadImage(result.photoUris[0])
      const user: UserVO = await UserService.updateProfile({ avatarUrl: url })
      this.applyUser(user)
      this.getUIContext().getPromptAction().showToast({ message: '头像更新成功', duration: 1800 })
    } catch (error) {
      this.errorText = this.getErrorMessage(error)
    } finally {
      this.uploading = false
    }
  }

  avatarSource(): Resource | string {
    if (!this.avatarUri) {
      return $r('app.media.theme')
    }
    if (this.avatarUri.startsWith('http')) {
      return this.avatarUri
    }
    return ApiClient.BASE_URL + (this.avatarUri.startsWith('/') ? this.avatarUri : '/' + this.avatarUri)
  }

  // 分节标题
  @Builder
  sectionHeader(title: string) {
    Text(title)
      .fontSize(AppFontSize.MD)
      .fontWeight(FontWeight.Bold)
      .fontColor(AppColors.TEXT_PRIMARY)
      .width('100%')
  }

  // 状态提示
  @Builder
  statusBanner(message: string, bgColor: ResourceColor, textColor: ResourceColor) {
    Row() {
      Text(message)
        .fontSize(AppFontSize.SM)
        .fontColor(textColor)
        .width('100%')
    }
    .width('100%')
    .padding(AppSpacing.MD)
    .backgroundColor(bgColor)
    .borderRadius(AppRadius.LG)
  }

  // 头像卡片
  @Builder
  avatarCard() {
    Column({ space: AppSpacing.SM }) {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Image(this.avatarSource())
          .width(96)
          .height(96)
          .borderRadius(AppRadius.FULL)
          .objectFit(ImageFit.Cover)
          .shadow({
            radius: 12,
            color: 'rgba(0, 0, 0, 0.08)',
            offsetX: 0,
            offsetY: 4
          })

        if (this.uploading) {
          LoadingProgress()
            .width(32)
            .height(32)
            .color(AppColors.PRIMARY)
            .backgroundColor('#E5FFFFFF')
            .borderRadius(AppRadius.FULL)
        }

        Stack() {
          Text('编辑')
            .fontSize(10)
            .fontColor('#FFFFFF')
        }
        .width(32)
        .height(32)
        .backgroundColor(AppColors.PRIMARY)
        .borderRadius(AppRadius.FULL)
        .border({ width: 2, color: AppColors.BG_CARD })
      }
      .width(96)
      .height(96)

      Text(this.uploading ? '头像上传中...' : '点击更换头像')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_MUTED)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding(AppSpacing.LG)
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius(AppRadius.LG)
    .onClick(() => { this.selectAvatar() })
  }

  // 展示行
  @Builder
  displayRow(label: string, value: string, field: string) {
    Row() {
      Text(label)
        .fontSize(AppFontSize.MD)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width(72)
      Text(value)
        .fontSize(AppFontSize.MD)
        .fontColor(value === '未设置' || value === '未绑定' ? AppColors.TEXT_MUTED : AppColors.TEXT_PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      Row({ space: AppSpacing.XS }) {
        Text('编辑')
          .fontSize(AppFontSize.SM)
          .fontColor(AppColors.PRIMARY)
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(AppFontSize.SM)
          .fontColor([AppColors.TEXT_MUTED])
      }
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        if (field === 'password') {
          this.openPasswordDialog()
        } else {
          this.openEditDialog(field)
        }
      })
    }
    .width('100%')
    .height(AppSpacing.LIST_ITEM_HEIGHT)
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
    .alignItems(VerticalAlign.Center)
  }

  // 基础资料卡片
  @Builder
  profileCard() {
    Column({ space: AppSpacing.MD }) {
      this.sectionHeader('基础资料')

      Column({ space: AppSpacing.ZERO }) {
        this.displayRow('昵称', this.getFieldValue('username') || '未设置', 'username')
        Divider().width('100%').height(AppSpacing.DIVIDER_THICKNESS).color(AppColors.BORDER).opacity(0.4)
        this.displayRow('手机号', this.formatPhone(this.phone), 'phone')
        Divider().width('100%').height(AppSpacing.DIVIDER_THICKNESS).color(AppColors.BORDER).opacity(0.4)
        this.displayRow('邮箱', this.formatEmail(this.email), 'email')
      }
      .width('100%')
      .backgroundColor(AppColors.BG_CARD)
      .borderRadius(AppRadius.LG)
      .padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })
    }
    .width('100%')
  }

  // 账号安全卡片
  @Builder
  securityCard() {
    Column({ space: AppSpacing.MD }) {
      this.sectionHeader('账号安全')

      Row() {
        SymbolGlyph($r('sys.symbol.lock'))
          .fontSize(AppFontSize.ICON_MD)
          .fontColor([AppColors.TEXT_SECONDARY])
          .margin({ right: AppSpacing.MD })
        Text('密码')
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
        Row({ space: AppSpacing.XS }) {
          Text('修改')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.PRIMARY)
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(AppFontSize.SM)
            .fontColor([AppColors.TEXT_MUTED])
        }
        .alignItems(VerticalAlign.Center)
        .onClick(() => { this.openPasswordDialog() })
      }
      .width('100%')
      .height(AppSpacing.LIST_ITEM_HEIGHT)
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
      .backgroundColor(AppColors.BG_CARD)
      .borderRadius(AppRadius.LG)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
  }

  build() {
    Column() {
      NavBar({ title: '个人资料', showBack: true })

      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(36)
            .height(36)
            .color(AppColors.PRIMARY)
          Text('正在加载资料')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
            .margin({ top: AppSpacing.SM })
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: AppSpacing.LG }) {
            if (this.errorText) {
              this.statusBanner(this.errorText, AppColors.ERROR_BG, AppColors.DANGER)
            }
            if (this.successText) {
              this.statusBanner(this.successText, AppColors.SUCCESS_BG, AppColors.SUCCESS)
            }

            this.avatarCard()
            this.profileCard()
            this.securityCard()

            Text('手机号和邮箱修改需要验证当前密码，密码修改成功后需要重新登录。')
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.TEXT_MUTED)
              .width('100%')
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.LG, bottom: AppSpacing.XL })
          .alignItems(HorizontalAlign.Center)
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
