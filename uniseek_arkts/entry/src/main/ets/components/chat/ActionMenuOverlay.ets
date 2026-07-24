// ActionMenuOverlay.ets — 聊天更多操作抽屉内容
// 职责：作为底部 Sheet 的内容，提供发送图片、发送简历等入口

import { AppColors, AppFontSize, AppRadius, AppSpacing } from '../../common/AppStyles';

interface MenuAction {
  label: string
  icon: Resource
  onClick?: () => void
}

@Component
export struct ActionMenuOverlay {
  onSendImage?: () => void;
  onSendResume?: () => void;

  private actionButtons(): MenuAction[] {
    return [
      { label: '发送图片', icon: $r('sys.symbol.picture'), onClick: this.onSendImage },
      { label: '发送简历', icon: $r('sys.symbol.doc_text'), onClick: this.onSendResume }
    ];
  }

  build() {
    Column({ space: AppSpacing.MD }) {
      Text('更多操作')
        .fontSize(AppFontSize.MD)
        .fontColor(AppColors.TEXT_PRIMARY)
        .fontWeight(FontWeight.Medium)
        .margin({ top: AppSpacing.SM })

      Row({ space: AppSpacing.XL }) {
        ForEach(this.actionButtons(), (action: MenuAction) => {
          Column({ space: AppSpacing.SM }) {
            Button() {
              SymbolGlyph(action.icon)
                .fontSize(AppFontSize.ICON_LG)
                .fontColor([AppColors.PRIMARY])
            }
            .width(56)
            .height(56)
            .borderRadius(AppRadius.XL)
            .backgroundColor(AppColors.SELECTED_BG)
            .stateStyles({
              pressed: {
                .backgroundColor(AppColors.PRIMARY_ALPHA_8)
              }
            })
            .onClick(() => {
              action.onClick?.();
            })

            Text(action.label)
              .fontSize(AppFontSize.SM)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
        }, (action: MenuAction) => action.label)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ top: AppSpacing.LG, bottom: AppSpacing.XL })
    }
    .width('100%')
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD })
  }
}
