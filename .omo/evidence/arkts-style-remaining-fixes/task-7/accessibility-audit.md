# Task 7 图标/按钮 accessibilityText 审计表

> 审计日期：2026-07-24
> 审计对象：`uniseek_arkts/entry/src/main/ets/pages` 下 6 个目标文件的所有 `SymbolGlyph(...)` 与图标型 `Button({ type: ... })`。
> 原则：优先在父级 `Button` / `Row` / `Column` 上补充 `accessibilityText`，避免在同一可聚焦组件内重复设置。

---

## 1. ChatDetailPage.ets

| 行号 | 组件/图标 | 父级组件与行号 | 处理方式 | accessibilityText 值 | 未新增原因（如适用） |
|------|-----------|----------------|----------|------------------------|----------------------|
| 552 | `SymbolGlyph($r('sys.symbol.doc'))` | 简历附件卡片 `Column`（约 547-626 行，无 onClick） | 不新增 | - | 装饰性图标；父卡片已有文本标签“简历附件”说明语义，且该区域不可聚焦 |
| 675 | `SymbolGlyph($r('sys.symbol.picture'))` | 操作菜单 `Row`（约 674-696 行） | 已存在 | `选择图片` | 父 `Row` 在 Task 5 已添加（第 688 行），本次不重复 |
| 700 | `SymbolGlyph($r('sys.symbol.doc_text'))` | 操作菜单 `Row`（约 699-721 行） | 已存在 | `选择文件` | 父 `Row` 在 Task 5 已添加（第 713 行），本次不重复 |
| 763-764 | `Button({ type: ButtonType.Circle })` + `xmark` | `Button`（第 763-775 行） | 已存在 | `关闭图片预览` | Task 5 已处理（第 770 行），本次不重复 |
| 787-791 | `Button()` + `plus` | `Button`（第 787-808 行） | **本次新增** | `更多操作` | - |

---

## 2. JobDetailPage.ets

| 行号 | 组件/图标 | 父级组件与行号 | 处理方式 | accessibilityText 值 | 未新增原因（如适用） |
|------|-----------|----------------|----------|------------------------|----------------------|
| 339-340 | `Button()` + `star` | `Button`（第 339-345 行） | 已存在 | `收藏职位` / `取消收藏职位` | 父 `Button` 已设置（第 344 行），本次不重复 |
| 365-366 | `Button()` + `message` | `Button`（第 365-370 行） | 已存在 | `联系招聘方` | 父 `Button` 已设置（第 369 行），本次不重复 |

---

## 3. HomePage.ets

| 行号 | 组件/图标 | 父级组件与行号 | 处理方式 | accessibilityText 值 | 未新增原因（如适用） |
|------|-----------|----------------|----------|------------------------|----------------------|
| 882-883 | `Button({ type: ButtonType.Capsule })` + `magnifyingglass` | `Button`（第 882-891 行） | 已存在 | `搜索职位` | 父 `Button` 已设置（第 890 行），本次不重复 |

---

## 4. ProfilePage.ets

| 行号 | 组件/图标 | 父级组件与行号 | 处理方式 | accessibilityText 值 | 未新增原因（如适用） |
|------|-----------|----------------|----------|------------------------|----------------------|
| 89 | `SymbolGlyph($r('sys.symbol.chevron_right'))` | 实名状态 `Row`（约 84-101 行） | 本次新增（父级） | `实名认证` | - |
| 107 | `SymbolGlyph($r('sys.symbol.chevron_right'))` | 个人信息头部 `Row`（约 72-117 行，该图标自身可点击） | 本次新增（自身） | `个人资料` | - |
| 205 | `SymbolGlyph(icon)` | 菜单项 `Row`（约 201-226 行） | 不单独新增 | 由父 `Row` 覆盖 | 父 `Row` 本次新增动态标签 `accessibilityText(text)`（第 220 行），左侧图标语义已被菜单标题覆盖 |
| 213 | `SymbolGlyph($r('sys.symbol.chevron_right'))` | 同上 | 不新增 | - | 装饰性箭头；父 `Row` 已承载完整语义 |

菜单项实例（由 `menuItem` builder 产生，父 `Row` accessibilityText 随 `text` 变化）：

- `已投简历`（第 148 行调用）
- `收藏`（第 150 行调用）
- `个人简历`（第 152 行调用）
- `设置`（第 154 行调用）
- `账号管理`（第 156 行调用）

---

## 5. RecruiterHomeTab.ets

| 行号 | 组件/图标 | 父级组件与行号 | 处理方式 | accessibilityText 值 | 未新增原因（如适用） |
|------|-----------|----------------|----------|------------------------|----------------------|
| 46 | `SymbolGlyph($r('sys.symbol.chevron_right'))` | 人才卡片 `Row`（约 21-59 行） | 本次新增（父级） | `查看候选人简历` | - |
| 131-132 | `Button({ type: ButtonType.Capsule })` + `magnifyingglass` | `Button`（第 130-138 行） | 已存在 | `搜索人才` | 父 `Button` 已设置（第 137 行），本次不重复 |

---

## 6. RecruiterProfileTab.ets

| 行号 | 组件/图标 | 父级组件与行号 | 处理方式 | accessibilityText 值 | 未新增原因（如适用） |
|------|-----------|----------------|----------|------------------------|----------------------|
| 95 | `SymbolGlyph($r('sys.symbol.chevron_right'))` | 实名状态 `Row`（约 90-106 行） | 本次新增（父级） | `实名认证` | - |
| 117 | `SymbolGlyph($r('sys.symbol.chevron_right'))` | 企业资质状态 `Row`（约 108-125 行） | 本次新增（父级） | `企业资质` | - |
| 133 | `SymbolGlyph($r('sys.symbol.chevron_right'))` | 个人信息头部 `Row`（约 78-137 行，该图标自身可点击） | 本次新增（自身） | `个人资料` | - |
| 239 | `SymbolGlyph(icon)` | 菜单项 `Row`（约 234-257 行） | 不单独新增 | 由父 `Row` 覆盖 | 父 `Row` 本次新增动态标签 `accessibilityText(text)`（第 254 行），左侧图标语义已被菜单标题覆盖 |
| 247 | `SymbolGlyph($r('sys.symbol.chevron_right'))` | 同上 | 不新增 | - | 装饰性箭头；父 `Row` 已承载完整语义 |

菜单项实例（由 `menuItemCheck` builder 产生，父 `Row` accessibilityText 随 `text` 变化）：

- `我的公司`（第 166 行调用）
- `发布职位`（第 174 行调用）
- `请求处理`（第 182 行调用）
- `设置`（第 186 行调用）
- `账号管理`（第 190 行调用）

---

## 7. 审计结论

- 已新增 `accessibilityText` 的组件：6 处（ChatDetailPage 加号按钮、ProfilePage 实名/个人资料/菜单、RecruiterHomeTab 人才卡片、RecruiterProfileTab 实名/企业资质/个人资料/菜单）。
- 已存在且保留的 `accessibilityText`：ChatDetailPage 菜单与关闭按钮、JobDetailPage 收藏与联系按钮、HomePage 搜索按钮、RecruiterHomeTab 搜索按钮。
- 明确未新增且已说明原因：
  - ChatDetailPage 简历附件 `doc` 图标（装饰性，卡片已有文本标签）；
  - ProfilePage / RecruiterProfileTab 菜单右侧 `chevron_right`（装饰性箭头，父 `Row` 已覆盖）；
  - ProfilePage / RecruiterProfileTab 菜单左侧动态 `icon`（父 `Row` 使用菜单标题作为标签，已覆盖）。
- 目标文件内无未说明遗漏。
