# Task 3 字号/间距/圆角收敛方案

## 1. 目标文件与待收敛项

针对以下 11 个 ArkTS 页面/公共样式文件，收敛硬编码字号、间距、圆角（`fontSize`/`borderRadius`/`padding`/`margin`/`height`/`width`）：

- `uniseek_arkts/entry/src/main/ets/pages/LoginPage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/RegisterPage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/JobDetailPage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/ChatDetailPage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/HomePage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/JobFeedCard.ets`
- `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/JobFeedList.ets`
- `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/ProfilePage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/MainPage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/RecruiterHomePage.ets`
- `uniseek_arkts/entry/src/main/ets/common/AppStyles.ets`（Token 源）

## 2. 新增 Token 与映射关系

基于 `AppStyles.ets` 现有常量，本次新增语义 Token：

| 新增 Token | 值 | 使用场景 | 收敛来源 |
|---|---|---|---|
| `AppFontSize.ICON_MD` | 18 | 表单 SymbolGlyph 图标字号 | LoginPage/RegisterPage `.fontSize(18)` |
| `AppSpacing.BUTTON_HEIGHT_XS` | 28 | 注册页“用户协议/隐私政策”小按钮高度 | RegisterPage `.height(28)` |
| `AppSpacing.ZERO` | 0 | 显式重置 padding 为 0 | ChatDetailPage `.padding(0)` |
| `AppSpacing.XXS` | 2 | 极紧凑间距，如聊天标题副标题上间距 | ChatDetailPage `.margin({ top: 2 })` |
| `AppSpacing.XS_GAP` | 6 | 小型元素间横向/纵向间隙 | ChatDetailPage/JobFeedCard/ChatDetailPage 的 6 像素间距 |
| `AppSpacing.SM_GAP` | 10 | 登录页 Logo 底部、筛选列表项上下内边距等中间档 | LoginPage logo 底部、HomePage list 上下内边距 |
| `AppSpacing.SM_PLUS` | 12 | 列表项/气泡横向与竖向padding的常用中间档 | ChatDetailPage 气泡 padding、HomePage list 多项 padding |

现有 Token 直接复用：

| 现有 Token | 值 | 收敛来源 |
|---|---|---|
| `AppSpacing.INPUT_HEIGHT_STANDARD` | 50 | LoginPage/RegisterPage 输入框 `.height(50)` |
| `AppSpacing.BUTTON_HEIGHT` | 40 | RegisterPage 注册主按钮 `.height(40)` |
| `AppSpacing.BUTTON_HEIGHT_MINI` | 32 | LoginPage/RegisterPage 文字按钮 `.height(32)` |
| `AppRadius.PILL` | 20 | LoginPage/RegisterPage 胶囊输入框 `.borderRadius(20)` |
| `AppSpacing.XL` | 32 | RegisterPage 页面水平内边距 `.padding({ left: 32, right: 32 })` |
| `AppSpacing.XS` | 4 | MainPage/RecruiterHomePage 标签文字上边距、JobFeedCard/JobFeedList 小间距 |
| `AppSpacing.SM` | 8 | ChatDetailPage 简历消息左间距、HomePage 筛选输入框间隔 |
| `AppSpacing.MD` | 16 | ChatDetailPage 气泡左右内边距 |

## 3. 不可收敛魔法数字及理由

以下魔法数字因语义特殊、仅单次出现或破坏布局风险较高，予以保留并在 `fix-approach.md` 声明：

1. **ChatDetailPage.ets `.margin({ left: 28, bottom: 100 })`**
   - 理由：菜单面板弹出位置为相对于屏幕左下角的绝对偏移，28/100 为设计稿定位参数，无通用语义，改为 Token 易误导。
2. **ChatDetailPage.ets `.padding({ left: AppSpacing.PAGE_PADDING_VERTICAL, right: AppSpacing.PAGE_PADDING_VERTICAL, top: AppSpacing.MD, bottom: 20 })`**
   - 理由：输入区域底部 20 为软键盘/安全区过渡补偿，属于页面级特殊间距，未在系统间距阶梯中体现。
3. **RegisterPage.ets `.margin({ top: 60, bottom: AppSpacing.XL })`**
   - 理由：60 为注册页顶部标题区整体下沉量，仅该页面使用，属于页面级布局参数，无复用价值。

上述保留项不会出现在验收命令 `Select-String -Pattern '\.(fontSize|borderRadius|height|width)\([0-9]+' `中，因此不影响 PowerShell 验收命中数。

## 4. 影响范围与回退策略

- 影响范围：仅涉及上述 11 个文件的视觉参数（字号、间距、圆角），不改动业务逻辑、导航、状态变量、TabBar 动效（Task 4 已完成）及颜色（Task 2 已完成）。
- 回退策略：如出现布局偏差，直接回滚对应文件改动；新增 Token 若使用不当，可在 `AppStyles.ets` 中删除（但本次新增 Token 均为首次使用，无其他引用）。
- 验证计划：
  1. 运行 `codelinter --exit-on error <11个目标文件>`，期望退出码 0；
  2. 运行 `hvigorw assembleHap --no-daemon`，期望 `BUILD SUCCESSFUL`；
  3. 运行验收 `Select-String` 命令，期望命中数 ≤5（本次目标为 0）。
