import { router } from '@kit.ArkUI';
import { ResumeCardData } from '../services/RecruiterTypes';
import { ChatService } from '../services/ChatService';

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
      Row() {
        Image($r('app.media.left_arrow'))
          .width(24)
          .height(24)
          .fillColor('#333333')
          .onClick(() => { router.back() })
        Text('简历详情')
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
          Row() {
            Text(this.resume.name)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')

            Text(this.resume.age + '岁')
              .fontSize(16)
              .fontColor('#666666')
              .margin({ left: 12 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text(this.resume.school + ' · ' + this.resume.major)
            .fontSize(16)
            .fontColor('#666666')
            .margin({ top: 8 })
            .width('100%')

          Row() {
            Text(this.resume.education)
              .fontSize(14)
              .fontColor('#666666')
              .backgroundColor('#F5F5F5')
              .borderRadius(4)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            Text(this.resume.experience)
              .fontSize(14)
              .fontColor('#666666')
              .backgroundColor('#F5F5F5')
              .borderRadius(4)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .margin({ left: 10 })
          }
          .margin({ top: 12 })
          .width('100%')

          Text('期望薪资：' + this.resume.expectedSalary)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FF6B35')
            .margin({ top: 12 })
            .width('100%')

          Row() {
            Text(this.resume.region)
              .fontSize(13)
              .fontColor('#666666')
              .backgroundColor('#F5F5F5')
              .borderRadius(4)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            Text(this.resume.type)
              .fontSize(13)
              .fontColor('#666666')
              .backgroundColor('#F5F5F5')
              .borderRadius(4)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .margin({ left: 10 })
            Text(this.resume.category)
              .fontSize(13)
              .fontColor('#666666')
              .backgroundColor('#F5F5F5')
              .borderRadius(4)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .margin({ left: 10 })
          }
          .margin({ top: 12 })
          .width('100%')

          Divider()
            .margin({ top: 20, bottom: 16 })

          Text('技能标签')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .width('100%')

          Text(this.resume.skills)
            .fontSize(15)
            .fontColor('#666666')
            .lineHeight(24)
            .margin({ top: 10 })
            .width('100%')

          Divider()
            .margin({ top: 20, bottom: 16 })

          Text('个人简介')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .width('100%')

          Text(this.resume.description)
            .fontSize(15)
            .fontColor('#666666')
            .lineHeight(24)
            .margin({ top: 10 })
            .width('100%')
        }
        .padding({ left: 16, right: 16, bottom: 24 })
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')

      Row() {
        Button(this.contacted ? '继续沟通' : '立即沟通')
          .width('90%')
          .height(48)
          .backgroundColor('#007AFF')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .borderRadius(24)
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
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .alignItems(HorizontalAlign.Center)
  }
}
