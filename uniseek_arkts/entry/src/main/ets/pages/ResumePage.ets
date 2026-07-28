import { SegmentButton, SegmentButtonOptions } from '@kit.ArkUI';
import { picker, fileIo } from '@kit.CoreFileKit';
import { ChatService } from '../services/ChatService';
import { ResumeService, ResumeRequest } from '../services/ResumeService';
import { AppColors, AppSpacing, AppRadius, AppFontSize, PrimaryButton, StandardInput } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';
import { ResumeCompletionPolicy } from '../common/BusinessPolicies';
import { UploadPolicy } from '../common/FormValidators';

const EDUCATION_LEVELS: string[] = ['初中及以下', '中专/中技', '高中', '大专', '本科', '硕士', '博士']
const FULLTIME_OPTIONS: string[] = ['全日制', '非全日制']

// 学历选择弹窗
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
    Column({ space: AppSpacing.MD }) {
      Text('选择学历')
        .fontSize(AppFontSize.LG)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')

      Row({ space: AppSpacing.SM }) {
        Scroll() {
          Column({ space: AppSpacing.SM }) {
            ForEach(EDUCATION_LEVELS, (level: string) => {
              Text(level)
                .fontSize(AppFontSize.MD)
                .fontColor(this.selectedEducation === level ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
                .backgroundColor(this.selectedEducation === level ? AppColors.PRIMARY : 'transparent')
                .borderRadius(AppRadius.MD)
                .padding({ top: AppSpacing.SM, bottom: AppSpacing.SM, left: AppSpacing.MD, right: AppSpacing.MD })
                .width('100%')
                .textAlign(TextAlign.Center)
                .onClick(() => {
                  this.selectedEducation = level
                  if (!this.needFullTime()) {
                    this.selectedIsFullTime = false
                  }
                })
            }, (level: string) => level)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .width(0)

        if (this.needFullTime()) {
          Scroll() {
            Column({ space: AppSpacing.SM }) {
              ForEach(FULLTIME_OPTIONS, (option: string) => {
                Text(option)
                  .fontSize(AppFontSize.MD)
                  .fontColor((option === '全日制' && this.selectedIsFullTime) ||
                    (option === '非全日制' && !this.selectedIsFullTime) ? '#FFFFFF' : AppColors.TEXT_PRIMARY)
                  .backgroundColor((option === '全日制' && this.selectedIsFullTime) ||
                    (option === '非全日制' && !this.selectedIsFullTime) ? AppColors.PRIMARY : 'transparent')
                  .borderRadius(AppRadius.MD)
                  .padding({ top: AppSpacing.SM, bottom: AppSpacing.SM, left: AppSpacing.MD, right: AppSpacing.MD })
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .onClick(() => {
                    this.selectedIsFullTime = (option === '全日制')
                  })
              }, (option: string) => option)
            }
            .width('100%')
          }
          .layoutWeight(1)
          .width(0)
        }
      }
      .layoutWeight(1)
      .width('100%')

      Row({ space: AppSpacing.SM }) {
        Button('取消', { type: ButtonType.Normal })
          .layoutWeight(1)
          .height(AppSpacing.BUTTON_HEIGHT)
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_PRIMARY)
          .backgroundColor(AppColors.INPUT_BG)
          .onClick(() => { this.onCancel?.() })

        Button('确定', { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(AppSpacing.BUTTON_HEIGHT)
          .fontSize(AppFontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor(AppColors.PRIMARY)
          .onClick(() => {
            this.onConfirm?.(this.selectedEducation, this.selectedIsFullTime)
          })
      }
      .width('100%')
    }
    .padding(AppSpacing.LG)
    .width('100%')
    .height('55%')
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius({ topLeft: AppRadius.XL, topRight: AppRadius.XL })
  }
}

// 日期选择弹窗
@CustomDialog
struct DatePickerDialog {
  controller?: CustomDialogController
  title: string = '选择日期'
  currentDate: string = ''
  startDate?: Date
  endDate?: Date
  onConfirm?: (date: string) => void
  onCancel?: () => void

  @State selectedDate: Date = new Date()

  aboutToAppear(): void {
    if (this.currentDate) {
      const parsed = new Date(this.currentDate.replace(/-/g, '/'))
      if (!isNaN(parsed.getTime())) {
        this.selectedDate = parsed
      }
    }
  }

  formatDate(date: Date): string {
    const y = date.getFullYear()
    const m = String(date.getMonth() + 1).padStart(2, '0')
    const d = String(date.getDate()).padStart(2, '0')
    return `${y}-${m}-${d}`
  }

  build() {
    Column({ space: AppSpacing.MD }) {
      Text(this.title)
        .fontSize(AppFontSize.LG)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')

      DatePicker({
        start: this.startDate,
        end: this.endDate,
        selected: this.selectedDate
      })
        .lunar(false)
        .onDateChange((value: Date) => {
          this.selectedDate = value
        })
        .layoutWeight(1)
        .width('100%')

      Row({ space: AppSpacing.SM }) {
        Button('取消', { type: ButtonType.Normal })
          .layoutWeight(1)
          .height(AppSpacing.BUTTON_HEIGHT)
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_PRIMARY)
          .backgroundColor(AppColors.INPUT_BG)
          .onClick(() => { this.onCancel?.() })

        Button('确定', { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(AppSpacing.BUTTON_HEIGHT)
          .fontSize(AppFontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor(AppColors.PRIMARY)
          .onClick(() => {
            this.onConfirm?.(this.formatDate(this.selectedDate))
          })
      }
      .width('100%')
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
  @State genderIndexes: number[] = []
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
  @State isLoadingResume: boolean = true
  @State loadError: string = ''
  @State errorMsg: string = ''
  @State showSuccess: boolean = false

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
      }
    }).catch(() => {
      this.loadError = '简历加载失败，请重新加载'
    }).finally(() => {
      this.isLoadingResume = false
    })
  }

  completionRate(): number {
    return ResumeCompletionPolicy.calculate(
      this.name,
      this.gender,
      this.birthDate,
      this.education,
      this.school,
      this.graduationDate,
      this.skills,
      this.experience
    )
  }

  educationLabel(): string {
    if (!this.education) {
      return '请选择学历'
    }
    if (['大专', '本科', '硕士', '博士'].indexOf(this.education) >= 0) {
      return this.education + ' · ' + (this.isFullTime ? '全日制' : '非全日制')
    }
    return this.education
  }

  // 分节标题
  @Builder
  sectionHeader(title: string) {
    Column({ space: AppSpacing.XS }) {
      Text(title)
        .fontSize(AppFontSize.MD)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')

      Divider()
        .strokeWidth(AppSpacing.DIVIDER_THICKNESS)
        .color(AppColors.BORDER)
        .opacity(0.4)
        .width('100%')
    }
    .width('100%')
  }

  // 文本标签
  @Builder
  fieldLabel(text: string) {
    Text(text)
      .fontSize(AppFontSize.SM)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.TEXT_PRIMARY)
      .width('100%')
  }

  // 选择器字段（学历、日期等）
  @Builder
  selectorField(label: string, value: string, placeholder: string, onTap: () => void) {
    Column({ space: AppSpacing.XS }) {
      this.fieldLabel(label)
      Row() {
        Text(value || placeholder)
          .fontSize(AppFontSize.MD)
          .fontColor(value ? AppColors.TEXT_PRIMARY : AppColors.TEXT_MUTED)
          .layoutWeight(1)
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(AppFontSize.MD)
          .fontColor([AppColors.TEXT_MUTED])
      }
      .width('100%')
      .height(AppSpacing.INPUT_HEIGHT_STANDARD)
      .backgroundColor(AppColors.INPUT_BG)
      .borderRadius(AppRadius.PILL)
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
      .alignItems(VerticalAlign.Center)
      .onClick(() => onTap())
    }
    .width('100%')
  }

  // 只读字段（姓名）
  @Builder
  readOnlyField(label: string, value: string) {
    Column({ space: AppSpacing.XS }) {
      this.fieldLabel(label)
      Row() {
        Text(value || '（暂未获取）')
          .fontSize(AppFontSize.MD)
          .fontColor(value ? AppColors.TEXT_PRIMARY : AppColors.TEXT_MUTED)
          .layoutWeight(1)
      }
      .width('100%')
      .height(AppSpacing.INPUT_HEIGHT_STANDARD)
      .backgroundColor(AppColors.INPUT_BG)
      .borderRadius(AppRadius.PILL)
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
  }

  // 状态提示
  @Builder
  statusBanner(message: string, bgColor: ResourceColor, textColor: ResourceColor, icon?: Resource) {
    Row({ space: AppSpacing.SM }) {
      if (icon) {
        SymbolGlyph(icon)
          .fontSize(AppFontSize.ICON_MD)
          .fontColor([textColor])
      }
      Text(message)
        .fontSize(AppFontSize.SM)
        .fontColor(textColor)
        .layoutWeight(1)
    }
    .width('100%')
    .padding(AppSpacing.MD)
    .backgroundColor(bgColor)
    .borderRadius(AppRadius.LG)
  }

  // 完成度进度卡片
  @Builder
  completionCard() {
    Column({ space: AppSpacing.SM }) {
      Row() {
        Text('简历完整度')
          .fontSize(AppFontSize.MD)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
        Text(`${this.completionRate()}%`)
          .fontSize(AppFontSize.MD)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.completionRate() === 100 ? AppColors.SUCCESS : AppColors.PRIMARY)
      }
      .width('100%')

      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(8)
          .backgroundColor(AppColors.INPUT_BG)
          .borderRadius(AppRadius.PILL)
        Row()
          .width(`${this.completionRate()}%`)
          .height(8)
          .backgroundColor(this.completionRate() === 100 ? AppColors.SUCCESS : AppColors.PRIMARY)
          .borderRadius(AppRadius.PILL)
          .animation({ duration: 300, curve: Curve.EaseInOut })
      }
      .width('100%')

      Text(this.completionRate() === 100 ? '简历信息很完整，可以开始投递心仪的职位了' : '继续完善信息，让企业更快了解你')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
    }
    .width('100%')
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius(AppRadius.LG)
    .padding(AppSpacing.MD)
  }

  // 附件简历区域
  @Builder
  attachmentSection() {
    Column({ space: AppSpacing.XS }) {
      this.fieldLabel('附件简历（PDF）')
      Row() {
        Text(this.attachmentName || '未选择文件')
          .fontSize(AppFontSize.MD)
          .fontColor(this.attachmentName ? AppColors.TEXT_PRIMARY : AppColors.TEXT_MUTED)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Button(this.uploading ? '上传中...' : (this.attachmentName ? '重新选择' : '选择文件'), { type: ButtonType.Capsule })
          .height(AppSpacing.BUTTON_HEIGHT_SM)
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.PRIMARY)
          .backgroundColor(AppColors.SELECTED_BG)
          .enabled(!this.uploading)
          .onClick(() => { this.selectFile() })
      }
      .width('100%')
      .height(AppSpacing.INPUT_HEIGHT_STANDARD)
      .backgroundColor(AppColors.INPUT_BG)
      .borderRadius(AppRadius.PILL)
      .padding({ left: AppSpacing.MD, right: AppSpacing.SM })
      .alignItems(VerticalAlign.Center)

      if (this.attachmentUrl) {
        Row({ space: AppSpacing.SM }) {
          Button('预览', { type: ButtonType.Capsule })
            .height(AppSpacing.BUTTON_HEIGHT_SM)
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.PRIMARY)
            .backgroundColor(AppColors.SELECTED_BG)
            .onClick((): void => { void ChatService.previewAttachment(this.attachmentUrl) })
          Button('删除', { type: ButtonType.Capsule })
            .height(AppSpacing.BUTTON_HEIGHT_SM)
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.DANGER)
            .backgroundColor(AppColors.ERROR_BG)
            .onClick((): void => {
              this.attachmentUrl = ''
              this.attachmentName = ''
            })
        }
        .width('100%')
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      NavBar({ title: '个人简历', showBack: true })

      Scroll() {
        Column({ space: AppSpacing.LG }) {
          if (this.isLoadingResume) {
            Row({ space: AppSpacing.SM }) {
              LoadingProgress().width(20).height(20).color(AppColors.PRIMARY)
              Text('正在加载简历...')
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.TEXT_MUTED)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding(AppSpacing.MD)
          } else if (this.loadError) {
            Column({ space: AppSpacing.MD }) {
              this.statusBanner(this.loadError, AppColors.ERROR_BG, AppColors.DANGER, $r('sys.symbol.exclamationmark_circle'))
              Button('重新加载', { type: ButtonType.Capsule })
                .width('100%')
                .height(AppSpacing.BUTTON_HEIGHT)
                .fontSize(AppFontSize.MD)
                .fontColor(AppColors.PRIMARY)
                .backgroundColor(AppColors.SELECTED_BG)
                .onClick(() => { this.loadResume() })
            }
            .width('100%')
          } else {
            // 完成度
            this.completionCard()

            // 基本信息
            Column({ space: AppSpacing.MD }) {
              this.sectionHeader('基本信息')
              this.readOnlyField('姓名', this.name)
              Column({ space: AppSpacing.XS }) {
                this.fieldLabel('性别')
                SegmentButton({
                  options: this.genderOptions,
                  selectedIndexes: $genderIndexes,
                  onItemClicked: (index: number): void => { this.gender = index }
                })
                  .width('100%')
              }
              .width('100%')
              this.selectorField('出生日期', this.birthDate, '请选择出生日期', () => { this.showBirthDatePicker() })
            }
            .width('100%')
            .backgroundColor(AppColors.BG_CARD)
            .borderRadius(AppRadius.LG)
            .padding(AppSpacing.MD)

            // 教育经历
            Column({ space: AppSpacing.MD }) {
              this.sectionHeader('教育经历')
              StandardInput({
                value: $school,
                placeholder: '请输入毕业院校'
              })
              this.selectorField('学历', this.educationLabel(), '请选择学历', () => { this.showEducationPicker() })
              this.selectorField('毕业日期', this.graduationDate, '请选择毕业日期', () => { this.showGraduationDatePicker() })
            }
            .width('100%')
            .backgroundColor(AppColors.BG_CARD)
            .borderRadius(AppRadius.LG)
            .padding(AppSpacing.MD)

            // 个人优势
            Column({ space: AppSpacing.MD }) {
              this.sectionHeader('个人优势')
              TextArea({ placeholder: '描述你的技能特长，如沟通能力强、熟练使用 Office 等', text: this.skills })
                .onChange((value: string) => { this.skills = value })
                .width('100%')
                .height(100)
                .backgroundColor(AppColors.INPUT_BG)
                .borderRadius(AppRadius.LG)
                .padding(AppSpacing.MD)
                .fontSize(AppFontSize.MD)
                .fontColor(AppColors.TEXT_PRIMARY)
                .placeholderColor(AppColors.TEXT_MUTED)
                .align(Alignment.TopStart)
            }
            .width('100%')
            .backgroundColor(AppColors.BG_CARD)
            .borderRadius(AppRadius.LG)
            .padding(AppSpacing.MD)

            // 实践经历
            Column({ space: AppSpacing.MD }) {
              this.sectionHeader('实践经历')
              TextArea({ placeholder: '描述你的校园经历、实习经历或项目经验', text: this.experience })
                .onChange((value: string) => { this.experience = value })
                .width('100%')
                .height(120)
                .backgroundColor(AppColors.INPUT_BG)
                .borderRadius(AppRadius.LG)
                .padding(AppSpacing.MD)
                .fontSize(AppFontSize.MD)
                .fontColor(AppColors.TEXT_PRIMARY)
                .placeholderColor(AppColors.TEXT_MUTED)
                .align(Alignment.TopStart)
            }
            .width('100%')
            .backgroundColor(AppColors.BG_CARD)
            .borderRadius(AppRadius.LG)
            .padding(AppSpacing.MD)

            // 附件
            Column({ space: AppSpacing.MD }) {
              this.sectionHeader('附件简历')
              this.attachmentSection()
            }
            .width('100%')
            .backgroundColor(AppColors.BG_CARD)
            .borderRadius(AppRadius.LG)
            .padding(AppSpacing.MD)

            PrimaryButton({
              text: '保存简历',
              loading: this.saving,
              disabled: this.isLoadingResume || this.loadError !== '',
              onTap: () => { void this.handleSave() }
            })

            if (this.errorMsg) {
              this.statusBanner(this.errorMsg, AppColors.ERROR_BG, AppColors.DANGER, $r('sys.symbol.exclamationmark_circle'))
            }

            if (this.showSuccess) {
              this.statusBanner('保存成功', AppColors.SUCCESS_BG, AppColors.SUCCESS, $r('sys.symbol.checkmark'))
            }
          }
        }
        .width('100%')
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.LG, bottom: AppSpacing.XL })
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  selectFile(): void {
    const documentPicker = new picker.DocumentViewPicker(getContext())
     const options: picker.DocumentSelectOptions = new picker.DocumentSelectOptions()
     options.maxSelectNumber = 1
     options.fileSuffixFilters = ['PDF文档|.pdf']
     documentPicker.select(options).then((uris: string[]) => {
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
        this.getUIContext().getPromptAction().showToast({ message: errorText })
        return
      }
      this.attachmentName = fileName
      this.uploading = true
       ChatService.uploadResumeAttachment(uri).then((url: string) => {
        this.attachmentUrl = url
        this.getUIContext().getPromptAction().showToast({ message: '简历上传成功' })
      }).catch(() => {
        this.attachmentUrl = ''
        this.getUIContext().getPromptAction().showToast({ message: '简历上传失败，请重试' })
      }).finally(() => {
        this.uploading = false
      })
    }).catch(() => {
      this.getUIContext().getPromptAction().showToast({ message: '未选择文件' })
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

  private showDatePicker(title: string, target: 'birthDate' | 'graduationDate'): void {
    const now = new Date()
    const startDate = target === 'birthDate' ? new Date('1950-01-01') : new Date('1970-01-01')
    const endDate = target === 'birthDate' ? now : new Date(now.getFullYear() + 10, 11, 31)
    const dialog = new CustomDialogController({
      builder: DatePickerDialog({
        title: title,
        currentDate: target === 'birthDate' ? this.birthDate : this.graduationDate,
        startDate: startDate,
        endDate: endDate,
        onConfirm: (date: string) => {
          if (target === 'birthDate') {
            this.birthDate = date
          } else {
            this.graduationDate = date
          }
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

  showBirthDatePicker(): void {
    this.showDatePicker('选择出生日期', 'birthDate')
  }

  showGraduationDatePicker(): void {
    this.showDatePicker('选择毕业日期', 'graduationDate')
  }

  async handleSave(): Promise<void> {
    this.saving = true
    this.errorMsg = ''
    this.showSuccess = false
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
    try {
      await ResumeService.saveResume(data)
      this.showSuccess = true
      setTimeout(() => {
        this.getUIContext().getRouter().back()
      }, 1500)
    } catch (e) {
      this.errorMsg = (e as Error).message || '保存失败，请重试'
    } finally {
      this.saving = false
    }
  }
}
