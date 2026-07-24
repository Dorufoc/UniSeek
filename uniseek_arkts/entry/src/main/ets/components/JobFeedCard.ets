// JobFeedCard — 职位信息流卡片
// 职责：在列表中承载单个职位摘要，统一视觉层级与按压反馈

import { JobData } from '../services/ChatTypes';
import { AppColors, AppFontSize, AppRadius, AppShadow, AppSpacing, AppAnimation } from '../common/AppStyles';

@Component
export struct JobFeedCard {
  @Prop job: JobData = {
    id: '', title: '', company: '', salary: '',
    salaryMid: 0, popularity: 0, region: '',
    type: '', category: '', description: '',
    enterpriseId: 0, categoryId: 0, regionId: 0,
    salaryMin: 0, salaryMax: 0, salaryUnit: 0,
    jobType: 0, status: 0, hasApplied: false,
    applicationId: 0,
    tag: [], remainingQuota: 0,
    hrName: '', hrAvatar: '',
    enterpriseName: '', totalQuota: 0, address: '', deadline: '',
    applicationCount: 0, hasFavorited: false
  };

  private formatRemaining(): string {
    if (this.job.remainingQuota === undefined || this.job.totalQuota === undefined) {
      return ''
    }
    if (this.job.remainingQuota <= 0) {
      return '已招满'
    }
    return `剩 ${this.job.remainingQuota} / ${this.job.totalQuota} 人`
  }

  private formatDeadline(): string {
    if (!this.job.deadline) {
      return ''
    }
    const date = this.job.deadline.split(' ')[0]
    return `截止 ${date}`
  }

  build() {
    Column() {
      // 第一行：职位标题（主）+ 薪资（次，右对齐）
      Row() {
        Text(this.job.title)
          .fontSize(AppFontSize.LG)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.job.salary)
          .fontSize(AppFontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.PRIMARY)
          .maxLines(1)
          .margin({ left: AppSpacing.SM })
      }
      .width('100%')

      // 第二行：类别/技能标签
      if (this.job.category || (this.job.tag && this.job.tag.length > 0)) {
        Row() {
          if (this.job.category) {
            Text(this.job.category)
              .fontSize(AppFontSize.TINY)
              .fontColor(AppColors.PRIMARY)
              .backgroundColor(AppColors.SELECTED_BG)
              .borderRadius(AppRadius.XS)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .margin({ right: 4 })
          }
          ForEach(this.job.tag.slice(0, 3), (tag: string) => {
            Text(tag)
              .fontSize(AppFontSize.TINY)
              .fontColor(AppColors.TEXT_MUTED)
              .backgroundColor(AppColors.INPUT_BG)
              .borderRadius(AppRadius.XS)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .margin({ right: 4 })
          }, (tag: string): string => tag)
        }
        .width('100%')
        .margin({ top: AppSpacing.SM })
        .alignItems(VerticalAlign.Center)
      }

      // 第三行：企业名称 · 地点
      Row() {
        Text((this.job.company || '') + ' · ' + (this.job.region || ''))
          .fontSize(AppFontSize.META)
          .fontColor(AppColors.TEXT_SECONDARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: AppSpacing.XS })

      // 第四行：剩余名额 + 截止时间（决策辅助信息）
      if (this.formatRemaining() || this.formatDeadline()) {
        Row() {
          if (this.formatRemaining()) {
            Text(this.formatRemaining())
              .fontSize(AppFontSize.TINY)
              .fontColor(this.job.remainingQuota > 0 ? AppColors.SUCCESS : AppColors.DANGER)
              .margin({ right: AppSpacing.SM })
          }
          if (this.formatDeadline()) {
            Text(this.formatDeadline())
              .fontSize(AppFontSize.TINY)
              .fontColor(AppColors.TEXT_MUTED)
          }
          Blank()
          if (this.job.hasApplied) {
            Text('已投递')
              .fontSize(AppFontSize.TINY)
              .fontColor(AppColors.PRIMARY)
              .backgroundColor(AppColors.SELECTED_BG)
              .borderRadius(AppRadius.XS)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          }
        }
        .width('100%')
        .margin({ top: AppSpacing.SM })
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
    .padding({ left: AppSpacing.CARD_PADDING, right: AppSpacing.CARD_PADDING, top: AppSpacing.SM_PLUS, bottom: AppSpacing.SM_PLUS })
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius(AppRadius.MD)
    .shadow(AppShadow.SM)
    .onClick(() => {
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/JobDetailPage',
        params: { jobId: this.job.id }
      });
    })
    .stateStyles({
      pressed: {
        .backgroundColor(AppColors.INPUT_BG)
        .scale({ x: 0.99, y: 0.99 })
      }
    })
    .animation({
      duration: AppAnimation.DURATION_FAST,
      curve: AppAnimation.CURVE_EMPHASIZED
    })
    .accessibilityGroup(true)
    .accessibilityText(`${this.job.title}，${this.job.salary}，${this.job.company}，${this.job.region}`)
  }
}
