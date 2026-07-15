import { router } from '@kit.ArkUI';
import { ResumeService } from '../services/ResumeService';

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
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
        Text('取消')
          .fontSize(15)
          .fontColor('#999999')
          .onClick(() => {
            this.onCancel?.()
          })
      }
      .width('100%')
      .padding({ bottom: 16 })

      Row() {
        Scroll() {
          Column() {
            ForEach(EDUCATION_LEVELS, (level: string) => {
              Text(level)
                .fontSize(15)
                .fontColor(this.selectedEducation === level ? '#FFFFFF' : '#333333')
                .backgroundColor(this.selectedEducation === level ? '#007AFF' : 'transparent')
                .borderRadius(8)
                .padding({ top: 10, bottom: 10, left: 12, right: 12 })
                .textAlign(TextAlign.Start)
                .width('100%')
                .onClick(() => {
                  this.selectedEducation = level
                  if (!this.needFullTime()) {
                    this.selectedIsFullTime = false
                  }
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
                  .fontSize(15)
                  .fontColor((option === '全日制' && this.selectedIsFullTime) ||
                    (option === '非全日制' && !this.selectedIsFullTime) ? '#FFFFFF' : '#333333')
                  .backgroundColor((option === '全日制' && this.selectedIsFullTime) ||
                    (option === '非全日制' && !this.selectedIsFullTime) ? '#007AFF' : 'transparent')
                  .borderRadius(8)
                  .padding({ top: 10, bottom: 10, left: 12, right: 12 })
                  .textAlign(TextAlign.Start)
                  .width('100%')
                  .onClick(() => {
                    this.selectedIsFullTime = (option === '全日制')
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
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .borderRadius(20)
          .padding({ left: 28, right: 28, top: 10, bottom: 10 })
          .onClick(() => {
            this.onConfirm?.(this.selectedEducation, this.selectedIsFullTime)
          })
      }
      .width('100%')
      .padding({ top: 16 })
    }
    .padding(20)
    .width('100%')
    .height('55%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
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

  aboutToAppear(): void {
    // TODO: 对接后端后从 API 获取用户姓名
    const saved = ResumeService.loadResume()
    if (saved) {
      this.name = saved.name
      this.school = saved.school
      this.education = saved.education
      this.isFullTime = saved.isFullTime
      this.skills = saved.skills
      this.experience = saved.experience
      this.attachmentName = saved.attachmentName
    }
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
      Row() {
        Image($r('app.media.left_arrow'))
          .width(24)
          .height(24)
          .fillColor('#333333')
          .onClick(() => {
            router.back()
          })

        Text('个人简历')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row().width(24).height(24)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          Text('姓名')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .width('100%')
            .margin({ bottom: 8 })

          Row() {
            Text(this.name || '（暂未获取）')
              .fontSize(15)
              .fontColor('#999999')
          }
          .width('100%')
          .height(44)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 14 })
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 16 })

          Text('学校')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .width('100%')
            .margin({ bottom: 8 })

          TextInput({ placeholder: '请输入毕业院校', text: this.school })
            .onChange((value: string) => { this.school = value })
            .height(44)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({ left: 14 })
            .margin({ bottom: 16 })

          Text('学历')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .width('100%')
            .margin({ bottom: 8 })

          Row() {
            Text(this.educationLabel())
              .fontSize(15)
              .fontColor(this.education ? '#333333' : '#999999')
              .layoutWeight(1)
            Image($r('app.media.right_arrow'))
              .width(16)
              .height(16)
              .fillColor('#CCCCCC')
          }
          .width('100%')
          .height(44)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 14, right: 14 })
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 16 })
          .onClick(() => {
            this.showEducationPicker()
          })

          Text('技能')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .width('100%')
            .margin({ bottom: 8 })

          TextArea({ placeholder: '请输入技能特长', text: this.skills })
            .onChange((value: string) => { this.skills = value })
            .height(80)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({ left: 14, right: 14 })
            .margin({ bottom: 16 })

          Text('经历')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .width('100%')
            .margin({ bottom: 8 })

          TextArea({ placeholder: '请输入工作经历', text: this.experience })
            .onChange((value: string) => { this.experience = value })
            .height(100)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({ left: 14, right: 14 })
            .margin({ bottom: 16 })

          Text('简历（PDF）')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .width('100%')
            .margin({ bottom: 8 })

          Row() {
            Button('选择文件')
              .fontSize(14)
              .fontColor('#007AFF')
              .backgroundColor('#EBF5FF')
              .borderRadius(8)
              .height(36)
              .onClick(() => {
                this.selectFile()
              })
            if (this.attachmentName) {
              Text(this.attachmentName)
                .fontSize(14)
                .fontColor('#333333')
                .margin({ left: 12 })
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            } else {
              Text('未选择文件')
                .fontSize(14)
                .fontColor('#BBBBBB')
                .margin({ left: 12 })
            }
          }
          .width('100%')
          .height(44)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 14, right: 14 })
          .alignItems(VerticalAlign.Center)
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 24 })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
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

}
