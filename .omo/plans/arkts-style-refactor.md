# ArkTS 前端样式重构计划

## TL;DR (For humans)

对 UniSeek 鸿蒙端（ArkTS）全部 41 个 .ets 文件（其中 30 个页面/组件文件需重构，11 个服务层文件不变）进行样式重构，引入 HMOS 设计体系和 frontend-skill 设计原则，保留全部原始功能。**核心变更**：颜色统一到品牌色 #1762FB、图标迁移到 SymbolGlyph、引入 HMOS Token 色彩体系、统一导航栏/按钮/卡片/弹窗样式、添加 HMOS 引力动效、整体提升设计品质。

**强调色**: `#1762FB`（保持不变）
**设计参考**: hmos-design SKILL + frontend-skill SKILL
**执行要求**: 每个子代理在执行修改前必须加载 `hmos-design` 和 `frontend-skill` 两个 skill

---

## Phase 1: 设计系统重构（Design Token & Component）

### Todo 1: AppStyles.ets — 重构全局设计 Token 体系 [x]
- **文件**: `uniseek_arkts/entry/src/main/ets/common/AppStyles.ets`
- **变更**:
  1. 更新 AppColors: PRIMARY 保持 `#1762FB`，PRIMARY_HOVER 改为 `#0A4BDB`，删除 PRIMARY_BG/PRIMARY_BORDER（改用 HMOS sys.color）
  2. 新增 `HMOS_BRAND` = `#1762FB` 作为品牌色常量
  3. 新增系统色引用：`SYS_BG = $r('sys.color.background_primary')` 等注释说明
  4. 更新 AppShadow: 采用 HMOS 标准化阴影层级（SM: radius=6 / MD: radius=12 / LG: radius=24）
  5. 更新 AppAnimation: 采用 HMOS 引力动效曲线（CURVE_DEFAULT = Curve.FastOutLinearIn, 新增 CURVE_EMPHASIZED = Curve.Emphasized）
  6. 新增 AppTypography 类：定义 TextTypes 层级常量
  7. 更新 StandardInput: 使用 HMOS 规范（borderRadius=20, 使用系统色）  
  8. 更新 PrimaryButton: 使用 HMOS 胶囊按钮规范（ButtonType.Capsule, height=40）

### Todo 2: 新增导航栏公共组件 NavBar.ets [x]
- **文件**: 新建 `uniseek_arkts/entry/src/main/ets/common/NavBar.ets`
- **设计**: 
  - 基于 HMOS Navigation 组件规范
  - 支持标题、返回按钮（默认 showBack=true）、右侧操作菜单
  - 使用 `title()` 模式而非手写 Row
  - 背景色使用 `$r('sys.color.background_primary')`
  - 品牌色强调返回箭头
- **约束**: 替代所有页面中手写的 `Row() { Image(←) + Text(title) }` 模式

### Todo 3: 新增卡片组件规范 StandardCard.ets [x]
- **文件**: 新建 `uniseek_arkts/entry/src/main/ets/common/StandardCard.ets`
- **设计**: 
  - HMOS 卡片规范：白色背景 + 12vp 圆角 + 轻阴影
  - 提供 title/subtitle/content 插槽
  - 采用 `comp_background_list_card` 系统色背景

---

## Phase 2: 全局颜色统一（修复所有硬编码色值）

### Todo 4: 替换所有 `#007AFF` 为品牌色 `#1762FB` [x]
- **搜索模式**: 全局搜索 `#007AFF`（iOS 蓝色）
- **涉及文件**: 全部 .ets 页面文件（约 20+ 处）
- **变更**: 替换为 `AppColors.PRIMARY` 或 `$r('sys.color.brand')`
- **注意**: 保留 `#007AFF` 作为通用强调色的地方改为使用功能色
- **HMOS 指导**: 使用 `$r('sys.color.brand')` 在支持动态主题的组件中

### Todo 5: 替换所有硬编码中性色 [x]
- **搜索模式**: `#333333` / `#666666` / `#999999` / `#F5F5F5` / `#FFFFFF`
- **变更**:
  - `#333333` → `$r('sys.color.font_primary')`
  - `#666666` → `$r('sys.color.font_secondary')`
  - `#999999` → `$r('sys.color.font_tertiary')`
  - `#F5F5F5` → `$r('sys.color.comp_background_tertiary')`
  - `#FFFFFF`（卡片背景）→ `$r('sys.color.comp_background_list_card')`
- **例外**: 纯白色页面背景保留 `'#FFFFFF'` 或使用 `$r('sys.color.background_primary')`

### Todo 6: 替换所有 `#FF4444` / `#FF6B35` 等功能色 [x]
- **变更**:
  - `#FF4444`（错误红）→ `AppColors.DANGER` 或 `$r('sys.color.warning')`
  - `#FF6B35`（薪资橙）→ `AppColors.WARNING`（#f59e0b）
  - `#34C759`（成功绿）→ `AppColors.SUCCESS`（#10b981）
  - `#EBF5FF`（选中背景）→ `$r('sys.color.interactive_hover')`

---

## Phase 3: 图标系统迁移（Image → SymbolGlyph）

### Todo 7: MainPage.ets 和 RecruiterHomePage.ets — TabBar 图标迁移 [x]
- **文件**: `MainPage.ets`, `RecruiterHomePage.ets`
- **变更**:
  1. 移除 Image 图标，改用 `SymbolGlyph($r('sys.symbol.*'))`
  2. tabItem Builder 改为使用 HMOS 标准 Tab 写法（参考 hmos-design §9.4）
  3. 选中色: `$r('sys.color.brand')`（#1762FB）
  4. 未选中色: `$r('sys.color.icon_tertiary')`
  5. 添加 BounceEffect 弹跳动效
- **Symbol 映射**:
  - `home` → `$r('sys.symbol.house')`
  - `chat` → `$r('sys.symbol.bubble_left')`
  - `mine` → `$r('sys.symbol.person')`
- **保持功能**: Tab 切换逻辑、onChange 事件、currentIndex 状态

### Todo 8: 各页面图标迁移 [x]
- **涉及文件**: SearchPage, JobDetailPage, ProfilePage, RecruiterProfileTab, SubmittedPage, FavoritesPage, ResumePage, SettingsPage 等
- **变更**:
  - `←` 箭头 → `SymbolGlyph($r('sys.symbol.chevron_left'))`（封装在 NavBar.ets 中）
  - `→` 箭头 → `SymbolGlyph($r('sys.symbol.chevron_right'))`
  - 搜索图标 → `SymbolGlyph($r('sys.symbol.magnifyingglass'))`
  - 星标/收藏 → `SymbolGlyph($r('sys.symbol.star'))`
  - 设置 → `SymbolGlyph($r('sys.symbol.gearshape'))`
  - 简历图标 → `SymbolGlyph($r('sys.symbol.doc_text'))`
  - 公司/企业 → `SymbolGlyph($r('sys.symbol.building'))`
- **保持功能**: 所有 onClick 事件、路由跳转

---

## Phase 4: 导航栏统一化

### Todo 9: 在所有页面中应用 NavBar 组件 [x]
- **涉及文件**: JobDetailPage, SearchPage, SearchResultsPage, ResumePage, RealNameAuthPage, SettingsPage, FavoritesPage, SubmittedPage, ProfileDetailPage, RecruiterPublishJobPage, ChatDetailPage 等
- **变更**:
  1. 导入 `{ NavBar } from '../common/NavBar'`
  2. 替换手动实现的顶部导航栏（Row + back箭头 + title）
  3. 配置标题、返回按钮行为、右侧操作（如有）
- **保持功能**: router.back() 行为、页面标题、右侧操作

---

## Phase 5: 核心页面样式重构

### Todo 10: LoginPage.ets — 登录页重构 [x]
- **当前问题**: 背景淡蓝、布局拥挤、按钮扁平
- **变更**:
  1. 背景: 使用 HMOS 纯白背景 + 品牌色元素点缀（非大色块背景）
  2. Logo: 改为更精致的布局，上方居中
  3. 输入框: 使用胶囊样式（borderRadius=20）+ 系统背景色
  4. 分段切换: SegmentButton 保留，颜色同步品牌色
  5. 登录按钮: 改为 HMOS Capsule 按钮（ButtonType.Capsule, height=40）
  6. 注册引导: 更简洁，「立即注册」使用系统品牌色
  7. 添加页面进入动效（淡入 + 上移）
- **保持功能**: 手机号密码登录、角色切换、调试弹窗

### Todo 11: RegisterPage.ets — 注册页重构 [x]
- **当前问题**: 与登录页风格脱节，输入框使用 `#F5F5F5`
- **变更**:
  1. 标题区: 保持大标题风格，增加 HMOS 字体排印规范
  2. 输入框: 统一胶囊样式
  3. 角色选择: 使用 HMOS 胶囊按钮样式，品牌色高亮
  4. 注册按钮: HMOS Capsule 按钮
  5. 「已有账号」引导: 更紧凑
- **保持功能**: 所有字段验证、注册逻辑

### Todo 12: HomePage.ets & RecruiterHomeTab.ets — 首页/招聘首页重构 [x]
- **当前问题**: 
  - JobCard 设计陈旧（白色卡片+简单阴影）
  - 顶部区域标题文案需优化排版
  - 筛选按钮使用 Image 图标
  - 分类切换样式简单
- **变更**:
  1. JobCard 和 ResumeCard: 采用 HMOS 卡片风格（内部样式而非替换组件，保持组件结构不变），移除阴影改为更精致的样式
  2. 分类切换（全职/实习/兼职）: 使用 SegmentButton 或 HMOS 标签样式
  3. 筛选栏: 图标使用 SymbolGlyph，选中状态使用品牌色
  4. 搜索入口: 使用 Search 组件替代手写 Row
  5. 标题文案: 更精简，使用 HMOS TextTypes
  6. List: 使用 HMOS 标准列表样式 + divider 规范
  7. 添加列表项进出动效
- **保持功能**: 所有筛选逻辑、加载更多、分页

### Todo 13: JobDetailPage.ets — 职位详情页重构 [x]
- **当前问题**: 顶部导航手写、按钮风格不统一、薪资显示使用 #007AFF
- **变更**:
  1. 应用 NavBar 组件
  2. 薪资: 使用品牌色 #1762FB
  3. 标签区: 使用 HMOS 标签样式
  4. 底部操作栏: 收藏按钮使用 Stroke 胶囊样式，沟通按钮使用 Fill 胶囊样式
  5. 职位描述: 精简间距
  6. 错误提示: 使用 HMOS 规范 Error 样式
- **保持功能**: 投递、收藏、导航

### Todo 14: ChatPage.ets & ChatDetailPage.ets & RecruiterChatTab.ets — 聊天页面重构 [x]
- **当前问题**: 消息气泡简单、导航手写
- **变更**:
  1. ChatPage: 应用 NavBar 替代手动顶部
  2. ChatDetailPage: 自己消息气泡使用品牌色，对方气泡使用 HMOS 容器色
  3. 输入框: 胶囊输入框 + 胶囊发送按钮
  4. 未读角标: 使用 HMOS Badge 规范
  5. 时间戳: 使用 HMOS 字号规范
- **保持功能**: 消息加载、发送、已读标记

### Todo 15: ProfilePage.ets & RecruiterProfileTab.ets — 个人中心重构 [x]
- **当前问题**: 渐变背景风格旧、「我的」页面菜单项样式简单
- **变更**:
  1. 重新设计头像区域：使用 HMOS 卡片式 header
  2. 渐变色背景: 使用 HMOS 光感渐变规范（从品牌色柔滑过渡到白色）
  3. 菜单项: 使用 HMOS 列表项规范，SymbolGlyph 图标
  4. 分割线: 使用 divider 系统色
  5. 间距规范化
- **保持功能**: 路由、实名状态、企业资质状态

### Todo 16: 其余页面统一重构 [x]
- **涉及文件**: ResumePage, RealNameAuthPage, SettingsPage, FavoritesPage, SubmittedPage, SearchPage, SearchResultsPage, ProfileDetailPage, RecruiterPublishJobPage, RecruiterSearchPage, RecruiterRequestsPage, RecruiterEnterprisePage, RecruiterApplicationsPage, RecruiterJobFormPage, **RecruiterChatTab (tab/recruiter/)**, **ResumeDetailPage**
- **变更**:
  1. 应用 NavBar 统一导航
  2. 统一输入框/按钮/卡片风格到 HMOS 规范
  3. 颜色统一到品牌色+系统色
  4. 图标使用 SymbolGlyph
  5. 字体排印规范到 HMOS TextTypes
  6. 间距规范到 AppSpacing

---

## Phase 6: 动效系统集成

### Todo 17: 添加页面转场动效 [x]
- **涉及文件**: EntryAbility.ets（添加全局转场配置）
- **变更**:
  1. 在 `onWindowStageCreate` 中配置页面转场
  2. 使用 HMOS 引力动效: `transition(TransitionEffect.opacity(0.2).combine(TransitionEffect.translate({ y: 30 })).animation({ duration: 300, curve: Curve.Emphasized })`
  3. 或使用 `pageTransition()` API 配置 Push/Pop 转场

### Todo 18: 添加交互动效 [x]
- **涉及文件**: 所有按钮、卡片、列表项
- **变更**:
  1. 按钮添加按压态动效: 使用 HMOS interactive_pressed Token
  2. 列表项添加点击涟漪效果
  3. 卡片添加进入时淡入动效
  4. Tab 切换使用 BounceEffect
  5. 使用 `animation()` API 添加属性过渡

---

## Phase 7: 交付前检查

### Todo 19: 构建验证 [x]
- **检查**: 确认所有页面可正常编译
- **方法**: 运行 DevEco Studio 构建 / hvigor 构建
- **验证项**: 无编译错误、所有页面正常加载
- **结果**: `hvigorw assembleApp` → BUILD SUCCESSFUL (0 errors, 113 warnings)

### Todo 20: 功能回归测试 [x]
- **验证**: `hvigorw assembleApp` 构建通过（0 错误），功能回归测试需在鸿蒙真机/模拟器上执行
- **测试用例**（需在真机环境手动验证）:
  1. **登录流程**: 使用手机号 `18688886666` + 密码 `admin` 登录，验证跳转到对应的角色首页
  2. **注册流程**: 填写手机号/邮箱/昵称/密码，验证注册成功后跳转登录页
  3. **角色切换**: 在登录页切换"求职者/招聘者"，验证登录后跳转不同首页
  4. **职位筛选**: 在求职者首页切换分类（全职/实习/兼职），验证列表刷新；点击筛选按钮，验证弹窗正常
  5. **职位搜索**: 输入关键词"家教"，验证搜索结果页显示匹配条目
  6. **职位详情**: 点击职位卡片，验证跳转详情页；点击收藏，验证图标状态切换
  7. **投递沟通**: 在详情页点击"立即沟通"，验证跳转聊天页
  8. **聊天发送**: 在聊天页输入消息并发送，验证消息出现在列表中
  9. **个人中心**: 验证头像区域、菜单项（已投/收藏/简历/设置）点击跳转正常
  10. **退出登录**: 在设置页点击退出，验证跳转登录页
- **状态**: 构建验证通过，功能测试需在真机环境手动执行（CLI 环境限制）

---

## 执行顺序依赖

```
Phase 1 (Design Token) ──→ Phase 2 (Color Unification) ──→ Phase 3 (Icons)
                                                                    │
                                                                    └──→ Phase 4 (NavBar) ──→ Phase 5 (Pages) ──→ Phase 6 (Motion) ──→ Phase 7 (Verify)
```

⚠️ **串行执行约束**：Phase 1 和 Phase 2 不可并行。Phase 1 修改 AppStyles.ets 的常量结构（删除 PRIMARY_BG/PRIMARY_BORDER，新增 HMOS_BRAND 等），Phase 2 在 20+ 页面中引用这些常量。若并行会导致 import 冲突和引用不一致。必须 Phase 1 先完成并验证后，再启动 Phase 2。

Phase 3 依赖 Phase 1（SymbolGlyph 导入路径依赖设计系统更新）。Phase 4 依赖 Phase 3（NavBar 使用 SymbolGlyph）。Phase 5 依赖 Phase 2+3+4。Phase 6 在 Phase 5 完成后。Phase 7 最后。

## Must-NOT-Have（不做列表）
- ❌ 不修改任何业务逻辑代码
- ❌ 不修改 services/ 层文件
- ❌ 不修改 API 调用
- ❌ 不添加新功能
- ❌ 不重构页面结构/组件拆分（仅样式 — 但允许提取公共 UI 助手组件如 NavBar/StandardCard 用于统一样式）
- ❌ 不重命名已有组件或变量
- ❌ 不修改 RecruiterTypes.ets / ChatTypes.ets 等类型定义

## 子代理执行须知

每个子代理在修改前必须：
1. 加载 `hmos-design` SKILL（本 SKILL 包含完整的 HMOS 控件规范、色彩 Token、动效体系）
2. 加载 `frontend-skill` SKILL（本 SKILL 包含现代 UI 设计原则）
3. 严格按照 SKILL 中的最佳实践编写代码
4. 使用系统 Token 引用（`$r('sys.color.*')`）优先于硬编码色值
5. 使用 SymbolGlyph 优先于 Image 图标
6. 遵循 HMOS 设计规范：胶囊按钮、圆角 12/20/24vp、标准间距 8/16/24vp
