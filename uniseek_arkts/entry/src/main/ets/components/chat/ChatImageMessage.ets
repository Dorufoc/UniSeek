// ChatImageMessage.ets — 聊天图片消息气泡组件

import { AppColors, AppRadius, AppChat } from '../../common/AppStyles';
import { ServerConfig } from '../../services/ServerConfig'
import { ApiClient } from '../../services/ApiClient'

@Component
export struct ChatImageMessage {
  @Prop url: string = '';
  onImageClick?: () => void;

  build() {
    Image(ServerConfig.toHttpUrl(ApiClient.BASE_URL, this.url))
      .constraintSize({ maxHeight: AppChat.BUBBLE_IMAGE_MAX_HEIGHT })
      .width('100%')
      .borderRadius(AppChat.BUBBLE_IMAGE_RADIUS)
      .objectFit(ImageFit.Cover)
      .backgroundColor(AppColors.INPUT_BG)
      .hitTestBehavior(HitTestMode.Block)
      .onClick(() => {
        this.onImageClick?.();
      })
      .animation({ duration: AppChat.OVERLAY_ENTER_DURATION })
  }
}
