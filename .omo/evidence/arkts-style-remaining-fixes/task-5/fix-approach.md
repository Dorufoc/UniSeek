# Task 5 修复方案 — ChatDetailPage 导航栏扩展与消息气泡 / 操作菜单规范

## 1. 要修改的文件与位置

- `uniseek_arkts/entry/src/main/ets/common/NavBar.ets`
  - 在 `@BuilderParam rightContent` 之前新增 `@BuilderParam centerContent`。
  - 新增默认 Builder `defaultCenterContent()` 渲染现有标题 `Text(this.title)`。
  - 将中间标题区替换为 `Row() { this.centerContent() }.layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)`，保证自定义内容也居中。
- `uniseek_arkts/entry/src/main/ets/pages/ChatDetailPage.ets`
  - 删除 `customHeader()` Builder（原约 377-417 行）。
  - 在组件内新增 `@Builder chatHeaderCenter()`，并通过 `NavBar({ showBack: true, centerContent: this.chatHeaderCenter })` 使用扩展后的导航栏。
  - 检查 `myMessageItem`、`otherMessageItem`、`resumeMessageItem` 的字号/颜色/padding 是否全部使用 `AppFontSize` / `AppColors` / `AppSpacing` / `AppRadius`，仅补齐未被收敛的硬编码。
  - 将 `actionMenuOverlay` 中菜单开头的 emoji 图标 📷 / 📄 替换为 `SymbolGlyph`，并为每个菜单项父级 `Row` 添加 `accessibilityText`。

## 2. NavBar 如何扩展

- 新增字段：
  ```ets
  @BuilderParam centerContent: () => void = this.defaultCenterContent
  ```
- 新增默认 Builder：
  ```ets
  @Builder
  defaultCenterContent() {
    Text(this.title)
      .fontSize(AppFontSize.LG)
      .fontWeight(FontWeight.Bold)
      .fontColor(AppColors.TEXT_PRIMARY)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
  }
  ```
- 中间区域改为：
  ```ets
  Row() {
    this.centerContent()
  }
  .layoutWeight(1)
  .justifyContent(FlexAlign.Center)
  .alignItems(VerticalAlign.Center)
  ```
- 未传入 `centerContent` 时，默认 Builder 渲染标题，字号/颜色保持 `AppFontSize.LG` / `AppColors.TEXT_PRIMARY`，仍居中显示。
- 左侧无返回按钮时仍保持 72vp 占位，右侧仍固定 72vp 占位，标题/自定义中心内容继续居中对称。

## 3. ChatDetailPage 的 customHeader() 如何替换为 NavBar

- 删除 `@Builder customHeader()` 方法体，避免与公共组件重复。
- 在 `ChatDetailPage` 中新增：
  ```ets
  @Builder chatHeaderCenter() {
    Column() {
      Text(this.counterpartName || '聊天')
        .fontSize(AppFontSize.LG)
        .fontColor(AppColors.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
      Text(this.taskTitle || '职位沟通')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_MUTED)
    }
    .alignItems(HorizontalAlign.Center)
  }
  ```
- 在 `build()` 中：
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
- 保留返回按钮行为：NavBar 默认 `showBack: true` 时使用 `router.back()`，与当前 `customHeader()` 一致，无需额外传 `onBack`。
- 原 `customHeader()` 中的底部边框由页面侧 `Column` 包裹 `NavBar` 并设置 `.borderWidth({ bottom: 1 })` / `.borderColor({ bottom: AppColors.BORDER })` 复现。

## 4. emoji 图标替换方案与无障碍标签值

- 操作菜单 `actionMenuOverlay` 中有两行菜单：
  - 发送图片：emoji `📷` → `SymbolGlyph($r('sys.symbol.picture')).fontSize(AppFontSize.XL).fontColor([AppColors.PRIMARY])`
    - 说明：当前 SDK 中 `sys.symbol.photo` 资源不存在，编译报错 "Unknown resource name 'photo'"；使用语义相近且已验证存在的 `sys.symbol.picture` 替代。
  - 发送简历：emoji `📄` → `SymbolGlyph($r('sys.symbol.doc_text')).fontSize(AppFontSize.XL).fontColor([AppColors.PRIMARY])`
- 为每个菜单项所在的父级 `Row` 追加 `.accessibilityText(...)`：
  - 发送图片行：`accessibilityText('选择图片')`
  - 发送简历行：`accessibilityText('选择文件')`
- 保持菜单项的行高、padding、点击行为、stateStyles、过渡动画不变。

## 5. 影响范围与回退策略

- 影响范围：
  - 仅修改 `NavBar.ets` 与 `ChatDetailPage.ets` 的视觉/结构代码。
  - 不改动 `ChatService`、`ChatWebSocketService`、消息发送/加载/预览/附件下载逻辑、WebSocket 回调。
  - 不改动 Task 3 已收敛的 Token 引用；本次检查将少量剩余硬编码 `space: 12` / `translate: { y: 12 }` 替换为 `AppSpacing.SM_PLUS`。
- 回退策略：
  - 若扩展后的 NavBar 导致其他页面调用方出现布局异常，可保留当前默认 Builder 继续使用；`centerContent` 为非必填 BuilderParam，默认行为与旧版本完全一致。
  - 若 `customHeader()` 删除后仍有引用，此文件内仅 `build()` 一处使用，删除后不会有悬空引用；编译器会验证。
