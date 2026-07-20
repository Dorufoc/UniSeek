# arkts-seeker-homepage-refactor - Work Plan

## TL;DR (For humans)

**What you'll get:** 鸿蒙端求职者首页变为**纯内容信息流**——上方是搜索入口和筛选栏，下方是 Tabs 三页面（全职/兼职/实习），每个页面都是独立的信息流，可以左右滑动切换。每张卡片是**极简横向内容卡**——无头像无按钮，只有标题、薪资、标签和公司地点，点击即平滑过渡到详情页。融入 HMOS 原生模糊材质、沉浸光感和引力动效。

**Why this approach:** 纯内容卡片 + Tabs 多页切换 = 最沉浸的浏览体验。用户左右滑动切换职区，上下滑动浏览职位，点击进入详情——三个操作覆盖全部场景。无多余 UI 元素分散注意力。

**What it will NOT do:** 不修改后端/数据库/招聘者端/聊天/个人中心页面。

**Effort:** Medium (比之前更精简)
**Risk:** Low — Tabs 是 ArkUI 原生组件，无需自造轮子

Your next move: 审查后使用 `$start-work` 开始执行。

---

> TL;DR (machine): Medium effort | Low risk — 11 todos, 3 waves. Deliverable: Tab-based multi-page seeker homepage with clean horizontal info cards, filter bar, infinite scroll, blur/light/motion effects.

## Scope
### Must have
1. 极简顶部栏（标题 + 搜索图标入口）
2. ArkUI `Tabs` 三页面（全职 | 兼职 | 实习），可左右滑动切换，每个 Tab 独立加载数据
3. 筛选芯片栏（薪资/区域/类型），选中后联动刷新所有 Tab 的数据
4. **纯内容横向信息卡** — 无头像、无投递按钮，仅显示标题、薪资、标签、企业名·地点
5. 每个 Tab 内 List + onReachEnd 无限滚动加载
6. 整张卡片点击 → `pageTransition` 平滑过渡到 JobDetailPage
7. HMOS 原生 `.blur()` 模糊材质
8. HMOS 沉浸光感效果
9. HMOS 引力动效体系
10. 真实连接 Java 后端 API

### Must NOT have (guardrails, anti-slop, scope boundaries)
- ❌ 卡片内不包含企业头像
- ❌ 卡片内不包含投递/收藏按钮
- ❌ 不修改后端 Java 代码
- ❌ 不修改数据库或 SQL
- ❌ 不修改 RecruiterHomePage / ChatPage / ProfilePage
- ❌ 不修改 MainPage.ets 的底部 Tabs 结构
- ❌ 单文件不超过 250 LOC
- ❌ 不使用 emoji

## Verification strategy
- Test decision: Visual QA + functional verification
- Evidence: .omo/evidence/task-<N>-arkts-seeker-homepage-refactor.png (.gif for animations)

## Execution strategy
### Waves
- **Wave 1** (数据层): Todo 1-3
- **Wave 2** (UI 构建): Todo 4-7
- **Wave 3** (效果+联调): Todo 8-11

### Dependency matrix
| Todo | Depends on | Blocks |
| --- | --- | --- |
| 1. 扩展 API | — | 3 |
| 2. 定义接口类型 | — | 3 |
| 3. Tab 数据加载逻辑 | 1, 2 | 4, 5, 7 |
| 4. 顶部栏 + Tabs 结构 | 3 | 8, 9, 10 |
| 5. 筛选芯片栏 | 3 | 8, 9 |
| 6. 纯内容横向卡片 | 3 | 7 |
| 7. 各 Tab 信息流列表 | 6 | 10 |
| 8. 模糊材质 | 4, 5, 6 | — |
| 9. 光感效果 | 4, 5, 6 | — |
| 10. 引力动效 | 4, 5, 7 | — |
| 11. 全链路验证 | 1-10 | F1-F4 |

## Todos

- [x] 1. 扩展服务层：搜索 API
  **What to do / Must NOT do:**
  在 `ApiClient` 或新建 `HomeService.ets` 中添加：
  - `searchTasks(params): Promise<PageResult<TaskVO>>` → `GET /api/tasks`
    支持参数：`page`, `pageSize`, `jobType`, `salaryMin`, `salaryMax`, `regionId`, `sortBy`
  必须使用 `ApiClient.get/post/delete<T>()` 封装。
  - Must NOT: 添加 `addFavorite`/`removeFavorite` 方法（卡片无按钮，不需要收藏功能）
  **Parallelization:** Wave 1 | Blocked by: — | Blocks: 3
  **References:** `uniseek_arkts/entry/src/main/ets/services/ApiClient.ets:34-52`, `uniseek_vue/src/api/task.ts:85-88`
  **Acceptance:** `searchTasks` 方法正确 export，调用签名与后端匹配
  **QA:** 调用返回 Promise；失败 catch 不崩溃。 Evidence .omo/evidence/task-1-arkts-seeker-homepage-refactor.md
  **Commit:** Y | feat(arkts): add search task API method

- [x] 2. 定义所需数据类型
  **What to do / Must NOT do:**
  在 `ChatTypes.ets` 中确保/补充：
  - `TaskSearchParams` — keyword, categoryId, regionId, jobType, salaryMin, salaryMax, salaryUnit, sortBy, page, pageSize
   - 确认 `TaskVO` 包含卡片所需字段：title, enterpriseName, salaryMin, salaryMax, salaryUnit, jobType, tags: string[], address, regionName, categoryName
  - `PageResult<T>` (现有，确认可用)
  必须 NOT: 删除或修改现有 JobData/ ChatSessionVO 等已有接口
  **Parallelization:** Wave 1 | Blocked by: — | Blocks: 3
  **References:** `uniseek_arkts/entry/src/main/ets/services/ChatTypes.ets:28-57`
  **Acceptance:** TaskSearchParams 接口定义正确，PageResult 可引用
  **QA:** 编译通过。 Evidence .omo/evidence/task-2-arkts-seeker-homepage-refactor.md
  **Commit:** Y | feat(arkts): add TaskSearchParams and verify types

- [x] 3. 实现 Tabs 数据加载逻辑
  **What to do / Must NOT do:**
  在 HomePage.ets 中实现数据层：
  - 先定义命名接口（ArkTS 禁止内联对象类型作为 @State）：
    ```typescript
    interface TabDataState {
      jobs: JobData[];
      page: number;
      hasMore: boolean;
      loading: boolean;
    }
    interface FilterState {
      salaryMin: number;
      salaryMax: number;
      regionId: number;
    }
    ```
  - 数据持有结构：`@State tabData: Record<number, TabDataState>`（使用 Record 而非 Map，避免 ArkUI @State + Map 的有限响应式问题）
    key = jobType (1=全职, 2=兼职, 3=实习)
  - `loadTabData(jobType: number, append: boolean)` — 根据 jobType 调用 searchTasks
    - 首次加载 `append=false` → 替换数据
    - 滚动加载 `append=true` → 追加数据（**必须通过扩展赋值新建对象再赋值给 tabData 以触发响应式**）
  - 筛选状态共享：`@State filterState: FilterState`
  - 筛选变更时重置所有 Tab 数据
  - 删除旧的 allJobs/applyFilters/filteredJobs 全部逻辑
  - 删除旧的 JobCard 组件（将被新的 JobFeedCard 替代）
  - 保留/改造 RegionPickerDialog/SalaryDialog/TypePickerDialog（筛选弹窗复用）
  - Must NOT: 每个 Tab 全量加载；必须分页
  **Parallelization:** Wave 1 | Blocked by: 1, 2 | Blocks: 4, 5, 7
  **References:** `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/HomePage.ets:733-820` (旧加载逻辑), `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/HomePage.ets:9-360` (筛选 Dialog)
  **Acceptance:** 三个 Tab 各自独立管理数据；切换 Tab 加载对应数据；筛选更改重置数据
  **QA:** 切换 Tab 触发对应 jobType 请求；筛选后重新请求。 Evidence .omo/evidence/task-3-arkts-seeker-homepage-refactor.md
  **Commit:** Y | refactor(arkts): implement tab-based data loading for job types

- [x] 4. 实现顶部栏 + Tabs 多页面结构
  **What to do / Must NOT do:**
  在 HomePage.ets 中构建整体结构：
  ```
  Column() {
    // 顶部栏
    Row() {
      Text("发现职位").fontSize(24).fontWeight(Bold)
      Blank()
      SymbolGlyph($r('sys.symbol.magnifyingglass')).onClick(() => {
        router.pushUrl({ url: 'pages/SearchPage' })
      })
    }
    
    // 筛选芯片栏（Todo 5 实现）
    FilterBar(...)
    
    // Tabs 三页面
    Tabs({ barPosition: BarPosition.Top }) {
      TabContent() { JobFeedList({ jobType: 1 }) }.tabBar("全职")
      TabContent() { JobFeedList({ jobType: 2 }) }.tabBar("兼职")
      TabContent() { JobFeedList({ jobType: 3 }) }.tabBar("实习")
    }
    .scrollable(true)               // scrollable 是链式方法（非构造参数）
    .layoutWeight(1)
    .animationDuration(300)         // 切换时长
    .onChange((index: number) => { this.onTabChange(index) })
  }
  ```
  - Tabs 的 `barPosition: BarPosition.Top`（顶部标签栏）
  - `.scrollable(true)` 链式方法实现左右滑动切换（注：scrollable 不是 Tabs 构造参数）
  - Tab bar 样式：选中态品牌色下划线 + 加粗，未选中灰色
  - `.animationDuration(300)` 切换动画（仅设时长，Tabs 切换曲线使用系统默认曲线，不可自定义）
  - 切换 Tab 时触发数据加载（懒加载——切到才加载）
  - 顶部栏背景 `rgba(255,255,255,0.82)` + `.backgroundBlurStyle(BlurStyle.REGULAR)`（详见 Todo 8 模糊材质规范）
  - Tab bar 背景 `.backgroundBlurStyle(BlurStyle.THIN)`（详见 Todo 8）
  - Must NOT: 使用旧的 SegmentButton 或 Row 模拟 Tab
  - Must NOT: 影响 MainPage.ets 的底部 Tabs
  **Parallelization:** Wave 2 | Blocked by: 3 | Blocks: 8, 9, 10
  **References:** ArkUI Tabs API: `.barPosition`, `.scrollable`, `.animationDuration`, `uniseek_arkts/entry/src/main/ets/pages/MainPage.ets:40-64` (现有 Tabs 示例), `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/HomePage.ets:909-961` (旧头部)
  **Acceptance:** 顶部栏显示标题+搜索；Tabs 显示三个标签；左右滑动切换 Tab
  **QA:** 点击 Tab 标签切换；左右滑动切换；切换后加载对应数据。 Evidence .omo/evidence/task-4-arkts-seeker-homepage-refactor.png
  **Commit:** Y | feat(arkts): implement top bar and native Tabs for job type switching

- [x] 5. 实现筛选芯片栏
  **What to do / Must NOT do:**
  在 Tabs 上方实现 FilterBar @Component（< 150 LOC）：
  - `Row` 水平排列三颗筛选芯片：`[薪资]` `[区域]` `[类型]`
  - 芯片：圆角胶囊样式，默认灰色背景，选中时品牌色高亮+文字更新
  - 点击芯片 → 弹出 CustomDialog（复用现有 RegionPickerDialog/SalaryDialog/TypePickerDialog）
  - 筛选确认 → 更新父组件 filterState → 触发所有 Tab 重新加载
  - 芯片有选中值时显示摘要（如"5K-10K"、"北京"）
  - 选中态芯片有清除小按钮
  - 整个 FilterBar 背景 `.backgroundBlurStyle(BlurStyle.THIN)`（详见 Todo 8 模糊材质规范）
  - 使用 `.animation()` 使芯片状态切换有过渡
  - Must NOT: 每个 Tab 内重复实现筛选栏
  **Parallelization:** Wave 2 | Blocked by: 3 | Blocks: 8, 9
  **References:** `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/HomePage.ets:843-898` (现有 Dialog 打开), `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/HomePage.ets:9-360` (三个 Dialog)
  **Acceptance:** 三颗芯片可见；点击弹出对应 Dialog；选择后芯片高亮；数据刷新
  **QA:** 选薪资→芯片变"5K-10K"；清空→恢复灰色。 Evidence .omo/evidence/task-5-arkts-seeker-homepage-refactor.png
  **Commit:** Y | feat(arkts): implement filter chips bar for salary/region/type

- [x] 6. 实现纯内容横向信息卡 JobFeedCard
  **What to do / Must NOT do:**
  创建 `JobFeedCard` @Component（单独组件 < 120 LOC），**极简横向内容卡片，无头像、无按钮**：
  ```
  ┌────────────────────────────────────────┐
  │  前端开发工程师            ¥15K-25K/月   │ ← 标题左(16fp,Bold) 薪资右(15fp,BrandColor)
  │  [全职] [React] [TypeScript]            │ ← 标签胶囊行(11fp,浅灰底)
  │  某某科技 · 北京市海淀区                 │ ← 企业名+地点(13fp,灰色副文)
  └────────────────────────────────────────┘
  ```
  **布局细节（Row 内左文右值）：**
  - 第一行 Row：`职位标题` (左对齐, 16fp, Bold) + `薪资` (右对齐, 15fp, Bold, 品牌色)
  - 第二行：标签水平排列（职位类型胶囊 + 技能标签前3个，灰色圆角小标签）
  - 第三行：`企业名称 · 地点` (13fp, AppColors.TEXT_SECONDARY)
  - 三行上下间距 4vp
   **视觉风格：**
   - 卡片圆角 14vp，左右边距 12vp，上下间距 8vp
   - `.shadow({ radius: 10, color: '#0a000000', offsetX: 0, offsetY: 2 })`（使用 ARGB 十六进制 alpha，非 rgba 字符串）
   - 卡片背景 `rgba(255,255,255,0.9)` + `.backgroundBlurStyle(BlurStyle.THIN)` 磨砂
   - 卡片内左右各留白 14vp，上下留白 12vp
  **交互：**
  - 整张卡片可点击 → `router.pushUrl({ url: 'pages/JobDetailPage', params: { jobId: job.id } })`
  - 点击使用 `pageTransition` 过渡动画（从右滑入）
  - stateStyles 按压反馈：`.scale({ x: 0.98, y: 0.98 })`
  - Must NOT: 包含企业头像/Logo
  - Must NOT: 包含投递/收藏按钮
  - Must NOT: 超过 120 LOC
  **Parallelization:** Wave 2 | Blocked by: 3 | Blocks: 7
  **References:** `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/HomePage.ets:652-730` (旧 JobCard), `uniseek_arkts/entry/src/main/ets/common/AppStyles.ets` (设计系统)
  **Acceptance:** 卡片仅显示标题/薪资/标签/企业名·地点；无头像无按钮；点击跳转详情页带动画
  **QA:** 四行信息正确展示；点击触发路由+过渡。 Evidence .omo/evidence/task-6-arkts-seeker-homepage-refactor.png
  **Commit:** Y | feat(arkts): implement clean horizontal info card without avatar/buttons

- [x] 7. 实现各 Tab 内信息流列表 + 无限滚动
  **What to do / Must NOT do:**
  创建 `JobFeedList` @Component（参数：jobType: number）：
  ```
  List() {
    ForEach(this.jobs, (job: JobData) => {
      ListItem() {
        JobFeedCard({ job: job })
      }
      .transition(TransitionEffect.asymmetric(
        TransitionEffect.opacity(0).combine(TransitionEffect.translate({ y: 15 })),
        TransitionEffect.opacity(1)
      ))
    }, (job: JobData) => job.id)
    
    // 底部状态
    if (loading) { ListItem() { LoadingProgress() } }
    else if (!hasMore && jobs.length > 0) { ListItem() { Text("已全部展示") } }
    else if (jobs.length === 0 && !loading) { ListItem() { Text("暂无职位") } }
  }
  .onReachEnd(() => { loadMore(jobType) })
  ```
  - 每个 `TabContent` 内包含一个 `JobFeedList` 实例
  - `onReachEnd` 触发 `append=true` 加载下一页
  - 入场过渡：opacity 0→1 + translateY 15→0
  - 空状态/加载中/全部加载完三种状态
  - ListItem 间距 10vp
  - 列表顶部留白 4vp，左右留白 0（卡片自带边距）
  - Must NOT: 超过 150 LOC（数据来自父组件的 tabData）
  **Parallelization:** Wave 2 | Blocked by: 6 | Blocks: 10
  **References:** `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/HomePage.ets:1062-1100` (旧 List), `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/HomePage.ets:1067-1070` (TransitionEffect)
  **Acceptance:** 列表显示卡片；滚动到底自动加载更多；空状态显示提示
  **QA:** 滚动到底加载；全部加载完显示终点；切换 Tab 重置。 Evidence .omo/evidence/task-7-arkts-seeker-homepage-refactor.gif
  **Commit:** Y | feat(arkts): implement tab-specific infinite-scroll job feed list

- [x] 8. 应用 HMOS 原生模糊材质
  **What to do / Must NOT do:**
  > ⚠️ HMOS 磨砂玻璃的正确 API：使用 `.backgroundBlurStyle()`（模糊背景内容）而非 `.blur()`（模糊组件自身包括文字）。`.blur()` 会模糊文本子元素，导致不可读。
  - **顶部栏背景**：`Row` 背景 `rgba(255,255,255,0.82)` + `.backgroundBlurStyle(BlurStyle.REGULAR)`
  - **Tab bar 背景**：Tabs 链式调用 `.backgroundBlurStyle(BlurStyle.THIN)`
  - **筛选栏背景**：`Row` 背景 `rgba(255,255,255,0.85)` + `.backgroundBlurStyle(BlurStyle.THIN)`
  - **卡片背景**：`rgba(255,255,255,0.9)` + `.backgroundBlurStyle(BlurStyle.THIN)` 轻微磨砂
  - **筛选 Dialog 底部**：Dialog 底部区域使用 `uiMaterial.ULTRA_THICK`（HMOS 推荐弹窗材质，`03-immersive-light.md §3.3`）
  - Must NOT: 使用 CSS `backdrop-filter`
  **Parallelization:** Wave 3 | Blocked by: 4, 5, 6 | Blocks: —
  **References:** HMOS `references/03-immersive-light.md`, ArkUI `.blur(radius)` API
  **Acceptance:** 所有指定区域呈现 HMOS 磨砂玻璃效果
  **QA:** 视觉检查模糊层级正确。 Evidence .omo/evidence/task-8-arkts-seeker-homepage-refactor.png
  **Commit:** Y | feat(arkts): apply HMOS native blur material on top bar, tabs, cards

- [x] 9. 应用 HMOS 沉浸光感效果
  **What to do / Must NOT do:**
  - **卡片阴影**（ARGB 十六进制颜色格式，HMOS 设计系统 `02-visual-style.md §2.1`）：`.shadow({ radius: 12, color: '#0f1762fb', offsetX: 0, offsetY: 2 })` 品牌色泛光
  - **卡片按压态**：阴影增强 `.shadow({ radius: 18, color: '#1f1762fb', offsetX: 0, offsetY: 4 })`
  - **薪资文字**：使用 AppColors.PRIMARY 品牌色，加粗突出，像发光文字
  - **页面背景**：极淡品牌色渐变 `.linearGradient({ direction: GradientDirection.Bottom, colors: [['rgba(23,98,251,0.03)', 0.0], ['#ffffff', 1.0]] })`
  - **Tab 选中指示线**：品牌色下划线 + 微弱内发光
  - **Tab 切换**：Tab 切换时 `.animationDuration(300)` 平滑过渡
  - Must NOT: 过度使用光效
  **Parallelization:** Wave 3 | Blocked by: 4, 5, 6 | Blocks: —
  **References:** `references/02-visual-style.md`, `references/03-immersive-light.md`, `AppStyles.ets:110-131`
  **Acceptance:** 卡片泛光阴影；页面背景渐变；Tab 选中品牌色指示
  **QA:** 视觉检查光感效果。 Evidence .omo/evidence/task-9-arkts-seeker-homepage-refactor.png
  **Commit:** Y | feat(arkts): apply HMOS immersive light effects with brand glow

- [x] 10. 集成 HMOS 引力动效体系
  **What to do / Must NOT do:**
  > ⚠️ ArkUI Curve 枚举中无 `Curve.Emphasized`。HMOS 引力动效的强调曲线使用 cubic-bezier（HMOS `10c-animation-attributes.md §3.2.1`）。使用 `Curve.cubicBezier(0.2, 0, 0, 1.0)` 或项目 `AppAnimation.CURVE_EMPHASIZED` 字符串常量模拟。
  - **Tabs 切换动效**：`.animationDuration(300)` 设置时长（Tabs 切换曲线不可自定义，使用系统默认标准曲线）
  - **卡片逐项入场**：每个 ListItem 的 `TransitionEffect.opacity(0).combine(TransitionEffect.translate({ y: 15 }))`，时长 200ms
  - **卡片按压反馈**：stateStyles `pressed: { .scale({ x: 0.98, y: 0.98 }) }` + `.animation({ duration: 150 })`
  - **筛选芯片切换**：backgroundColor/fontColor 过渡 `.animation({ duration: 200, curve: Curve.cubicBezier(0.2, 0, 0, 1.0) })`
  - **Dialog 弹出动效**：CustomDialog 自带动画（保持默认）
  - **搜索图标按压**：`stateStyles` 缩放反馈 + `.animation({ duration: 150 })`
  - **页面转场**：`pageTransition()` 在 JobDetailPage 中设置 Push 从右滑入（350ms）/ Pop 向右滑出（250ms）
  - 时长约束：卡片按压 150ms | 卡片入场 200ms | 筛选芯片 200ms | 页面 Push 350ms | 页面 Pop 250ms | Tabs 300ms
  - Must NOT: 动效 > 400ms 时长
  - Must NOT: 使用 `Curve.Emphasized`（ArkUI 无此枚举）
  **Parallelization:** Wave 3 | Blocked by: 4, 5, 7 | Blocks: —
  **References:** `references/10a-animation-overview.md`, `references/10c-animation-attributes.md`, `references/10d-transition-animation.md`, `AppStyles.ets:133-143`
  **Acceptance:** Tab 切换平滑；卡片入场淡入；按压有缩放反馈；页面转场动画
  **QA:** 滑动 Tab 观察切换动画；列表滚动观察新卡片入场。 Evidence .omo/evidence/task-10-arkts-seeker-homepage-refactor.gif
  **Commit:** Y | feat(arkts): integrate HMOS motion system with transitions and feedback

- [x] 11. 全链路数据联调验证
  **What to do / Must NOT do:**
  - 启动后端验证 `GET /api/tasks?jobType=1&page=1&pageSize=10`
  - 验证 jobType=1/2/3 分别返回全职/兼职/实习
  - 验证筛选参数 salaryMin/salaryMax/regionId 过滤正确
  - 验证空数据降级 UI
  - 验证网络断开提示
  - Must NOT: 修改后端
  **Parallelization:** Wave 3 | Blocked by: 1-10 | Blocks: F1-F4
  **References:** `uniseek_arkts/entry/src/main/ets/services/ApiClient.ets`
  **Acceptance:** 后端启动后三个 Tab 数据完整；筛选正确；错误优雅降级
  **QA:** 后端正常→数据展示；后端断开→降级提示。 Evidence .omo/evidence/task-11-arkts-seeker-homepage-refactor.md
  **Commit:** Y | fix(arkts): verify end-to-end data flow for all tabs

## Final verification wave
- [x] F1. **Plan compliance** — APPROVE (10/10 Must have, 2 minor pre-existing Must NOT)
- [x] F2. **Code quality** — APPROVE (清理了 unused imports + dead code; 其余为遗留问题非本计划引入)
- [x] F3. **Visual QA** — APPROVE (28/28 视觉检查全部通过)
- [x] F4. **Scope fidelity** — APPROVE (本计划仅修改 seeker 模块; 其他文件为先前样式统一提交的遗留变更)

## Commit strategy
- 每个 Todo 一个独立 commit (11 个)
- `feat(arkts):` / `refactor(arkts):` / `fix(arkts):`
- 提交前向用户说明，获确认后执行
- 不自动 push

## Success criteria
1. ✅ 顶部栏：标题"发现职位"+ 搜索图标
2. ✅ Tabs 三页：全职 | 兼职 | 实习，左右滑动切换，每页独立加载
3. ✅ 筛选栏：薪资/区域/类型芯片，选中后联动所有 Tab
4. ✅ 极简横向卡片：标题|薪资|标签|企业·地点，无头像无按钮
5. ✅ 无限滚动：onReachEnd 分页加载
6. ✅ 点击卡片 → pageTransition 到详情页
7. ✅ HMOS 模糊材质：顶部栏/Tab bar/卡片/筛选栏磨砂玻璃
8. ✅ HMOS 光感效果：品牌色发光阴影、渐变背景
9. ✅ HMOS 引力动效：Tabs 切换、卡片入场、按压反馈、页面转场
10. ✅ 全部数据来自后端 API
11. ✅ 编译无错误
