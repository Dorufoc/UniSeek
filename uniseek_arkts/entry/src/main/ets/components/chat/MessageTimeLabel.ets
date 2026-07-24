// 消息时间标签：会话列表或聊天详情页的小字号时间

import { AppColors, AppFontSize } from '../../common/AppStyles';

@Component
export struct MessageTimeLabel {
  @Prop time: string = ''

  build() {
    Text(this.time)
      .fontSize(AppFontSize.XS)
      .fontColor(AppColors.TEXT_MUTED)
      .fontWeight(FontWeight.Medium)
  }
}
