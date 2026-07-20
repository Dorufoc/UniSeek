// 统一导航栏公共组件
// 遵循 HMOS 设计规范，替代所有页面中手写的顶部导航栏模式

import { router } from '@kit.ArkUI';
import { AppColors, AppSpacing, AppFontSize } from './AppStyles';

/**
 * 统一导航栏组件
 *
 * 用法：
 * ```typescript
 * // 基本用法（带返回按钮）
 * NavBar({ title: '页面标题' })
 *
 * // 自定义返回回调
 * NavBar({
 *   title: '职位详情',
 *   showBack: true,
 *   onBack: () => router.back()
 * })
 *
 * // 无返回按钮 + 右侧插槽
 * NavBar({
 *   title: '个人主页',
 *   showBack: false,
 *   rightContent: () => { Image($r('app.media.settings')).width(24).height(24) }
 * })
 * ```
 */
@Component
export struct NavBar {
  /** 页面标题 */
  @Prop title: string = '';
  /** 是否显示返回按钮，默认 true */
  @Prop showBack: boolean = true;
  /** 返回按钮点击回调，默认执行 router.back() */
  onBack?: () => void;
  /** 右侧操作区域插槽 */
  @BuilderParam rightContent: () => void = this.emptyRightContent;

  /** 默认空右侧插槽 */
  @Builder
  emptyRightContent() {
  }

  build() {
    Row() {
      // 左侧返回区域，固定 72vp 占位（含箭头），保证标题居中对称
      if (this.showBack) {
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(20)
            .fontColor([AppColors.PRIMARY])
        }
        .width(72)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          if (this.onBack) {
            this.onBack();
          } else {
            router.back();
          }
        })
      } else {
        // 无返回按钮时保留 72vp 占位以保持标题居中
        Row().width(72)
      }

      // 中间标题（弹性居中）
      Text(this.title)
        .fontSize(AppFontSize.LG)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 右侧操作区域，固定 72vp 占位，保证标题居中
      Row() {
        this.rightContent()
      }
      .width(72)
      .justifyContent(FlexAlign.End)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(56)
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
    .backgroundColor('#FFFFFF')
    .alignItems(VerticalAlign.Center)
  }
}
