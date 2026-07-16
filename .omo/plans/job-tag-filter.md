# job-tag-filter - Work Plan

## TL;DR (For humans)

**要解决的问题**：职位详情页内的分类标签点击跳转至职位列表页后，无对应的筛选功能。

**采取的方法**：只需修改 2 个前端文件（`Jobs.vue` + `JobDetail.vue`），后端零改动。后端和前端 API 层已完备，断链仅在前端。
- `JobDetail.vue`：使 `job.categoryName` 可点击跳转到分类筛选；`job.tag[]` 标签已有跳转逻辑不变
- `Jobs.vue`：读取 URL 的 `tag` 参数 → 传递给后端 → 在搜索栏下方显示可关闭的筛选 chip

**不会做的事**：
- 不修改后端 Java 代码
- 不修改 API 层
- 不修改数据库
- 不涉及 ArkTS 端
- 不重构现有筛选系统

**工作量**：2 个文件，预估 30-60 分钟实现 + 验证

**风险**：低 — 改动完全独立、范围明确

**决策记录**：
- 分类名称 `categoryName` → 添加点击跳转 ✅
- 激活 tag 筛选展示 → 搜索栏下方 Chip ✅

## Scope

**In Scope**:
1. `uniseek_vue/src/pages/JobDetail.vue` — `job.categoryName` 添加 `@click` 导航至 `/jobs?categoryId=X`
2. `uniseek_vue/src/pages/Jobs.vue` — 新增 tag 筛选支持（filter + loadTasks + URL 读取）
3. `uniseek_vue/src/pages/Jobs.vue` — 新增搜索栏下方 tag 筛选 chip UI
4. `uniseek_vue/src/pages/Jobs.vue` — `resetFilters` 包含 tag 清除

**Out of Scope**:
- 后端任何修改
- API 层任何修改
- ArkTS / 鸿蒙端
- 职位列表卡片上 tag 的点击跳转（仅详情页标签跳转）
- 多 tag 组合筛选（后端只支持单 tag LIKE）

## Verification strategy

每项 todo 验收标准：
1. **分类名称点击**：点击分类名称 → URL 变为 `/jobs?categoryId=X` → 列表按该分类筛选 → 级联选择器选中该分类
2. **tag URL 参数读取**：直接访问 `/jobs?tag=包吃` → 列表仅显示含"包吃"标签的职位 → chip 显示"标签：包吃"
3. **chip 交互**：点击 chip 关闭按钮 → tag 筛选消失 → 列表重新加载全部职位
4. **重置筛选**：点击重置按钮 → tag 筛选被清除 → chip 消失

QA 方式：手动浏览器测试 + 观察 URL 和列表内容

## Execution strategy

**顺序**：Todo 1 → Todo 2 (含 3, 4) → 最终验证

Todo 1（JobDetail.vue）和 Todo 2（Jobs.vue）独立，但先做 Todo 1 便于 Todo 2 验证时直接点击详情页标签跳转。

## Todos

1. [x] JobDetail.vue — 分类名称添加点击跳转

**文件**: `uniseek_vue/src/pages/JobDetail.vue`

**改动内容**:
- 找到 L222: `<span class="meta-tag" v-if="job.categoryName">{{ job.categoryName }}</span>`
- 改为: `<span class="meta-tag category-clickable" v-if="job.categoryName" @click="goToCategory">{{ job.categoryName }}</span>`
- 在 script 中添加 `goToCategory` 函数:
  ```ts
  const goToCategory = () => {
    if (job.value?.categoryId) {
      router.push({ path: '/jobs', query: { categoryId: job.value.categoryId } })
    }
  }
  ```
- 添加样式 `.category-clickable { cursor: pointer; transition: all 0.2s; }`
- 添加 hover 样式 `.category-clickable:hover { border-color: #1762FB; color: #1762FB; }`

**References**:
- `JobDetail.vue` L62-64: `goToTag` 函数作为导航模式参考
- `Jobs.vue` L281-291: `onMounted` 中读取 `route.query.categoryId` 的现有逻辑

**Acceptance criteria**:
- 分类名称 `job.categoryName` 文本变为可点击样式（hover 变色）
- 点击后导航至 `/jobs?categoryId=<此职位的 categoryId>`
- `jobs` 页面正确读取该参数并选中对应分类

**QA (happy path)**:
1. 打开任意职位详情页 → 观察分类名称处鼠标变为手型，hover 变色
2. 点击分类名称 → 跳转到 `/jobs?categoryId=X` → 左侧分类选择器选中该项 → 列表按该分类筛选
3. 验证 URL 参数: 手动输入 `/jobs?categoryId=1` → 同样效果

**QA (failure path)**:
1. `job.categoryId` 为 null/undefined → 点击不触发导航（已用 `?.` 安全访问）

**Commit**: `feat(JobDetail): 职位分类名称支持点击跳转筛选`

---

2. [x] Jobs.vue — 添加 tag 筛选支持 + filter chip UI

**文件**: `uniseek_vue/src/pages/Jobs.vue`

**改动内容**（5 处）:

**2a. 在 `filter` reactive 对象中添加 `tag` 字段**（L71-81 区域）:

> ⚠️ 注意：当前代码中 `categoryIds` 通过 `onCategoryChange`（L177）动态赋值 `filter.categoryIds = ids.join(',')`，但未在 `filter` 初始 `reactive()` 中声明。请**同时将 `categoryIds: undefined as string | undefined` 补入 `filter` 初始对象**，以完善 TypeScript 类型推断。

```ts
const filter = reactive({
  regionId: undefined as number | undefined,
  regionIds: undefined as string | undefined,
  categoryId: undefined as number | undefined,
  categoryIds: undefined as string | undefined,
  jobType: undefined as number | undefined,
  salaryMin: undefined as number | undefined,
  salaryMax: undefined as number | undefined,
  salaryUnit: undefined as number | undefined,
  tag: undefined as string | undefined,  // ← 新增
  sortBy: 'create_time' as string,
  sortOrder: 'desc' as string
})
```

**2b. 在 `loadTasks` 中传递 `tag` 参数**（L202-227 区域）:
```ts
const result = await searchTasks({
  keyword: keyword.value || undefined,
  categoryId: filter.categoryIds ? undefined : filter.categoryId,
  categoryIds: filter.categoryIds,
  regionId: filter.regionIds ? undefined : filter.regionId,
  regionIds: filter.regionIds,
  jobType: filter.jobType,
  salaryMin: filter.salaryMin,
  salaryMax: filter.salaryMax,
  salaryUnit: filter.salaryUnit,
  tag: filter.tag,                              // ← 新增
  sortBy: filter.sortBy,
  sortOrder: filter.sortOrder,
  page: page.value,
  pageSize
})
```

**2c. 在 `onMounted` 中读取 `route.query.tag`**（L265-294 区域，在读取 categoryId 之后）:
```ts
// 读取 tag URL 参数
const tagParam = route.query.tag as string
if (tagParam) {
  filter.tag = tagParam
}
```

**2d. 在 `resetFilters` 中清除 tag**（L234-251 区域）:
```ts
const resetFilters = () => {
  filter.regionId = undefined
  filter.regionIds = undefined
  filter.categoryId = undefined
  filter.categoryIds = undefined
  filter.jobType = undefined
  filter.salaryMin = undefined
  filter.salaryMax = undefined
  filter.salaryUnit = undefined
  filter.tag = undefined                         // ← 新增
  settlementType.value = undefined
  salaryMinInput.value = undefined
  salaryMaxInput.value = undefined
  regionCascaderValue.value = []
  categoryCascaderValue.value = undefined
  keyword.value = ''
  page.value = 1
  loadTasks()
}
```

**2e. 在 template 搜索栏下方添加 filter chip UI**（在搜索栏 `<div class="search-bar">` 之后、`.jobs-body` 之前）:
```html
<!-- 激活的筛选标签 -->
<div class="active-filters" v-if="filter.tag">
  <span class="filter-chip">
    标签：{{ filter.tag }}
    <span class="chip-close" @click="clearTagFilter">&times;</span>
  </span>
</div>
```

对应的 script:
```ts
const clearTagFilter = () => {
  filter.tag = undefined
  page.value = 1
  loadTasks()
}
```

对应的 style:
```css
.active-filters {
  max-width: 1200px;
  margin: 0 auto;
  padding: 8px 24px 0;
}
.filter-chip {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 12px;
  font-size: 13px;
  background: rgba(0, 122, 255, 0.08);
  color: #1762FB;
  border: 1px solid rgba(0, 122, 255, 0.2);
  border-radius: 16px;
}
.chip-close {
  cursor: pointer;
  font-size: 16px;
  line-height: 1;
  color: #1762FB;
  opacity: 0.6;
  transition: opacity 0.2s;
}
.chip-close:hover {
  opacity: 1;
}
```

**References**:
- `JobDetail.vue` L62-64: `goToTag` 已导航至 `/jobs?tag=<tag>`
- `Jobs.vue` L281-291: `route.query.categoryId` 读取模式参考
- `Jobs.vue` L71-81: `filter` reactive 对象
- `Jobs.vue` L202-227: `loadTasks` 函数
- `Jobs.vue` L234-251: `resetFilters` 函数
- `TasksMapper.xml` L133-135: 后端 SQL `tag LIKE` 条件确认

**Acceptance criteria**:
- 直接访问 `/jobs?tag=包吃` → 列表仅显示含"包吃"标签的职位
- 搜索栏下方显示蓝色 chip「标签：包吃 ×」
- 点击 chip 的 × → 清除 tag 筛选 → 列表重新加载全部
- 点击重置筛选按钮 → tag 和其他筛选一起清除
- tag 筛选与其他筛选（分类、地区、薪资等）可同时生效

**QA (happy path)**:
1. 直接访问 `/jobs?tag=包吃` → 列表正确筛选 → chip 显示"标签：包吃"
2. 点击 chip 的 × → chip 消失 → 列表恢复全部
3. 先从详情页点击标签跳转 → URL 正确 → 筛选正常
4. tag + 分类组合筛选 → 两者同时生效
5. 点击重置 → 所有筛选清除 → chip 消失

**QA (failure path)**:
1. 访问 `/jobs?tag=`（空值）→ filter.tag 为 undefined，不触发筛选
2. 无 tag 参数正常访问 `/jobs` → 无 chip 显示
3. tag 与其他筛选冲突时（如 tag=包吃 + 分类=IT）→ 按 AND 逻辑正确返回结果

**Commit**: `feat(Jobs): 标签点击跳转筛选支持 + filter chip UI`

## Final verification wave

通过后告知用户结果，由用户确认完成。

F1. [x] 功能完整性检查
F2. [x] 回归检查（确保未破坏现有功能）
F3. [x] 浏览器兼容性

## Commit strategy

| # | Commit 信息 | 文件 |
|---|-------------|------|
| 1 | `feat(JobDetail): 职位分类名称支持点击跳转筛选` | `JobDetail.vue` |
| 2 | `feat(Jobs): 标签点击跳转筛选支持 + filter chip UI` | `Jobs.vue` |

两个 commit 顺序无关，可合并为一个 PR/提交批次。

## Success criteria

1. ✅ 用户从详情页点击任何标签 → 跳转到列表页并正确筛选
2. ✅ 用户从详情页点击分类名称 → 跳转到列表页并正确按分类筛选
3. ✅ 筛选 chip 清晰展示当前 tag 筛选，可一键关闭
4. ✅ 不影响现有任何功能
