# Task 4 变更摘要

## 修改文件
- `uniseek_arkts/entry/src/main/ets/pages/MainPage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/RecruiterHomePage.ets`

## 变更要点
1. TabBar 的 `tabItem` Builder 中 `SymbolGlyph` 增加弹跳符号动效：
   ```ets
   .symbolEffect(new BounceSymbolEffect(EffectScope.WHOLE, EffectDirection.DOWN), this.currentIndex === index)
   ```
2. 选中/未选中颜色改为系统 Token：
   - 选中：`$r('sys.color.brand')`
   - 未选中：`$r('sys.color.icon_tertiary')`
3. 每个 Tab 项根 `Column` 添加 `.accessibilityText(label)`。

## SDK 兼容性说明
- `BounceSymbolEffect`、`EffectScope`、`EffectDirection` 在当前 `targetSdkVersion=6.1.1(24)` 下不是 `@kit.ArkUI` 的命名导出，也不可通过 `@ohos.arkui` 导入；它们作为全局声明直接使用。

## 验证结果
- `codelinter --exit-on error entry/src/main/ets/pages/MainPage.ets entry/src/main/ets/pages/RecruiterHomePage.ets`：No defects found。
- `hvigorw assembleHap --no-daemon`：BUILD SUCCESSFUL（仅 API 废弃 warning）。
- 对两文件均命中 `BounceSymbolEffect`、`sys.color.brand|sys.color.icon_tertiary`、`accessibilityText`。

## 影响的调用方
- 仅底部 TabBar 视觉与动效，未改动 Tab 切换逻辑与导航。
