import { ResumeCardData } from '../services/RecruiterTypes';
import { ChatService } from '../services/ChatService';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';

@Entry
@Component
struct ResumeDetailPage {
  @State resume: ResumeCardData = {
    id: '', name: '', age: 0, avatar: '', education: '', school: '',
    major: '', experience: '', skills: '', region: '',
    type: '', category: '', expectedSalary: '', description: '', attachmentUrl: ''
  }
  @State contacted: boolean = false
  @State isContacting: boolean = false

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>
    if (params['resumeData']) {
      this.resume = JSON.parse(params['resumeData']) as ResumeCardData
    }
  }

  educationText(): string {
    const parts: string[] = []
    if (this.resume.school) {
      parts.push(this.resume.school)
    }
    if (this.resume.major) {
      parts.push(this.resume.major)
    }
    return parts.length > 0 ? parts.join(' · ') : '暂无教育经历'
  }

  openDirectChat(): void {
    const targetUserId = Number(this.resume.id)
    if (!targetUserId) {
      this.getUIContext().getPromptAction().showToast({ message: '求职者信息不完整，暂无法发起沟通' })
      return
    }
    this.isContacting = true
    ChatService.createDirectSession(targetUserId).then((applicationId: number) => {
      this.contacted = true
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/ChatDetailPage',
        params: {
          applicationId: applicationId,
          counterpartName: this.resume.name,
          counterpartAvatar: this.resume.avatar
        }
      })
      this.isContacting = false
    }).catch(() => {
      this.isContacting = false
      this.getUIContext().getPromptAction().showToast({ message: '暂时无法建立沟通，请稍后重试' })
    })
  }
  build() {
    Column() {
      NavBar({
        title: '简历详情',
        showBack: true,
        onBack: () => this.getUIContext().getRouter().back()
      })

      Scroll() {
        Column() {
          Row() {
            Text(this.resume.name)
              .fontSize(AppFontSize.XXL)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT_PRIMARY)

            Text(this.resume.age + '岁')
              .fontSize(AppFontSize.MD)
              .fontColor(AppColors.TEXT_SECONDARY)
              .margin({ left: AppSpacing.SM })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text(this.educationText())
            .fontSize(AppFontSize.MD)
            .fontColor(AppColors.TEXT_SECONDARY)
            .margin({ top: AppSpacing.SM })
            .width('100%')

          Row() {
            Text(this.resume.education)
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.TEXT_SECONDARY)
              .backgroundColor(AppColors.INPUT_BG)
              .borderRadius(AppRadius.SM)
              .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XS, bottom: AppSpacing.XS })
            Text(this.resume.experience)
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.TEXT_SECONDARY)
              .backgroundColor(AppColors.INPUT_BG)
              .borderRadius(AppRadius.SM)
              .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XS, bottom: AppSpacing.XS })
              .margin({ left: AppSpacing.SM })
          }
          .margin({ top: AppSpacing.SM })
          .width('100%')

          Text('期望薪资：' + this.resume.expectedSalary)
            .fontSize(AppFontSize.MD)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.WARNING)
            .margin({ top: AppSpacing.SM })
            .width('100%')

          Row() {
            Text(this.resume.region)
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.TEXT_SECONDARY)
              .backgroundColor(AppColors.INPUT_BG)
              .borderRadius(AppRadius.SM)
              .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XS, bottom: AppSpacing.XS })
            Text(this.resume.type)
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.TEXT_SECONDARY)
              .backgroundColor(AppColors.INPUT_BG)
              .borderRadius(AppRadius.SM)
              .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XS, bottom: AppSpacing.XS })
              .margin({ left: AppSpacing.SM })
            Text(this.resume.category)
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.TEXT_SECONDARY)
              .backgroundColor(AppColors.INPUT_BG)
              .borderRadius(AppRadius.SM)
              .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XS, bottom: AppSpacing.XS })
              .margin({ left: AppSpacing.SM })
          }
          .margin({ top: AppSpacing.SM })
          .width('100%')

          Divider()
            .margin({ top: AppSpacing.LG, bottom: AppSpacing.MD })

          Text('技能标签')
            .fontSize(AppFontSize.MD)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
            .width('100%')

          Text(this.resume.skills)
            .fontSize(AppFontSize.MD)
            .fontColor(AppColors.TEXT_SECONDARY)
            .lineHeight(AppSpacing.LG)
            .margin({ top: AppSpacing.SM })
            .width('100%')

          Divider()
            .margin({ top: AppSpacing.LG, bottom: AppSpacing.MD })

          Text('个人简介')
            .fontSize(AppFontSize.MD)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
            .width('100%')

          Text(this.resume.description)
            .fontSize(AppFontSize.MD)
            .fontColor(AppColors.TEXT_SECONDARY)
            .lineHeight(AppSpacing.LG)
            .margin({ top: AppSpacing.SM })
            .width('100%')

          if (this.resume.attachmentUrl) {
            Row({ space: AppSpacing.SM }) {
              Text('附件简历')
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.TEXT_SECONDARY)
                .layoutWeight(1)
              Button('预览', { type: ButtonType.Capsule })
                .height(32)
                .fontSize(AppFontSize.XS)
                .fontColor(AppColors.PRIMARY)
                .backgroundColor(AppColors.SELECTED_BG)
                .onClick((): void => { void ChatService.previewAttachment(this.resume.attachmentUrl || '') })
              Button('下载', { type: ButtonType.Capsule })
                .height(32)
                .fontSize(AppFontSize.XS)
                .fontColor(AppColors.PRIMARY)
                .backgroundColor(AppColors.SELECTED_BG)
                .onClick((): void => { void ChatService.downloadAttachment(this.resume.attachmentUrl || '') })
            }
            .width('100%')
            .margin({ top: AppSpacing.MD })
          }
        }
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, bottom: AppSpacing.LG })
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')

      Row() {
        Button({ type: ButtonType.Capsule }) {
          Text(this.isContacting ? '正在连接...' : (this.contacted ? '继续沟通' : '立即沟通'))
            .fontSize(AppFontSize.MD)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
          .width('90%')
          .height(48)
          .backgroundColor(AppColors.PRIMARY)
          .enabled(!this.isContacting)
          .onClick(() => {
            this.openDirectChat()

          })
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
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: AppSpacing.LG })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
    .alignItems(HorizontalAlign.Center)
  }
}
