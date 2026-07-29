import { ResumeCardData, APPLICATION_STATUS_LABELS } from '../services/RecruiterTypes';
import { ChatService } from '../services/ChatService';
import { ChatMessageVO } from '../services/ChatTypes';
import { UserSession } from '../services/UserSession';
import { ResumeService, ResumeData } from '../services/ResumeService';
import { AppColors, AppSpacing, AppRadius, AppFontSize, PrimaryButton } from '../common/AppStyles';
import { StandardCard } from '../common/StandardCard';
import { NavBar } from '../common/NavBar';
import { ApplicationStatusBar } from '../components/application/ApplicationStatusBar';

const DEFAULT_RESUME: ResumeCardData = {
  id: '',
  name: '',
  age: 0,
  avatar: '',
  education: '',
  school: '',
  major: '',
  experience: '',
  skills: '',
  region: '',
  type: '',
  category: '',
  expectedSalary: '',
  description: '',
  attachmentUrl: '',
  graduationDate: '',
  gender: -1,
  birthDate: '',
  applicationId: 0,
  applicationStatus: -1,
  jobTitle: '',
  createTime: ''
}

@Entry
@Component
struct ResumeDetailPage {
  @State resume: ResumeCardData = DEFAULT_RESUME
  @State contacted: boolean = false
  @State isContacting: boolean = false
  @State hasSentResumeAttachment: boolean = false
  @State attachmentUrl: string = ''

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>
    if (params && params['resumeData']) {
      this.resume = JSON.parse(params['resumeData']) as ResumeCardData
      this.attachmentUrl = this.resume.attachmentUrl || ''
      void this.loadResumeDetail()
    }
  }

  private async loadResumeDetail(): Promise<void> {
    await this.loadFullResume()
    await this.checkResumeAttachmentFromChat()
  }

  private async loadFullResume(): Promise<void> {
    const userId = Number(this.resume.id)
    if (!userId) {
      return
    }
    try {
      const full = await ResumeService.getPublishedResume(userId)
      if (full) {
        this.mergeFullResume(full)
      }
    } catch {
      // 求职者未将简历发布到人才市场时不影响快照展示
    }
  }

  /**
   * 合并投递记录中的附件和聊天消息中的附件，任一来源存在即可查看。
   */
  private async checkResumeAttachmentFromChat(): Promise<void> {
    const applicationId = this.resume.applicationId ?? 0
    if (!applicationId) {
      this.hasSentResumeAttachment = this.attachmentUrl.trim().length > 0
      return
    }
    const currentUserId = UserSession.userId || 0
    const CHAT_MESSAGE_ATTACHMENT = 2
    const pageSize = 50
    let beforeId: number | undefined = undefined
    let foundUrl: string = ''
    try {
      while (true) {
        const messages: ChatMessageVO[] = await ChatService.getMessages(applicationId, beforeId, pageSize)
        if (!messages || messages.length === 0) {
          break
        }
        for (let i = 0; i < messages.length; i++) {
          const msg: ChatMessageVO = messages[i]
          if (msg.messageType === CHAT_MESSAGE_ATTACHMENT && (currentUserId === 0 || msg.senderId !== currentUserId)) {
            foundUrl = msg.content
            break
          }
        }
        if (foundUrl) {
          break
        }
        beforeId = messages[messages.length - 1].id
        if (messages.length < pageSize) {
          break
        }
      }
      if (foundUrl) {
        this.hasSentResumeAttachment = true
        this.attachmentUrl = foundUrl
      } else {
        this.hasSentResumeAttachment = this.attachmentUrl.trim().length > 0
      }
    } catch {
      this.hasSentResumeAttachment = this.attachmentUrl.trim().length > 0
    }
  }

  private mergeFullResume(full: ResumeData): void {
    if (full.realName && !this.resume.name) {
      this.resume.name = full.realName
    }
    if (full.gender !== undefined && full.gender >= 0) {
      this.resume.gender = full.gender
    }
    if (full.birthDate && !this.resume.birthDate) {
      this.resume.birthDate = full.birthDate
    }
    if (full.education && !this.resume.education) {
      this.resume.education = full.education
    }
    if (full.school && !this.resume.school) {
      this.resume.school = full.school
    }
    if (full.graduationDate && !this.resume.graduationDate) {
      this.resume.graduationDate = full.graduationDate
    }
    if (full.skills && !this.resume.skills) {
      this.resume.skills = full.skills
    }
    if (full.experience && !this.resume.experience) {
      this.resume.experience = full.experience
    }
    if (full.attachmentUrl && !this.resume.attachmentUrl) {
      this.resume.attachmentUrl = full.attachmentUrl
    }
  }

  private displayName(): string {
    return this.resume.name || '匿名求职者'
  }

  private avatarInitial(): string {
    const name = this.displayName()
    return name.length > 0 ? name.charAt(0) : '?'
  }

  private displayAge(): string {
    if (this.resume.birthDate && this.resume.birthDate.length >= 4) {
      const birthYear = Number(this.resume.birthDate.substring(0, 4))
      const currentYear = new Date().getFullYear()
      if (birthYear >= 1900 && birthYear <= currentYear) {
        return `${currentYear - birthYear}岁`
      }
    }
    if (this.resume.age > 0) {
      return `${this.resume.age}岁`
    }
    return ''
  }

  private birthLabel(): string {
    return this.resume.birthDate || ''
  }

  private genderLabel(): string {
    if (this.resume.gender === 0) {
      return '男'
    }
    if (this.resume.gender === 1) {
      return '女'
    }
    return '保密'
  }

  private graduationLabel(): string {
    if (!this.resume.graduationDate) {
      return '未填写'
    }
    return this.resume.graduationDate.split('T')[0] || this.resume.graduationDate.split(' ')[0] || this.resume.graduationDate
  }

  private educationSummary(): string {
    const parts: string[] = []
    if (this.resume.education) {
      parts.push(this.resume.education)
    }
    if (this.resume.school) {
      parts.push(this.resume.school)
    }
    return parts.length > 0 ? parts.join(' · ') : '暂无教育经历'
  }

  private skillTags(): string[] {
    const raw = (this.resume.skills || '').trim()
    if (!raw) {
      return []
    }
    if (raw.charAt(0) === '[') {
      try {
        const parsed = JSON.parse(raw) as string[]
        if (Array.isArray(parsed)) {
          return parsed.filter((item: string) => item && item.trim().length > 0)
        }
      } catch {
        // 快照中的技能不是 JSON 数组时继续按分隔符拆分
      }
    }
    return raw.split(/[,，、\s]+/).filter((item: string) => item.trim().length > 0)
  }

  private plainExperience(): string {
    const raw = this.resume.experience || ''
    return raw.replace(/<[^>]+>/g, '').trim()
  }

  private hasAttachment(): boolean {
    return (this.attachmentUrl || '').trim().length > 0
  }

  private attachmentName(): string {
    const url = this.attachmentUrl || ''
    const segment = url.substring(url.lastIndexOf('/') + 1).split('?')[0]
    if (!segment) {
      return '简历附件'
    }
    try {
      return decodeURIComponent(segment)
    } catch {
      return segment
    }
  }

  private formatDateTime(timeText?: string): string {
    if (!timeText) {
      return ''
    }
    return timeText.split('T')[0] || timeText.split(' ')[0] || timeText
  }

  private statusColor(status: number): ResourceColor {
    switch (status) {
      case 0:
        return AppColors.WARNING
      case 1:
        return AppColors.PRIMARY
      case 2:
        return AppColors.TEXT_MUTED
      case 3:
        return AppColors.SUCCESS
      case 4:
        return AppColors.DANGER
      case 5:
        return AppColors.TEXT_MUTED
      default:
        return AppColors.TEXT_MUTED
    }
  }

  private statusBgColor(status: number): ResourceColor {
    switch (status) {
      case 0:
        return AppColors.WARNING_BG
      case 1:
        return AppColors.SELECTED_BG
      case 2:
        return AppColors.INPUT_BG
      case 3:
        return AppColors.SUCCESS_BG
      case 4:
        return AppColors.ERROR_BG
      case 5:
        return AppColors.INPUT_BG
      default:
        return AppColors.INPUT_BG
    }
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
          counterpartName: this.displayName(),
          counterpartAvatar: this.resume.avatar,
          sessionType: 'direct'
        }
      })
      this.isContacting = false
    }).catch(() => {
      this.isContacting = false
      this.getUIContext().getPromptAction().showToast({ message: '暂时无法建立沟通，请稍后重试' })
    })
  }

  @Builder
  sectionHeader(icon: Resource, title: string) {
    Row({ space: AppSpacing.SM }) {
      SymbolGlyph(icon)
        .fontSize(AppFontSize.ICON_MD)
        .fontColor([AppColors.PRIMARY])
      Text(title)
        .fontSize(AppFontSize.MD)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
    }
    .width('100%')
    .margin({ bottom: AppSpacing.SM })
  }

  @Builder
  infoRow(icon: Resource, label: string, value: string, placeholder: string = '未填写') {
    Row({ space: AppSpacing.SM }) {
      SymbolGlyph(icon)
        .fontSize(AppFontSize.ICON_MD)
        .fontColor([AppColors.PRIMARY])
      Text(label)
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width(72)
      Text(value || placeholder)
        .fontSize(AppFontSize.MD)
        .fontColor(value ? AppColors.TEXT_PRIMARY : AppColors.TEXT_MUTED)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  statusBadge(status: number) {
    Text(APPLICATION_STATUS_LABELS[status] ?? '未知')
      .fontSize(AppFontSize.XS)
      .fontColor(this.statusColor(status))
      .backgroundColor(this.statusBgColor(status))
      .borderRadius(AppRadius.PILL)
      .padding({
        left: AppSpacing.SM,
        right: AppSpacing.SM,
        top: AppSpacing.XS,
        bottom: AppSpacing.XS
      })
  }

  @Builder
  profileHeader() {
    StandardCard({ accessibilityLabel: '求职者基本信息' }) {
      Row({ space: AppSpacing.MD }) {
        Stack({ alignContent: Alignment.Center }) {
          if (this.resume.avatar) {
            Image(this.resume.avatar)
              .width(AppSpacing.AVATAR_XL)
              .height(AppSpacing.AVATAR_XL)
              .borderRadius(AppRadius.FULL)
              .objectFit(ImageFit.Cover)
          } else {
            Text(this.avatarInitial())
              .fontSize(AppFontSize.XL)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
        }
        .width(AppSpacing.AVATAR_XL)
        .height(AppSpacing.AVATAR_XL)
        .backgroundColor(AppColors.PRIMARY)
        .borderRadius(AppRadius.FULL)

        Column({ space: AppSpacing.XS }) {
          Row({ space: AppSpacing.SM }) {
            Text(this.displayName())
              .fontSize(AppFontSize.XXL)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT_PRIMARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            if (this.displayAge()) {
              Text(this.displayAge())
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.TEXT_SECONDARY)
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text(this.educationSummary())
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_SECONDARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          if (this.resume.jobTitle) {
            Row({ space: AppSpacing.XS }) {
              SymbolGlyph($r('sys.symbol.briefcase'))
                .fontSize(AppFontSize.SM)
                .fontColor([AppColors.TEXT_MUTED])
              Text('应聘：' + this.resume.jobTitle)
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.TEXT_SECONDARY)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
            }
            .width('100%')
          }

          if (this.resume.createTime) {
            Text('投递时间：' + this.formatDateTime(this.resume.createTime))
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.TEXT_MUTED)
              .width('100%')
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        if (this.resume.applicationStatus !== undefined && this.resume.applicationStatus >= 0) {
          this.statusBadge(this.resume.applicationStatus)
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
  }

  @Builder
  basicInfoSection() {
    StandardCard({ accessibilityLabel: '基本资料' }) {
      Column({ space: AppSpacing.XS }) {
        this.sectionHeader($r('sys.symbol.person'), '基本资料')
        this.infoRow($r('sys.symbol.person'), '姓名', this.displayName())
        this.infoRow($r('sys.symbol.person'), '性别', this.genderLabel())
        this.infoRow($r('sys.symbol.calendar'), '出生日期', this.birthLabel())
        if (this.resume.region) {
          this.infoRow($r('sys.symbol.info_circle'), '所在地区', this.resume.region)
        }
      }
      .width('100%')
    }
  }

  @Builder
  educationSection() {
    StandardCard({ accessibilityLabel: '教育经历' }) {
      Column({ space: AppSpacing.XS }) {
        this.sectionHeader($r('sys.symbol.graduationcap'), '教育经历')
        this.infoRow($r('sys.symbol.book'), '最高学历', this.resume.education)
        this.infoRow($r('sys.symbol.building'), '毕业院校', this.resume.school)
        this.infoRow($r('sys.symbol.calendar'), '毕业时间', this.graduationLabel())
      }
      .width('100%')
    }
  }

  @Builder
  skillsSection() {
    StandardCard({ accessibilityLabel: '技能标签' }) {
      Column({ space: AppSpacing.XS }) {
        this.sectionHeader($r('sys.symbol.star'), '技能标签')
        if (this.skillTags().length > 0) {
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            ForEach(this.skillTags(), (tag: string) => {
              Text(tag)
                .fontSize(AppFontSize.XS)
                .fontColor(AppColors.PRIMARY)
                .backgroundColor(AppColors.SELECTED_BG)
                .borderRadius(AppRadius.PILL)
                .padding({
                  left: AppSpacing.SM,
                  right: AppSpacing.SM,
                  top: AppSpacing.XS,
                  bottom: AppSpacing.XS
                })
                .margin({ right: AppSpacing.SM, bottom: AppSpacing.SM })
            }, (tag: string) => tag)
          }
          .width('100%')
        } else {
          Text('暂无技能标签')
            .fontSize(AppFontSize.MD)
            .fontColor(AppColors.TEXT_MUTED)
            .width('100%')
        }
      }
      .width('100%')
    }
  }

  @Builder
  experienceSection() {
    StandardCard({ accessibilityLabel: '实践经历' }) {
      Column({ space: AppSpacing.XS }) {
        this.sectionHeader($r('sys.symbol.doc_text'), '实践经历')
        if (this.plainExperience().length > 0) {
          Text(this.plainExperience())
            .fontSize(AppFontSize.MD)
            .fontColor(AppColors.TEXT_PRIMARY)
            .lineHeight(AppSpacing.LG)
            .width('100%')
        } else {
          Text('暂无实践经历')
            .fontSize(AppFontSize.MD)
            .fontColor(AppColors.TEXT_MUTED)
            .width('100%')
        }
      }
      .width('100%')
    }
  }

  @Builder
  attachmentSection() {
    StandardCard({ accessibilityLabel: '附件简历' }) {
      Column({ space: AppSpacing.SM }) {
        this.sectionHeader($r('sys.symbol.doc'), '附件简历')
        if (this.hasSentResumeAttachment && this.attachmentUrl) {
          Row() {
            SymbolGlyph($r('sys.symbol.doc_text'))
              .fontSize(AppFontSize.ICON_LG)
              .fontColor([AppColors.PRIMARY])
            Column({ space: AppSpacing.XS }) {
              Text(this.attachmentName())
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.TEXT_PRIMARY)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
              Text('PDF / Word')
                .fontSize(AppFontSize.XS)
                .fontColor(AppColors.TEXT_MUTED)
                .width('100%')
            }
            .layoutWeight(1)
            .margin({ left: AppSpacing.SM })
            .alignItems(HorizontalAlign.Start)

            Row({ space: AppSpacing.SM }) {
              Button('预览', { type: ButtonType.Capsule })
                .height(AppSpacing.BUTTON_HEIGHT_MINI)
                .fontSize(AppFontSize.XS)
                .fontColor(AppColors.PRIMARY)
                .backgroundColor(AppColors.SELECTED_BG)
                 .onClick((): void => {
                   this.getUIContext().getRouter().pushUrl({
                     url: 'pages/PdfPreviewPage',
                     params: { attachmentUrl: this.attachmentUrl }
                   }).catch(() => {
                     this.getUIContext().getPromptAction().showToast({ message: '附件预览页面打开失败，请重试' })
                   })
                 })
              Button('下载', { type: ButtonType.Capsule })
                .height(AppSpacing.BUTTON_HEIGHT_MINI)
                .fontSize(AppFontSize.XS)
                .fontColor(AppColors.PRIMARY)
                .backgroundColor(AppColors.SELECTED_BG)
                .onClick((): void => {
                  void ChatService.downloadAttachment(this.attachmentUrl).then((path: string) => {
                    this.getUIContext().getPromptAction().showToast({ message: '已下载至：' + path })
                  })
                })
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        } else {
          Column({ space: AppSpacing.SM }) {
            SymbolGlyph($r('sys.symbol.doc_text'))
              .fontSize(AppFontSize.ICON_LG)
              .fontColor([AppColors.TEXT_MUTED])
            Text('对方暂时没有向您发送简历文件')
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.TEXT_MUTED)
          }
          .width('100%')
          .padding({ top: AppSpacing.MD, bottom: AppSpacing.MD })
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width('100%')
    }
  }

  @Builder
  applicationContextSection() {
    StandardCard({ accessibilityLabel: '投递状态' }) {
      Column({ space: AppSpacing.XS }) {
        this.sectionHeader($r('sys.symbol.clock'), '投递状态')
        this.infoRow($r('sys.symbol.briefcase'), '应聘职位', this.resume.jobTitle || '未知职位')
        Row({ space: AppSpacing.SM }) {
          SymbolGlyph($r('sys.symbol.flag'))
            .fontSize(AppFontSize.ICON_MD)
            .fontColor([AppColors.PRIMARY])
          Text('当前状态')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_SECONDARY)
            .width(72)
          this.statusBadge(this.resume.applicationStatus ?? -1)
        }
        .width('100%')
        .padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })
        .alignItems(VerticalAlign.Center)

        if (this.resume.createTime) {
          this.infoRow($r('sys.symbol.calendar'), '投递时间', this.formatDateTime(this.resume.createTime))
        }
      }
      .width('100%')
    }
  }

  build() {
    Column() {
      NavBar({
        title: '求职者详情',
        showBack: true,
        onBack: () => this.getUIContext().getRouter().back()
      })

      ApplicationStatusBar({
        applicationId: this.resume.applicationId ?? 0,
        currentStatus: this.resume.applicationStatus ?? -1,
        applicantName: this.displayName(),
        onStatusChanged: (status: number): void => {
          this.resume.applicationStatus = status
        }
      })

      Scroll() {
        Column({ space: AppSpacing.MD }) {
          this.profileHeader()
          this.applicationContextSection()
          this.basicInfoSection()
          this.educationSection()
          this.skillsSection()
          this.experienceSection()
          this.attachmentSection()
        }
        .width('100%')
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: AppSpacing.XL })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto)

      Row() {
        PrimaryButton({
          text: this.isContacting ? '正在连接...' : (this.contacted ? '继续沟通' : '立即沟通'),
          loading: this.isContacting,
          disabled: false,
          onTap: () => { this.openDirectChat() }
        })
      }
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, bottom: AppSpacing.LG })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
