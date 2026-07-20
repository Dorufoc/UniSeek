import { router } from '@kit.ArkUI';
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
    type: '', category: '', expectedSalary: '', description: ''
  }
  @State contacted: boolean = false

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    if (params['resumeData']) {
      this.resume = JSON.parse(params['resumeData']) as ResumeCardData
    }
  }

  build() {
    Column() {
      NavBar({
        title: '简历详情',
        showBack: true,
        onBack: () => router.back()
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

          Text(this.resume.school + ' · ' + this.resume.major)
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
        }
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, bottom: AppSpacing.LG })
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')

      Row() {
        Button({ type: ButtonType.Capsule }) {
          Text(this.contacted ? '继续沟通' : '立即沟通')
            .fontSize(AppFontSize.MD)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
          .width('90%')
          .height(48)
          .backgroundColor(AppColors.PRIMARY)
          .onClick(() => {
            if (this.contacted) {
              router.pushUrl({
                url: 'pages/ChatDetailPage',
                params: {
                  applicationId: 0,
                  counterpartName: this.resume.name,
                  counterpartAvatar: this.resume.avatar
                }
              })
              return
            }
            ChatService.createApplication(Number(this.resume.id)).then((app) => {
              if (app) {
                this.contacted = true
                router.pushUrl({
                  url: 'pages/ChatDetailPage',
                  params: {
                    applicationId: app.id,
                    counterpartName: this.resume.name,
                    counterpartAvatar: this.resume.avatar
                  }
                })
              }
            })
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
