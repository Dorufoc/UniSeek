// LoadMoreFooter — 统一列表底部加载/全部加载完成提示
// 职责：在 List 触底加载或没有更多数据时给出一致反馈

import { AppColors, AppFontSize, AppSpacing } from '../common/AppStyles';

@Component
export struct LoadMoreFooter {
  @Prop loading: boolean = false;
  @Prop hasMore: boolean = true;
  @Prop finishedText: string = '已全部展示';

  build() {
    Row() {
      if (this.loading) {
        LoadingProgress()
          .width(AppSpacing.ICON_SM)
          .height(AppSpacing.ICON_SM)
          .color(AppColors.PRIMARY)
        Text('加载中...')
          .fontSize(AppFontSize.SM)
          .fontColor(AppColors.TEXT_MUTED)
          .margin({ left: AppSpacing.SM })
      } else if (!this.hasMore) {
        Text(this.finishedText)
          .fontSize(AppFontSize.SM)
          .fontColor(AppColors.TEXT_MUTED)
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding(AppSpacing.MD)
  }
}
