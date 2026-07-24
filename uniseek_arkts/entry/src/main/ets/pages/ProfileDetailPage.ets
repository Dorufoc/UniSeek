import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { AuthService, UserVO } from '../services/AuthService';
import { ChatService } from '../services/ChatService';
import { ApiClient } from '../services/ApiClient';
import { UserService } from '../services/UserService';
import { UserSession } from '../services/UserSession';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';

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
  @State editingField: string = ''
  @State editValue: string = ''
  @State editPassword: string = ''
  @State editConfirm: string = ''
  @State errorText: string = ''
  @State successText: string = ''

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

  startEdit(field: string): void {
    this.errorText = ''
    this.successText = ''
    this.editingField = field
    this.editValue = this.getFieldValue(field)
    this.editPassword = ''
    this.editConfirm = ''
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

  async saveEdit(): Promise<void> {
    if (this.saving) {
      return
    }
    const value: string = this.editValue.trim()
    if (!value) {
      this.errorText = '请输入要保存的内容'
      return
    }
    if (this.editingField === 'username' && (value.length < 1 || value.length > 20)) {
      this.errorText = '昵称长度需为 1-20 个字符'
      return
    }
    if (this.editingField === 'phone' && !/^1[3-9][0-9]{9}$/.test(value)) {
      this.errorText = '请输入正确的手机号'
      return
    }
    if (this.editingField === 'email' && !/^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$/.test(value)) {
      this.errorText = '请输入正确的邮箱地址'
      return
    }
    if ((this.editingField === 'phone' || this.editingField === 'email') && this.editPassword.length < 6) {
      this.errorText = '请输入当前登录密码'
      return
    }

    this.saving = true
    this.errorText = ''
    try {
      if (this.editingField === 'username') {
        const user: UserVO = await UserService.updateProfile({ nickname: value })
        this.applyUser(user)
      } else if (this.editingField === 'phone') {
        await AuthService.updatePhone(value, this.editPassword)
        await this.loadProfile(false)
      } else if (this.editingField === 'email') {
        await AuthService.updateEmail(value, this.editPassword)
        await this.loadProfile(false)
      }
      this.successText = '资料更新成功'
      this.getUIContext().getPromptAction().showToast({ message: '资料更新成功', duration: 1800 })
      this.cancelEdit()
    } catch (error) {
      this.errorText = this.getErrorMessage(error)
    } finally {
      this.saving = false
    }
  }

  async savePassword(): Promise<void> {
    if (this.saving) {
      return
    }
    if (this.editPassword.length < 6) {
      this.errorText = '原密码至少需要 6 位'
      return
    }
    if (this.editValue.length < 6 || this.editValue.length > 20) {
      this.errorText = '新密码长度需为 6-20 位'
      return
    }
    if (this.editValue !== this.editConfirm) {
      this.errorText = '两次输入的新密码不一致'
      return
    }
    if (this.editValue === this.editPassword) {
      this.errorText = '新密码不能与原密码相同'
      return
    }

    this.saving = true
    this.errorText = ''
    try {
      await AuthService.changePassword(this.editPassword, this.editValue, this.editConfirm)
      this.getUIContext().getPromptAction().showToast({ message: '密码修改成功，请重新登录', duration: 2200 })
      await AuthService.logout()
      this.getUIContext().getRouter().replaceUrl({ url: 'pages/LoginPage' })
    } catch (error) {
      this.errorText = this.getErrorMessage(error)
    } finally {
      this.saving = false
    }
  }

  cancelEdit(): void {
    this.editingField = ''
    this.editValue = ''
    this.editPassword = ''
    this.editConfirm = ''
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

  build() {
    Column() {
      NavBar({
        title: '个人资料',
        showBack: true,
        onBack: () => this.getUIContext().getRouter().back()
      })

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
          Column() {
            if (this.errorText) {
              Text(this.errorText)
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.DANGER)
                .width('100%')
                .padding(AppSpacing.SM)
                .backgroundColor(AppColors.ERROR_BG)
                .borderRadius(AppRadius.SM)
                .margin({ bottom: AppSpacing.SM })
            }
            if (this.successText) {
              Text(this.successText)
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.SUCCESS)
                .width('100%')
                .padding(AppSpacing.SM)
                .backgroundColor(AppColors.SUCCESS_BG)
                .borderRadius(AppRadius.SM)
                .margin({ bottom: AppSpacing.SM })
            }

            Column() {
              Stack() {
                Image(this.avatarSource())
                  .width(80)
                  .height(80)
                  .borderRadius(40)
                  .objectFit(ImageFit.Cover)
                if (this.uploading) {
                  LoadingProgress()
                    .width(28)
                    .height(28)
                    .color(AppColors.PRIMARY)
                    .backgroundColor('#CCFFFFFF')
                    .borderRadius(14)
                }
              }
              Text(this.uploading ? '头像上传中...' : '点击更换头像')
                .fontSize(AppFontSize.XS)
                .fontColor(AppColors.TEXT_MUTED)
                .margin({ top: AppSpacing.SM })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .padding({ top: AppSpacing.MD, bottom: AppSpacing.MD })
            .backgroundColor(AppColors.BG_CARD)
            .borderRadius(AppRadius.LG)
            .onClick(() => {
              this.selectAvatar()
            })
            .animation({ duration: 180 })

            Column() {
              this.infoRow('昵称', this.username, 'username')
              Divider().width('100%').height(0.5).color(AppColors.BORDER)
              this.infoRow('手机号', this.formatPhone(this.phone), 'phone')
              Divider().width('100%').height(0.5).color(AppColors.BORDER)
              this.infoRow('邮箱', this.formatEmail(this.email), 'email')
            }
            .width('100%')
            .backgroundColor(AppColors.BG_CARD)
            .borderRadius(AppRadius.LG)
            .margin({ top: AppSpacing.MD })

            if (this.editingField === 'password') {
              this.passwordEditor()
            } else {
              Row() {
                SymbolGlyph($r('sys.symbol.lock'))
                  .fontSize(22)
                  .fontColor([AppColors.TEXT_SECONDARY])
                  .margin({ right: AppSpacing.MD })
                Text('密码')
                  .fontSize(AppFontSize.MD)
                  .fontColor(AppColors.TEXT_PRIMARY)
                  .layoutWeight(1)
                Button('修改', { type: ButtonType.Capsule })
                  .height(32)
                  .fontSize(AppFontSize.SM)
                  .fontColor(AppColors.PRIMARY)
                  .backgroundColor(AppColors.SELECTED_BG)
                  .onClick(() => {
                    this.startEdit('password')
                  })
              }
              .width('100%')
              .height(56)
              .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
              .backgroundColor(AppColors.BG_CARD)
              .borderRadius(AppRadius.LG)
              .margin({ top: AppSpacing.MD })
            }

            Text('手机号和邮箱修改需要验证当前密码，密码修改成功后需要重新登录。')
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.TEXT_MUTED)
              .width('100%')
              .margin({ top: AppSpacing.SM, bottom: AppSpacing.LG })
          }
          .width('100%')
          .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: AppSpacing.XL })
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

  @Builder
  infoRow(label: string, value: string, field: string) {
    if (this.editingField === field) {
      this.editRow(label, field)
    } else {
      this.displayRow(label, value, field)
    }
  }

  @Builder
  editRow(label: string, field: string) {
    Column() {
      Row() {
        Text(label)
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_SECONDARY)
          .width(72)
        TextInput({ text: this.editValue })
          .maxLength(field === 'phone' ? 11 : 40)
          .type(field === 'phone' ? InputType.PhoneNumber : InputType.Normal)
          .onChange((value: string) => {
            this.editValue = value
            this.errorText = ''
          })
          .height(36)
          .backgroundColor(AppColors.INPUT_BG)
          .borderRadius(AppRadius.SM)
          .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
          .layoutWeight(1)
      }
      if (field === 'phone' || field === 'email') {
        TextInput({ placeholder: '请输入当前密码', text: this.editPassword })
          .type(InputType.Password)
          .onChange((value: string) => {
            this.editPassword = value
            this.errorText = ''
          })
          .height(36)
          .backgroundColor(AppColors.INPUT_BG)
          .borderRadius(AppRadius.SM)
          .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
          .width('100%')
          .margin({ left: 72, top: AppSpacing.XS })
      }
      Row() {
        Button(this.saving ? '保存中...' : '保存', { type: ButtonType.Capsule })
          .height(32)
          .fontSize(AppFontSize.SM)
          .backgroundColor(this.saving ? AppColors.TEXT_MUTED : AppColors.PRIMARY)
          .enabled(!this.saving)
          .onClick(() => {
            this.saveEdit()
          })
        Button('取消', { type: ButtonType.Capsule })
          .height(32)
          .fontSize(AppFontSize.SM)
          .fontColor(AppColors.TEXT_SECONDARY)
          .backgroundColor(AppColors.INPUT_BG)
          .margin({ left: AppSpacing.SM })
          .enabled(!this.saving)
          .onClick(() => {
            this.cancelEdit()
          })
      }
      .margin({ left: 72, top: AppSpacing.XS })
    }
    .width('100%')
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.SM })
    .backgroundColor(AppColors.BG_CARD)
  }

  @Builder
  displayRow(label: string, value: string, field: string) {
    Row() {
      Text(label)
        .fontSize(AppFontSize.MD)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width(72)
      Text(value || '未设置')
        .fontSize(AppFontSize.MD)
        .fontColor(AppColors.TEXT_PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      Button('编辑', { type: ButtonType.Capsule })
        .height(32)
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.PRIMARY)
        .backgroundColor(AppColors.SELECTED_BG)
        .onClick(() => {
          this.startEdit(field)
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  passwordEditor() {
    Column() {
      Text('修改密码')
        .fontSize(AppFontSize.LG)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')
        .margin({ bottom: AppSpacing.SM })
      TextInput({ placeholder: '原密码', text: this.editPassword })
        .type(InputType.Password)
        .onChange((value: string) => {
          this.editPassword = value
          this.errorText = ''
        })
        .height(44)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
        .width('100%')
      TextInput({ placeholder: '新密码（6-20位）', text: this.editValue })
        .type(InputType.Password)
        .onChange((value: string) => {
          this.editValue = value
          this.errorText = ''
        })
        .height(44)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
        .width('100%')
        .margin({ top: AppSpacing.SM })
      TextInput({ placeholder: '确认新密码', text: this.editConfirm })
        .type(InputType.Password)
        .onChange((value: string) => {
          this.editConfirm = value
          this.errorText = ''
        })
        .height(44)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
        .width('100%')
        .margin({ top: AppSpacing.SM })
      Row() {
        Button(this.saving ? '提交中...' : '确认修改', { type: ButtonType.Capsule })
          .height(40)
          .fontSize(AppFontSize.MD)
          .backgroundColor(this.saving ? AppColors.TEXT_MUTED : AppColors.PRIMARY)
          .enabled(!this.saving)
          .onClick(() => {
            this.savePassword()
          })
        Button('取消', { type: ButtonType.Capsule })
          .height(40)
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_SECONDARY)
          .backgroundColor(AppColors.INPUT_BG)
          .margin({ left: AppSpacing.SM })
          .enabled(!this.saving)
          .onClick(() => {
            this.cancelEdit()
          })
      }
      .width('100%')
      .margin({ top: AppSpacing.MD })
    }
    .width('100%')
    .padding(AppSpacing.MD)
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius(AppRadius.LG)
    .margin({ top: AppSpacing.MD })
  }
}
