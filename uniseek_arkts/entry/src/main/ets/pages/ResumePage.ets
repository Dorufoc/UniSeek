import { router } from '@kit.ArkUI';
import { ResumeService, ResumeRequest } from '../services/ResumeService';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';

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
        Text('取消')
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_MUTED)
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
            })
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
              })
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
          Text('确定')
            .fontSize(AppFontSize.MD)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .backgroundColor(AppColors.PRIMARY)
            .borderRadius(AppRadius.FULL)
            .padding({ left: 28, right: 28, top: AppSpacing.SM, bottom: AppSpacing.SM })
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
  @State school: string = ''
  @State education: string = ''
  @State isFullTime: boolean = false
  @State skills: string = ''
  @State experience: string = ''
  @State attachmentName: string = ''
  @State saving: boolean = false
  @State showError: boolean = false
  @State errorMsg: string = ''
  @State showSuccess: boolean = false

  aboutToAppear(): void {
    ResumeService.getMyResume().then((saved) => {
      if (saved) {
        this.name = saved.realName || ''
        this.school = saved.school || ''
        this.education = saved.education || ''
        this.skills = saved.skills || ''
        this.experience = saved.experience || ''
        this.attachmentName = saved.attachmentUrl ? saved.attachmentUrl.split('/').pop() || '' : ''
      }
    }).catch(() => {})
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
            Button('选择文件')
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.PRIMARY)
              .backgroundColor(AppColors.SELECTED_BG)
              .borderRadius(AppRadius.SM)
              .height(36)
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
            .backgroundColor(this.saving ? AppColors.TEXT_MUTED : AppColors.PRIMARY)
            .enabled(!this.saving)
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
                .backgroundColor(AppColors.PRIMARY)
              }
            })
            .animation({
              duration: 200
            })
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
    // TODO: 对接后端后使用 filePicker 选择 PDF 文件
    // import { filePicker } from '@kit.CoreFileKit';
    // const documentPicker = new filePicker.DocumentViewPicker(getContext());
    // documentPicker.select({ maxSelectNumber: 1 }).then((uris: string[]) => {
    //   if (uris.length > 0) {
    //     this.attachmentName = uris[0].split('/').pop() || '简历.pdf'
    //   }
    // }).catch(() => {})
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
      school: this.school || undefined,
      education: this.education || undefined,
      skills: this.skills || undefined,
      experience: this.experience || undefined
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
}
