# Task 6 修复方案：响应式断点接入与溢出保护

## 1. 要修改的文件与位置

| 文件 | 修改位置 | 修改内容 |
|---|---|---|
| `entry/src/main/ets/entryability/EntryAbility.ets` | 顶部 import、类字段、`onWindowStageCreate` 成功回调、`onWindowStageDestroy`/`onDestroy` | 引入 `BreakpointResolver` / `WindowBreakpoint`；通过 `windowStage.getMainWindowSync()` / `win.getUIContext().getMediaQuery()` 注册两条媒体查询监听器；将当前断点写入 `AppStorage`；在 Ability 销毁时统一 `off('change')` 注销 |
| `entry/src/main/ets/pages/LoginPage.ets` | 顶部 import、struct 状态、根 `Column` 与表单 `Column` 样式 | 增加 `@StorageLink('breakpoint')`；主表单 Column 限制最大宽度 420vp 并在父容器中水平居中 |
| `entry/src/main/ets/pages/RegisterPage.ets` | 顶部 import、struct 状态、主 `Column` 容器 | 增加 `@StorageLink('breakpoint')`；主 Column 套一层全屏居中外壳，限制最大宽度 420vp |
| `entry/src/main/ets/pages/tab/seeker/HomePage.ets` | 顶部 import、struct 状态、`FilterSheetBuilder` 根 Column | 增加 `@StorageLink('breakpoint')`；筛选 bindSheet 内容根 Column 保持百分比宽度并添加 `constraintSize({ maxWidth: 560 })` |

## 2. EntryAbility.ets 媒体查询注册与注销方案

- 使用 `import { mediaQuery } from '@kit.ArkUI'`（与现有 `window` 导入同源）。
- 增加类字段 `private mqListeners: mediaQuery.MediaQueryListener[] = []` 保存监听器引用。
- 在 `onWindowStageCreate` 的 `windowStage.loadContent` 成功回调中：
  1. `const win = windowStage.getMainWindowSync();`
  2. `const uiContext = win.getUIContext();`
  3. `const mq = uiContext.getMediaQuery();`
  4. 读取 `win.getWindowProperties().windowRect.width` 并写入 `AppStorage.setOrCreate('breakpoint', BreakpointResolver.resolve(rect.width));`
  5. 使用 `mq.matchMediaSync('(width < 600vp)')` 与 `mq.matchMediaSync('(width < 840vp)')` 创建监听器；回调中重新读取窗口宽度并更新 `AppStorage`。
  6. 将监听器存入 `mqListeners`。
- 在 `onWindowStageDestroy()` 中遍历 `mqListeners`，对每个监听调用 `.off('change')` 并清空数组；`onDestroy()` 中作为兜底再调用一次，避免 Ability 销毁路径差异导致泄漏。

## 3. 三页面如何读取 breakpoint 并做最小适配

- 三页面均导入 `WindowBreakpoint`。
- 在 struct 内增加：
  ```ets
  @StorageLink('breakpoint') breakpoint: WindowBreakpoint = WindowBreakpoint.COMPACT
  ```
- **LoginPage**：给底部表单主 `Column` 增加 `constraintSize({ maxWidth: 420 })`，并在其外层渐变 `Column` 上增加 `alignItems(HorizontalAlign.Center)`，保证在平板/2in1 上最大宽度不超过 420vp 且居中，手机端保持原有百分比宽度。
- **RegisterPage**：将当前根 `Column` 作为内容区，外面套一层全屏 `Column` 设置 `width('100%')`、`height('100%')`、`backgroundColor(AppColors.BG_CARD)`、`alignItems(HorizontalAlign.Center)`；原根 `Column` 保持 `width('100%')` 并增加 `constraintSize({ maxWidth: 420 })`，实现居中限制。
- **HomePage**：仅对筛选 `bindSheet` 的 builder 根 `Column` 增加 `constraintSize({ maxWidth: 560 })`，保持原有 `width('100%')` 百分比策略，不做弹窗布局大改。

## 4. 影响范围与回退策略

- 影响范围：4 个 ArkTS 文件；仅新增响应式断点状态写入与最小宽度限制，未改动业务逻辑、接口协议、导航、状态管理、TabBar 动效或 Task 3/5 已收敛的字号/颜色/导航栏。
- 回退策略：如编译失败或出现运行时布局异常，可单独移除各页面的 `constraintSize` / `alignItems` 适配，保留 EntryAbility 的媒体查询注册逻辑；或注释掉 `mqListeners` 相关代码并删除 `@StorageLink`，恢复至上一次可运行状态。
