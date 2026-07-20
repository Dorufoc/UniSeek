// 应用样式常量 - 设计系统
// 遵循 arkts-style-guide.md 规范，与 Vue 端设计体系保持一致

// 动画曲线使用字符串类型，.animation() 接受 Curve | string

// ==================== 颜色系统 ====================
export class AppColors {
  // 主色调（品牌色）
  static readonly PRIMARY = '#1762FB';
  static readonly PRIMARY_HOVER = '#0A4BDB';
  static readonly HMOS_BRAND = '#1762FB';

  // 功能色
  static readonly SUCCESS = '#10b981';
  static readonly WARNING = '#f59e0b';
  static readonly DANGER = '#ef4444';
  static readonly INFO = '#6366f1';

  // 选中态/错误态背景色
  static readonly SELECTED_BG = '#EBF5FF';
  static readonly ERROR_BG = '#FFF0F0';

  // 中性色
  static readonly TEXT_PRIMARY = '#1a1a2e';
  static readonly TEXT_SECONDARY = '#64748b';
  static readonly TEXT_MUTED = '#94a3b8';
  static readonly BG_PAGE = '#f8fafc';
  static readonly BG_CARD = '#ffffff';
  static readonly BORDER = '#e2e8f0';
  static readonly INPUT_BG = '#f5f7fa';
  static readonly INPUT_FOCUS_BG = '#eef2f8';
  static readonly OVERLAY = 'rgba(0, 0, 0, 0.4)';

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
  static readonly XS = 4;
  static readonly SM = 8;
  static readonly MD = 16;
  static readonly LG = 24;
  static readonly XL = 32;
  static readonly XXL = 48;
}

// ==================== 圆角系统 ====================
export class AppRadius {
  static readonly SM = 6;
  static readonly MD = 8;
  static readonly LG = 12;
  static readonly XL = 16;
  static readonly FULL = 100;
}

// ==================== 字体大小系统 ====================
export class AppFontSize {
  static readonly XS = 12;
  static readonly SM = 14;
  static readonly MD = 16;
  static readonly LG = 18;
  static readonly XL = 20;
  static readonly XXL = 24;
  static readonly XXXL = 32;
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

// ==================== 公共组件 ====================

// 标准输入框组件
@Component
export struct StandardInput {
  @Prop placeholder: string = '';
  @Link @Watch('onValueChange') value: string;
  @Prop inputType: InputType = InputType.Normal;
  @Prop maxLength: number = 100;
  @Prop hasError: boolean = false;

  build() {
    TextInput({ placeholder: this.placeholder, text: this.value })
      .type(this.inputType)
      .maxLength(this.maxLength)
      .height(50)
      // HMOS 规范推荐背景色：$r('sys.color.comp_background_tertiary')
      .backgroundColor(AppColors.INPUT_BG)
      .borderRadius(20) // 胶囊样式，符合 HMOS TextInput 规范
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
      .fontSize(AppFontSize.MD)
      .fontColor(AppColors.TEXT_PRIMARY)
      .placeholderColor(AppColors.TEXT_MUTED)
      .onChange((value: string) => {
        this.value = value;
      })
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
      .height(40) // HMOS 胶囊按钮高度规范
      .backgroundColor(this.disabled || this.loading ? AppColors.TEXT_MUTED : AppColors.PRIMARY)
      .fontSize(AppFontSize.MD)
      .fontWeight(FontWeight.Medium)
      .fontColor('#ffffff')
      .enabled(!this.disabled && !this.loading)
      .onClick(() => {
        this.onTap?.();
      })
  }
}


