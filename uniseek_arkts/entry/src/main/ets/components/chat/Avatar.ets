// Avatar.ets — 聊天头像组件
// url 有效时显示网络图片；加载失败或 url 为空时显示名字首字母占位圆

import { AppColors, AppChat, AppRadius } from '../../common/AppStyles';

@Component
export struct Avatar {
  @Prop url: string = '';
  @Prop name: string = '';
  // ArkUI CustomComponent 已存在 size 方法，故使用 avatarSize 作为属性名
  @Prop avatarSize: number = AppChat.AVATAR_SESSION;

  @State private imageFailed: boolean = false;

  private getInitials(): string {
    const trimmed: string = this.name ? this.name.trim() : '';
    if (trimmed.length > 0) {
      return trimmed.charAt(0);
    }
    return '?';
  }

  build() {
    if (this.url && this.url.length > 0 && !this.imageFailed) {
      Image(this.url)
        .width(this.avatarSize)
        .height(this.avatarSize)
        .borderRadius(AppRadius.FULL)
        .objectFit(ImageFit.Cover)
        .clip(true)
        .onError(() => {
          this.imageFailed = true;
        })
    } else {
      Column() {
        Text(this.getInitials())
          .fontSize(Math.floor(this.avatarSize * AppChat.AVATAR_INITIAL_FONT_RATIO))
          .fontColor(AppColors.BG_CARD)
          .fontWeight(FontWeight.Medium)
      }
      .width(this.avatarSize)
      .height(this.avatarSize)
      .borderRadius(AppRadius.FULL)
      .backgroundColor(AppColors.PRIMARY)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .clip(true)
    }
  }
}
