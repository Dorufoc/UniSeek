# ArkTS 样式修正方案（Task 1）

## 目标
统一鸿蒙端底部操作区高度常量，补齐字号/圆角缺失档位，并替换 LoginPage 中的旧常量引用。

## 修改点

### 1. `uniseek_arkts/entry/src/main/ets/common/AppStyles.ets`

- 在 `AppSpacing` 类中新增底部固定操作区高度常量：
  ```ts
  static readonly BOTTOM_ACTION_HEIGHT = 56
  ```
  用于按钮栏、悬浮操作栏等统一高度。

- 如 `AppFontSize` 类存在，则新增 Headline 字号常量：
  ```ts
  static readonly HEADLINE = 18
  ```
  对应系统 `font_headline6`（18fp）卡片标题等级。

- 如 `AppRadius` 类存在，则新增超小圆角常量：
  ```ts
  static readonly XS = 4
  ```
  用于小标签、细小组件等。

> 所有新增均为 `static readonly`，保留已有常量，不删除任何现有内容。

### 2. `uniseek_arkts/entry/src/main/ets/pages/LoginPage.ets`

- 在第 163 行附近，将 `AppTypography.BUTTON_HEIGHT` 替换为 `AppSpacing.BOTTOM_ACTION_HEIGHT`：
  ```ts
  .margin({ bottom: AppSpacing.BOTTOM_ACTION_HEIGHT })
  ```

## 验证
- 检查 `AppStyles.ets` 中三类常量是否新增且命名/值正确。
- 检查 `LoginPage.ets` 中是否不再引用 `AppTypography.BUTTON_HEIGHT`，并正确引用 `AppSpacing.BOTTOM_ACTION_HEIGHT`。
