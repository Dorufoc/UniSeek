import { router, promptAction, SegmentButton, SegmentButtonOptions } from '@kit.ArkUI';
import { picker } from '@kit.CoreFileKit';
import { fileIo } from '@kit.CoreFileKit';
import { ChatService } from '../services/ChatService';
import { ResumeService, ResumeRequest } from '../services/ResumeService';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';
import { ResumeCompletionPolicy } from '../common/BusinessPolicies'
import { UploadPolicy } from '../common/FormValidators'

const EDUCATION_LEVELS: string[] = ['初中及以下', '中专/中技', '高中', '大专', '本科', '硕士', '博士']
const FULLTIME_OPTIONS: string[] = ['全日制', '非全日制']

@CustomDialog
struct EducationPickerDialog {
  controller?: CustomDialogController
  currentEducation: string = ''
  currentIsFullTime: boolean = true
  onConfirm?: (education: string, isFullTime: boolean) => void
  onCancel?: () => void

  @State selectedEducation: string = ''
  @State selectedIsFullTime: boolean = true

  aboutToAppear(): void {
    this.selectedEducation = this.currentEducation
    this.selectedIsFullTime = this.currentIsFullTime
  }

  needFullTime(): boolean {
    return ['大专', '本科', '硕士', '博士'].indexOf(this.selectedEducation) >= 0
  }

  build() {
    Column() {
      Row() {
        Text('选择学历')
          .fontSize(AppFontSize.LG)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
        Button('取消', { type: ButtonType.Normal })
          .height(32)
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_MUTED)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.onCancel?.()
          })
      }
      .width('100%')
      .padding({ bottom: AppSpacing.MD })

      Row() {
        Scroll() {
          Column() {
            ForEach(EDUCATION_LEVELS, (level: string) => {
              Text(level)
                .fontSize(AppFontSize.MD)
                .fontColor(this.selectedEducation === level ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
                .backgroundColor(this.selectedEducation === level ? AppColors.PRIMARY : 'transparent')
                .borderRadius(AppRadius.SM)
                .padding({ top: AppSpacing.SM, bottom: AppSpacing.SM, left: AppSpacing.SM, right: AppSpacing.SM })
                .textAlign(TextAlign.Start)
                .width('100%')
                .onClick(() => {
                  this.selectedEducation = level
                  if (!this.needFullTime()) {
                    this.selectedIsFullTime = false
                  }
                })
                .animation({
                  duration: 150
                })
            }, (level: string) => level)
          }
          .width('100%')
          .padding({ left: 6, right: 6 })
        }
        .layoutWeight(1)
        .width(0)

        if (this.needFullTime()) {
          Scroll() {
            Column() {
              ForEach(FULLTIME_OPTIONS, (option: string) => {
                Text(option)
                  .fontSize(AppFontSize.MD)
                  .fontColor((option === '全日制' && this.selectedIsFullTime) ||
                    (option === '非全日制' && !this.selectedIsFullTime) ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
                  .backgroundColor((option === '全日制' && this.selectedIsFullTime) ||
                    (option === '非全日制' && !this.selectedIsFullTime) ? AppColors.PRIMARY : 'transparent')
                  .borderRadius(AppRadius.SM)
                  .padding({ top: AppSpacing.SM, bottom: AppSpacing.SM, left: AppSpacing.SM, right: AppSpacing.SM })
                  .textAlign(TextAlign.Start)
                  .width('100%')
                  .onClick(() => {
                    this.selectedIsFullTime = (option === '全日制')
                  })
                  .animation({
                    duration: 150
                  })
              }, (option: string) => option)
            }
            .width('100%')
            .padding({ left: 6, right: 6 })
          }
          .layoutWeight(1)
          .width(0)
        }
      }
      .layoutWeight(1)
      .width('100%')

        Row() {
          Row().layoutWeight(1)
          Button('确定', { type: ButtonType.Capsule })
            .height(40)
            .fontSize(AppFontSize.MD)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .backgroundColor(AppColors.PRIMARY)
            .padding({ left: 28, right: 28 })
          .onClick(() => {
            this.onConfirm?.(this.selectedEducation, this.selectedIsFullTime)
          })
          .stateStyles({
            pressed: {
              .scale({ x: 0.97, y: 0.97 })
              .opacity(0.9)
            },
            normal: {
              .scale({ x: 1, y: 1 })
              .opacity(1)
            }
          })
          .animation({
            duration: 200
          })
      }
      .width('100%')
      .padding({ top: AppSpacing.MD })
    }
    .padding(AppSpacing.LG)
    .width('100%')
    .height('55%')
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius({ topLeft: AppRadius.XL, topRight: AppRadius.XL })
  }
}

@Entry
@Component
struct ResumePage {
  @State name: string = ''
  @State gender: number = -1
  @State birthDate: string = ''
  @State school: string = ''
  @State education: string = ''
  @State isFullTime: boolean = false
  @State skills: string = ''
  @State experience: string = ''
  @State graduationDate: string = ''
  @State attachmentName: string = ''
  @State attachmentUrl: string = ''
  @State uploading: boolean = false
  @State saving: boolean = false
  @State showError: boolean = false
  @State errorMsg: string = ''
  @State showSuccess: boolean = false
  @State isLoadingResume: boolean = true
  @State loadError: string = ''
  @State isPublished: boolean = false
  @State isPublishing: boolean = false
  @State genderIndexes: number[] = []
  @State genderOptions: SegmentButtonOptions = SegmentButtonOptions.capsule({
    buttons: [{ text: '男' }, { text: '女' }],
    multiply: false,
    selectedBackgroundColor: AppColors.PRIMARY,
    backgroundColor: AppColors.INPUT_BG,
    selectedFontColor: '#FFFFFF',
    fontColor: AppColors.TEXT_SECONDARY
  })

  aboutToAppear(): void {
    this.loadResume()
  }

  loadResume(): void {
    this.isLoadingResume = true
    this.loadError = ''
    ResumeService.getMyResume().then((saved) => {
      if (saved) {
        this.name = saved.realName || ''
        this.gender = saved.gender
        this.genderIndexes = saved.gender === 0 || saved.gender === 1 ? [saved.gender] : []
        this.birthDate = saved.birthDate || ''
        this.school = saved.school || ''
        this.education = saved.education || ''
        this.skills = saved.skills || ''
        this.experience = saved.experience || ''
        this.graduationDate = saved.graduationDate || ''
        this.attachmentUrl = saved.attachmentUrl || ''
        this.attachmentName = saved.attachmentUrl ? saved.attachmentUrl.split('/').pop() || '' : ''
        this.isPublished = saved.isPublished === 1
      }
    }).catch(() => {
      this.loadError = '简历加载失败，为避免覆盖原数据，请重新加载'
    }).finally(() => {
      this.isLoadingResume = false
    })
  }

  educationLabel(): string {
    if (!this.education) {
      return '请选择学历'
    }
    if (['大专', '本科', '硕士', '博士'].indexOf(this.education) >= 0) {
      return this.education + ' ' + (this.isFullTime ? '全日制' : '非全日制')
    }
    return this.education
  }

  build() {
    Column() {
      NavBar({
        title: '个人简历',
        showBack: true,
        onBack: () => router.back()
      })

      Scroll() {
        Column() {
          if (this.isLoadingResume) {
            Row({ space: AppSpacing.SM }) {
              LoadingProgress().width(20).height(20).color(AppColors.PRIMARY)
              Text('正在加载简历').fontSize(AppFontSize.SM).fontColor(AppColors.TEXT_MUTED)
            }
            .width('100%')
            .padding(AppSpacing.SM)
            .margin({ bottom: AppSpacing.SM })
          } else if (this.loadError) {
            Row({ space: AppSpacing.SM }) {
              Text(this.loadError)
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.DANGER)
                .layoutWeight(1)
              Button('重新加载', { type: ButtonType.Capsule })
                .height(32)
                .fontSize(AppFontSize.XS)
                .fontColor(AppColors.PRIMARY)
                .backgroundColor(AppColors.SELECTED_BG)
                .onClick(() => { this.loadResume() })
            }
            .width('100%')
            .padding(AppSpacing.SM)
            .backgroundColor(AppColors.ERROR_BG)
            .borderRadius(AppRadius.SM)
            .margin({ bottom: AppSpacing.SM })
          }

          Text('姓名')
            .fontSize(AppFontSize.SM)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .width('100%')
            .margin({ bottom: AppSpacing.SM })

          Row() {
            Text(this.name || '（暂未获取）')
              .fontSize(AppFontSize.MD)
              .fontColor(AppColors.TEXT_MUTED)
          }
          .width('100%')
          .height(44)
          .backgroundColor(AppColors.INPUT_BG)
          .borderRadius(AppRadius.SM)
          .padding({ left: AppSpacing.SM })
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: AppSpacing.MD })

          Text('性别')
            .fontSize(AppFontSize.SM)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .width('100%')
            .margin({ bottom: AppSpacing.SM })
          SegmentButton({
            options: this.genderOptions,
            selectedIndexes: $genderIndexes,
            onItemClicked: (index: number): void => { this.gender = index }
          })
          .width('100%')
          .margin({ bottom: AppSpacing.MD })

          Text('出生日期')
            .fontSize(AppFontSize.SM)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .width('100%')
            .margin({ bottom: AppSpacing.SM })
          TextInput({ placeholder: '例如 2000-01-01', text: this.birthDate })
            .height(44)
            .maxLength(10)
            .backgroundColor(AppColors.INPUT_BG)
            .borderRadius(AppRadius.SM)
            .padding({ left: AppSpacing.SM })
            .onChange((value: string): void => { this.birthDate = value })
            .margin({ bottom: AppSpacing.MD })

          Text('学校')
            .fontSize(AppFontSize.SM)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .width('100%')
            .margin({ bottom: AppSpacing.SM })

          TextInput({ placeholder: '请输入毕业院校', text: this.school })
            .onChange((value: string) => { this.school = value })
            .height(44)
            .backgroundColor(AppColors.INPUT_BG)
            .borderRadius(AppRadius.SM)
            .padding({ left: AppSpacing.SM })
            .margin({ bottom: AppSpacing.MD })

          Text('学历')
            .fontSize(AppFontSize.SM)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .width('100%')
            .margin({ bottom: AppSpacing.SM })

          Row() {
            Text(this.educationLabel())
              .fontSize(AppFontSize.MD)
              .fontColor(this.education ? AppColors.TEXT_PRIMARY : AppColors.TEXT_MUTED)
              .layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(AppFontSize.MD)
              .fontColor([AppColors.TEXT_MUTED])
          }
          .width('100%')
          .height(44)
          .backgroundColor(AppColors.INPUT_BG)
          .borderRadius(AppRadius.SM)
          .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: AppSpacing.MD })

          Text('毕业日期')
            .fontSize(AppFontSize.SM)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .width('100%')
            .margin({ bottom: AppSpacing.SM })
          TextInput({ placeholder: '例如 2024-06-30', text: this.graduationDate })
            .height(44)
            .maxLength(10)
            .backgroundColor(AppColors.INPUT_BG)
            .borderRadius(AppRadius.SM)
            .padding({ left: AppSpacing.SM })
            .onChange((value: string): void => { this.graduationDate = value })
            .margin({ bottom: AppSpacing.MD })
          .onClick(() => {
            this.showEducationPicker()
          })

          Text('技能')
            .fontSize(AppFontSize.SM)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .width('100%')
            .margin({ bottom: AppSpacing.SM })

          TextArea({ placeholder: '请输入技能特长', text: this.skills })
            .onChange((value: string) => { this.skills = value })
            .height(80)
            .backgroundColor(AppColors.INPUT_BG)
            .borderRadius(AppRadius.SM)
            .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
            .margin({ bottom: AppSpacing.MD })

          Text('经历')
            .fontSize(AppFontSize.SM)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .width('100%')
            .margin({ bottom: AppSpacing.SM })

          TextArea({ placeholder: '请输入工作经历', text: this.experience })
            .onChange((value: string) => { this.experience = value })
            .height(100)
            .backgroundColor(AppColors.INPUT_BG)
            .borderRadius(AppRadius.SM)
            .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
            .margin({ bottom: AppSpacing.MD })

          Text('简历（PDF）')
            .fontSize(AppFontSize.SM)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .width('100%')
            .margin({ bottom: AppSpacing.SM })

          Row() {
            Button(this.uploading ? '上传中...' : '选择文件')
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.PRIMARY)
              .backgroundColor(AppColors.SELECTED_BG)
              .borderRadius(AppRadius.SM)
              .height(36)
              .enabled(!this.uploading)
              .onClick(() => {
                this.selectFile()
              })
              .stateStyles({
                pressed: {
                  .scale({ x: 0.97, y: 0.97 })
                  .opacity(0.9)
                },
                normal: {
                  .scale({ x: 1, y: 1 })
                  .opacity(1)
                }
              })
              .animation({
                duration: 200
              })
            if (this.attachmentName) {
              Text(this.attachmentName)
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.TEXT_PRIMARY)
                .margin({ left: AppSpacing.SM })
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            } else {
              Text('未选择文件')
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.TEXT_MUTED)
                .margin({ left: AppSpacing.SM })
            }
          }
          .width('100%')
          .height(44)
          .backgroundColor(AppColors.INPUT_BG)
          .borderRadius(AppRadius.SM)
          .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
          .alignItems(VerticalAlign.Center)

          if (this.attachmentUrl) {
            Row({ space: AppSpacing.SM }) {
              Button('预览', { type: ButtonType.Capsule })
                .height(32)
                .fontSize(AppFontSize.XS)
                .fontColor(AppColors.PRIMARY)
                .backgroundColor(AppColors.SELECTED_BG)
                .onClick((): void => { void ChatService.previewAttachment(this.attachmentUrl) })
              Button('删除', { type: ButtonType.Capsule })
                .height(32)
                .fontSize(AppFontSize.XS)
                .fontColor(AppColors.DANGER)
                .backgroundColor(AppColors.ERROR_BG)
                .onClick((): void => {
                  this.attachmentUrl = ''
                  this.attachmentName = ''
                })
            }
            .width('100%')
            .margin({ top: AppSpacing.SM })
          }

          if (this.showSuccess) {
            Text('保存成功')
              .fontSize(AppFontSize.MD)
              .fontColor('#FFFFFF')
              .width('100%')
              .height(44)
              .backgroundColor(AppColors.SUCCESS)
              .borderRadius(AppRadius.SM)
              .textAlign(TextAlign.Center)
              .margin({ top: AppSpacing.SM })
          }

          if (this.showError) {
            Text(this.errorMsg)
              .fontSize(AppFontSize.SM)
              .fontColor('#FFFFFF')
              .width('100%')
              .padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })
              .backgroundColor(AppColors.DANGER)
              .borderRadius(AppRadius.SM)
              .textAlign(TextAlign.Center)
              .margin({ top: AppSpacing.SM })
          }

          Button({ type: ButtonType.Capsule }) {
            Text('保存简历')
              .fontSize(AppFontSize.LG)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
            .width('100%')
            .height(48)
            .backgroundColor(this.saving || this.isLoadingResume || this.loadError !== '' ? AppColors.DISABLED : AppColors.PRIMARY)
            .enabled(!this.saving && !this.isLoadingResume && this.loadError === '')
            .margin({ top: AppSpacing.SM })
            .onClick(() => { this.handleSave() })
            .stateStyles({
              pressed: {
                .scale({ x: 0.97, y: 0.97 })
                .opacity(0.9)
                .backgroundColor(AppColors.PRIMARY_HOVER)
              },
              normal: {
                .scale({ x: 1, y: 1 })
                .opacity(1)
              }
            })
            .animation({
              duration: 200
            })

          Button({ type: ButtonType.Capsule }) {
            Text(this.isPublishing ? '正在更新...' : (this.isPublished ? '从人才市场下架' : '发布到人才市场'))
              .fontSize(AppFontSize.MD)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.isPublished ? AppColors.PRIMARY : '#FFFFFF')
          }
            .width('100%')
            .height(44)
            .backgroundColor(this.isPublished ? AppColors.SELECTED_BG : AppColors.PRIMARY)
            .enabled(!this.isPublishing && !this.saving)
            .margin({ top: AppSpacing.SM })
            .onClick((): void => { this.handlePublishToggle() })
        }
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.LG })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  selectFile(): void {
    const documentPicker = new picker.DocumentViewPicker(getContext())
    documentPicker.select({ maxSelectNumber: 1 } as picker.DocumentSelectOptions).then((uris: string[]) => {
      if (uris.length === 0) {
        return
      }
      const uri = uris[0]
      const fileName: string = uri.split('/').pop() || '简历.pdf'
      let errorText: string = ''
      try {
        const stat = fileIo.statSync(uri)
        errorText = UploadPolicy.validateResume(fileName, stat.size)
      } catch {
        errorText = '无法读取所选文件'
      }
      if (errorText) {
        promptAction.showToast({ message: errorText })
        return
      }
      this.attachmentName = fileName
      this.uploading = true
      ChatService.uploadFile(uri).then((url: string) => {
        this.attachmentUrl = url
        promptAction.showToast({ message: '简历上传成功' })
      }).catch(() => {
        this.attachmentUrl = ''
        promptAction.showToast({ message: '简历上传失败，请重试' })
      }).finally(() => {
        this.uploading = false
      })
    }).catch(() => {
      promptAction.showToast({ message: '未选择文件' })
    })
  }

  showEducationPicker(): void {
    const dialog = new CustomDialogController({
      builder: EducationPickerDialog({
        currentEducation: this.education,
        currentIsFullTime: this.isFullTime,
        onConfirm: (education: string, isFullTime: boolean) => {
          this.education = education
          this.isFullTime = isFullTime
          dialog.close()
        },
        onCancel: () => {
          dialog.close()
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Bottom
    })
    dialog.open()
  }

  handleSave(): void {
    this.saving = true
    this.showError = false
    const data: ResumeRequest = {
      gender: this.gender >= 0 ? this.gender : undefined,
      birthDate: this.birthDate || undefined,
      school: this.school || undefined,
      education: this.education || undefined,
      graduationDate: this.graduationDate || undefined,
      skills: this.skills || undefined,
      experience: this.experience || undefined,
      attachmentUrl: this.attachmentUrl || undefined
    }
    ResumeService.saveResume(data)
      .then(() => {
        this.saving = false
        this.showSuccess = true
        setTimeout(() => {
          router.back()
        }, 1500)
      })
      .catch((e: Error) => {
        this.saving = false
        this.showError = true
        this.errorMsg = e.message || '保存失败，请重试'
      })
  }

  handlePublishToggle(): void {
    if (!this.isPublished && !ResumeCompletionPolicy.canPublish(this.name, this.gender, this.birthDate,
      this.education, this.school, this.graduationDate)) {
      promptAction.showToast({ message: '请完善姓名、性别、出生日期、学历、学校和毕业日期后再发布' })
      return
    }
    this.isPublishing = true
    const request: Promise<void> = this.isPublished ? ResumeService.unpublishResume() : ResumeService.publishResume()
    request.then((): void => {
      this.isPublished = !this.isPublished
      promptAction.showToast({ message: this.isPublished ? '简历已发布到人才市场' : '简历已从人才市场下架' })
    }).catch((): void => {
      promptAction.showToast({ message: '简历状态更新失败，请稍后重试' })
    }).finally((): void => {
      this.isPublishing = false
    })
  }
}
