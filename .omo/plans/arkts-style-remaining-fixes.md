# arkts-style-remaining-fixes - Work Plan

## TL;DR (For humans)

**What you'll get:** 对 UniSeek 鸿蒙端 ArkTS 代码做一次系统性样式治理：先消灭编译阻塞，再把散落各页面与公共组件里的硬编码颜色/字号/间距统一收敛到 AppStyles 设计系统，补全 TabBar 动效和无障碍标签，统一 ChatDetailPage 导航栏风格，接入响应式断点，最终通过 `codelinter` + `hvigorw assembleHap` 校验，保证零错误构建。

**Why this approach:** 现有代码已部分使用 AppStyles，但仍有大量魔法数字、一处 `AppTypography.BUTTON_HEIGHT` 编译错误，且未启用 HMOS 系统 Token 与响应式断点。采用“先修阻塞 → 再统一 Token → 再逐项页面整改 → 最后构建校验”的串行依赖链，避免相互破坏。

**What it will NOT do:** 不改业务逻辑、不改后端接口、不拆分重组件、不新增页面或功能、不动 Java/Vue；**不执行任何 git 操作（包括 commit、push、stash、reset 等）**，只读不写本地与远程仓库记录。

**Effort:** Medium
**Risk:** Medium -  because 样式改动面广，需保证每一次修改后均能通过构建，且不能破坏现有交互；同时要保证 ArkTS HR/求职者角色功能与 Vue 端一致。

**Decisions to sanity-check:**
1. 品牌色保持 `#1762FB`（与 Vue 端一致）。
2. 本次不强制把所有颜色改 `sys.color`，而是先收敛到 `AppColors` 常量，关键背景/文本色再逐步替换为 `$r('sys.color.*')`。
3. 响应式仅补齐断点基础设施与页面溢出保护，不做双栏大重构。
4. ChatDetailPage 标题区需要双行内容，因此扩展 `NavBar` 增加 `centerContent` BuilderParam，而不是把双行标题塞进 `rightContent`。

**Shell environment note:** 本计划中的 `grep`/`sed`/`cut`/`ls`/`&&`/`\` 续行等命令以 POSIX Bash 风格书写。当前工作空间是 **win32 / PowerShell**，执行代理必须使用等效 PowerShell 命令（如 `Select-String -Pattern`、`Get-Content`、`.split()`、`Test-Path`），或在已安装 Git Bash / WSL 的 POSIX shell 中运行。所有正则表达式本身保持不变。

Your next move: 审批后执行 `/start-work` 启动 worker 会话。详细执行方案见下。

---

> TL;DR (machine): Medium effort, Medium risk, deliverables: compile-error-free ArkTS code with unified design tokens, HMOS-aligned styling, NavBar extended for centered subtitle, and verified build.

## Scope
### Must have
1. 修复 `AppTypography.BUTTON_HEIGHT` 导致的编译错误。
2. 统一 hardcoded 颜色到 `AppColors` / `sys.color`（含 `AppStyles.ets` 内部 `StandardInput` / `PrimaryButton`）。
3. 统一 hardcoded 字号/圆角/间距到 `AppFontSize` / `AppRadius` / `AppSpacing`。
4. `MainPage.ets` / `RecruiterHomePage.ets` TabBar 使用官方 `BounceSymbolEffect`，并补充 `accessibilityText`；图标颜色使用 `sys.color.icon_tertiary` / `sys.color.brand`。
5. `ChatDetailPage.ets` 扩展 `NavBar` 的 `centerContent` 以保留双行标题，规范消息气泡样式，并把 emoji 图标替换为 `SymbolGlyph`。
6. 接入 `Responsive.ets` 断点，在 `EntryAbility.ets` 中正确获取主窗口 `UIContext` 注册媒体查询并清理监听器，防止折叠屏/宽屏布局溢出。
7. 为关键图标/按钮补充 `accessibilityText`。
8. **Vue 角色功能一致性校验**：对照 Vue 端 HR/求职者核心页面，检查 ArkTS 端对应角色页面具备等价功能入口与状态展示。
9. 每个阶段运行 `codelinter --exit-on error` 与 `hvigorw assembleHap --no-daemon` 验证。

### Must NOT have (guardrails, anti-slop, scope boundaries)
- 不修改 `services/`、`api/`、`models/` 等业务逻辑代码。
- 不修改前后端接口协议、字段、行为。
- 不做页面结构大重构（不拆分出新组件，不移动文件）。
- 不引入新页面、新功能、新依赖。
- 不动 Java/Vue 模块。
- **不执行任何 git 操作**（commit、push、stash、reset、revert、amend 等），仅允许查看仓库状态与 diff。
- 不删除已有业务状态或导航逻辑。

## Verification strategy
> Zero human intervention - all verification is agent-executed.
- Test decision: 无单元测试；采用编译校验 + 静态检查 + 代码断言作为 QA。
- Evidence: `.omo/evidence/arkts-style-remaining-fixes/<task>/` 下保存每次 `codelinter`/`hvigorw` 输出、对比 diff 与关键文件片段。

## Execution strategy
### Skill-first 实现原则
用户要求：**参考 skill（`hmos-design`、`arkui-knowledge`、`arkts-grammar-standards`、`frontend-skill`、`hmos-cli-toolkit`），使 ArkTS 界面更遵循 ArkUI 鸿蒙原生样式**。因此每个 Todo 的执行代理在修改 `.ets` 文件时：
1. 优先加载对应 HMOS skill，并在 `fix-approach.md` 中引用官方 API 示例或章节。
2. 优先使用 ArkUI 原生组件与系统资源（`SymbolGlyph`、`NavDestination`、`$r('sys.color.*')`、`$r('sys.float.*')` 等），避免手写等效样式。
3. 优先使用技能文档中推荐的布局模式（`Row`/`Column` + `layoutWeight`、`AlignRules`、`List`/`Grid` 等），避免过多嵌套 `Stack` 与绝对定位。
4. 所有新增 Token、动画、响应式、无障碍写法必须与 `hmos-design` / `arkui-knowledge` 中的官方示例等价。
5. **特别注意**：`hmos-design` 等 skill 中的示例代码可能随版本滞后（例如旧示例使用 `new BounceEffect()`）。执行时必须以 HarmonyOS 官方 API 文档为准——当前计划已明确使用 `BounceSymbolEffect`；开发者不得以 skill 旧示例为由回退到 `BounceEffect`。

### 每次修改前的说明要求
用户明确要求：**每次修复之前简单阐述一下你打算怎么修**。因此每个 Todo 的执行代理在编辑任何 `.ets` 文件前，必须先在 `.omo/evidence/arkts-style-remaining-fixes/task-<N>/` 下写入 `fix-approach.md`，包含：
1. 要修改的文件与位置；
2. 打算怎么改（颜色如何收敛、字号用哪个常量、布局如何调整）；
3. 可能影响的调用方与回退策略。
只有写完后才能继续编辑文件。

### Parallel execution waves
- Wave 1: 修复编译阻塞 + 设计 Token 补齐（必须先完成）。
- Wave 2: 全局硬编码颜色替换 → 字号/间距/圆角替换（顺序执行，避免同一文件被并发改写）；Vue 页面映射校验可全程只读并行。
- Wave 3: ChatDetailPage/NavBar 扩展 → MainPage/RecruiterHomePage TabBar 改造 → 响应式断点 → 剩余无障碍标签（顺序执行）。
- Wave 4: 最终编译验证与问题收敛。

### Dependency matrix
| Todo | Depends on | Blocks | Can parallelize with |
| --- | --- | --- | --- |
| 1 | - | 2,8,9 | - |
| 2 | 1 | 3,9 | 8 |
| 3 | 2 | 4,5,6,7,9 | 8 |
| 4 | 3 | 9 | 8 |
| 5 | 3 | 6,7,9 | 4,8 |
| 6 | 5 | 7,9 | 8 |
| 7 | 5,6 | 9 | 8 |
| 8 | 1 | 9 | 2,3,4,5,6,7 |
| 9 | 1-8 | - | - |

## Todos
> Implementation + Test = ONE todo. Never separate.
<!-- APPEND TASK BATCHES BELOW THIS LINE WITH edit/apply_patch - never rewrite the headers above. -->
- [x] 1. AppStyles.ets — 修复缺失常量并补齐设计 Token
  What to do / Must NOT do: 在 `AppStyles.ets` 的 `AppSpacing` 类中新增 `BOTTOM_ACTION_HEIGHT = 56`（或按设计规范取值），把 `LoginPage.ets:163` 对不存在的 `AppTypography.BUTTON_HEIGHT` 的引用替换为 `AppSpacing.BOTTOM_ACTION_HEIGHT`；同时保留 `AppTypography` 作为 Typography 层级文档。必要时在 `AppFontSize` / `AppRadius` / `AppSpacing` 中补充 Wave 2/Wave 3 需要的新中间档（如 `AppFontSize.HEADLINE = 18`、`AppRadius.XS = 4`、`AppSpacing.BOTTOM_ACTION_HEIGHT = 56`）。Must NOT 删除现有已被其他文件引用的常量（如 `AppColors.PRIMARY`）。
  Parallelization: Wave 1 | Blocked by: - | Blocks: 2,8,9
  References (executor has NO interview context - be exhaustive): `uniseek_arkts/entry/src/main/ets/common/AppStyles.ets:57-64` (`AppSpacing`), `uniseek_arkts/entry/src/main/ets/common/AppStyles.ets:99-103` (`AppTypography` 占位), `uniseek_arkts/entry/src/main/ets/pages/LoginPage.ets:163` (`AppTypography.BUTTON_HEIGHT` 引用)
  Acceptance criteria (agent-executable):
  1. `cd uniseek_arkts; codelinter --exit-on error entry/src/main/ets/pages/LoginPage.ets` 返回退出码 0。
  2. `cd uniseek_arkts; hvigorw assembleHap --no-daemon` 输出包含 `BUILD SUCCESSFUL` 且 0 errors（warnings 可记录）。
  QA scenarios (name the exact tool + invocation): happy — `codelinter` 与 `hvigorw` 均通过；failure — 若仍有 `AppTypography.BUTTON_HEIGHT` 引用或新增常量未定义，`hvigorw` / `lsp_diagnostics` 报错。Evidence: `.omo/evidence/arkts-style-remaining-fixes/task-1/`
  Diff label: style(arkts): 修复 LoginPage 引用的缺失常量并补齐设计 Token

- [x] 2. 全局硬编码颜色收敛到 AppColors / HMOS sys.color
  What to do / Must NOT do: 在以下目标文件中，将硬编码 `'#FFFFFF'`、`'rgba(0,0,0,0.x)'`、`'#5A8CFF'` 等替换为 `AppColors.*` 常量或 `$r('sys.color.*')` 系统资源：
  - `uniseek_arkts/entry/src/main/ets/pages/LoginPage.ets`
  - `uniseek_arkts/entry/src/main/ets/pages/RegisterPage.ets`
  - `uniseek_arkts/entry/src/main/ets/pages/JobDetailPage.ets`
  - `uniseek_arkts/entry/src/main/ets/pages/ChatDetailPage.ets`
  - `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/HomePage.ets`（含筛选弹窗）
  - `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/JobFeedCard.ets`
  - `uniseek_arkts/entry/src/main/ets/common/AppStyles.ets`（`PrimaryButton`、`StandardInput` 内部）
  Must NOT 替换纯业务语义色（如状态标签的 `AppColors.SUCCESS`/`WARNING`/`DANGER`、薪资 `AppColors.DANGER`）或导致功能色消失。
  Parallelization: Wave 2 | Blocked by: 1 | Blocks: 3,9 | Can parallelize with: 8
  References: 先用 `grep -R -nE "('#[0-9a-fA-F]{3,8}'|'rgba?\([^)]+\)')" <target-files>` 扫描并记录所有命中位置，然后在 `fix-approach.md` 中列出具体行。当前已知典型位置：
  - `LoginPage.ets:112`, `LoginPage.ets:172-179`
  - `RegisterPage.ets:25`, `RegisterPage.ets:225`, `RegisterPage.ets:274`
  - `JobDetailPage.ets:274`, `JobDetailPage.ets:306`, `JobDetailPage.ets:348`, `JobDetailPage.ets:383`, `JobDetailPage.ets:672`
  - `ChatDetailPage.ets:327`, `ChatDetailPage.ets:432`, `ChatDetailPage.ets:467`, `ChatDetailPage.ets:685`, `ChatDetailPage.ets:742`, `ChatDetailPage.ets:761`, `ChatDetailPage.ets:780`, `ChatDetailPage.ets:853`, `ChatDetailPage.ets:874`
  - `HomePage.ets` 筛选弹窗多处（如 `:520`, `:529`, `:538`, `:584`, `:589`, `:611`, `:613`, `:655`, `:657`, `:696`, `:698`, `:754`, `:759`, `:784`, `:786`, `:832`）
  Acceptance criteria (agent-executable): 在 `uniseek_arkts` 根目录运行以下 POSIX 命令（PowerShell 见全局 Shell environment note），结果中仅允许保留 `AppColors` / `AppShadow` 的 `static readonly` 定义行、整行注释（行首 `//`）、`sys.*` 资源引用，以及已在 `fix-approach.md` 中登记保留的业务语义色；任何其他命中必须处理或逐行说明保留映射：
  ```bash
  grep -R -nE "('#[0-9a-fA-F]{3,8}'|'rgba?\([^)]+\)')" \
    entry/src/main/ets/pages/LoginPage.ets \
    entry/src/main/ets/pages/RegisterPage.ets \
    entry/src/main/ets/pages/JobDetailPage.ets \
    entry/src/main/ets/pages/ChatDetailPage.ets \
    entry/src/main/ets/pages/tab/seeker/HomePage.ets \
    entry/src/main/ets/pages/tab/seeker/JobFeedCard.ets \
    entry/src/main/ets/common/AppStyles.ets | grep -vE "(static readonly|AppColors\.|AppShadow\.|^\s*//|sys\.color|sys\.float)"
  ```
  QA scenarios: happy — grep 返回空（或仅保留已登记的 AppColors 定义/注释/业务语义色）；failure — 任意页面仍直接写死 `#FFFFFF` / `rgba(...)` 且未收敛到常量。Evidence: `.omo/evidence/arkts-style-remaining-fixes/task-2/`
  Diff label: style(arkts): 收敛硬编码颜色到设计 Token

- [x] 3. 全局硬编码字号、间距、圆角收敛
  What to do / Must NOT do: 将 `ChatDetailPage.ets`、`JobDetailPage.ets`、`HomePage.ets`、`JobFeedCard.ets`、`JobFeedList.ets`、`MainPage.ets`、`RecruiterHomePage.ets`、`ProfilePage.ets`、`AppStyles.ets`（`StandardInput` / `PrimaryButton`）中的魔法数字（如 `fontSize(17/13/12.5/14.5/11)`、`padding(28)`、`borderRadius(14/18/10/12)`、`height(40/44/50/52/56)`）替换为 `AppFontSize` / `AppSpacing` / `AppRadius` 常量；必要时在 `AppStyles.ets` 新增 `AppFontSize.HEADLINE = 18`、`AppSpacing.BOTTOM_ACTION_HEIGHT = 56`、`AppRadius.XS = 4` 等。Must NOT 为了凑数而把合理的小差异全部抹平；允许保留动态计算值与少量不可收敛的异性圆角。
  Parallelization: Wave 2 | Blocked by: 2 | Blocks: 4,5,6,7,9 | Can parallelize with: 8
  References: 先用 `grep -R -nE "\.(fontSize|borderRadius|padding|margin|height|width)\([0-9]+(\.[0-9]+)?\)" <target-files>` 扫描目标文件，记录命中位置。当前已知典型位置：
  - `LoginPage.ets`: `fontSize(18)`, `height(50)`, `height(32)`, `margin({bottom:10})`, `.width('95%')`
  - `RegisterPage.ets`: `fontSize(18)`, `height(50)`, `height(40)`, `height(32)`, `height(28)`, `padding({ left: 32, right: 32 })`
  - `ChatDetailPage.ets`: `fontSize(17/13/12.5/14.5/11/15/20/22/24)`, `padding(16/28/8/14)`, `borderRadius(14/18/8/10/12/6)`, `width(180/40/44/48/52)`, `position({ x: '86%', y: 32 })`
  - `JobDetailPage.ets`: `fontSize(22)`, `lineHeight(40)`, `lineHeight(24)`, `width(48/52)`, `height(48/52/52)`, `margin({ right: 12 })`
  - `HomePage.ets`: `fontSize(16/24/15)`, `height(44/36/200/180/48)`, `borderRadius(8)`, `margin(...)`
  - `JobFeedCard.ets`: `fontSize(16/15/11/13)`, `padding(...){6/2/14/12}`, `borderRadius(4)`, `scale(0.99)`
  - `JobFeedList.ets`: `width(24)`, `height(24)`, `fontSize(14)`, `height(36)`
  - `MainPage.ets` / `RecruiterHomePage.ets`: `fontSize(24/10)`, `height(56)`, `margin({ top: 4 })`
  - `ProfilePage.ets`: `width(72)`, `height(72)`, `borderRadius(36)`, `fontSize(14/16/22)`, `height(104/32/56)`
  - `AppStyles.ets`: `height(50/40)`, `borderRadius(20)`
  Acceptance criteria (agent-executable): 在 `uniseek_arkts` 根目录运行以下命令，目标文件中剩余 `fontSize(<number>)` / `borderRadius(<number>)` / `height(<number>)` / `width(<number>)` 等魔法数字 ≤ 5 处（且均已在 `fix-approach.md` 中注明不可收敛理由）：
  ```bash
  grep -R -nE "\.(fontSize|borderRadius|height|width)\([0-9]+(\.[0-9]+)?\)" \
    entry/src/main/ets/pages/LoginPage.ets \
    entry/src/main/ets/pages/RegisterPage.ets \
    entry/src/main/ets/pages/JobDetailPage.ets \
    entry/src/main/ets/pages/ChatDetailPage.ets \
    entry/src/main/ets/pages/tab/seeker/HomePage.ets \
    entry/src/main/ets/pages/tab/seeker/JobFeedCard.ets \
    entry/src/main/ets/pages/tab/seeker/JobFeedList.ets \
    entry/src/main/ets/pages/tab/seeker/ProfilePage.ets \
    entry/src/main/ets/pages/MainPage.ets \
    entry/src/main/ets/pages/RecruiterHomePage.ets \
    entry/src/main/ets/common/AppStyles.ets
  ```
  QA scenarios: happy — 目标页面字号/间距/圆角/高度主要来自 `AppStyles`；failure — 仍大量存在 `fontSize(14.5)` / `height(40)` 等魔法数字。Evidence: `.omo/evidence/arkts-style-remaining-fixes/task-3/`
  Diff label: style(arkts): 统一字号、间距、圆角常量

- [x] 4. MainPage/RecruiterHomePage TabBar 添加 BounceSymbolEffect、无障碍标签与系统色
  What to do / Must NOT do: 在 `pages/MainPage.ets:24-38` 与 `pages/RecruiterHomePage.ets:24-38` 的 `tabItem` Builder 中：
  1. 给 `SymbolGlyph` 添加 `.symbolEffect(new BounceSymbolEffect(EffectScope.WHOLE, EffectDirection.DOWN), this.currentIndex === index)`，并导入 `BounceSymbolEffect`、`EffectScope`、`EffectDirection`（参考 HarmonyOS 官方 `ts-basic-components-symbolglyph`，**不是** skill 中可能过时的 `BounceEffect`）。
  2. 未选中色改为 `$r('sys.color.icon_tertiary')`，选中色改为 `$r('sys.color.brand')`。
  3. 给 `Column` 添加 `.accessibilityText(label)`。
  Must NOT 改变 Tab 切换逻辑。
  Parallelization: Wave 3 | Blocked by: 3 | Blocks: 9 | Can parallelize with: 8
  References: `pages/MainPage.ets:24-38`, `pages/RecruiterHomePage.ets:24-38`, `common/AppStyles.ets`
  Acceptance criteria (agent-executable):
  1. `cd uniseek_arkts; codelinter --exit-on error entry/src/main/ets/pages/MainPage.ets entry/src/main/ets/pages/RecruiterHomePage.ets` 返回 0。
  2. 对 `entry/src/main/ets/pages/MainPage.ets` 和 `entry/src/main/ets/pages/RecruiterHomePage.ets` 各运行以下三条命令，且均命中：
     - `grep -n "BounceSymbolEffect" <file>` 命中（动效导入或使用）；
     - `grep -nE "sys\.color\.brand|sys\.color\.icon_tertiary" <file>` 命中（系统色使用）；
     - `grep -n "accessibilityText" <file>` 命中（无障碍标签）。
  QA scenarios: happy — TabBar 图标在切换时有弹跳动效且无 lint 错误；failure — 使用 `BounceEffect`（错误类名）导致编译失败。Evidence: `.omo/evidence/arkts-style-remaining-fixes/task-4/`
  Diff label: style(arkts): TabBar 使用 BounceSymbolEffect 与无障碍标签

- [x] 5. ChatDetailPage.ets — 扩展 NavBar 并规范消息气泡 / 操作菜单
  What to do / Must NOT do:
  1. 扩展 `common/NavBar.ets`：新增 `@BuilderParam centerContent: () => void = this.defaultCenterContent`。默认 Builder 必须保持现有标题居中：在 `Row()` 中使用 `Row() { this.centerContent() }.layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)` 包裹 Builder，确保 `centerContent` 自定义内容也居中；当未传入时渲染现有 `Text(this.title)`。
  2. 将 `ChatDetailPage.ets:377-417` 的 `customHeader()` 替换为扩展后的 `NavBar`：通过 `centerContent` 传入包含 `counterpartName`（字号 `AppFontSize.LG`）与 `taskTitle`（字号 `AppFontSize.SM`、颜色 `AppColors.TEXT_MUTED`）的居中 `Column`；保留返回按钮。
  3. 消息气泡中的字号、颜色、padding 收敛到 `AppFontSize` / `AppColors`（`myMessageItem` / `otherMessageItem` / `resumeMessageItem`）。
  4. 操作菜单的 emoji 图标（`ChatDetailPage.ets:695` 的 📷、`ChatDetailPage.ets:718` 的 📄）替换为 `SymbolGlyph`（`sys.symbol.photo`、`sys.symbol.doc_text`）并加 `.accessibilityText(...)`。
  Must NOT 改变消息发送/加载/预览逻辑。
  Parallelization: Wave 3 | Blocked by: 3 | Blocks: 6,7,9 | Can parallelize with: 4,8
  References: `ChatDetailPage.ets:377-417` (customHeader), `ChatDetailPage.ets:441-545` (message bubbles), `ChatDetailPage.ets:679-747` (actionMenuOverlay), `common/NavBar.ets`
  Acceptance criteria (agent-executable):
  1. `cd uniseek_arkts; codelinter --exit-on error entry/src/main/ets/pages/ChatDetailPage.ets entry/src/main/ets/common/NavBar.ets` 返回 0。
  2. 在 PowerShell 中运行 `Select-String -Path entry/src/main/ets/pages/ChatDetailPage.ets -Pattern '(\uD83D\uDCF7|\uD83D\uDCC4)' -Encoding UTF8` 返回空（无 📷/📄 emoji 残留）。（POSIX 环境可用 `grep -Pn '(\x{1F4F7}|\x{1F4C4})' entry/src/main/ets/pages/ChatDetailPage.ets`。）
  3. `grep -n "centerContent" entry/src/main/ets/common/NavBar.ets` 命中 `@BuilderParam centerContent` 定义，且 `grep -n "layoutWeight(1).justifyContent(FlexAlign.Center)" entry/src/main/ets/common/NavBar.ets` 命中，确保默认标题仍居中。
  QA scenarios: happy — `codelinter`/`hvigorw` 通过，导航栏视觉与 NavBar 一致且标题仍居中；failure — 使用 `rightContent` 放置双行标题导致标题右偏/截断。Evidence: `.omo/evidence/arkts-style-remaining-fixes/task-5/`
  Diff label: style(arkts): 扩展 NavBar 并规范 ChatDetailPage 导航栏与消息气泡

- [x] 6. 响应式断点接入与溢出保护
  What to do / Must NOT do: 在 `EntryAbility.ets` 中按以下步骤实现：
  1. 增加导入：从 `common/Responsive.ets` 导入 `BreakpointResolver`、`WindowBreakpoint`；从官方 ArkUI 模块导入媒体查询 API（HarmonyOS ArkTS 6.1.1 常见写法为 `import { mediaquery } from '@kit.ArkUI'`，具体导入名/事件名以官方 API 文档和编译器提示为准）。`AppStorage` 为 ArkTS 全局单例，无需 import。
  2. 在 `onWindowStageCreate` 的 `windowStage.loadContent` 成功回调中，通过 `const win = windowStage.getMainWindowSync(); const uiContext = win.getUIContext(); const mq = uiContext.getMediaQuery();` 获取主窗口的 `MediaQuery`。
  3. 初始断点：`const rect = win.getWindowProperties().windowRect; AppStorage.setOrCreate('breakpoint', BreakpointResolver.resolve(rect.width));`。
  4. 注册监听器：创建 `matchMediaSync('(width < 600vp)')` 与 `matchMediaSync('(width < 840vp)')` 两个媒体查询监听器，并在 `.on('change' | 'changed', ...)` 回调中使用 `BreakpointResolver.resolve(...)` 更新 `AppStorage`。事件名以 HarmonyOS ArkTS 6.1.1 官方 API 文档为准，验收时同时接受两者。保存 listener 引用数组以便注销（类型以实际 API 返回为准）。
  5. 在 `onWindowStageDestroy()` 与 `onDestroy()` 中遍历 listener 数组调用 `.off('change' | 'changed')` 清理，避免泄漏。
  6. 在 `LoginPage.ets`、`RegisterPage.ets`、`HomePage.ets` 中导入 `WindowBreakpoint` 并添加 `@StorageLink('breakpoint') breakpoint: WindowBreakpoint = WindowBreakpoint.COMPACT`，对 `MEDIUM/EXPANDED` 做最小适配：如登录/注册页 `Column` 最大宽度 420vp 并居中、`HomePage` 筛选弹窗最大宽度 560vp。
  Must NOT 对所有页面做双栏大重构。
  Parallelization: Wave 3 | Blocked by: 5 | Blocks: 7,9 | Can parallelize with: 8
  References: `common/Responsive.ets`, `entry/src/main/ets/entryability/EntryAbility.ets`, `hmos-design` §4.3
  Acceptance criteria (agent-executable):
  1. `cd uniseek_arkts; codelinter --exit-on error entry/src/main/ets/entryability/EntryAbility.ets entry/src/main/ets/pages/LoginPage.ets entry/src/main/ets/pages/RegisterPage.ets entry/src/main/ets/pages/tab/seeker/HomePage.ets` 返回 0。
  2. `grep -R -n "@StorageLink('breakpoint')" entry/src/main/ets/pages/LoginPage.ets entry/src/main/ets/pages/RegisterPage.ets entry/src/main/ets/pages/tab/seeker/HomePage.ets` 命中 ≥3 处。
  3. `grep -nE "getMainWindowSync\(\)|getUIContext\(\)|getMediaQuery\(\)|matchMediaSync" entry/src/main/ets/entryability/EntryAbility.ets` 命中。
  4. `grep -nE "mqListeners.*off\(['\"](change|changed)['\"]\)|\.off\(['\"](change|changed)['\"]\)" entry/src/main/ets/entryability/EntryAbility.ets` 命中（至少一处监听器注销）。
  QA scenarios: happy — 代码中存在从主窗口 UIContext 获取的媒体查询、多页面读取 breakpoint、监听器有注销；failure — 缺少任一项或使用了不存在的顶层 `mediaQuery.matchMediaSync`。Evidence: `.omo/evidence/arkts-style-remaining-fixes/task-6/`
  Diff label: style(arkts): 接入响应式断点并防止宽屏溢出

- [x] 7. 关键图标与按钮补充 accessibilityText
  What to do / Must NOT do: 遍历 `JobDetailPage.ets`、`ChatDetailPage.ets`、`HomePage.ets` 顶部搜索按钮、`ProfilePage.ets` 菜单图标/箭头、`RecruiterHomeTab.ets`、`RecruiterProfileTab.ets` 等，为所有 `SymbolGlyph` / 图标型 `Button` 补充 `.accessibilityText('...')`。**HINT**：很多图标把 `accessibilityText` 加在父级 `Button` / `Row` 上即可，不一定加在 `SymbolGlyph` 本身；只要在同一个可聚焦组件内即可。`MainPage.ets` / `RecruiterHomePage.ets` 的 TabBar 图标已在 Todo 4 处理，本任务不再重复。Must NOT 删除已有正确的标签。
  Parallelization: Wave 3 | Blocked by: 5,6 | Blocks: 9 | Can parallelize with: 8
  References: `hmos-design` §11, `pages/JobDetailPage.ets:341` (收藏), `pages/ChatDetailPage.ets:382` (返回按钮), `pages/ChatDetailPage.ets:803` (加号), `pages/tab/seeker/HomePage.ets:879-888` (搜索), `pages/tab/seeker/ProfilePage.ets:148-156` (菜单项), `pages/tab/recruiter/RecruiterHomeTab.ets`, `pages/tab/recruiter/RecruiterProfileTab.ets`
  Acceptance criteria (agent-executable): 在 `.omo/evidence/arkts-style-remaining-fixes/task-7/accessibility-audit.md` 中输出一份审计表，列出目标文件中每个 `SymbolGlyph(...)` / `Button({ type:` 出现的文件与行号、其所在的父组件（Button/Row/Column），以及对应的 `accessibilityText` 值；无 `accessibilityText` 的行必须说明已注册父组件 `accessibilityText` 或已在 Todo 4 处理。审计表完成后，`codelinter --exit-on error <target-files>` 返回 0。
  QA scenarios: happy — 审计表覆盖所有目标图标且 `codelinter` 通过；failure — 存在未标注图标且无父组件 accessibilityText。Evidence: `.omo/evidence/arkts-style-remaining-fixes/task-7/`
  Diff label: style(arkts): 为关键图标与按钮补充无障碍标签

- [x] 8. Vue 角色功能一致性校验
  What to do / Must NOT do: 逐一对照 Vue 端 HR 与求职者角色的核心页面，检查 ArkTS 端对应页面是否具备等价的功能入口、操作按钮、状态展示与跳转逻辑。Must NOT 在 ArkTS 端新增 Vue 端没有的功能；Must NOT 为补全功能改动后端接口。
  Parallelization: Wave 2 / Wave 3 | Blocked by: 1 | Blocks: 9 | Can parallelize with: 2,3,4,5,6,7
  References: 下表给出必须核验的 Vue ↔ ArkTS 页面映射与检查命令示例（若使用 PowerShell，请将 `grep` 替换为 `Select-String -Pattern`，`ls` 替换为 `Get-ChildItem` / `Test-Path`）：

  | 功能域 | Vue 页面 | ArkTS 对应页面/组件 | 检查命令示例 |
  |---|---|---|---|
  | 求职者职位搜索/筛选 | `uniseek_vue/src/pages/Home.vue` | `pages/tab/seeker/HomePage.ets` | `grep -R -n "pages/SearchPage\|showFilterSheet\|searchTasks" entry/src/main/ets/pages/tab/seeker/HomePage.ets` |
  | 求职者投递记录 | `uniseek_vue/src/pages/MyApplications.vue` | `pages/SubmittedPage.ets` | `grep -R -n "SubmittedPage\|pages/SubmittedPage" entry/src/main/ets/pages` |
  | 求职者简历 | `uniseek_vue/src/pages/Resume.vue` | `pages/ResumePage.ets` | `grep -R -n "pages/ResumePage" entry/src/main/ets/pages` |
  | 求职者聊天 | `uniseek_vue/src/pages/Messages.vue`, `Chat.vue` | `pages/tab/seeker/ChatPage.ets`, `pages/ChatDetailPage.ets` | `grep -R -n "ChatDetailPage\|ChatPage" entry/src/main/ets/pages/tab/seeker/ChatPage.ets entry/src/main/ets/pages/ChatDetailPage.ets` |
  | 求职者收藏 | `uniseek_vue/src/pages/Profile.vue`（收藏入口） | `pages/FavoritesPage.ets` | `grep -R -n "pages/FavoritesPage\|favorite" entry/src/main/ets/pages/tab/seeker/ProfilePage.ets entry/src/main/ets/pages/FavoritesPage.ets` |
  | 求职者个人中心 | `uniseek_vue/src/pages/Profile.vue` | `pages/tab/seeker/ProfilePage.ets` | `Test-Path entry/src/main/ets/pages/tab/seeker/ProfilePage.ets` |
  | 企业 HR 首页 | `uniseek_vue/src/pages/JobManagement.vue` | `pages/tab/recruiter/RecruiterHomeTab.ets` | `Test-Path entry/src/main/ets/pages/tab/recruiter/RecruiterHomeTab.ets` |
  | 企业发布职位 | `uniseek_vue/src/pages/PostJob.vue` | `pages/RecruiterPublishJobPage.ets`, `pages/RecruiterJobFormPage.ets` | `grep -R -n "RecruiterPublishJobPage\|RecruiterJobFormPage" entry/src/main/ets/pages` |
  | 企业人才库 | `uniseek_vue/src/pages/ResumePool.vue`, `Talents.vue` | `pages/RecruiterSearchPage.ets`, `pages/ResumeDetailPage.ets` | `grep -R -n "RecruiterSearchPage\|ResumeDetailPage\|talent" entry/src/main/ets/pages` |
  | 企业认证 | `uniseek_vue/src/pages/EnterpriseCertification.vue` | `pages/RecruiterEnterprisePage.ets` | `Test-Path entry/src/main/ets/pages/RecruiterEnterprisePage.ets` |
  | 企业申请/录用 | `uniseek_vue/src/pages/JobManagement.vue` | `pages/RecruiterApplicationsPage.ets`, `pages/RecruiterRequestsPage.ets` | `Test-Path entry/src/main/ets/pages/RecruiterApplicationsPage.ets entry/src/main/ets/pages/RecruiterRequestsPage.ets` |

  Acceptance criteria (agent-executable): 在 `.omo/evidence/arkts-style-remaining-fixes/task-8/` 下输出 `vue-arkts-parity-report.md`，至少包含上述 11 个功能域的 Vue 状态、ArkTS 状态、差异说明；若存在缺失，必须给出具体 ArkTS 页面文件与行号或“页面不存在”结论。
  QA scenarios: happy — 报告覆盖全部功能域且 ArkTS 无关键缺失；failure — 明显对应功能（如 HR 发布职位、求职者收藏）在 ArkTS 端找不到入口或缺失状态流转。Evidence: `.omo/evidence/arkts-style-remaining-fixes/task-8/`
  Diff label: N/A（本任务为只读校验，不修改代码）

- [x] 9. 最终编译校验与问题收敛
  What to do / Must NOT do: 在 `uniseek_arkts` 根目录执行 `codelinter --exit-on error` 与 `hvigorw assembleHap --no-daemon --stacktrace`；对仍然存在的 warning/error 进行分类修复或记录为已知兼容项（需说明理由）。Must NOT 为修复无关 warning 改业务逻辑。
  Parallelization: Wave 4 | Blocked by: 1-8 | Blocks: -
  References: `code-linter.json5`, `hmos-cli-toolkit` §01/§04
  Acceptance criteria: `codelinter --exit-on error` 退出码 0；`hvigorw assembleHap --no-daemon` 返回 `BUILD SUCCESSFUL`（0 errors，warnings 可接受但需记录）。
  QA scenarios: happy — 双重校验均通过；failure — 任一方有 error 则返回相应文件并修复。Evidence: `.omo/evidence/arkts-style-remaining-fixes/task-9/`
  Diff label: N/A（按用户要求不执行 git 提交，仅生成 diff 摘要供用户审阅）

## Final verification wave
> 所有检查均由 agent 在本机执行，无需人工操作；完成后向用户展示结果并等待最终确认。
- [x] F1. Plan compliance audit：检查 `.omo/evidence/arkts-style-remaining-fixes/task-{1..9}/` 是否均存在 `fix-approach.md` 与 `changes-summary.md`。
- [x] F2. Code quality review：`cd uniseek_arkts; codelinter --exit-on error` 退出码 0。
- [x] F3. Build verification：`cd uniseek_arkts; hvigorw assembleHap --no-daemon --stacktrace` 输出 `BUILD SUCCESSFUL`。
- [x] F4. Scope fidelity：检查 `.omo/evidence/arkts-style-remaining-fixes/final-diff-summary.md`，确认修改文件只限于 `uniseek_arkts/entry/src/main/ets/` 与 `.omo/`（计划文件），未触碰 Java/Vue 模块与 git 历史。

## Commit strategy
**用户明确要求：本次不执行任何 git 操作。因此本计划中的“Diff label”仅作为变更摘要标签，用于生成 diff 说明，不实际运行 `git add` / `git commit` / `git push` / `git stash` / `git reset` 等命令。**
1. 每个 Todo 完成后，按其改动类型给出 Conventional Commit 格式的摘要标签：`style(arkts): <what>` 或 `fix(arkts): <what>`。
2. 每次改动前在 `.omo/evidence/arkts-style-remaining-fixes/task-<N>/fix-approach.md` 中记录修复思路；完成后在同一目录保存 `changes-summary.md`，列出修改文件与 diff 要点，供用户自行决定是否提交。
3. 最终全部 Todo 完成后输出 `.omo/evidence/arkts-style-remaining-fixes/final-diff-summary.md`，按 Conventional Commit 分组，方便用户一键复制后自行提交。
4. 不推送、不修改本地与远程仓库记录。

## Success criteria
1. `codelinter --exit-on error` 返回退出码 0。
2. `hvigorw assembleHap --no-daemon` 返回 `BUILD SUCCESSFUL`，0 个 error。
3. 所有页面不再引用未定义的 `AppTypography.BUTTON_HEIGHT`。
4. 硬编码颜色/字号/间距在核心页面（LoginPage、RegisterPage、MainPage、RecruiterHomePage、HomePage、JobDetailPage、ChatDetailPage、JobFeedCard、ProfilePage、JobFeedList）及公共组件（StandardInput、PrimaryButton）中全部收敛到 `AppStyles` 常量或 HMOS `sys.*` 资源。
5. TabBar、按钮、卡片、输入框风格一致，符合 HMOS 设计规范；组件写法优先参考 `hmos-design`、`arkui-knowledge`、`arkts-grammar-standards`、`frontend-skill` 中的原生 ArkUI 示例。
6. 响应式断点使用主窗口 UIContext 的媒体查询实现，宽屏下无内容溢出或截断，且监听器有注册/注销。
7. 关键图标/按钮均带 `accessibilityText`。
8. 输出 `vue-arkts-parity-report.md`，确认 ArkTS 端 HR/求职者角色的功能入口、状态展示与 Vue 端保持一致；对确实缺失的功能给出文件级定位与补齐建议（补齐本身须经用户确认）。
9. 全程不执行 git 提交/推送/回滚等写仓库操作。
