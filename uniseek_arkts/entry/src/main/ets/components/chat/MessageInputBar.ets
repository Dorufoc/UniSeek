// MessageInputBar.ets — 聊天输入栏：加号菜单、文本输入、发送按钮

import { AppColors, AppFontSize, AppRadius, AppSpacing, AppChat } from '../../common/AppStyles';

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
    Column() {
      Row({ space: AppSpacing.SM_PLUS }) {
        // 加号按钮：展开更多操作菜单
        Button() {
          SymbolGlyph($r('sys.symbol.plus'))
            .fontSize(AppFontSize.ICON_LG)
            .fontColor([AppColors.TEXT_SECONDARY])
        }
        .width(AppSpacing.ICON_XXL)
        .height(AppSpacing.ICON_XXL)
        .padding(AppSpacing.ZERO)
        .borderRadius(AppRadius.SOFT)
        .border({ width: 1.5, color: AppColors.BORDER })
        .backgroundColor(AppColors.BG_PAGE)
        .stateStyles({
          pressed: {
            .backgroundColor(AppColors.INPUT_FOCUS_BG)
          }
        })
        .accessibilityText('更多操作')
        .enabled(this.canSend)
        .onClick(() => {
          this.onToggleMenu?.();
        })

        // 文本输入框
        TextInput({ placeholder: this.getPlaceholder(), text: this.inputText })
          .onChange((value: string) => {
            this.inputText = value;
          })
          .layoutWeight(1)
          .height(AppSpacing.INPUT_HEIGHT)
          .borderRadius(AppRadius.SOFT)
          .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
          .fontSize(AppFontSize.BODY)
          .fontColor(AppColors.TEXT_PRIMARY)
          .placeholderColor(AppColors.TEXT_MUTED)
          .backgroundColor(AppColors.BG_PAGE)
          .border({ width: 1.5, color: AppColors.BORDER })
          .enabled(this.canSend)
          .stateStyles({
            focused: {
              .borderColor(AppColors.PRIMARY)
              .backgroundColor(AppColors.BG_CARD)
              .shadow({ radius: 4, color: AppColors.PRIMARY_ALPHA_8, offsetX: 0, offsetY: 0 })
            }
          })

        // 发送按钮
        Button() {
          Text(this.isSending ? '...' : '发送')
            .fontSize(AppFontSize.BODY)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.BG_CARD)
        }
        .height(AppSpacing.INPUT_HEIGHT)
        .constraintSize({ minWidth: 80 })
        .padding({ left: AppSpacing.LG, right: AppSpacing.LG })
        .borderRadius(AppRadius.SOFT)
        .backgroundColor(AppColors.PRIMARY)
        .enabled(this.canSendMessage())
        .onClick(() => {
          this.onSend?.();
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({
      left: AppSpacing.PAGE_PADDING_VERTICAL,
      right: AppSpacing.PAGE_PADDING_VERTICAL,
      top: AppSpacing.MD,
      bottom: AppChat.INPUT_BAR_PADDING_BOTTOM
    })
    .backgroundColor(AppColors.BG_CARD)
    .borderWidth({ top: 1 })
    .borderColor({ top: AppColors.BORDER_FAINT })
  }
}
