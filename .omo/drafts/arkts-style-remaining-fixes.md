---
slug: arkts-style-remaining-fixes
status: awaiting-approval
intent: clear
review_required: true
pending-action: review .omo/plans/arkts-style-remaining-fixes.md after round-003 fixes
review_round_id: review-2026-07-23-007
plan_path: .omo/plans/arkts-style-remaining-fixes.md
plan_sha256: revised-after-round-003-changes
approach: 基于当前 ArkTS 代码实际状态进行系统性样式问题审计与修复，先修复编译级错误，再统一设计 Token、图标、布局、响应式与无障碍，最后通过 codelinter + hvigorw 双重校验确保构建成功。
---

# Draft: arkts-style-remaining-fixes

## Components (topology ledger)
<!-- Lock the SHAPE before depth. One row per top-level component that can succeed or fail independently. -->
<!-- id | outcome (one line) | status: active|deferred | evidence path -->
| id | outcome | status | evidence path |
|---|---|---|---|
| common/AppStyles.ets | 修复 AppTypography 缺失属性，补充设计 Token | active | 文件读取 |
| common/NavBar.ets | 已存在，保持使用 | active | 文件读取 |
| common/StandardCard.ets | 已存在，保持使用 | active | 文件读取 |
| pages/LoginPage.ets | 修复编译错误与硬编码样式 | active | 文件读取 |
| pages/RegisterPage.ets | 统一输入框/按钮/颜色规范 | active | 文件读取 |
| pages/MainPage.ets | TabBar 添加 SymbolEffect，统一 Token | active | 文件读取 |
| pages/RecruiterHomePage.ets | TabBar 添加 SymbolEffect，统一 Token | active | 文件读取 |
| pages/JobDetailPage.ets | 统一颜色、字体、卡片规范 | active | 文件读取 |
| pages/ChatDetailPage.ets | 改用公共 NavBar，统一字体/颜色 | active | 文件读取 |
| pages/HomePage.ets + tab/* | 筛选弹窗与卡片样式规范化 | active | 文件读取 |
| 其他页面 | 抽样审计 + 全局替换硬编码值 | active | 文件读取 |

## Open assumptions (announced defaults)
<!-- Record any default you adopt instead of asking, so the user can veto it at the gate. -->
| assumption | adopted default | rationale | reversible? |
|---|---|---|---|
| 品牌色 | 保持 `#1762FB`（AppColors.PRIMARY） | 与 Vue 端和现有 AppStyles 一致 | 是 |
| 深色模式 | 本次优先使用 AppColors 常量；sys.color Token 作为增量引入 | DevEco 项目系统资源可用，避免一次改动过大 | 是 |
| TabBar 动效 | 激活态添加 `BounceSymbolEffect`（非旧版 `BounceEffect`） | HMOS 官方 Symbol API，6.1.1 正确类名 | 是 |
| 响应式 | 仅完善 WindowBreakpoint 工具并启用；不对所有页面做双栏重构 | 保持范围可控 | 是 |
| 字体单位 | 字号统一使用 AppFontSize 常量；不强制改为 fp | 与现有代码一致，降低风险 | 是 |

## Findings (cited - path:lines)

### P0 - 编译/运行阻塞
- `uniseek_arkts/entry/src/main/ets/pages/LoginPage.ets:163` 引用 `AppTypography.BUTTON_HEIGHT`，但 `common/AppStyles.ets:99-103` 的 `AppTypography` 类为空，仅含注释，无 `BUTTON_HEIGHT` 属性。**当前会导致编译失败。**

### P1 - 硬编码颜色（与 HMOS Token / AppStyles 不一致）
- `LoginPage.ets:112,172,175-179` 使用 `'#FFFFFF'`、`'#5A8CFF'`、`'#A8C4FF'`、`'#E4EEFF'`、`'#1762FB'` 等渐变硬编码。
- `RegisterPage.ets:25,112,147,205,225,274` 使用 `'#FFFFFF'`、`Color.Transparent` 混合。
- `JobDetailPage.ets:274,306,327,348` 使用 `'#FFFFFF'`、`AppColors.PRIMARY` 硬编码；薪资文本使用 `AppColors.DANGER`（红色）不符合品牌色语义。
- `ChatDetailPage.ets:327,432,467,515,612,629,661,685,742,761,780,853` 多处使用 `'#FFFFFF'`、`'rgba(...)'`、emoji `'📷'`、`'📄'` 等。
- `HomePage.ets` 筛选弹窗中大量使用 `'#FFFFFF'`、`'transparent'`、`fontColor(... ? '#FFFFFF' : ...)`。
- `JobFeedCard.ets:49,58` 标签使用 `AppColors.SELECTED_BG` / `AppColors.INPUT_BG` 背景，符合品牌体系但字号硬编码。
- `ProfilePage.ets:89,107,132,135,148-156` 菜单使用 `SymbolGlyph`，但部分行高/尺寸未用常量。

### P2 - 硬编码字号/间距/圆角
- `ChatDetailPage.ets` 充斥 `fontSize(17/13/12.5/14.5/11/13.5/12/20/15)`、`padding(16/28)`、`borderRadius(14/18/8/10/12/6)` 等魔法数字。
- `JobDetailPage.ets:244,246,287,301,306,311,399` 存在 `fontSize(AppFontSize.XXXL/XXL/LG...)` 之外的硬编码与 `lineHeight(40)`、`lineHeight(24)`。
- `HomePage.ets` 筛选弹窗内 `fontSize(15)`、`height(44/36/200/180)`、`padding(10/12)` 等未使用常量。
- `JobFeedCard.ets:29,36,49,58,74,84` 使用 `fontSize(16/15/11/13)`、`padding(14/12/6/2)`、`borderRadius(4)`。
- `MainPage.ets:27,30,35` Tab 图标字号 `24`、标签字号 `10`、高度 `56` 为硬编码（虽未违规但缺少注释与 BounceEffect）。

### P3 - 布局与响应式
- `Responsive.ets` 仅定义断点，但没有任何页面使用 `@StorageLink('breakpoint')` 或 `WindowBreakpoint`。
- 所有页面都是手机单列布局，折叠屏/平板未做双栏适配。
- `ChatDetailPage.ets:377-417` 使用自定义 `customHeader()` 而非公共 `NavBar`，造成导航栏风格不一致。
- 登录/注册页宽度使用 `'95%'` / `padding(32)`，未适配宽屏居中。

### P4 - 无障碍与交互
- `MainPage.ets` / `RecruiterHomePage.ets` 的 `tabItem` 未给 SymbolGlyph 添加 `accessibilityText`。
- `JobDetailPage.ets:341` 收藏按钮已加 `accessibilityText`，但 `ChatDetailPage.ets:382` 返回按钮、加号按钮未加。
- 大量图标按钮尺寸 `40/44/48/52` 虽多数 ≥ 44vp，但 `JobDetailPage.ets` 中部分图标按钮仅有 `20` 字号、触控区域良好。
- `ChatDetailPage.ets:695,718` 操作菜单使用 emoji 作为图标，无 SymbolGlyph，也无 accessibilityText。

### P5 - 动效与 HMOS 规范
- TabBar 未使用 `BounceEffect`。
- 列表项/卡片缺少统一的 `transition`/`.animation` 入场动效。
- 按钮 `stateStyles` 写法不统一，部分使用 `.scale({0.97})` 等非 HMOS 推荐方式。

## Review feedback (round 003 → 004 fixes)
1. **Todo 3 / Todo 4 文件写入冲突**：原矩阵允许 Todo 3（字号/间距/圆角）与 Todo 4（TabBar）并行，两者都会修改 `MainPage.ets` / `RecruiterHomePage.ets`。已在矩阵中把 Todo 4 的依赖从 Todo 1 改为 Todo 3，并移除并行关系，改为串行 Wave-3 步骤。
2. **Todo 2 硬编码颜色稽核误过滤内联注释**：原验收命令用 `grep -vE "...|//|..."` 会把行内注释后的真实颜色也过滤掉。已改为仅过滤行首 `//` 的整行注释（`^\s*//`），并要求代理对剩余命中行在 `fix-approach.md` 中逐行说明。
3. **Todo 6 媒体查询导入/事件名**：原方案直接写死 `import { mediaQuery, AppStorage } from '@kit.ArkUI'`，但 `AppStorage` 为全局对象通常无需 import，且 `mediaQuery` 的导出形式/事件名在不同版本示例中可能为 `mediaquery` + `'change'` 或 `mediaQuery` + `'changed'`。已改为让执行代理参考官方 API 与编译器提示，验收时同时接受 `'change'`/`'changed'` 与不同大小写导入名，并把 `AppStorage` 从 import 示例中移除。
4. **Todo 8 命令风格**：验收命令仍以 POSIX Bash 风格给出，全局 Shell environment note 已明确要求在 win32/PowerShell 下使用等效命令；属于低风险风格问题，未做结构性修改。

## Review feedback (round 005 → 006 fixes)
1. **Todo 3 依赖矩阵仍声明可与 Todo 4 并行**：Todo 3 的 `Can parallelize with` 仍写 `4,8`，但 Todo 4 已 `Blocked by: 3`，且两者会改写 `MainPage.ets` / `RecruiterHomePage.ets`。已将 Todo 3 的 `Can parallelize with: 4,8` 改为 `8`。
2. **Todo 6 监听器注销验收 grep 转义错误**：`grep -nE "...off(...)\|\.off(...)"` 在 ERE 中把 `\|` 当作字面量管道，不会命中 `l.off('change')`；且函数字面量右括号未转义。已改为 `grep -nE "mqListeners.*off\(['\"](change|changed)['\"]\)|\.off\(['\"](change|changed)['\"]\)"`。

## Review feedback (round 006 → 007 fixes)
本轮 Momus 给出 `CHANGES_REQUESTED`，Oracle 给出 `APPROVED`。Momus 指出的依赖/矩阵字段不一致已修正：
1. Todo 2 的 `Can parallelize with` 从 `4,8` 改为 `8`，与矩阵一致。
2. Todo 3 的 `Blocks` 从 `5,6,7,9` 改为 `4,5,6,7,9`，与矩阵一致。
3. Todo 5 的 `Blocks` 从 `7,9` 改为 `6,7,9`，矩阵的 `Can parallelize with` 恢复为 `4,8`，与 Todo 5 详情一致。
4. Todo 7 的 `Blocked by: 5,6` 与矩阵对齐，矩阵行 7 的 `Depends on` 从 `6` 改为 `5,6`。

## Decisions (with rationale)
1. **先修编译错误**：`AppTypography.BUTTON_HEIGHT` 不存在，必须删除引用或补充常量，确保 hvigorw 能通过。
2. **硬编码颜色替换**：优先统一为 `AppColors.*` 常量；再引入 `$r('sys.color.*')` 作为关键背景/文本色，确保深浅色一致。
3. **字号规范化**：统一使用 `AppFontSize` 与 `AppRadius`/`AppSpacing`，减少魔法数字；聊天页等密集区保留少量 0.5 级的差异但集中在常量中。
4. **公共组件落地**：`ChatDetailPage.ets` 的手写 header 替换为 `NavBar`（保留聊天特有的双行标题需求时通过 BuilderParam 自定义）。
5. **响应式基线**：修复 `Responsive.ets` 在 `EntryAbility` 的媒体查询注册，让 `@StorageLink('breakpoint')` 可用；页面不做大改但确保不会在小屏、折叠屏下溢出。
6. **构建校验**：每个阶段完成后运行 `codelinter` 与 `hvigorw assembleHap --no-daemon`；最终 CI 门禁使用 `codelinter -e error` + `hvigorw assembleHap`。

## Scope IN
- `uniseek_arkts/entry/src/main/ets/common/*.ets`
- `uniseek_arkts/entry/src/main/ets/pages/*.ets`
- `uniseek_arkts/entry/src/main/ets/pages/tab/**/*.ets`
- 修复编译错误、统一设计 Token、规范化样式与布局、响应式基线、无障碍标签、TabBar 动效

## Scope OUT (Must NOT have)
- 不修改 services/、api/、models/ 等业务逻辑
- 不修改前后端接口与数据流
- 不做页面结构大重构（不拆分组件）
- 不引入新页面或新功能
- 不修改 Java/Vue 模块

## Open questions
- 无。探索可回答的问题已全部确认。

## Approval gate
status: awaiting-approval
plan_path: .omo/plans/arkts-style-remaining-fixes.md
<!-- 用户回复“确认/批准/开始”后，worker 通过 /start-work 执行本计划 -->
