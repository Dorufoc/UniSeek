# Draft: job-tag-filter

## Intent
- **intent**: clear
- **review_required**: true (user requested high-accuracy review)
- **size**: Standard (2 files, clear feature fix)

## Summary
用户反馈：职位详情页内的分类标签点击跳转至职位列表页后，无对应的筛选功能。

## Exploration Findings

### 后端: 已完备
- `TaskSearchRequest.java` (L44): 已有 `tag` 字段
- `TaskMapper.xml` (L133-135): 已有 `task.tag LIKE CONCAT('%', #{req.tag}, '%')` SQL 筛选

### 前端 API: 已完备
- `task.ts` (L25): `TaskSearchParams` 已有 `tag?: string` 参数

### 前端 JobDetail.vue: 部分实现
- L62-64: `goToTag(tag)` 函数，导航至 `/jobs?tag=<tag>`
- L230-232: `tag-section` 渲染 `job.tag[]` 可点击标签
- L222: `job.categoryName` 展示为普通文本（不可点击）

### 前端 Jobs.vue: 断链处
- L71-81: `filter` reactive 对象没有 `tag` 字段
- L202-227: `loadTasks` 调用 `searchTasks` 时未传递 `tag` 参数
- L265-294: `onMounted` 读取 `route.query.q` 和 `route.query.categoryId`，但**未读取 `route.query.tag`**

### 用户界面模式
- categoryId 从 URL 读取后，设置了级联选择器的值和 filter.categoryId
- 没有现有的"筛选标签/chip"UI模式 — 需要新增

## Decisions Ledger

### 1. tag 筛选在 Jobs.vue 的呈现方式
- **Default**: 在搜索栏下方添加一个可关闭的筛选标签 chip，展示当前激活的 tag 筛选
- **Options considered**: ① 搜索框自动填入（推荐 — 用户可见可编辑）② 仅静默应用 ③ 筛选标签 chip
- **Rationale**: chip 方式最清晰，用户可以一眼看到当前 tag 筛选并可以一键清除

### 2. categoryName 是否改为可点击
- **Default**: 是 — 将 `job.categoryName` 改为可点击，导航至 `/jobs?categoryId=<id>`
- **Rationale**: 与 tag 筛选功能一致，完善分类标签的交互体验

### 3. 清除 tag 筛选的方式
- **Default**: 点击 chip 的关闭按钮 → `filter.tag = undefined` → 重新加载
- 重置筛选按钮也会清除 tag 筛选

## User Decisions
- 分类名称改为可点击: ✅ 同意
- tag 筛选展示方式: ✅ 标签 Chip

## High-Accuracy Review Results

### Momus 审查
- **结果**: ✅ APPROVE
- **发现**: 全部 7 个文件引用与实际源码完全匹配；后端/API 已完备；无矛盾、无范围蔓延、无未验证假设
- **关键结论**: "计划精准且可执行 — 无阻塞性问题"

### Oracle 审查
- **结果**: ✅ APPROVED（带 1 处建议）
- **发现**: 全部引用准确，技术方案合理，验收条件可测
- **建议**: Todo 2a 的 `categoryIds` 歧义 → **已修复**，现改为明确指令

### 修复
- Todo 2a: 将 `注意: 需要检查 categoryIds 是否已存在` 改为明确的 `将 categoryIds: undefined as string | undefined 补入 filter 初始对象`

## Status
- [x] Exploration complete
- [x] Decisions recorded
- [x] User interview complete
- [x] Approved
- [x] Plan generated → `.omo/plans/job-tag-filter.md`
- [x] High-accuracy review complete (Momus ✅ | Oracle ✅)
- [ ] Final verification
