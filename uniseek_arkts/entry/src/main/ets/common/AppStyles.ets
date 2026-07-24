

// 应用样式常量 - 设计系统
// 本文件优先复用 HarmonyOS 系统 Token，仅在产品级语义/渐变/透明度场景保留硬编码值
// 所有组件颜色应尽量从 AppColors/AppFontSize/AppSpacing 取值，避免页面中再次硬编码

// ==================== 颜色系统 ====================
// 类型说明：ResourceColor 可接受 string / Color / Resource，因此以下常量既能保留自定义
// HEX，也能直接引用 $r('sys.color.*')。页面中 fontColor / backgroundColor / borderColor 均接受 ResourceColor。
export class AppColors {
  // 主色调（品牌色）—— 优先使用系统 brand Token，保证随主题/深浅色自动切换
  static readonly PRIMARY: ResourceColor = $r('sys.color.brand');
  static readonly PRIMARY_HOVER: ResourceColor = $r('sys.color.interactive_hover');
  static readonly HMOS_BRAND: ResourceColor = $r('sys.color.brand');

  // 功能色：产品业务语义保留，便于业务光伏识别
  static readonly SUCCESS = '#10b981';
  static readonly WARNING = '#f59e0b';
  static readonly DANGER = '#ef4444';
  static readonly INFO = '#6366f1';

  // 选中态/错误态背景色：产品语义色，保留自定义以满足明显彩色提示
  static readonly SELECTED_BG = '#EBF5FF';
  static readonly ERROR_BG = '#FFF0F0';
  static readonly WARNING_BG = '#FFF7E6';
  static readonly SUCCESS_BG = '#ECFDF5';

  // 中性色：全部迁移到 HMOS 系统 Token，自动适配深浅色
  static readonly TEXT_PRIMARY: ResourceColor = $r('sys.color.font_primary');
  static readonly TEXT_SECONDARY: ResourceColor = $r('sys.color.font_secondary');
  static readonly TEXT_MUTED: ResourceColor = $r('sys.color.font_tertiary');
  static readonly BG_PAGE: ResourceColor = $r('sys.color.background_primary');
  static readonly BG_CARD: ResourceColor = $r('sys.color.comp_background_primary');
  static readonly BORDER: ResourceColor = $r('sys.color.comp_divider');
  static readonly INPUT_BG: ResourceColor = $r('sys.color.comp_background_tertiary');
  static readonly INPUT_FOCUS_BG: ResourceColor = $r('sys.color.comp_background_tertiary');
  static readonly DISABLED: ResourceColor = $r('sys.color.font_fourth');
  static readonly OVERLAY = 'rgba(0, 0, 0, 0.4)';
  static readonly OVERLAY_DARK = 'rgba(0, 0, 0, 0.9)';

  // 主色透明层（用于按压态、光晕阴影）—— 透明度值无系统 Token，保留自定义 RGBA 字符串
  static readonly PRIMARY_ALPHA_6 = 'rgba(23, 98, 251, 0.06)';
  static readonly PRIMARY_ALPHA_8 = 'rgba(23, 98, 251, 0.08)';

  // 渐变/装饰色（登录页背景过渡）—— 产品品牌渐变保留
  static readonly PRIMARY_LIGHT = '#5A8CFF';
  static readonly PRIMARY_LIGHTER = '#A8C4FF';
  static readonly PRIMARY_FAINT = '#E4EEFF';

  // 浅色边框与分隔线
  static readonly BORDER_LIGHT = 'rgba(0, 0, 0, 0.06)';
  static readonly BORDER_FAINT = 'rgba(0, 0, 0, 0.04)';

  /**
   * HMOS 系统色 Token 引用说明（$r 仅在 @Component 中可用，此处仅作文档参考）：
   *
   * | 使用场景          | 当前硬编码值      | 推荐 HMOS 系统 Token                              |
   * |-------------------|-------------------|---------------------------------------------------|
   * | 页面背景          | BG_PAGE           | $r('sys.color.background_primary')                |
   * | 卡片背景          | BG_CARD           | $r('sys.color.comp_background_primary')           |
   * | 输入框背景        | INPUT_BG          | $r('sys.color.comp_background_tertiary')          |
   * | 输入框聚焦背景    | INPUT_FOCUS_BG    | $r('sys.color.comp_background_tertiary')          |
   * | 分割线/边框       | BORDER            | $r('sys.color.comp_background_tertiary')          |
   * | 遮罩层            | OVERLAY           | $r('sys.color.background_primary') + 透明度       |
   * | 品牌色            | PRIMARY           | $r('sys.color.brand')                             |
   * | 品牌悬停色        | PRIMARY_HOVER     | $r('sys.color.interactive_hover')                 |
   * | 正文文本          | TEXT_PRIMARY      | $r('sys.color.font_primary')                      |
   * | 次要文本          | TEXT_SECONDARY    | $r('sys.color.font_secondary')                    |
   * | 占位/禁用文本     | TEXT_MUTED        | $r('sys.color.font_tertiary')                     |
   */
}

// ==================== 间距系统 ====================
export class AppSpacing {
  static readonly ZERO = 0;
  static readonly XXS = 2;
  static readonly XS = 4;
  static readonly XS_GAP = 6;
  static readonly SM = 8;
  static readonly SM_GAP = 10;
  static readonly SM_PLUS = 12;
  static readonly MD = 16;
  static readonly LG = 24;
  static readonly XL = 32;
  static readonly XXL = 48;
  // 底部固定操作区高度（按钮栏、悬浮操作栏等）
  static readonly BOTTOM_ACTION_HEIGHT = 56;

  // 图标/头像尺寸
  static readonly ICON_XS = 20;
  static readonly ICON_SM = 24;
  static readonly ICON_MD = 28;
  static readonly ICON_LG = 40;
  static readonly ICON_XL = 44;
  static readonly ICON_XXL = 48;
  static readonly AVATAR_XL = 72;

  // 按钮/输入框高度
  static readonly BUTTON_HEIGHT_MINI = 32;
  static readonly BUTTON_HEIGHT_XS = 28;
  static readonly BUTTON_HEIGHT_SM = 36;
  static readonly BUTTON_HEIGHT = 40;
  static readonly BUTTON_HEIGHT_MD = 44;
  static readonly INPUT_HEIGHT = 48;
  static readonly INPUT_HEIGHT_STANDARD = 50;
  static readonly BUTTON_HEIGHT_LG = 52;

  // 列表/页面结构尺寸
  static readonly LIST_ITEM_HEIGHT = 56;
  static readonly FOOTER_SPACER = 88;
  static readonly HEADER_HEIGHT = 104;
  static readonly FILTER_LIST_HEIGHT = 200;
  static readonly FILTER_OCCUPATION_LIST_HEIGHT = 180;
  static readonly MENU_PANEL_WIDTH = 180;
  static readonly CARD_PADDING = 14;
  static readonly PAGE_PADDING_VERTICAL = 28;

  // 分隔线
  static readonly DIVIDER_THICKNESS = 0.5;
  static readonly DIVIDER_THICKNESS_BOLD = 1;
}

// ==================== 圆角系统 ====================
export class AppRadius {
  static readonly XS = 4;
  static readonly SM = 6;
  static readonly MD = 8;
  static readonly LG = 12;
  static readonly XL = 16;
  static readonly FULL = 100;

  // 业务中间档
  static readonly PANEL = 10;
  static readonly SOFT = 14;
  static readonly BUBBLE = 18;
  static readonly PILL = 20;
}

// ==================== 字体大小系统 ====================
export class AppFontSize {
  static readonly XXS = 10;
  static readonly XS = 12;
  static readonly SM = 14;
  static readonly MD = 16;
  static readonly LG = 18;
  // Headline：卡片标题等级字号，对应系统 font_headline6（18fp）
  static readonly HEADLINE = 18;
  static readonly XL = 20;
  static readonly XXL = 24;
  static readonly XXXL = 32;

  // 业务中间档
  static readonly TINY = 11;
  static readonly CAPTION = 12.5;
  static readonly META = 13;
  static readonly LABEL = 13.5;
  static readonly BODY = 14.5;
  static readonly SUBHEAD = 15;
  static readonly TITLE = 17;
  static readonly ICON_MD = 18;
  static readonly ICON_LG = 22;
}

// ==================== 字体层级（Typography）====================
// HMOS 文本层级映射（使用 $r('sys.float.font_*') 或 .textTypes() 替代硬编码字号）：
//
// | HMOS 层级       | 系统资源                            | 字号    | 使用场景              |
// |-----------------|-------------------------------------|---------|-----------------------|
// | Display         | $r('sys.float.font_display')        | 40-57fp | 首屏数字/大标题       |
// | Title1          | $r('sys.float.font_title1')         | 32fp    | 页面大标题            |
// | Title2          | $r('sys.float.font_title2')         | 24fp    | 页面标题              |
// | Title3          | $r('sys.float.font_title3')         | 20fp    | 模块标题              |
// | Headline        | $r('sys.float.font_headline6')      | 18fp    | 卡片标题              |
// | Body            | $r('sys.float.font_body1')          | 16fp    | 正文                  |
// | Sub             | $r('sys.float.font_body2')          | 14fp    | 辅助文字              |
// | Caption         | $r('sys.float.font_caption1')       | 12fp    | 说明文字              |
export class AppTypography {
  // 此类作为 Typography 层级参考文档，
  // 实际使用时请使用 $r 系统资源或 .textTypes() API。
  // 保留 AppFontSize 中的硬编码值用于非 @Component 场景（如动态计算）。
}

// ==================== 阴影系统 ====================
export interface ShadowConfig {
  radius: number;
  color: string;
  offsetX: number;
  offsetY: number;
}

export class AppShadow {
  static readonly SM: ShadowConfig = {
    radius: 6,
    color: 'rgba(0, 0, 0, 0.04)',
    offsetX: 0,
    offsetY: 1
  };

  static readonly MD: ShadowConfig = {
    radius: 12,
    color: 'rgba(0, 0, 0, 0.06)',
    offsetX: 0,
    offsetY: 4
  };

  static readonly LG: ShadowConfig = {
    radius: 24,
    color: 'rgba(0, 0, 0, 0.08)',
    offsetX: 0,
    offsetY: 8
  };

  static readonly MENU: ShadowConfig = {
    radius: 16,
    color: 'rgba(0, 0, 0, 0.12)',
    offsetX: 0,
    offsetY: 4
  };
}

// ==================== 动画常量 ====================
export class AppAnimation {
  static readonly DURATION_FAST = 150;
  static readonly DURATION_NORMAL = 250;
  static readonly DURATION_SLOW = 350;
  // 曲线常量使用字符串，.animation() API 接受 Curve | string
  static readonly CURVE_DEFAULT = 'fast-out-linear-in';
  // CURVE_EMPHASIZED 是 API 12+ HMOS 引力动效推荐曲线，用于强调性动画
  // 使用 cubicBezier 字符串模拟 HMOS 引力动效曲线
  static readonly CURVE_EMPHASIZED = 'cubic-bezier(0.2, 0.0, 0.2, 1.0)';
  // CURVE_EMPHASIZED_GRAVITY — HMOS 引力动效曲线，用于入场/转场等强调动画
  // 更激进的回弹效果，适合卡片入场、芯片切换等场景
  static readonly CURVE_EMPHASIZED_GRAVITY = 'cubic-bezier(0.2, 0, 0, 1.0)';
}

// ==================== 筛选/选择器语义化 Token ====================
export class AppFilter {
  // 胶囊芯片尺寸
  static readonly CHIP_HEIGHT = AppSpacing.BUTTON_HEIGHT_MINI;
  static readonly CHIP_PADDING_HORIZONTAL = AppSpacing.MD;
  static readonly CHIP_ICON_TEXT_GAP = AppSpacing.XS;
  static readonly CHIP_FONT_SIZE = AppFontSize.XS;
  static readonly CHIP_ICON_SIZE = AppFontSize.XS;
  static readonly CHIP_CLOSE_ICON_SIZE = AppFontSize.XXS;
  static readonly CHIP_BAR_SPACE = AppSpacing.SM;
  static readonly CHIP_BAR_PADDING_VERTICAL = AppSpacing.SM;

  // 选择器 Sheet 头部
  static readonly SHEET_HEADER_HEIGHT = AppSpacing.BUTTON_HEIGHT_MINI;
  static readonly SHEET_HEADER_PADDING = AppSpacing.MD;
  static readonly SHEET_TITLE_FONT_SIZE = AppFontSize.LG;
  static readonly SHEET_TITLE_FONT_WEIGHT = FontWeight.Bold;
  static readonly SHEET_RESET_FONT_SIZE = AppFontSize.SM;

  // 单选列表项
  static readonly OPTION_ROW_HEIGHT = AppSpacing.LIST_ITEM_HEIGHT;
  static readonly OPTION_HORIZONTAL_PADDING = AppSpacing.LG;
  static readonly OPTION_FONT_SIZE = AppFontSize.SM;
  static readonly OPTION_CHECK_ICON_SIZE = AppFontSize.ICON_MD;

  // 区块标题
  static readonly SECTION_TITLE_FONT_SIZE = AppFontSize.MD;
  static readonly SECTION_TITLE_FONT_WEIGHT = FontWeight.Bold;
  static readonly SECTION_TITLE_MARGIN = 12;

  // 复选行
  static readonly CHECK_OPTION_HEIGHT = 40;
  static readonly CHECK_OPTION_HORIZONTAL_PADDING = AppSpacing.SM_PLUS;
  static readonly CHECK_OPTION_FONT_SIZE = AppFontSize.SUBHEAD;

  // 分段选择器
  static readonly CHOICE_CHIP_HEIGHT = AppSpacing.BUTTON_HEIGHT_SM;
  static readonly CHOICE_CHIP_FONT_SIZE = AppFontSize.SM;
  static readonly CHOICE_CHIP_SPACE = AppSpacing.SM;

  // 表单选择字段行
  static readonly SELECTOR_FIELD_HEIGHT = AppSpacing.INPUT_HEIGHT;
  static readonly SELECTOR_FIELD_FONT_SIZE = AppFontSize.SM;
  static readonly SELECTOR_FIELD_LABEL_FONT_SIZE = AppFontSize.XS;
  static readonly SELECTOR_FIELD_CHEVRON_SIZE = AppFontSize.MD;

  // 颜色语义（统一引用现有色板，不重复定义颜色值）
  static readonly ACTIVE_TEXT_COLOR: ResourceColor = AppColors.PRIMARY;
  static readonly ACTIVE_BACKGROUND_COLOR: ResourceColor = AppColors.SELECTED_BG;
  static readonly INACTIVE_TEXT_COLOR: ResourceColor = AppColors.TEXT_SECONDARY;
  static readonly INACTIVE_BACKGROUND_COLOR: ResourceColor = AppColors.INPUT_BG;
  static readonly DIVIDER_COLOR: ResourceColor = AppColors.BORDER;
  static readonly DIVIDER_HEIGHT = AppSpacing.DIVIDER_THICKNESS;
  static readonly DIVIDER_INSETS = AppSpacing.MD;
}

// ==================== 聊天模块语义化 Token ====================
export class AppChat {
  // 头像尺寸：会话列表使用大头像，聊天消息使用小头像
  static readonly AVATAR_SESSION = AppSpacing.ICON_XXL;
  static readonly AVATAR_MESSAGE = AppSpacing.ICON_MD;

  // 头像占位 initials 字号与尺寸比例，保证圆形内居中可读
  static readonly AVATAR_INITIAL_FONT_RATIO: number = 0.45;

  // 会话项
  static readonly SESSION_ITEM_PADDING = AppSpacing.SM;
  static readonly SESSION_ITEM_HEIGHT = 72;
  static readonly SESSION_NAME_FONT = AppFontSize.SUBHEAD;
  static readonly SESSION_PREVIEW_FONT = AppFontSize.LABEL;
  static readonly SESSION_TIME_FONT = AppFontSize.XS;
  static readonly PREVIEW_LINE_HEIGHT = 20;
  static readonly SESSION_SELECT_DURATION = 180;

  // 会话列表分割线：从左边缘缩进至文本区域起始位置（头像 + 左侧内边距 + 间距）
  static readonly SESSION_LIST_DIVIDER_INSET = AppChat.AVATAR_SESSION + AppSpacing.MD + AppSpacing.SM_PLUS;

  // 列表项入场动效
  static readonly LIST_ENTER_TRANSLATE_Y = 12;

  // 消息气泡
  static readonly BUBBLE_MAX_WIDTH = '76%';
  static readonly BUBBLE_FONT = AppFontSize.MD;
  static readonly BUBBLE_RADIUS = AppRadius.BUBBLE;
  static readonly BUBBLE_LINE_HEIGHT = 23;
  static readonly BUBBLE_SELF_SHARP_CORNER = AppRadius.SM;
  static readonly BUBBLE_OTHER_SHARP_CORNER = AppRadius.SM;

  // 图片/附件气泡
  static readonly BUBBLE_IMAGE_MAX_HEIGHT = 320;
  static readonly ATTACHMENT_TAG_FONT = AppFontSize.XS;
  static readonly ATTACHMENT_BUTTON_FONT = AppFontSize.META;

  // 消息行
  static readonly MESSAGE_ROW_SPACE = AppSpacing.SM_PLUS;
  static readonly MESSAGE_TIME_GAP = AppSpacing.XS;

  // 输入栏
  static readonly INPUT_BAR_HEIGHT = AppSpacing.INPUT_HEIGHT_STANDARD;
  static readonly INPUT_BAR_PADDING_BOTTOM = 20;
  static readonly INPUT_BAR_HORIZONTAL_PADDING = AppSpacing.PAGE_PADDING_VERTICAL;
  static readonly INPUT_BAR_TOP_PADDING = AppSpacing.MD;

  // 消息气泡图片与附件通用圆角
  static readonly BUBBLE_IMAGE_RADIUS = AppRadius.SOFT;

  // 遮罩层进入/退出动画时长
  static readonly OVERLAY_ENTER_DURATION = 200;
  static readonly OVERLAY_EXIT_DURATION = 200;

  // 选中态左侧指示条
  static readonly SELECTOR_WIDTH = 3;
  static readonly SELECTOR_HEIGHT = 24;
  static readonly SELECTOR_RADIUS = AppRadius.XS;

  // 未读消息徽标
  static readonly BADGE_FONT = AppFontSize.TINY;
  static readonly BADGE_MIN_WIDTH = 20;
  static readonly BADGE_HEIGHT = 20;
  static readonly BADGE_RADIUS = AppRadius.PILL;
  static readonly BADGE_MAX_TEXT = '99+';
  static readonly BADGE_OVERFLOW_THRESHOLD = 100;
  static readonly BADGE_HORIZONTAL_PADDING = 6;
}

// ==================== 公共组件 ====================

// 标准输入框组件
@Component
export struct StandardInput {
  @Prop placeholder: string = '';
  @Link @Watch('onValueChange') value: string;
  @Prop inputType: InputType = InputType.Normal;
  @Prop maxLength: number = 100;
  @Prop hasError: boolean = false;
  @Prop errorText: string = '';
  @Prop leadingIcon?: Resource;
  @Prop trailingIcon?: Resource;
  onTapTrailing?: () => void;

  build() {
    Column() {
      Row() {
        if (this.leadingIcon) {
          SymbolGlyph(this.leadingIcon)
            .fontSize(AppFontSize.ICON_MD)
            .fontColor([AppColors.TEXT_MUTED])
            .margin({ right: AppSpacing.SM })
        }

        TextInput({ placeholder: this.placeholder, text: this.value })
          .type(this.inputType)
          .maxLength(this.maxLength)
          .height(AppSpacing.INPUT_HEIGHT_STANDARD)
          .backgroundColor(Color.Transparent)
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_PRIMARY)
          .placeholderColor(AppColors.TEXT_MUTED)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.value = value;
          })

        if (this.trailingIcon) {
          SymbolGlyph(this.trailingIcon)
            .fontSize(AppFontSize.ICON_MD)
            .fontColor([AppColors.TEXT_MUTED])
            .margin({ left: AppSpacing.SM })
            .onClick(() => {
              this.onTapTrailing?.();
            })
        }
      }
      .width('100%')
      .height(AppSpacing.INPUT_HEIGHT_STANDARD)
      .backgroundColor(AppColors.INPUT_BG)
      .borderRadius(AppRadius.PILL)
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
      .border({
        width: this.hasError ? 1 : 0,
        color: this.hasError ? AppColors.DANGER : AppColors.BORDER
      })

      if (this.hasError && this.errorText) {
        Text(this.errorText)
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.DANGER)
          .width('100%')
          .padding({ left: AppSpacing.MD, top: AppSpacing.XS })
      }
    }
    .width('100%')
  }

  onValueChange(): void {
    // 值变化触发的回调响应
  }
}

// 主按钮组件
@Component
export struct PrimaryButton {
  @Prop text: string = '';
  @Prop disabled: boolean = false;
  @Prop loading: boolean = false;
  onTap?: () => void;

  build() {
    Button(this.loading ? '请稍候...' : this.text, { type: ButtonType.Capsule })
      .width('100%')
      .height(AppSpacing.BUTTON_HEIGHT) // HMOS 胶囊按钮高度规范
      .backgroundColor(this.disabled || this.loading ? AppColors.TEXT_MUTED : AppColors.PRIMARY)
      .fontSize(AppFontSize.MD)
      .fontWeight(FontWeight.Medium)
      .fontColor('#FFFFFF')
      .enabled(!this.disabled && !this.loading)
      .onClick(() => {
        this.onTap?.();
      })
  }
}
