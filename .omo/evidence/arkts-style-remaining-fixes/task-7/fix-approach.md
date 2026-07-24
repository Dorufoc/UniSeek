# Task 7 关键图标与按钮 accessibilityText 修复方案

## 1. 扫描范围与文件

本次对鸿蒙端（`uniseek_arkts`）6 个目标文件进行无障碍扫描，查找所有 `SymbolGlyph(...)` 与图标型 `Button({ type: ... })`，补充缺失的 `accessibilityText`。扫描文件如下：

- `uniseek_arkts/entry/src/main/ets/pages/ChatDetailPage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/JobDetailPage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/HomePage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/ProfilePage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/tab/recruiter/RecruiterHomeTab.ets`
- `uniseek_arkts/entry/src/main/ets/pages/tab/recruiter/RecruiterProfileTab.ets`

扫描命令：

```powershell
Select-String -Path <file> -Pattern 'SymbolGlyph\(|Button\(\{'
```

## 2. 每个目标文件预计需要补充的图标/按钮

### 2.1 ChatDetailPage.ets

| 行号 | 组件 | 父级 | 是否可聚焦 | 处理方式 |
|------|------|------|------------|----------|
| 552 | `SymbolGlyph($r('sys.symbol.doc'))` | 简历卡片 `Column` | 否（装饰性，无点击态） | 审计表中说明为装饰性图标，不新增 |
| 675 | `SymbolGlyph($r('sys.symbol.picture'))` | 菜单 `Row` | 是（菜单项） | 已由 Task 5 在父 `Row` 添加 `accessibilityText('选择图片')`，不重复 |
| 700 | `SymbolGlyph($r('sys.symbol.doc_text'))` | 菜单 `Row` | 是（菜单项） | 已由 Task 5 在父 `Row` 添加 `accessibilityText('选择文件')`，不重复 |
| 763-770 | `Button({ type: ButtonType.Circle })` 含 `xmark` | `Button` | 是 | 已由 Task 5 添加 `accessibilityText('关闭图片预览')`，不重复 |
| 787-791 | `Button()` 含 `plus` | `Button` | 是 | **新增** `accessibilityText('更多操作')` 到父 `Button` |

### 2.2 JobDetailPage.ets

| 行号 | 组件 | 父级 | 是否可聚焦 | 处理方式 |
|------|------|------|------------|----------|
| 339-344 | `Button()` 含 `star` | `Button` | 是（收藏/取消收藏） | 已存在 `accessibilityText(this.hasFavorited ? '取消收藏职位' : '收藏职位')`，不重复 |
| 365-369 | `Button()` 含 `message` | `Button` | 是（联系 HR） | 已存在 `accessibilityText('联系招聘方')`，不重复 |

### 2.3 HomePage.ets

| 行号 | 组件 | 父级 | 是否可聚焦 | 处理方式 |
|------|------|------|------------|----------|
| 882-891 | `Button({ type: ButtonType.Capsule })` 含 `magnifyingglass` | `Button` | 是（搜索入口） | 已存在 `accessibilityText('搜索职位')`，不重复 |

### 2.4 ProfilePage.ets

| 行号 | 组件 | 父级 | 是否可聚焦 | 处理方式 |
|------|------|------|------------|----------|
| 89-99 | `SymbolGlyph($r('sys.symbol.chevron_right'))` | 实名状态 `Row` | 是 | **新增** `accessibilityText('实名认证')` 到父 `Row` |
| 106-117 | `SymbolGlyph($r('sys.symbol.chevron_right'))` | 最外层个人信息 `Row` | 是（进入个人详情） | **新增** `accessibilityText('个人资料')` 到该 `SymbolGlyph`（父级无可聚焦语义） |
| 203-213 | `SymbolGlyph(icon)` | `menuItem` 父 `Row` | 是（菜单项入口） | **新增** `accessibilityText(text)` 到父 `Row`，`text` 动态为菜单标题 |
| 211-214 | `SymbolGlyph($r('sys.symbol.chevron_right'))` | 同上 | 否（装饰性箭头，父 `Row` 已承载语义） | 不新增，审计表说明 |

### 2.5 RecruiterHomeTab.ets

| 行号 | 组件 | 父级 | 是否可聚焦 | 处理方式 |
|------|------|------|------------|----------|
| 46-49 | `SymbolGlyph($r('sys.symbol.chevron_right'))` | 人才卡片 `Row` | 是（进入简历详情） | **新增** `accessibilityText('查看候选人简历')` 到父 `Row` |
| 130-137 | `Button({ type: ButtonType.Capsule })` 含 `magnifyingglass` | `Button` | 是（搜索人才） | 已存在 `accessibilityText('搜索人才')`，不重复 |

### 2.6 RecruiterProfileTab.ets

| 行号 | 组件 | 父级 | 是否可聚焦 | 处理方式 |
|------|------|------|------------|----------|
| 95-102 | `SymbolGlyph($r('sys.symbol.chevron_right'))` | 实名状态 `Row` | 是 | **新增** `accessibilityText('实名认证')` 到父 `Row` |
| 116-125 | `SymbolGlyph($r('sys.symbol.chevron_right'))` | 企业资质状态 `Row` | 是 | **新增** `accessibilityText('企业资质')` 到父 `Row` |
| 131-137 | `SymbolGlyph($r('sys.symbol.chevron_right'))` | 最外层个人信息 `Row` | 是（进入个人详情） | **新增** `accessibilityText('个人资料')` 到该 `SymbolGlyph` |
| 236-247 | `SymbolGlyph(icon)` | `menuItemCheck` 父 `Row` | 是（菜单项入口） | **新增** `accessibilityText(text)` 到父 `Row`，`text` 动态为菜单标题 |
| 244-247 | `SymbolGlyph($r('sys.symbol.chevron_right'))` | 同上 | 否（装饰性箭头） | 不新增，审计表说明 |

## 3. 无障碍标签值设计

所有新增标签使用中文，语义简洁，符合 HarmonyOS 无障碍规范：

- `更多操作`：展开聊天输入区附件菜单
- `实名认证`：进入实名认证流程
- `个人资料`：进入个人资料详情页
- `查看候选人简历`：进入简历详情
- 菜单项：复用菜单文本，如 `已投简历`、`收藏`、`个人简历`、`设置`、`账号管理`、`我的公司`、`发布职位`、`请求处理` 等
- 状态切换类标签保留已有的 `收藏职位` / `取消收藏职位`

## 4. 影响范围与回退策略

- **影响范围**：仅修改上述 6 个 `.ets` 文件，只新增 `accessibilityText` 调用，不改动业务逻辑、页面结构、状态变量、导航或样式 Token。
- **回退策略**：若验证失败，可通过 `git diff` 回滚对应行的 `.accessibilityText(...)` 链式调用；由于改动单一且独立，风险可控。
- **兼容性**：`accessibilityText` 为 ArkUI 通用属性，target SDK 6.1.1 支持，无需额外导入。
