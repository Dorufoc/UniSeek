# ArkTS 前端样式重构 - 草稿

## 元信息
- **Slug**: arkts-style-refactor
- **Intent**: CLEAR
- **Review Required**: false
- **Status**: drafting

## 决策记录

**Status**: reviewed-and-fixed
**Review Type**: 高精度审查（Momus + Oracle）
**Review Result**: `需修改` — 已修复 3 项 P1/P2 问题（补充 ResumeDetailPage、串行化 Phase 1→2、细化 QA 用例）
**Pending Action**: write .omo/plans/arkts-style-refactor.md（已完成）
**Approach**: 7 Phase 重构，20 个 Todo，按依赖顺序执行

### 设计方向
1. **设计哲学**: 采用 HMOS "One·Harmonious·Universe" 设计理念 + frontend-skill "克制、品质、现代"原则
2. **强调色**: #1762FB 保持不变（AppColors.PRIMARY）
3. **图标系统**: 从 Image + png 迁移到 HMOS SymbolGlyph / SymbolSpan
4. **色彩系统**: 使用 HMOS sys.color Token 体系 + 自定义品牌色 #1762FB
5. **动效系统**: 采用 HMOS 引力动效体系（Gravity Animation）
6. **布局原则**: Linear-style 克制型 UI，减少不必要的卡片，强化层次和间距
7. **字体排印**: HarmonyOS Sans 系统字体，使用 TextTypes 规范

### 范围界定
- **范围**: uniseek_arkts/entry/src/main/ets/ 下所有 .ets 文件
- **不涉及**: 业务逻辑重构、API 调用修改、services 层重构
- **保留**: 所有原始功能、交互逻辑、数据流

### 已知问题清单（代码审查发现）
1. 大量硬编码 `#007AFF`（iOS 蓝）而非使用品牌色 `#1762FB`
2. 所有图标使用 Image + png 资源，未使用 SymbolGlyph
3. 颜色散落在各页面中，未统一使用 AppColors 常量
4. 导航栏在每个页面重复实现（手动 Row + Image + Text 模式）
5. 缺少页面转场动效
6. 卡片设计风格陈旧（简单的白色+阴影）
7. TabBar 使用 Image 图标而非 SymbolGlyph
8. 颜色 `#F5F5F5`、`#333333`、`#999999` 等在各页面中硬编码
9. 弹窗风格不统一（CustomDialog vs AlertDialog 混用）
10. 渐变背景仅在 ProfilePage 使用，且风格不统一
11. 消息气泡设计简单
12. 按钮风格不统一（部分使用 Button 组件，部分使用 Text+Border 模拟按钮）

### 无须提问的默认决策
- 迁移 Image 图标 → SymbolGlyph（HMOS 最佳实践）
- 替换 `#007AFF` → `#1762FB`（品牌色统一）
- 使用 sys.color 系统Token 替换硬编码中性色
- 替换硬编码颜色为 AppColors 常量引用
- 使用 HMOS 标准动效曲线替代普通 Curve
- 新增 NavigationBar 公共组件（统一顶部导航栏）
- 删除不必要的卡片容器
- 使用 `bindSheet` 替代部分 CustomDialog
- 应用 HMOS 6 大动效原则

## 探索记录
- 已读取全部 45 个 .ets 文件
- 已加载 hmos-design 完整 SKILL 及关键 references
- 已加载 frontend-skill 完整 SKILL
- 已确认 brand 颜色 = #1762FB
