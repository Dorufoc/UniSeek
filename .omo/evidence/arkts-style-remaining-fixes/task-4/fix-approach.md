# Task 4 修复方案

## 目标
为 `MainPage.ets` 与 `RecruiterHomePage.ets` 的底部 TabBar `tabItem` Builder 添加：
1. 切换时的 `BounceSymbolEffect` 弹跳符号动效。
2. 未选中/选中图标与文字分别使用系统色 `sys.color.icon_tertiary`、`sys.color.brand`。
3. 每个 Tab 项根 `Column` 添加无障碍标签 `.accessibilityText(label)`。

## 改动点

### 导入补充
-two 文件均从 `@kit.ArkUI` 补充导入：
```ets
import { BounceSymbolEffect, EffectScope, EffectDirection, router } from '@kit.ArkUI';
```
保留原有 `router` 导入，避免破坏现有引用结构。

### tabItem Builder
- `SymbolGlyph` 新增：
  ```ets
  .symbolEffect(new BounceSymbolEffect(EffectScope.WHOLE, EffectDirection.DOWN), this.currentIndex === index)
  ```
- 图标与文字的 `fontColor` 由 `AppColors.PRIMARY / TEXT_MUTED` 改为：
  ```ets
  this.currentIndex === index ? $r('sys.color.brand') : $r('sys.color.icon_tertiary')
  ```
- 根 `Column` 追加：
  ```ets
  .accessibilityText(label)
  ```

### 不变项
- Tab 切换逻辑（`Tabs.onChange`）保持不变。
- Tab 数量、标签文案、图标资源保持不变。
- 不修改 Java / Vue / services / api / models。

## 验证计划
1. `codelinter --exit-on error` 对修改的两文件返回 0。
2. `Select-String` 命中 `BounceSymbolEffect`、`sys.color.icon_tertiary`、`sys.color.brand`、`accessibilityText`。
3. `hvigorw assembleHap --no-daemon` BUILD SUCCESSFUL。
