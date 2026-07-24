import { AppColors, AppFontSize, AppSpacing } from '../common/AppStyles'
import { NavBar } from '../common/NavBar'

@Entry
@Component
struct UserAgreementPage {
  build() {
    Column() {
      NavBar({ title: '用户协议', showBack: true, onBack: (): void => { this.getUIContext().getRouter().back() } })
      Scroll() {
        Column({ space: AppSpacing.MD }) {
          Text('UniSeek 用户协议')
            .fontSize(AppFontSize.XL)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
            .width('100%')
          Text('更新时间：2026 年 7 月 23 日')
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.TEXT_MUTED)
            .width('100%')
          this.section('服务说明', 'UniSeek 为求职者和招聘方提供职位发布、简历展示、沟通和投递管理服务。用户应保证注册信息、简历内容和招聘信息真实、准确、合法。')
          this.section('账号与使用', '请妥善保管账号和密码。不得发布虚假职位、虚假简历、歧视性内容或违法信息，不得干扰平台正常运行。')
          this.section('内容与责任', '用户对自行发布、上传和发送的内容负责。平台可依据法律法规和服务规则处理违规内容，并在必要时限制相关账号功能。')
          this.section('服务变更', '平台可能因业务、技术或法律要求调整服务内容，并会在合理范围内通过应用内方式提示。继续使用服务即表示接受调整后的规则。')
          this.section('联系我们', '如有服务问题或投诉建议，请通过平台客服渠道联系我们。')
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
