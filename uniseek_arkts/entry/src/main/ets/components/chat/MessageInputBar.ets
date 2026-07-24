// MessageInputBar.ets — 聊天输入栏：紧凑布局，对齐微信/飞书/钉钉比例

import { AppColors, AppFontSize, AppRadius, AppSpacing } from '../../common/AppStyles';

const INPUT_BAR_HEIGHT = 54       // IM 常见输入栏高度 +10
const ACTION_BUTTON_SIZE = 34     // 左侧圆形加号按钮
const SEND_BUTTON_HEIGHT = 32     // 发送按钮高度
const SEND_BUTTON_MIN_WIDTH = 60  // 发送按钮最小宽度

@Component
export struct MessageInputBar {
  @Link inputText: string;
  @Prop canSend: boolean = true;
  @Prop isSending: boolean = false;
  onSend?: () => void;
  onToggleMenu?: () => void;

  private canSendMessage(): boolean {
    return this.canSend && !this.isSending && this.inputText.trim().length > 0;
  }

  private getPlaceholder(): string {
    return this.canSend ? '请输入消息...' : 'HR 未回复前，您只能发送一条消息';
  }

  build() {
    Row({ space: AppSpacing.SM }) {
      // 加号按钮：打开底部操作抽屉
      Button() {
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(AppFontSize.ICON_MD)
          .fontColor([AppColors.TEXT_SECONDARY])
      }
      .width(ACTION_BUTTON_SIZE)
      .height(ACTION_BUTTON_SIZE)
      .padding(AppSpacing.ZERO)
      .borderRadius(AppRadius.FULL)
      .border({ width: 1, color: AppColors.BORDER })
      .backgroundColor(AppColors.BG_PAGE)
      .accessibilityText('更多操作')
      .enabled(this.canSend)
      .stateStyles({
        pressed: {
          .backgroundColor(AppColors.INPUT_FOCUS_BG)
        }
      })
      .onClick(() => {
        this.onToggleMenu?.();
      })

      // 文本输入框
      TextInput({ placeholder: this.getPlaceholder(), text: this.inputText })
        .onChange((value: string) => {
          this.inputText = value;
        })
        .layoutWeight(1)
        .height(SEND_BUTTON_HEIGHT)
        .fontSize(AppFontSize.BODY)
        .fontColor(AppColors.TEXT_PRIMARY)
        .placeholderColor(AppColors.TEXT_MUTED)
        .backgroundColor(AppColors.BG_PAGE)
        .borderRadius(AppRadius.SOFT)
        .border({ width: 1, color: AppColors.BORDER })
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
        .enabled(this.canSend)
        .stateStyles({
          focused: {
            .borderColor(AppColors.PRIMARY)
            .backgroundColor(AppColors.BG_CARD)
            .shadow({ radius: 4, color: AppColors.PRIMARY_ALPHA_8, offsetX: 0, offsetY: 0 })
          }
        })

      // 发送按钮
      Button(this.isSending ? '...' : '发送', { type: ButtonType.Capsule })
        .height(SEND_BUTTON_HEIGHT)
        .constraintSize({ minWidth: SEND_BUTTON_MIN_WIDTH })
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
        .fontSize(AppFontSize.SM)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.BG_CARD)
        .backgroundColor(this.canSendMessage() ? AppColors.PRIMARY : AppColors.TEXT_MUTED)
        .enabled(this.canSendMessage())
        .onClick(() => {
          this.onSend?.();
        })
    }
    .width('90%')
    .height(INPUT_BAR_HEIGHT)
    .alignItems(VerticalAlign.Center)
  }
}
