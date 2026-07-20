import { router } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';

const PREF_NAME = 'user_profile_db';
const KEY_USERNAME = 'username';
const KEY_PHONE = 'phone';
const KEY_EMAIL = 'email';
const KEY_PASSWORD = 'password';
const KEY_AVATAR = 'avatarUri';

@Entry
@Component
struct ProfileDetailPage {
  @State username: string = ''
  @State phone: string = ''
  @State email: string = ''
  @State password: string = ''
  @State avatarUri: string = ''

  @State editingField: string = ''
  @State editValue: string = ''

  @State showPasswordVerify: boolean = false
  @State oldPasswordInput: string = ''
  @State verifyError: string = ''
  @State newPassword: string = ''

  aboutToAppear(): void {
    this.loadProfile()
  }

  loadProfile(): void {
    let pref = preferences.getPreferencesSync(getContext(), { name: PREF_NAME })
    this.username = pref.getSync(KEY_USERNAME, this.generateDefaultUsername()) as string
    this.phone = pref.getSync(KEY_PHONE, '') as string
    this.email = pref.getSync(KEY_EMAIL, '') as string
    this.password = pref.getSync(KEY_PASSWORD, '') as string
    this.avatarUri = pref.getSync(KEY_AVATAR, '') as string
  }

  saveProfile(): void {
    let pref = preferences.getPreferencesSync(getContext(), { name: PREF_NAME })
    pref.putSync(KEY_USERNAME, this.username)
    pref.putSync(KEY_PHONE, this.phone)
    pref.putSync(KEY_EMAIL, this.email)
    pref.putSync(KEY_PASSWORD, this.password)
    pref.putSync(KEY_AVATAR, this.avatarUri)
    pref.flushSync()
  }

  generateDefaultUsername(): string {
    let num = Math.floor(10000 + Math.random() * 90000)
    return '用户' + num
  }

  formatPhone(phone: string): string {
    if (phone.length >= 7) {
      return phone.slice(0, 3) + '****' + phone.slice(-4)
    }
    return phone
  }

  startEdit(field: string): void {
    if (field === 'password') {
      this.showPasswordVerify = true
      this.oldPasswordInput = ''
      this.verifyError = ''
      return
    }
    this.editingField = field
    this.editValue = this.getFieldValue(field)
  }

  getFieldValue(field: string): string {
    switch (field) {
      case 'username': return this.username
      case 'phone': return this.phone
      case 'email': return this.email
      default: return ''
    }
  }

  saveEdit(): void {
    let val = this.editValue.trim()
    if (!val) return
    switch (this.editingField) {
      case 'username':
        this.username = val
        break
      case 'phone':
        this.phone = val
        break
      case 'email':
        this.email = val
        break
    }
    this.saveProfile()
    this.editingField = ''
    this.editValue = ''
  }

  cancelEdit(): void {
    this.editingField = ''
    this.editValue = ''
    this.showPasswordVerify = false
    this.oldPasswordInput = ''
    this.verifyError = ''
    this.newPassword = ''
  }

  verifyOldPassword(): void {
    if (this.oldPasswordInput === this.password) {
      this.showPasswordVerify = false
      this.editingField = 'password'
      this.editValue = ''
      this.verifyError = ''
      return
    }
    this.verifyError = '原密码错误'
  }

  savePassword(): void {
    let val = this.editValue.trim()
    if (!val) return
    this.password = val
    this.saveProfile()
    this.editingField = ''
    this.editValue = ''
  }

  selectAvatar(): void {
    try {
      let picker = new photoAccessHelper.PhotoViewPicker()
      picker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      }).then((result: photoAccessHelper.PhotoSelectResult) => {
        if (result.photoUris.length > 0) {
          this.avatarUri = result.photoUris[0]
          this.saveProfile()
        }
      }).catch(() => { })
    } catch (err) {
      console.error('选择图片失败:', JSON.stringify(err))
    }
  }

  avatarSource(): Resource | string {
    return this.avatarUri ? this.avatarUri : $r('app.media.theme')
  }

  build() {
    Column() {
      NavBar({
        title: '个人资料',
        showBack: true,
        onBack: () => router.back()
      })

      Column() {
        Image(this.avatarSource())
          .width(72)
          .height(72)
          .borderRadius(36)
        Text('点击更换头像')
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.TEXT_MUTED)
          .margin({ top: AppSpacing.SM })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.selectAvatar()
      })
      .margin({ bottom: AppSpacing.LG })

      this.infoRow('用户名', this.username, 'username')

      if (this.editingField === 'phone') {
        this.editRow('手机号', 'phone')
      } else {
        this.displayRow('手机号', this.formatPhone(this.phone), 'phone')
      }

      this.infoRow('邮箱', this.email, 'email')

      if (this.editingField === 'password') {
        Row() {
          Text('密码')
            .fontSize(AppFontSize.MD)
            .fontColor(AppColors.TEXT_SECONDARY)
            .width(70)
          TextInput({ text: this.editValue })
            .type(InputType.Password)
            .onChange((val: string) => {
              this.editValue = val
            })
            .height(36)
            .backgroundColor(AppColors.INPUT_BG)
            .borderRadius(AppRadius.SM)
            .padding({ left: AppSpacing.SM })
            .layoutWeight(1)
          Text('保存')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.PRIMARY)
            .margin({ left: AppSpacing.SM })
            .onClick(() => {
              this.savePassword()
            })
          Text('取消')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
            .margin({ left: AppSpacing.SM })
            .onClick(() => {
              this.cancelEdit()
            })
        }
        .width('100%')
        .height(56)
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
        .alignItems(VerticalAlign.Center)
      } else if (this.showPasswordVerify) {
        Column() {
          Row() {
            Text('密码')
              .fontSize(AppFontSize.MD)
              .fontColor(AppColors.TEXT_SECONDARY)
              .width(70)
            TextInput({ placeholder: '请输入原密码', text: this.oldPasswordInput })
              .type(InputType.Password)
              .onChange((val: string) => {
                this.oldPasswordInput = val
                this.verifyError = ''
              })
              .height(36)
              .backgroundColor(AppColors.INPUT_BG)
              .borderRadius(AppRadius.SM)
              .padding({ left: AppSpacing.SM })
              .layoutWeight(1)
            Text('验证')
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.PRIMARY)
              .margin({ left: AppSpacing.SM })
              .onClick(() => {
                this.verifyOldPassword()
              })
            Text('取消')
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.TEXT_MUTED)
              .margin({ left: AppSpacing.SM })
              .onClick(() => {
                this.cancelEdit()
              })
          }
          .width('100%')
          .height(56)
          .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
          .alignItems(VerticalAlign.Center)

          if (this.verifyError) {
            Text(this.verifyError)
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.DANGER)
              .width('100%')
              .padding({ left: 100 })
          }
        }
      } else {
        Row() {
          Text('密码')
            .fontSize(AppFontSize.MD)
            .fontColor(AppColors.TEXT_SECONDARY)
            .width(70)
          Text('********')
            .fontSize(AppFontSize.MD)
            .fontColor(AppColors.TEXT_PRIMARY)
            .layoutWeight(1)
          Text(this.password ? '修改' : '设置')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.PRIMARY)
            .onClick(() => {
              this.startEdit('password')
            })
        }
        .width('100%')
        .height(56)
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  @Builder infoRow(label: string, value: string, field: string) {
    if (this.editingField === field) {
      this.editRow(label, field)
    } else {
      this.displayRow(label, value, field)
    }
  }

  @Builder editRow(label: string, field: string) {
    Row() {
      Text(label)
        .fontSize(AppFontSize.MD)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width(70)
      TextInput({ text: this.editValue })
        .onChange((val: string) => {
          this.editValue = val
        })
        .height(36)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .padding({ left: AppSpacing.SM })
        .layoutWeight(1)
      Text('保存')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.PRIMARY)
        .margin({ left: AppSpacing.SM })
        .onClick(() => {
          this.saveEdit()
        })
      Text('取消')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_MUTED)
        .margin({ left: AppSpacing.SM })
        .onClick(() => {
          this.cancelEdit()
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
    .alignItems(VerticalAlign.Center)
  }

  @Builder displayRow(label: string, value: string, field: string) {
    Row() {
      Text(label)
        .fontSize(AppFontSize.MD)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width(70)
      Text(value)
        .fontSize(AppFontSize.MD)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
      Text('编辑')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.PRIMARY)
        .onClick(() => {
          this.startEdit(field)
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.startEdit(field)
    })
  }
}
