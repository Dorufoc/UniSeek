import { router } from '@kit.ArkUI'
import { AppColors, AppFontSize, AppSpacing } from '../common/AppStyles'
import { NavBar } from '../common/NavBar'

@Entry
@Component
struct PrivacyPolicyPage {
  build() {
    Column() {
      NavBar({ title: '隐私政策', showBack: true, onBack: (): void => { router.back() } })
      Scroll() {
        Column({ space: AppSpacing.MD }) {
          Text('UniSeek 隐私政策')
            .fontSize(AppFontSize.XL)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
            .width('100%')
          Text('更新时间：2026 年 7 月 23 日')
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.TEXT_MUTED)
            .width('100%')
          this.section('收集的信息', '为提供账号、简历、职位投递和沟通服务，平台会收集注册信息、简历信息、认证信息及您主动提交的附件。')
          this.section('使用方式', '上述信息仅用于身份验证、职位匹配、投递处理、服务通知和安全保障。我们不会将个人信息用于与招聘服务无关的用途。')
          this.section('共享与展示', '当您主动发布简历或职位、发起投递或沟通时，相关信息会在实现该功能所必需的范围内向对应用户展示。')
          this.section('存储与保护', '平台采取合理的技术和管理措施保护个人信息。请勿在公开内容或聊天中泄露密码、银行卡等敏感信息。')
          this.section('您的权利', '您可在应用内更新部分账号和简历信息，也可通过客服渠道申请咨询、修改或删除相关信息。')
        }
        .width('100%')
        .padding(AppSpacing.MD)
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  @Builder
  section(title: string, content: string) {
    Column({ space: AppSpacing.XS }) {
      Text(title)
        .fontSize(AppFontSize.MD)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')
      Text(content)
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_SECONDARY)
        .lineHeight(22)
        .width('100%')
    }
    .width('100%')
  }
}
