# Task 6 变更摘要 — 响应式断点接入与溢出保护

## 修改文件

| 序号 | 文件路径 | 变更说明 |
| :--- | :--- | :--- |
| 1 | `uniseek_arkts/entry/src/main/ets/entryability/EntryAbility.ets` | 引入 `@ohos.mediaquery`，注册 `(width < 600vp)` 与 `(width < 840vp)` 两条媒体查询监听器，初始与监听回调中均通过 `getWindowProperties().windowRect.width` 计算断点并写入 `AppStorage.setOrCreate('breakpoint', ...)`；Ability 销毁时统一 `off('change')` 注销监听器。 |
| 2 | `uniseek_arkts/entry/src/main/ets/pages/LoginPage.ets` | 导入 `WindowBreakpoint`，增加 `@StorageLink('breakpoint')`，主表单宽度在 `COMPACT` 下保持 `95%`，其他断点下限制为 `420`。 |
| 3 | `uniseek_arkts/entry/src/main/ets/pages/RegisterPage.ets` | 导入 `WindowBreakpoint`，增加 `@StorageLink('breakpoint')`，主内容区宽度在 `COMPACT` 下保持 `100%`，其他断点下限制为 `420`。 |
| 4 | `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/HomePage.ets` | 导入 `WindowBreakpoint`，增加 `@StorageLink('breakpoint')`，筛选 `bindSheet` 根 Column 使用 `constraintSize({ maxWidth: ... })` 限制最大宽度（`COMPACT` 为 `100%`，其他为 `560`），保持百分比宽度策略不变。 |

## 验证结果

1. **静态检查（codelinter）**
   - 命令：`cmd /c "codelinter --exit-on error entry/src/main/ets/entryability/EntryAbility.ets entry/src/main/ets/pages/LoginPage.ets entry/src/main/ets/pages/RegisterPage.ets entry/src/main/ets/pages/tab/seeker/HomePage.ets & echo ERRORLEVEL=%ERRORLEVEL%"`
   - 结果：`Defects: 1; Errors: 0; Warns: 1; Suggestions: 0; ERRORLEVEL=0`
   - 唯一 `warn` 为 `HomePage.ets` 中已有的 `@performance/avoid-overusing-custom-component-check`，非本次引入。

2. **构建检查（hvigorw）**
   - 命令：`hvigorw assembleHap --no-daemon`
   - 结果：`BUILD SUCCESSFUL in 1m 50s`

3. **代码模式确认（Select-String）**
   - `EntryAbility.ets` 中已存在 `import mediaQuery from '@ohos.mediaquery'`、`mediaQuery.MediaQueryListener`、`getMainWindowSync()`、`getWindowProperties().windowRect`、`matchMediaSync('(width < 600vp)')`、`matchMediaSync('(width < 840vp)')`、`AppStorage.setOrCreate('breakpoint', ...)`、`listener.off('change')`。
   - `LoginPage.ets`、`RegisterPage.ets`、`HomePage.ets` 中均已存在 `import { WindowBreakpoint } from .../common/Responsive`、`@StorageLink('breakpoint') breakpoint: WindowBreakpoint = WindowBreakpoint.COMPACT`、`this.breakpoint` 条件宽度/最大宽度控制。
   - `fix-approach.md` 已存在并包含 Task 6 断点相关方案描述。

## 回退方式

- 如需回退页面布局适配，可单独移除 `LoginPage.ets`、`RegisterPage.ets`、`HomePage.ets` 中的 `@StorageLink('breakpoint')` 与相关 `width()`/`constraintSize()` 行。
- 如需回退媒体查询注册，可移除 `EntryAbility.ets` 中 `mqListeners` 相关字段、监听注册、注销逻辑及 `breakpoint` 写入逻辑，保留原始 Ability 生命周期。
