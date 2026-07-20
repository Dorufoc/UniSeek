# T11 全链路数据联调验证报告

**验证日期**: 2026-07-20
**验证范围**: ApiClient.searchTasks -> loadTabData -> JobFeedList UI 渲染
**源文件版本**: 基于当前工作区最新提交

---

## 链路1：Tab 切换加载

**源文件**: HomePage.ets lines 745-752, 921-924

| 验证点 | 结果 | 说明 |
|-------|:----:|------|
| index->jobType 映射 | OK | const jobTypes = [1, 2, 3] -> 0->1(全职), 1->2(兼职), 2->3(实习) |
| 懒加载（仅首次切换加载） | OK | if (state.jobs.length === 0 && !state.loading) |
| Tab 切换后不丢失已有数据 | OK | 每个 jobType 独立存储在 Record<number, TabDataState> 中 |
| 初始加载触发 | OK | aboutToAppear() 中调用 loadTabData(1, false) |

**结论**: 链路1 数据流正确，所有验证点通过。

---

## 链路2：loadTabData(jobType, append)

**源文件**: HomePage.ets lines 691-733

### 参数构造 (lines 700-708)

| 验证点 | 结果 | 说明 |
|-------|:----:|------|
| 参数包含 jobType (1/2/3) | OK | 直接传入 jobType 参数 |
| append=true 时 page 递增 | OK | append ? state.page + 1 : 1 |
| pageSize 固定为 10 | OK | 硬编码为 10 |
| salaryMin/salaryMax/regionId 传递 | BUG | 详见下方说明 |
| append=true 时数据追加 | OK | jobs: append ? [...state.jobs, ...newJobs] : newJobs |
| append=false 时数据替换 | OK | 同上，非追加模式直接替换 |
| page 存储服务端返回值 | OK | page: result.page |
| hasMore 判断 | OK | result.page < result.totalPages |
| @State 响应式更新 | OK | 新建 tabData 对象再赋值 |
| try-catch 错误处理 | OK | lines 723-731 |
| 错误时 loading=false | OK | catch 块中设置 loading: false |
| 加载锁 | OK | if (state.loading || ...) return |

### BUG 发现：filterState 未与筛选 UI 连接

**问题描述**:
- loadTabData() 从 this.filterState 读取筛选参数 (lines 704-707)
- filterState 初始化: { salaryMin: 0, salaryMax: 0, regionId: 0 }
- 但筛选对话框/清除回调更新的是独立状态变量，而非 filterState
- filterState 自初始化后从未被修改过

**影响**: 用户设置的筛选参数永远不会传递到 API 请求中。

**建议修复**: 在 loadTabData 中使用 this.salaryMin / this.salaryMax 替代 this.filterState 中的对应字段

---

## 链路3：loadMoreForTab / onReachEnd

**源文件**: HomePage.ets lines 754-756, JobFeedList.ets line 71

| 验证点 | 结果 | 说明 |
|-------|:----:|------|
| onReachEnd 触发 loadMore | OK | JobFeedList.ets:71 |
| loadMoreForTab 调用 loadTabData(append=true) | OK | HomePage.ets:754-756 |
| 重复加载防护（loading 锁） | OK | loadTabData 中检查 state.loading |

### 问题发现：hasMore 不在 loadMore 时检查

**问题描述**:
- loadTabData 中 append=true 模式只检查 state.loading，不检查 state.hasMore
- 在已全部展示状态下，用户继续滑动仍会触发不必要的 API 请求

**影响**: 低。服务器返回空数据，代码不会崩溃但浪费一次网络请求。

---

## 链路4：筛选联动

**源文件**: HomePage.ets lines 735-743, 779-833

| 验证点 | 结果 | 说明 |
|-------|:----:|------|
| 三个 Tab 全部重置 | OK | resetAllTabs() 重建完整 tabData |
| 当前 Tab 自动重新加载 | OK | 最后调用 loadTabData(currentType, false) |
| 筛选参数传递 | BUG | 同链路2 - filterState 未连接 |

**流程追踪**:
用户选择筛选 -> 对话框 onConfirm -> 更新独立变量 -> resetAllTabs() -> loadTabData() -> 读取 filterState (BUG)

---

## 链路5：searchTasks API 调用

**源文件**: ApiClient.ets lines 55-88

| 验证点 | 结果 | 说明 |
|-------|:----:|------|
| HTTP 方法 | OK | GET 请求 |
| URL 路径 | OK | /api/tasks |
| 参数映射 | OK | 所有可选参数通过 Array<[string, string]> 传递 |
| 参数过滤 | OK | 空值跳过 |
| 返回类型 | OK | Promise<PageResult<TaskVO>> |
| 错误处理 | OK | request 函数中统一 catch |
| 认证头 | OK | 自动携带 Authorization: Bearer <token> |

---

## 4b：类型一致性验证

| 数据层 | TaskSearchParams | API Query | TaskVO | JobData |
|--------|:----------------:|:---------:|:------:|:-------:|
| page | page?: number | ?page= | (PageResult) | - |
| pageSize | pageSize?: number | ?pageSize= | (PageResult) | - |
| jobType | jobType?: number | ?jobType= | jobType: number | jobType: number |
| salaryMin | salaryMin?: number | ?salaryMin= | salaryMin: number | salaryMin: number |
| salaryMax | salaryMax?: number | ?salaryMax= | salaryMax: number | salaryMax: number |
| regionId | regionId?: number | ?regionId= | regionId: number | regionId: number |

**类型一致性结论**: OK 全链路类型匹配一致。

**mapTaskToJobData 映射验证** (ChatTypes.ets lines 77-104):
- id: String(task.id) - number -> string OK
- salary: task.salaryMin + '-' + task.salaryMax + '元' OK
- category: jobType 映射 OK
- 所有字段均有 fallback（|| '', || 0, || []） OK

---

## 4c：UI 状态覆盖验证

**源文件**: JobFeedList.ets lines 18-72

| 状态 | 条件 | UI 展示 | 结果 |
|------|------|---------|:----:|
| 加载中（首次/加载更多） | tabData[jobType]?.loading | LoadingProgress() + 加载中... | OK |
| 空数据 | jobs.length === 0 && !loading（隐含） | 暂无职位 | OK |
| 全部加载完 | !hasMore && jobs.length > 0 | 已全部展示 | OK |

**UI 状态机**:
loading=true -> LoadingProgress + 加载中...
loading=false, jobs=0 -> 暂无职位
loading=false, jobs>0, hasMore=true -> job cards
loading=false, jobs>0, hasMore=false -> job cards + 已全部展示

OK 三种状态全部覆盖，条件判断无遗漏。

---

## 4d：LSP 诊断

| 文件 | 结果 | 说明 |
|------|:----:|------|
| HomePage.ets | 不可用 | 无 ArkTS LSP 服务器配置（DevEco Studio 专用） |
| JobFeedCard.ets | 不可用 | 同上 |
| FilterBar.ets | 不可用 | 同上 |
| JobFeedList.ets | 不可用 | 同上 |
| ApiClient.ets | 不可用 | 同上 |

**说明**: 当前环境未配置 .ets 文件的 LSP 服务器。

**人工代码审查**:
- 所有 import 路径正确 OK
- 接口/类型定义与使用一致 OK
- 无拼写错误 OK
- 无明显的 ArkTS 语法违规 OK

---

## 结论

### 验证汇总

| 项目 | 状态 | 说明 |
|------|:----:|:----:|
| 链路1: Tab 切换加载 | PASS | 映射正确，懒加载正常 |
| 链路2: loadTabData | PASS (含1个BUG) | 核心逻辑正确，但 filterState 未连接 |
| 链路3: loadMoreForTab | PASS (含1个问题) | 重复加载防护正常，hasMore 检查缺失 |
| 链路4: 筛选联动 | PASS (含1个BUG) | 重置逻辑正确，参数传递断层 |
| 链路5: searchTasks API | PASS | 参数映射和返回类型完整 |
| 4b: 类型一致性 | PASS | 全链路类型匹配 |
| 4c: UI 状态覆盖 | PASS | 三种状态完整覆盖 |
| 4d: LSP 诊断 | 不可用 | 环境限制 |

### 总体状态: PASS with known issues

### 发现的问题

#### BUG 1（严重）: filterState 未与筛选 UI 连接
- **文件**: HomePage.ets
- **位置**: lines 704-707 vs 筛选回调 (lines 779-833)
- **描述**: loadTabData() 从 this.filterState 读取筛选参数，但筛选 UI 更新独立变量
- **影响**: 所有筛选参数（薪资范围、地区）不会传到 API
- **建议修复**: 在 loadTabData() 中使用 this.salaryMin / this.salaryMax 替代 filterState

#### BUG 2（次要）: loadMore 未检查 hasMore
- **文件**: HomePage.ets line 693
- **描述**: append=true 模式不检查 hasMore
- **影响**: 轻微。额外的网络请求（返回空数据）
- **建议修复**: 在 loadMoreForTab 入口处增加 state.hasMore 判断

### 数据流总览

Tabs.onChange(index)
  -> onTabChange(index)
    -> jobTypes=[1,2,3]; jobType = jobTypes[index]
    -> if (jobs.length === 0) loadTabData(jobType, false)
      -> loading = true (@State 新建对象)
      -> 构造 TaskSearchParams { jobType, page, pageSize, salaryMin?, salaryMax?, regionId? }
      -> ApiClient.searchTasks(params)
        -> GET /api/tasks?jobType=X&page=Y&pageSize=10&...
        -> request<T>() -> parse ApiResult -> json.data as PageResult<TaskVO>
      -> result.records.map(task => mapTaskToJobData(task)) -> JobData[]
      -> hasMore = result.page < result.totalPages
      -> tabData[jobType] = { jobs, page: result.page, hasMore, loading: false }
      -> @State 响应 -> UI 刷新

onReachEnd
  -> loadMoreForTab(jobType)
    -> loadTabData(jobType, true)
      -> 同上(append模式)