# screen-real-data - Work Plan

## TL;DR (For humans)

**What you'll get:** 全局大屏从"假数据展示"变成"真数据驾驶舱"。后端新增 3 个统计 API，前端 5 个图表板块全部对接真实数据，并自动每 60 秒刷新。

**Why this approach:** 先建后端接口（独立职责），再通过前端 API 层对接，最后替换 ScreenPreview 中的硬编码数据——每步可独立验证。

**What it will NOT do:** 不动全国流向地图、不引入 WebSocket、不新建数据库表、不改动布局。

**Effort:** Short (1 天)
**Risk:** Low — 全部为新增代码，不修改现有逻辑

Your next move: 审阅计划并 approve。Full execution detail follows below.

---

> TL;DR (machine): Short effort, Low risk. Add 3 backend statistic APIs, connect 5 frontend chart panels to real data.

## Scope
### Must have
- Java: 新增 3 个统计接口（行业需求占比、热门岗位 TOP10、实时动态）
- Java: 扩展现有 AdminService 接口和实现
- Vue API: admin.ts 新增 3 个 API 函数
- Vue: KPI 卡片改用 getStatistics 真实数据
- Vue: 供需趋势图改用 dailyList 真实数据
- Vue: 行业需求占比改用 industries 接口数据
- Vue: 热门岗位 TOP10 改用 hot-tasks 接口数据
- Vue: 实时动态流改用 latest-activity 接口数据
- Vue: 添加 60s 自动轮询机制

### Must NOT have (guardrails, anti-slop, scope boundaries)
- 不改动现有 API 响应格式
- 不新增数据库表
- 不引入 WebSocket
- 不改动大屏布局结构
- 不修改全国流向地图
- 不修改其他页面

## Verification strategy
> Zero human intervention - all verification is agent-executed.
- Test decision: tests-after — mvn compile + 前端构建 + 接口 curl 验证
- Evidence: .omo/evidence/task-<N>-screen-real-data.<ext>

## Execution strategy
### Parallel execution waves
- **Wave 1** (后端, 3 接口可全并行): 行业接口 → 热门接口 → 动态接口
- **Wave 2** (前端 API 层, 依赖 Wave1): admin.ts 新增 3 个函数
- **Wave 3** (前端大屏, 5 板块可全并行): KPI → 趋势 → 行业 → 热门 → 动态 + 轮询
- **Final**: mvn compile + 构建验证

### Dependency matrix
| Todo # | 任务 | Depends on | Blocks | Can parallelize with |
| --- | --- | --- | --- | --- |
| 1 | 后端：行业需求占比接口 | — | — | 2,3,4 |
| 2 | 后端：热门岗位 TOP10 接口 | — | — | 1,3,4 |
| 3 | 后端：实时动态接口 | — | — | 1,2,4 |
| 4 | 后端：公开 KPI 汇总接口 | — | — | 1,2,3 |
| 5 | 前端：admin.ts 新增 4 个 API | 1,2,3,4 | — | — |
| 6 | 前端：KPI 卡片对接真实数据 | 5 | — | 7,8,9,10 |
| 7 | 前端：供需趋势图对接真实数据 | 5 | — | 6,8,9,10 |
| 8 | 前端：行业需求占比图对接真实数据 | 5 | — | 6,7,9,10 |
| 9 | 前端：热门岗位 TOP10 对接真实数据 | 5 | — | 6,7,8,10 |
| 10 | 前端：实时动态流对接 + 60s 轮询 | 5 | — | 6,7,8,9 |

## Todos

### Wave 1 — 后端新增统计 API

- [x] 1. java: 新增行业需求占比接口 GET /api/admin/statistics/industries
  **What to do / Must NOT do:**
  1. 在 `AdminService.java` 接口中新增方法：`Map<String, Object> getIndustryDistribution()`
  2. 在 `AdminServiceImpl.java` 中实现：查询 `task` 表按 `category_id` 分组 COUNT，再 JOIN `category` 表获取分类名称
     ```sql
     SELECT c.name AS industry, COUNT(t.id) AS count
     FROM task t JOIN category c ON t.category_id = c.id
     WHERE t.status = 1
     GROUP BY t.category_id
     ORDER BY count DESC
     ```
  3. 在 `AdminStatisticsController.java` 中新增：
     ```java
     @GetMapping("/industries")
     public ApiResult<List<Map<String, Object>>> getIndustryDistribution() {
         return ApiResult.success(adminService.getIndustryDistribution());
     }
     ```
  4. 方法不要求鉴权或使用 checkAdmin()（大屏可公开显示）
  **Must NOT:** 不修改现有 getStatistics 接口。不新增数据库表。
  **Parallelization:** Wave 1 | Blocked by: — | Blocks: —
  **References:** `AdminStatisticsController.java`；`AdminServiceImpl.java:282-345`（参考 getStatistics 实现模式）
  **Acceptance criteria:** `curl http://localhost:8080/api/admin/statistics/industries` 返回 JSON 数组，每项含 industry + count
  **QA scenarios:** 启动后端后 curl 验证；Evidence `.omo/evidence/task-1-screen-real-data.txt`
  **Commit:** Y | `feat(api): add industry distribution statistics endpoint`

- [x] 2. java: 新增热门岗位 TOP10 接口 GET /api/admin/statistics/hot-tasks
  **What to do / Must NOT do:**
  1. 在 `AdminService.java` 中新增：`List<Map<String, Object>> getHotTasks()`
  2. 在 `AdminServiceImpl.java` 中实现：按 task_application 投递量倒序取 TOP10
     ```sql
     SELECT t.id, t.title, e.company_name, COUNT(ta.id) AS application_count
     FROM task t
     JOIN enterprise e ON t.enterprise_id = e.id
     LEFT JOIN task_application ta ON ta.task_id = t.id
     WHERE t.status = 1
     GROUP BY t.id
     ORDER BY application_count DESC
     LIMIT 10
     ```
     使用 MyBatis-Plus 的 QueryWrapper 或自定义 SQL。
  3. 在 `AdminStatisticsController.java` 中新增：
     ```java
     @GetMapping("/hot-tasks")
     public ApiResult<List<Map<String, Object>>> getHotTasks() {
         return ApiResult.success(adminService.getHotTasks());
     }
     ```
  **Must NOT:** 不修改现有接口。不新增表。
  **Parallelization:** Wave 1 | Blocked by: — | Blocks: —
  **References:** `AdminServiceImpl.java`；`TaskMapper.java`
  **Acceptance criteria:** `curl http://localhost:8080/api/admin/statistics/hot-tasks` 返回 10 条记录，含 title + company_name + application_count
  **QA scenarios:** curl 验证；Evidence `.omo/evidence/task-2-screen-real-data.txt`
  **Commit:** Y | `feat(api): add hot tasks TOP10 statistics endpoint`

- [x] 3. java: 新增实时动态接口 GET /api/admin/statistics/latest-activity
  **What to do / Must NOT do:**
  1. 在 `AdminService.java` 中新增：`List<Map<String, Object>> getLatestActivity()`
  2. 在 `AdminServiceImpl.java` 中实现：取 `operation_log` 表最新 10 条，拼接可读的描述文案
     - 从 `operation_log` 表 SELECT * ORDER BY create_time DESC LIMIT 10
     - 将每条记录转换为前端可读格式：`{ id, message, time }`
      - 不同 operation_type 拼接不同文案（注意：使用 OperationType 常量类的完整常量名）：
        - USER_REGISTER → "新用户注册了账号"
        - USER_LOGIN → "用户登录了系统"
       - APPLICATION_DELIVER → "[用户] 投递了 [职位]"
       - APPLICATION_HIRE → "[用户] 被录用为 [职位]"
       - REAL_NAME_AUTH → "[用户] 完成了实名认证"
       - 其他 → "系统操作记录"
     - 拼接时使用 operation_log.detail 中的 JSON 信息
  3. 在 `AdminStatisticsController.java` 中新增：
     ```java
     @GetMapping("/latest-activity")
     public ApiResult<List<Map<String, Object>>> getLatestActivity() {
         return ApiResult.success(adminService.getLatestActivity());
     }
     ```
  **Must NOT:** 不修改 operation_log 表结构。不记录新的日志。
  **Parallelization:** Wave 1 | Blocked by: — | Blocks: —
  **References:** `OperationLog.java`；`AdminServiceImpl.java:396-424`（参考 listOperationLogs）
  **Acceptance criteria:** `curl http://localhost:8080/api/admin/statistics/latest-activity` 返回 10 条含 message + time 的记录
  **QA scenarios:** curl 验证数据格式；Evidence `.omo/evidence/task-3-screen-real-data.txt`
  **Commit:** Y | `feat(api): add latest activity feed endpoint`

### Wave 2 — 前端 API 层

- [x] 4. java: 新增公开 KPI 汇总接口 GET /api/admin/statistics/summary（无鉴权）
  **What to do / Must NOT do:**
  **背景：** 现有的 `getStatistics()` 调用 `checkAdmin()` 需要管理员权限，但大屏是公开页面。因此新建一个无鉴权的摘要接口。
  1. 在 `AdminService.java` 中新增：`Map<String, Object> getScreenSummary()`
  2. 在 `AdminServiceImpl.java` 中实现：直接复用 `getStatistics` 内部的汇总逻辑（但不调 `checkAdmin()`）
     - 统计 `totalUsers`、`totalEnterprises`、`totalTasks`、`publishedTasks`、`totalApplications`
     - 额外统计今日投递数：`taskApplicationMapper.selectCount(条件：DATE(create_time) = CURDATE())` 作为 `latestDeliveries`
     - 复用 `getDailyStatistics` 方法获取近 7 天每日新增 `newUsers`、`newTasks`、`newApplications` 作为 `dailyList`
  3. 在 `AdminStatisticsController.java` 中新增：
     ```java
     @GetMapping("/summary")
     public ApiResult<Map<String, Object>> getScreenSummary() {
         return ApiResult.success(adminService.getScreenSummary());
     }
     ```
  **Must NOT:** 不修改现有 getStatistics。不添加鉴权。
  **Parallelization:** Wave 1 | Blocked by: — | Blocks: —
  **References:** `AdminServiceImpl.java:282-345`（参考 getStatistics 的实现但不调用 checkAdmin）
  **Acceptance criteria:** `curl http://localhost:8080/api/admin/statistics/summary` 返回 KPI 汇总 JSON，无需登录
  **QA scenarios:** curl 验证无 401/403；Evidence `.omo/evidence/task-4-screen-real-data.txt`
  **Commit:** Y | `feat(api): add public KPI summary endpoint for screen`

- [x] 5. vue: admin.ts 新增 4 个 API 调用函数（含公开 summary 接口）
  **What to do / Must NOT do:**
  在 `uniseek_vue/src/api/admin.ts` 末尾（`listOperationLogs` 之后）新增：
  ```typescript
  // ==================== 大屏统计 API ====================

  /** 大屏公开 KPI 汇总（无需管理员权限） */
  export async function getScreenSummary(): Promise<{
    summary: { totalUsers: number; totalEnterprises: number; totalTasks: number; publishedTasks: number; totalApplications: number }
    latestDeliveries: number
    dailyList: Array<{ date: string; newUsers: number; newTasks: number; newApplications: number }>
  }> {
    const res: any = await request.get('/admin/statistics/summary')
    return res
  }

  export async function getIndustryDistribution(): Promise<Array<{ industry: string; count: number }>> {
    const res: any = await request.get('/admin/statistics/industries')
    return res
  }

  export async function getHotTasks(): Promise<Array<{ id: number; title: string; companyName: string; applicationCount: number }>> {
    const res: any = await request.get('/admin/statistics/hot-tasks')
    return res
  }

  export async function getLatestActivity(): Promise<Array<{ id: number; message: string; time: string }>> {
    const res: any = await request.get('/admin/statistics/latest-activity')
    return res
  }
  ```
  **Must NOT:** 不修改现有 API 函数。
  **Parallelization:** Wave 2 | Blocked by: 1,2,3 | Blocks: 5,6,7,8,9
  **References:** `uniseek_vue/src/api/admin.ts:113-121`（参考 getStatistics 写法）
  **Acceptance criteria:** 编译无 TypeScript 错误
  **QA scenarios:** `npm run build` 或 tsc 检查；Evidence `.omo/evidence/task-4-screen-real-data.txt`
  **Commit:** Y | `feat(vue): add 4 screen statistics API calls`

### Wave 3 — 前端数据对接

- [x] 6. vue: KPI 卡片改用 getScreenSummary 真实数据
  **What to do / Must NOT do:**
  **注意：** 不能直接使用现有的 `getStatistics` API（它调用 `checkAdmin()` 需要管理员权限，而大屏是公开页面）。而是使用新增的公开接口 `getScreenSummary()`（见 Todo 4 补充）。
  1. 在 `<script setup>` 中引入 `getScreenSummary`（来自 Todo 4 新增的函数）
  2. 将 `kpiData` 从硬编码 reactive 改为 `ref` + `fetchKpiData()` 函数
  3. 调用 `getScreenSummary()` 获取数据，映射到 kpiData：
     - `平台总用户` → `summary.totalUsers`
     - `在招活跃岗位` → `summary.publishedTasks`
     - `今日新增投递` → `latestDeliveries`（单独字段）
     - `认证企业数` → `summary.totalEnterprises`
  4. 新增 `fetchAllData()` 函数统一调用所有数据接口（使用 `Promise.allSettled` 并行请求，单个失败不影响其他图表）
  5. 在 `onMounted` 中调用 `fetchAllData()`
  6. 保留 `.trend` 字段显示，但若无数据则隐藏趋势箭头
  **Must NOT:** 不修改模板结构。不改动 CSS。
  **Parallelization:** Wave 3 | Blocked by: 4 | Blocks: —
  **References:** `ScreenPreview.vue:108-114`（kpiData）；`AdminServiceImpl.java:295-329`（summary 字段）
  **Acceptance criteria:** 页面加载后 KPI 卡片显示真实数据（非硬编码数字）
  **QA scenarios:** 启动前后端后访问大屏页面验证；Evidence `.omo/evidence/task-5-screen-real-data.txt`
  **Commit:** Y | `feat(vue): replace KPI cards with real statistics data`

- [x] 7. vue: 供需趋势图改用 dailyList 真实数据
  **What to do / Must NOT do:**
  1. 在 `fetchAllData()` 中调用 `getScreenSummary()` 获取 `dailyList`
  2. 将 trendOption 的 xAxis.data 改为 dailyList 中的日期数组
  3. 将 "新增岗位" 系列数据改为 `dailyList.map(d => d.newTasks)`
  4. 将 "投递简历" 系列数据改为 `dailyList.map(d => d.newApplications)`
  5. 日期范围默认最近 7 天：`startDate = 7天前`, `endDate = 今天`
  6. 图表初始化 && setOption 逻辑不变
  **Must NOT:** 不改动图表类型、颜色、样式。不改动布局。
  **Parallelization:** Wave 3 | Blocked by: 4 | Blocks: —
  **References:** `ScreenPreview.vue:276-310`（trendOption）；`AdminServiceImpl.java:350-392`（dailyList）
  **Acceptance criteria:** 供需趋势图显示 7 天真实数据折线
  **QA scenarios:** 页面加载后图表数据不再是 [320,380,420,...]；Evidence `.omo/evidence/task-6-screen-real-data.txt`
  **Commit:** Y | `feat(vue): replace trend chart with real daily statistics`

- [x] 8. vue: 行业需求占比图改用 industries 接口数据
  **What to do / Must NOT do:**
  1. 在 `fetchAllData()` 中调用 `getIndustryDistribution()`
  2. 将 ringOption 的 series[0].data 改为返回数据，映射 name=industry, value=count
  3. tooltip、颜色、环形图样式不变
  **Must NOT:** 不改动图表类型和样式。
  **Parallelization:** Wave 3 | Blocked by: 4 | Blocks: —
  **References:** `ScreenPreview.vue:452-493`（ringOption）
  **Acceptance criteria:** 环形图显示真实行业分类占比，不再是硬编码的 IT/教育/餐饮/制造/金融
  **QA scenarios:** 页面加载后核实 chart-ring 数据来源；Evidence `.omo/evidence/task-7-screen-real-data.txt`
  **Commit:** Y | `feat(vue): replace industry ring chart with real data`

- [x] 9. vue: 热门岗位 TOP10 改用 hot-tasks 接口数据
  **What to do / Must NOT do:**
  1. 在 `fetchAllData()` 中调用 `getHotTasks()`
  2. 将 barOption 的 xAxis.data 改为 `返回数据.map(t => t.title)`
  3. 将 series[0].data 改为 `返回数据.map(t => t.applicationCount)`
  4. 调整 yAxis.name 为 "投递量"
  **Must NOT:** 不改动图表类型和配色。
  **Parallelization:** Wave 3 | Blocked by: 4 | Blocks: —
  **References:** `ScreenPreview.vue:494-537`（barOption）
  **Acceptance criteria:** 条形图显示真实投递量 TOP10 岗位
  **QA scenarios:** 页面加载后核实 chart-bar 数据；Evidence `.omo/evidence/task-8-screen-real-data.txt`
  **Commit:** Y | `feat(vue): replace hot jobs bar chart with real TOP10 data`

- [x] 10. vue: 实时动态流对接真实数据 + 60s 自动轮询
  **What to do / Must NOT do:**
  1. 在 `fetchAllData()` 中调用 `getLatestActivity()`
  2. 将 `feedData` 从硬编码 reactive 改为 `ref` + 从 API 返回映射
  3. API 返回数据格式 `{ id, message, time }` 映射到 feed 项
  4. 设置 `setInterval(fetchAllData, 60000)` 在 onMounted 中启动
  5. 在 `onUnmounted` 中 `clearInterval` 防止内存泄漏
  6. feed-item 的 v-for 和 animationDelay 逻辑不变
  **Must NOT:** 不修改 feed 的 CSS 动画逻辑。
  **Parallelization:** Wave 3 | Blocked by: 4 | Blocks: —
  **References:** `ScreenPreview.vue:73-90`（feed 模板）；`ScreenPreview.vue:116-123`（feedData）
  **Acceptance criteria:** 动态流显示来自 operation_log 的真实记录；每 60s 自动刷新
  **QA scenarios:** 页面加载后核实 feed 列表内容；Evidence `.omo/evidence/task-9-screen-real-data.txt`
  **Commit:** Y | `feat(vue): replace live feed with real activity data + 60s polling`

## Final verification wave
> Runs in parallel after ALL todos. ALL must APPROVE.
- [x] F1. **后端编译**: `mvn compile -f uniseek_java/pom.xml` → BUILD SUCCESS
- [x] F2. **接口验证**: curl 4 个新接口返回正确 JSON
- [x] F3. **前端构建**: TypeScript 编译通过（vue-tsc 无错误）
- [x] F4. **数据正确性**: 4 个后端 API 已注册，ScreenPreview 已对接
- [x] F5. **60s 轮询**: fetchAllData + setInterval + onUnmounted clearInterval 已实现

## Commit strategy
- `feat(api):` 后端新接口（todo 1,2,3,4）
- `feat(vue):` 前端 API + 大屏改造（todo 5,6,7,8,9,10）

## Success criteria
1. ✅ 3 个后端统计接口返回正确 JSON
2. ✅ KPI 卡片显示数据库真实汇总数据
3. ✅ 供需趋势图展示近 7 天每日新增岗位和投递曲线
4. ✅ 行业需求占比环形图展示真实分类占比
5. ✅ 热门岗位 TOP10 展示真实投递量排名
6. ✅ 实时动态流展示 operation_log 最新记录
7. ✅ 页面每 60s 自动刷新数据
8. ✅ `mvn compile` + 前端构建无错误
