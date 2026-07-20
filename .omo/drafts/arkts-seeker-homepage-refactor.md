# Draft: arkts-seeker-homepage-refactor

## State
- intent: **CLEAR**
- review_required: **true** (高精度审查)
- status: **awaiting-approval** ✅ 双审查已通过
- plan_file: `.omo/plans/arkts-seeker-homepage-refactor.md` (已存在)
- draft_version: 3

## High-Accuracy Review Summary
- **Round 1 — Momus**: REJECT → 修正 → **Round 2 APPROVE** ✅
- **Round 1 — Oracle**: REJECT → 修正 → **Round 2 APPROVE** ✅
- **Fixes applied**: 9 个修复（6 CRITICAL + 2 MAJOR + 1 MINOR），全部已修正并通过验证

## High-Accuracy Review Log
### Round 1 — Momus 审查结果
- Verdict: REJECT
- Momus session: ses_0818f9554ffefTMEWjHh2Lznoz
- Top issues: (1) SymbolGlyph 参数语法错误, (2) scrollable 非 Tabs 构造参数, (3) @State + Map 响应式陷阱
- Fix: 全部已修正

### Round 1 — Oracle 审查结果
- Verdict: REJECT
- Oracle session: ses_0818f8ae1ffehv1X2ff4XbEK8L
- Top issues: (1) -> 运算符不存在, (2) scrollable 构造参数, (3) @State 内联对象类型, (4) Curve.Emphasized 不存在, (5) .blur() 磨砂错误
- Fix: 全部已修正

### Round 1 — 修正摘要（Applied Fixes）
| # | 问题 | 文件位置 | 修正 |
|---|------|---------|------|
| C1 | `->SearchPage` 无效运算符 | Todo 4 | 改为 `() => { router.pushUrl(...) }` |
| C2 | `scrollable: true` 在 Tabs 构造器 | Todo 4 | 改为链式 `.scrollable(true)` |
| C3 | `@State` 内联对象类型 + `Map` | Todo 3 | 提取为命名接口 `TabDataState`/`FilterState`；`Map` 改为 `Record<number, TabDataState>` |
| C4 | `Curve.Emphasized` 不存在 | Todo 10 | 替换为 `Curve.cubicBezier(0.2, 0, 0, 1.0)` + 项目常量；Tabs 曲线说明不可自定义 |
| C5 | `backgroundBlurStyle: X` 属性语法 | Todo 8 | 改为链式 `.backgroundBlurStyle(X)` |
| C6 | `.blur(N)` 磨砂模糊文字 | Todo 8 | 全部改为 `.backgroundBlurStyle()` + `uiMaterial` |
| M1 | `SymbolGlyph(magnifyingglass)` | Todo 4 | 改为 `$r('sys.symbol.magnifyingglass')` |
| M2 | `.animationDuration()` + 曲线 | Todo 10 | 分离为 `.animation({ duration, curve })` 独立使用 |
| M3 | 阴影 rgba 格式 | Todo 6, 9 | 改为 ARGB 十六进制 |
| M5 | 未使用的收藏 API | Todo 1 | 移除 `addFavorite`/`removeFavorite` |

## 设计决策记录

### 决策 1：纯内容横向卡片（无头像、无按钮）
- 卡片只展示：标题 | 薪资 | 标签 | 企业名·地点
- 无企业头像/Logo，无投递/收藏按钮
- 点击整张卡片 → 过渡动画 → JobDetailPage
- 视觉类比：像极简信息卡片，干净无干扰

### 决策 2：Tabs 替代 SegmentButton
- 使用 ArkUI 原生 Tabs 组件替代 SegmentButton
- 三个 TabContent：全职(1) | 兼职(2) | 实习(3)
- 左右滑动切换 + 点击标签切换
- 每个 Tab 独立管理数据加载

### 设计参考
- 照片应用风格 → 极简信息流浏览体验
- 模糊材质 → HMOS `.blur()` + `BlurStyle`
- 光感效果 → 品牌色泛光阴影 + 渐变背景
- 引力动效 → TransitionEffect + Curve.Emphasized

## 首页新架构

```
Column (全屏)
├── TopBar (极简: "发现职位" 标题 + 搜索图标)
│   └── 背景: rgba(255,255,255,0.82) + .blur(25)
├── FilterBar (薪资/区域/类型 筛选芯片)
│   ├── [薪资] 芯片 → 弹出 SalaryDialog
│   ├── [区域] 芯片 → 弹出 RegionDialog
│   └── [类型] 芯片 → 弹出 TypeDialog
│   └── 背景: rgba(255,255,255,0.85) + .blur(15)
├── Tabs (全职 | 兼职 | 实习) ← 左右滑动切换
│   ├── TabContent "全职" → JobFeedList(1) ← 独立加载
│   │   └── List { JobFeedCard[], onReachEnd 翻页 }
│   ├── TabContent "兼职" → JobFeedList(2)
│   │   └── List { JobFeedCard[], onReachEnd 翻页 }
│   └── TabContent "实习" → JobFeedList(3)
│       └── List { JobFeedCard[], onReachEnd 翻页 }
```

## 卡片设计

```
┌────────────────────────────────────────┐
│  前端开发工程师            ¥15K-25K/月   │ ← 标题左(16fp,Bold) 薪资右(15fp,Brand)
│  [全职] [React] [TypeScript]            │ ← 标签胶囊(11fp,浅灰底)
│  某某科技 · 北京市海淀区                 │ ← 企业+地点(13fp,灰色)
└────────────────────────────────────────┘
  ↑ 点击 → pageTransition 过渡动画 → JobDetailPage
```

## 否决的设计方案

| 方案 | 否决原因 |
|------|---------|
| SegmentButton 内联切换 | 改为 Tabs 多页切换，支持滑动 |
| 垂直卡片含头像/按钮 | 改为极简横向内容卡 |
| 分类轮播/Hero/热门公司 | 照片风格应极简，移除多余区段 |
| CSS backdrop-filter | 必须用 HMOS 原生 .blur() |
