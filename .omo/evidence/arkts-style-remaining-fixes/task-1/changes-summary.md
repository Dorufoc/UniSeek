# ArkTS 样式变更汇总（Task 1）

## 变更文件

### 1. `uniseek_arkts/entry/src/main/ets/common/AppStyles.ets`

| 行号 | 所在类 | 变更内容 |
|------|--------|----------|
| 65   | `AppSpacing` | 新增 `static readonly BOTTOM_ACTION_HEIGHT = 56;` |
| 85   | `AppFontSize` | 新增 `static readonly HEADLINE = 18;` |
| 70   | `AppRadius` | 新增 `static readonly XS = 4;` |

**关键新增代码片段：**

```ts
// AppSpacing 类
// 底部固定操作区高度（按钮栏、悬浮操作栏等）
static readonly BOTTOM_ACTION_HEIGHT = 56;
```

```ts
// AppFontSize 类
// Headline：卡片标题等级字号，对应系统 font_headline6（18fp）
static readonly HEADLINE = 18;
```

```ts
// AppRadius 类
static readonly XS = 4;
```

### 2. `uniseek_arkts/entry/src/main/ets/pages/LoginPage.ets`

| 行号 | 变更内容 |
|------|----------|
| 163  | `.margin({ bottom: AppTypography.BUTTON_HEIGHT })`<br>↓<br>`.margin({ bottom: AppSpacing.BOTTOM_ACTION_HEIGHT })` |

## 结果
- 底部操作区高度统一收敛到 `AppSpacing.BOTTOM_ACTION_HEIGHT`。
- `AppTypography.BUTTON_HEIGHT` 在 `LoginPage.ets` 中不再被引用。
- 现有常量全部保留，未删除任何内容。
