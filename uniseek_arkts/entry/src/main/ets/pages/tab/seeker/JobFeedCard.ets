// JobFeedCard — 极简纯内容横向信息卡片
// 无头像、无按钮，仅显示标题/薪资/标签/企业名·地点

import { router } from '@kit.ArkUI';
import { JobData } from '../../../services/ChatTypes';
import { AppColors, AppRadius, AppShadow, AppSpacing } from '../../../common/AppStyles';

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

  build() {
    Column() {
      // 第一行：标题（左对齐）+ 薪资（右对齐）
      Row() {
        Text(this.job.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.job.salary)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.PRIMARY)
          .maxLines(1)
          .margin({ left: AppSpacing.SM })
      }
      .width('100%')

      // 第二行：标签（类别标签 + 技能标签）
      if (this.job.tag && this.job.tag.length > 0) {
        Row() {
          // 类别标签（全职/兼职/实习）
          Text(this.job.category)
            .fontSize(11)
            .fontColor(AppColors.PRIMARY)
            .backgroundColor(AppColors.SELECTED_BG)
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .margin({ right: 4 })
          // 技能标签（最多前3个）
          ForEach(this.job.tag.slice(0, 3), (tag: string) => {
            Text(tag)
              .fontSize(11)
              .fontColor(AppColors.TEXT_MUTED)
              .backgroundColor(AppColors.INPUT_BG)
              .borderRadius(4)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .margin({ right: 4 })
          }, (tag: string): string => tag)
        }
        .width('100%')
        .margin({ top: 4 })
        .alignItems(VerticalAlign.Center)
      }

      // 第三行：企业名称 · 地点
      Row() {
        Text((this.job.company || '') + ' · ' + (this.job.region || ''))
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .width('100%')
      .margin({ top: 4 })
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .backgroundColor(AppColors.BG_CARD)
    .border({ width: 1, color: AppColors.BORDER })
    .borderRadius(AppRadius.MD)
    .shadow(AppShadow.SM)
    .onClick(() => {
      router.pushUrl({
        url: 'pages/JobDetailPage',
        params: { jobId: this.job.id }
      });
    })
    .stateStyles({
      pressed: {
        .backgroundColor(AppColors.SELECTED_BG)
        .scale({ x: 0.99, y: 0.99 })
      }
    })

  }
}
