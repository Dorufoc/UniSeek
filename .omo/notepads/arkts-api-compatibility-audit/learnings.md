# Learnings — arkts-api-compatibility-audit

Conventions, patterns, and successful approaches discovered during work on this plan.

_Auto-scaffolded by /start-work. Append new entries below - never overwrite._

---

## 2026-07-28 — 生成 ArkTS 页面与 Service 全量调用清单

产物：`D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\arkts-surface.json`（baseline-pending）。

### 扫描范围
- `main_pages.json` 注册页面：27 个，全部存在对应 `.ets` 文件。
- `pages/**/*.ets`：36 个（含 9 个未在 `main_pages.json` 注册的 tab 子页面）。
- `components/**/*.ets`：36 个。
- `services/*.ets`：20 个。
- `common/*.ets`：12 个（out-of-arkts-scope 本地工具）。
- `routeLiterals`：70 条（57 REST + 3 上传 + 10 WebSocket 事件）。

### ArkTS Service 复用模式
- 所有 HTTP 调用统一收敛到 `services/ApiClient.ets`：提供 `get/post/put/putWithParams/patch/delete`。
- 服务端地址由 `ServerConfig` 管理，默认 `http://192.168.246.118:8080`；WebSocket 地址通过 `ServerConfig.toWebSocketUrl()` 同源生成。
- 文件上传统一封装在 `ChatService`：
  - `/api/upload/image`
  - `/api/upload/file`
  - `/api/resume/upload-attachment`
- WebSocket 协议事件：`NEW_MESSAGE`、`SEND_ACK`、`MESSAGE_READ`、`PING`。
- 本地状态/缓存服务无服务端调用：`UserSession`、`SearchHistoryService`、`RecordService`、`FileTransferPolicy`、`ChatTypes`、`RecruiterTypes`。

### 页面-Service 关系
- 页面与组件不直接调用 `ApiClient`，而是通过 `services/` 下的业务 Service（如 `AuthService`、`TaskService`、`ChatService`）。
- 9 个未注册页面均为 `pages/tab/**` 下的 tab 子页面，被 `MainPage.ets` / `RecruiterHomePage.ets` 以组件方式引用，符合 ArkTS tab 设计模式。

### Java 端点交叉核对（codegraph 只读采样）
- `/api/upload/image`、`/api/upload/file` → `UploadController`
- `/api/auth/*` → `AuthController`
- `/api/resume/upload-attachment` → `ResumeController`
- `/api/enterprise/tasks` → `TaskController`
- `/api/enterprise/list` → `EnterpriseController`
- WebSocket `/ws/chat` 与事件类型 → `ChatWebSocketHandler`
- 采样路由均能在 Java 后端找到对应 Controller；未发现明显悬空路由。

---

## 2026-07-29 — 招聘者流程与投递状态机核对

产物：`D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\recruiter-evidence.json`。

### 核对结果
- 覆盖 12 条招聘者流程：`enterpriseSubmit`、`enterpriseUpdate`、`enterpriseAuditStatus`、`jobCreate`、`jobUpdate`、`jobStatusChange`、`jobResubmit`、`recruiterTaskList`、`recruiterApplicationList`、`applicationStatusUpdate`、`applicationComplete`、`recruiterProfile`。
- 投递状态机 0-5 在 Java `ApplicationStatusMachine` 与 ArkTS `BusinessPolicies.ApplicationActionPolicy` 中的允许流转完全一致（ArkTS 可操作按钮缺少 3→5 完成确认）。
- 职位状态机 Java 端 HR 只能执行上架(1)/下架(4)；ArkTS UI 也仅支持_toggle_ 1↔4，行为一致。
- 三端字段映射基本对齐：`RecruiterJobRequest` 与 Java `TaskRequest` 字段一致，缺少 `remainingQuota`、`status`、`version`、`longitude`、`latitude`、`rejectReason` 等由服务端填充字段。
- Vue `JobManagement.vue`/`PostJob.vue` 与工作类型、薪资单位、任务状态的标签和 Java 实体一致。

### 关键发现
- `applicationComplete`（`/api/applications/{id}/complete`）在 Java 中存在且实现，但 ArkTS 页面、按钮策略均未调用，属于缺失调用。
- ArkTS 职位"重新提交"按钮显示条件错误：在 `status=0` 且存在 `rejectReason` 时显示，但 Java `resubmit` 要求 `status=5`。
- ArkTS `APPLICATION_STATUS_LABELS`、`JOB_STATUS_LABELS` 均缺少 `5` 标签，导致已完成/已驳回职位显示"未知"。
- Java `TaskRequest.java` 对工作类型和薪资单位的注释与实体、ArkTS、Vue 不一致，属文档冲突。
- 运行时请求验证因服务与账号不可得标记为 `blocked`。

## 2026-07-29 — 验证 ApiClient 传输、鉴权和错误协议

产物：`D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\transport-evidence.json`（baseline-pending）。

### 三端一致性
- 鉴权头格式一致：ArkTS/Vue/Java 均使用 `Authorization: Bearer <token>`。ArkTS 在 `ApiClient.ets:261`，Vue 在 `api/index.ts:23`，Java 在 `JwtAuthInterceptor.java:46` 校验。
- 业务成功判断一致：均只看后端 `ApiResult.code === 200`，否则视为失败并 reject。
- 统一响应包装：Java `ApiResult` 字段为 `code/message/data`（`ApiResult.java:26-30`），与 ArkTS `ApiResult` 接口、`LoginData` 结构对齐。
- JSON 序列化一致：ArkTS `JSON.stringify(body)`（`ApiClient.ets:267`），Vue 由 axios 默认序列化 `application/json`。

### 默认地址与超时
- ArkTS 默认后端地址硬编码为 `http://192.168.246.118:8080`，支持 preference 持久化并可通过 `setBaseUrl` 修改（`ApiClient.ets:26,49-80`）。
- Vue 使用相对路径 `/api`，端口/主机由运行时代理决定（`api/index.ts:10`），与 ArkTS 的显式 IP:8080 不完全对齐。
- 超时：两端总请求/读取超时均为 15 秒；ArkTS 额外显式设置连接超时 10 秒（`ApiClient.ets:268-269`）。

### 测试证据
- 隔离 mock transport 测试 7 项全部通过：GET query+Bearer、POST JSON、PUT JSON、multipart、HTTP 200 业务码 400、HTTP 401、非 JSON 响应。结果文件：`scripts/mock-transport-test-output.json`。

---

## 2026-07-29 — 聊天 / WebSocket / 上传下载协议审计

产物：`D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\chat-evidence.json`。

### 协议一致性要点
- **REST endpoint**：会话列表、会话详情、历史消息、发送消息、标记已读、创建直接会话、未读数 7 个聊天相关 endpoint 在 ArkTS `ChatService.ets`、Java `ChatController.java`、Vue `api/chat.ts` 中路径、方法、字段名一致。
- **sessionType 机制**：投递会话 `application`、直接会话 `direct`；三端均将 `null/undefined/空字符串` 默认视为投递会话。
- **消息类型枚举**：text=0、image=1、resume/attachment=2 在三端语义一致。
- **上传协议**：图片 `/api/upload/image`、通用文件 `/api/upload/file`、简历附件 `/api/resume/upload-attachment` 均使用 `multipart/form-data` 字段名 `file`；服务端返回 `{code,message,data:{url}}`，ArkTS `FileTransferPolicy.readUploadUrl` 与 Vue 均按此结构取值。
- **WebSocket 帧**：统一 JSON 帧 `{type, data, timestamp}`；ArkTS/Vue 与 Java 在 `NEW_MESSAGE`、`SEND_ACK`、`MESSAGE_READ`、`PING/PONG` 的核心字段上对齐；ArkTS 通过 `ChatProtocolMappers` 将 `messageId` 映射为 `ChatMessageVO.id`。
- **URL/token**：ArkTS `ServerConfig.toWebSocketUrl` 生成 `/ws/chat?token=...`，与 Java `extractToken` 期望的查询参数一致。

### ArkTS 特有实现模式
- 文件上传前复制到 `context.cacheDir`，使用 `@kit.BasicServicesKit` 的 `request.uploadFile`；下载使用 `request.downloadFile`。
- WebSocket 服务为单例，支持 `listenerId` 级别的事件订阅；重连最多 5 次、心跳 30 秒；未读数通过拉取会话列表本地求和。
- 聊天详情页 `ChatDetailPage.ets` 对 `NEW_MESSAGE` 做 `applicationId + sessionType + senderId` 过滤和 `messageId` 去重，避免自己消息重复追加。

### 可复用的协议测试方法
- 使用 Node 隔离脚本模拟 ArkTS/Vue 与 Java 的帧构造/解析逻辑，可在无 DevEco/后端服务的情况下验证字段一致性；脚本位于 `.omo/audit/arkts-api/scripts/chat-frame-test.js`。

## 2026-07-29 — 共享数据/通知/收藏/分页兼容性核对

产物：`D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\shared-evidence.json`（baseline-pending）。

### 公共数据流
- 分类：`ArkTS DataService.getCategoryTree()` -> `GET /api/categories`，与 Java `CategoryController`、Vue `category.ts` 字段一致（id/parentId/name/sortOrder/children）。
- 地区：`ArkTS DataService.getRegionTree()` -> `GET /api/region/tree`，`RegionNode` 与 Java `RegionVO` 字段一致（id/name/level/children），level 语义（1 省、2 市、3 区县）在三端对齐。
- 地区子节点：`GET /api/region/children/{parentId}` 与 DataService `getProvinceChildren` 一致。

### 企业发现流
- `EnterpriseDiscoveryService.getEnterprises()` 调用 `GET /api/enterprise/list`，请求参数 page/pageSize/keyword/industry/regionId/sortBy/sortOrder 与 Java `EnterpriseController` 一致；Java 额外支持 `subCategoryId`，ArkTS 未暴露。
- 企业在招职位：`EnterpriseDiscoveryService.getPublishedJobs` 拼接 `/api/enterprise/{id}/tasks`，与 `TaskController.getPublishedEnterpriseTasks` 对齐。
- 公开企业详情返回完整 `Enterprise` 实体，ArkTS 仅以 `EnterpriseListItem` 消费，后端未做字段脱敏。

### 通知流
- `NotificationService` 四类操作（列表/未读数/单条已读/一键已读）分别对应 `NotificationController` 四个端点；`read-all` 语义一致：将当前接收者所有消息置为已读。
- ArkTS 招聘端 `getNewDeliveries` 固定 `type=0`，但未使用 `isRead` 过滤，需产品确认铃铛列表语义。

### 收藏流
- 新增/删除/检查/列表均能在 `FavoriteController` 找到对应端点；检查返回字段 `favorited` 与 Java `Map` 同名。
- `FavoriteServiceImpl.listFavorites` 手动构造 `PageResult` 时漏设 `totalPages`，ArkTS 分页循环会在第一页后停止。
- `/api/favorites/count` 在 Java/Vue 中存在，ArkTS 未实现；仅通过 `hasFavorited` 字段做状态感知。

### 分页命名
- ArkTS/Vue/Java 统一使用 `page`/`pageSize`；Java `PageResult` 和 ArkTS `PageResult`/`ChatTypes.PageResult` 字段（records/total/page/pageSize/totalPages）一致；未发现 `current`/`size` 命名冲突。

### 本地服务
- `SearchHistoryService` 使用鸿蒙 `preferences` 做本地持久化；`RecordService` 使用内存 `Map`；两者无服务端调用，不作为 API 遗漏。

### Route 回归
- DataService/TaskService/EnterpriseDiscoveryService/NotificationService/FavoriteService 中所有共享数据相关 route literal（15 条）在 `arkts-surface.json` 的 `routeLiterals` 中均有对应条目，缺失列表为空。

## 2026-07-29 — 生成最终 ArkTS API 兼容性审阅报告

产物：`D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\arkts-api-compatibility-report.md`。

### 完成内容
- 汇总 8 份证据 JSON（`java-vue-contract.json`、`arkts-surface.json`、`transport-evidence.json`、`seeker-evidence.json`、`recruiter-evidence.json`、`chat-evidence.json`、`shared-evidence.json`、`java-vue-findings.json`）。
- 矩阵共 81 行，其中 `java-source-truth` 42 行、`api-md-conflict` 20 行、`out-of-arkts-scope` 19 行。
- 结构化记录 key findings：1 项高危（F2 招聘者重新提交条件错误）、7 项中危、23 项低危，2 项信息级阻塞项。
- 报告包含 scope/Must-NOT-Have、事实来源层级、基线声明、接口矩阵概览、测试命令与结果路径、分类发现、风险汇总、阻塞项、复现指引、产物清单。

### 验证结果
- 全部 8 份证据 JSON 通过 `JSON.parse` 校验。
- mock transport 测试 7/7 通过；chat/WebSocket 帧隔离测试 12/12 通过。
- 当前 `git status --short` 与 baseline snapshot 对比：仅有 `.omo/audit/arkts-api/arkts-api-compatibility-report.md` 为本次新增产物；未新增或修改任何 `uniseek_arkts`、`uniseek_java`、`uniseek_vue`、`api.md` 中的产品代码。
- 基线仍为 `baseline-pending`，前置脏文件未清理，也未在本次审阅中引入新的脏文件。

---

## 2026-07-29 — 建立只读基线与审阅证据目录

产物：`D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\baseline.json`。

### 基线约定
- `baselineMode` 设置为 `frozen-dirty-by-continuation`，因为用户在本次 continuation 中未在“清理后开始”与“冻结脏基线”之间做显式选择。
- 基线仅作为本次审阅的可复现基线，记录 HEAD、完整 `git status --short`、`git diff --stat`、`git diff --name-only`、未跟踪文件清单、pre-existing 已修改跟踪文件的 SHA256、pre-existing 未跟踪文件字节数、工具可用性、ArkTS 测试入口、只读白名单和 evidence schema。
- 只读白名单：`uniseek_arkts/entry/src/main/ets/**`、`uniseek_java/**`、`uniseek_vue/**`、`api.md` 在本次审阅期间视为只读。
- 证据目录 `.omo/audit/arkts-api/evidence/` 已创建，供后续可复现证据 fixture 存放。
- 本次操作未修改任何产品代码、资源、测试或配置；未执行 git clean/reset/checkout/stash。
