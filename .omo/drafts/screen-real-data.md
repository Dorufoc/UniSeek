---
slug: screen-real-data
status: awaiting-approval
intent: clear
review_required: true
pending-action: write .omo/plans/screen-real-data.md
approach: 3-wave — 后端新增 3 个统计 API  → 前端 API 层对接 → ScreenPreview 替换 Mock 数据
---

# Draft: screen-real-data

## Components (topology ledger)
| id | outcome | status | evidence path |
|----|---------|--------|--------------|
| API-INDUSTRY | 新增行业需求占比接口 GET /api/admin/statistics/industries | active | AdminStatisticsController + AdminService |
| API-HOT | 新增热门岗位 TOP10 接口 GET /api/admin/statistics/hot-tasks | active | AdminStatisticsController + AdminService |
| API-ACTIVITY | 新增实时动态接口 GET /api/admin/statistics/latest-activity | active | AdminStatisticsController + AdminService |
| API-REGION | 新增地区分布接口 GET /api/admin/statistics/region-distribution | deferred | 地图数据较复杂，降级为 P2 |
| FE-API | 前端 admin.ts 增加 3 个新 API 调用 | active | uniseek_vue/src/api/admin.ts |
| FE-KPI | KPI 卡片改用 getStatistics 真实数据 | active | ScreenPreview.vue kpiData |
| FE-TREND | 供需趋势图改用 dailyList 真实数据 | active | ScreenPreview.vue trendOption |
| FE-RING | 行业需求占比改用 industries 接口数据 | active | ScreenPreview.vue ringOption |
| FE-BAR | 热门岗位 TOP10 改用 hot-tasks 接口数据 | active | ScreenPreview.vue barOption |
| FE-FEED | 实时动态流改用 latest-activity 接口数据 | active | ScreenPreview.vue feedData |

## Open assumptions (announced defaults)
| assumption | adopted default | rationale | reversible? |
|-----------|----------------|-----------|-------------|
| 行业需求占比数据来源 | 按 task.category_id 分组 COUNT | category 表已有完整分类树，直接 GROUP BY 即可 | 是 |
| 热门岗位 TOP10 排序 | 按 task_application 投递量倒序 LIMIT 10 | 投递量反映热门程度 | 是 |
| 实时动态内容 | 取 operation_log 最新 10 条，拼接可读文案 | operation_log 已有完整操作记录 | 是 |
| 大屏不要求实时 WebSocket 推送 | 页面挂载时 fetch 一次 + 每 60s 轮询 | 降低复杂度，无需引入 WebSocket | 是 |
| KPI 卡片无趋势数据时不显示箭头 | trend 字段设为 0 或隐藏趋势区域 | 后端无环比数据，暂不可得 | 是 |

## Findings (cited - path:lines)
- C-01: `AdminStatisticsController.java:33-39` getStatistics 已有 summary + dailyList，可直接复用
- C-02: `AdminStatisticsController.java` 无行业/热门/动态三个维度的接口
- C-03: `AdminServiceImpl.java:296-345` getStatistics 已统计 totalUsers/publishedTasks/totalApplications/totalComplaints
- C-04: `AdminServiceImpl.java:350-392` getDailyStatistics 有 newUsers/newTasks/newApplications 每日明细
- C-05: `ScreenPreview.vue:108-114` kpiData 为硬编码，共 4 项
- C-06: `ScreenPreview.vue:276-310` 供需趋势图数据硬编码
- C-07: `ScreenPreview.vue:452-493` 行业需求占比环形图数据硬编码
- C-08: `ScreenPreview.vue:494-537` 热门岗位 TOP10 数据硬编码
- C-09: `ScreenPreview.vue:116-123` feedData 为 5 条假动态
- C-10: `uniseek_vue/src/api/admin.ts:115-121` 已有 getStatistics API 封装

## Decisions (with rationale)
1. **新建 3 个后端 API 而非扩展现有接口**：getStatistics 已承担汇总+每日明细，加太多字段会耦合。独立接口职责清晰、可单独缓存。
2. **行业需求占比用 category_id 分组**：task 表已有 category_id 外键关联 category 表，无需额外关联，性能最优。
3. **热门岗位用投递量排序而非浏览量**：平台无浏览量字段，投递量是唯一可用的热度指标。
4. **实时动态取 operation_log**：操作日志已记录所有关键事件（注册、登录、投递、录用等），无需新建事件表。
5. **前端 60s 自动轮询**：大屏场景不需要即时推送，定时刷新即可；降低 WebSocket 维护成本。
6. **地区分布接口推迟到 P2**：地图流向数据需要城市坐标映射，实现复杂且 Mock 数据已能满足视觉需求。

## Scope IN
- Java 后端：AdminStatisticsController + AdminService 新增 3 个接口（industries / hot-tasks / latest-activity）
- Vue API 层：admin.ts 新增 3 个 API 调用函数
- ScreenPreview.vue：全部 5 个数据板块（KPI/趋势/行业/热门/动态）替换为真实后端数据
- 添加 60s 自动轮询机制

## Scope OUT (Must NOT have)
- ❌ 不新增数据库表
- ❌ 不改动现有 API 的响应格式（向后兼容）
- ❌ 不引入 WebSocket
- ❌ 不动全国流向地图（P2）
- ❌ 不动布局结构（仅替换数据）
- ❌ 不修改其他页面

## Approval gate
status: approved (with review fixes applied)
