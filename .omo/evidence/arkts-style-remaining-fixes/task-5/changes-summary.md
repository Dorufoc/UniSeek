# Task 5 变更摘要 — ChatDetailPage 导航栏扩展与消息气泡 / 操作菜单规范

## 1. 范围
- 仅涉及 `uniseek_arkts/entry/src/main/ets/common/NavBar.ets` 与 `uniseek_arkts/entry/src/main/ets/pages/ChatDetailPage.ets` 的视觉/结构代码。
- 不改动业务逻辑、Service、WebSocket、消息发送/加载/预览/附件下载逻辑，也不影响 Task 3 已收敛的 Token 引用。

## 2. 修改文件清单

| 文件 | 说明 |
| --- | --- |
| `uniseek_arkts/entry/src/main/ets/common/NavBar.ets` | 新增 `centerContent` BuilderParam 与默认 Builder; 中间标题区改为可插槽的居中结构。 |
| `uniseek_arkts/entry/src/main/ets/pages/ChatDetailPage.ets` | 删除 `customHeader()`；新增 `chatHeaderCenter()` 使用扩展后的 `NavBar`；将操作菜单 emoji 图标替换为 `SymbolGlyph` 并添加 `accessibilityText`；补齐消息气泡剩余硬编码 `space`/`translate` Token 引用。 |

## 3. 关键改动与行号

### 3.1 NavBar.ets
- **行 38-39**：新增中间内容 BuilderParam。
  ```ets
  /** 中间内容区域插槽 */
  @BuilderParam centerContent: () => void = this.defaultCenterContent
  ```
- **行 43-52**：新增默认 Builder `defaultCenterContent()`，使用 `AppFontSize.LG` / `AppColors.TEXT_PRIMARY` 渲染标题，并通过 `layoutWeight(1)` + `textAlign(TextAlign.Center)` 保持居中。
- **行 82-88**：中间区由固定标题 `Text(this.title)` 改为弹性插槽：
  ```ets
  Row() {
    this.centerContent()
  }
  .layoutWeight(1)
  .justifyContent(FlexAlign.Center)
  .alignItems(VerticalAlign.Center)
  ```
- 左侧返回区（行 62-80）与右侧操作区（行 91-96）仍保持 72vp 占位，确保标题/自定义中心内容居中对称。

### 3.2 ChatDetailPage.ets
- **行 11**：导入 `NavBar`。
- **行 310-318**：`build()` 中删除 `customHeader()`，改为：
  ```ets
  Column() {
    NavBar({
      showBack: true,
      centerContent: this.chatHeaderCenter
    })
  }
  .width('100%')
  .borderWidth({ bottom: 1 })
  .borderColor({ bottom: AppColors.BORDER })
  ```
- **行 384-397**：新增 `@Builder chatHeaderCenter()`，包含两行居中 `Text`（聊天对象名字 + 职位标题），使用 `AppFontSize` / `AppColors` Token。
- **行 659-719**：`actionMenuOverlay` 中：
  - 发送图片：emoji `📷` → `SymbolGlyph($r('sys.symbol.picture'))`，并添加 `.accessibilityText('选择图片')`。
  - 发送简历：emoji `📄` → `SymbolGlyph($r('sys.symbol.doc_text'))`，并添加 `.accessibilityText('选择文件')`。
  - 图标 `sys.symbol.photo` 在当前 SDK 中不存在，改用语义相近且编译通过的 `sys.symbol.picture`。
- **行 428、478、785**：消息气泡中的 `Row({ space: AppSpacing.SM_PLUS })`。
- **行 470、523**：消息气泡过渡 `transition({ opacity: 0, translate: { y: AppSpacing.SM_PLUS } })`。

## 4. 验证结果

### 4.1 codelinter
```powershell
cmd /c "codelinter --exit-on error entry/src/main/ets/pages/ChatDetailPage.ets entry/src/main/ets/common/NavBar.ets > NUL 2>&1 & echo CODELINT_EXIT=%errorlevel%"
# CODELINT_EXIT=0
```
- 输出日志：`Defects: 1; Errors: 0; Warns: 1; Suggestions: 0`
- 唯一警告为 `NavBar.ets:31` 的 `avoid-overusing-custom-component-check`，属于项目已有配置问题，非本次引入。

### 4.2 构建
```powershell
cmd /c "hvigorw assembleHap --no-daemon > C:\...\hvigorw-task5.log 2>&1 & echo HVIGOR_EXIT=%errorlevel%"
# HVIGOR_EXIT=0
```
- 日志最终输出：`BUILD SUCCESSFUL in 2 s 506 ms`
- 仅存在已有的 signingConfigs 警告 ArkTS/performance warning，无新增编译错误。

### 4.3 emoji 清理
```powershell
python -c "...emoji regex..."
# NO_EMOJI_FOUND
```

### 4.4 扩展验证
- `centerContent` / `layoutWeight` / `justifyContent(FlexAlign.Center)` 在 `NavBar.ets` 与 `ChatDetailPage.ets` 中均出现 ≥2 处。
- `ChatDetailPage.ets` 中 `\.(fontSize|borderRadius|height|width)\([0-9]+(\.[0-9]+)?\)` 命中数为 0。

## 5. 遗留风险与说明
- `sys.symbol.photo` 资源在当前 SDK 不存在；已改用 `sys.symbol.picture`。若设计规范后续要求严格使用 `photo`，需等 SDK 更新或导入自定义 SVG 图标。
- `NavBar` 组件的 `avoid-overusing-custom-component-check` 警告已存在；(component-vs-builder) 的大规模重构不在本次范围内，但本次扩展未增加新的自定义组件数量或调用点。
- 页面侧通过外层 `Column` 设置底部边框来复现原 `customHeader()` 分隔线；若后续希望 NavBar 自身携带边框，可在 NavBar `build()` 末尾追加 modifier，但当前保持最小化修改。
