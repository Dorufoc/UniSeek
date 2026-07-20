// StandardCard.ets — 统一卡片样式包装组件
// 提供一致的 HMOS 卡片视觉风格：白色背景、圆角 12vp、轻阴影、16vp 内边距
// 使用 @BuilderParam 插槽模式，由调用方填充内容

import { AppColors, AppRadius, AppSpacing } from './AppStyles';

@Component
export struct StandardCard {
  @BuilderParam content: () => void = this.defaultContentBuilder;

  onClickAction?: () => void;

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius(AppRadius.LG)
    .padding(AppSpacing.MD)
    .shadow({ radius: 6, color: 'rgba(0,0,0,0.06)', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      if (this.onClickAction) {
        this.onClickAction();
      }
    })
  }

  @Builder
  defaultContentBuilder() {
  }
}
