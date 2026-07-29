# UniSeek ArkTS API 兼容性审阅报告

## 1. 摘要

本报告基于 `uniseek_java` Controller/DTO、`uniseek_vue` 事实调用、`uniseek_arkts` 现有页面与 Service，对 ArkTS 端当前使用的 REST/WebSocket/上传接口与后端的兼容性进行只读审阅。审阅不修改任何产品代码，仅产出证据 JSON、隔离测试脚本与本 Markdown 文档。

- **审阅时间**：2026-07-28 至 2026-07-29
- **代码基线**：HEAD `476857d65a2f69e1df4668cd4455cb159ee026ff`；工作树存在前置脏变更，因此本次审阅为 `baseline-pending`
- **未修改任何产品代码**：新增产物全部位于 `.omo/audit/arkts-api/`

总体结论：ArkTS 与 Java/Vue 在主干接口路由、鉴权头、通用响应包装、消息类型枚举、分页字段名等维度基本对齐；但存在若干**状态标签缺失、筛选条件缺失、字段降级映射、重新提交条件错误、WebSocket 错误帧未处理、收藏分页提前终止、企业详情敏感字段未脱敏**等明确问题，以及大量 `api.md` 文档与代码不一致的 `documentation-conflict` 项。

---

## 2. 审阅范围与约束（Scope & Must-NOT-Have）

### 2.1 范围内（IN）
- 只读审阅 `uniseek_arkts/entry/src/main/ets/` 的页面、组件、Service、ApiClient、WebSocket、文件传输策略、已有测试。
- 只读核对 `uniseek_java/` 的 Controller、DTO、Interceptor、WebSocket Handler、上传服务。
- 只读核对 `uniseek_vue/src/api/` 及相关页面中的事实调用、字段、响应消费。
- 新增隔离验证脚本/测试代码，仅用于捕获实际请求和验证响应。

### 2.2 范围外（OUT）
- 不修改任何现有 ArkTS / Java / Vue / `api.md` / 数据库 / Mock 数据。
- 不补齐 Vue 已存在但 ArkTS 缺失的管理后台功能。
- 不自动执行 `git commit` / `git push`。
- 不将审阅结论直接落地为产品修复。
- ArkTS 未调用的后台接口统一标记为 `out-of-arkts-scope`，不视为遗漏。

---

## 3. 事实来源层级

| 优先级 | 来源 | 用途 | 证据文件 |
|--------|------|------|----------|
| 1 | Java Controller / DTO / Interceptor | 接口是否可用、请求/响应字段、鉴权、状态机 | `.omo/audit/arkts-api/java-vue-contract.json` |
| 2 | Vue API/页面实际调用 | 字段命名、响应消费、状态标签、业务流程 | `.omo/audit/arkts-api/recruiter-evidence.json` 等 |
| 3 | ArkTS 现有 Service / 页面 | 被审计对象；发现的差异为其问题 | `.omo/audit/arkts-api/seeker-evidence.json` 等 |
| 辅助 | `api.md` | 仅用于发现与代码不一致的文档冲突项 | 报告中 `documentation-conflict` 标签 |

---

## 4. 工作基线与文件变更声明

- **Git HEAD**：`476857d65a2f69e1df4668cd4455cb159ee026ff`
- **基线状态**：`baseline-pending`（前置脏变更未由本次审阅引入，也未清理）。
- **本次新增路径**：
  - `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\seeker-evidence.json`
  - `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\arkts-api-compatibility-report.md`
- **未修改任何以下目录中的既有文件**：`uniseek_arkts/entry/src/main/ets/**`、`uniseek_java/**`、`uniseek_vue/**`、`api.md`。
- 前置脏文件清单见 `.omo\audit\arkts-api\java-vue-contract.json` 中的 `meta.gitStatusSummary`。由于这些变更在本次审阅开始前已存在，本报告只基于当前工作树做静态证据，不做变更归属判断。

---

## 5. ArkTS 表面清单概览

证据文件：`.omo/audit/arkts-api/arkts-surface.json`

| 维度 | 数量 | 说明 |
|------|------|------|
| `main_pages.json` 注册页面 | 27 | 均存在对应 `.ets` 文件 |
| 实际 `pages/**/*.ets` | 36 | 含 9 个未注册 tab 子页面 |
| `components/**/*.ets` | 36 | — |
| `services/*.ets` / `common/*.ets` | 20 / 12 | 6 个 `local-only` 服务只处理本地状态/类型 |
| REST route literal | 57 | 覆盖所有业务模块 |
| 上传 route literal | 3 | `/api/upload/image`、`/api/upload/file`、`/api/resume/upload-attachment` |
| WebSocket 事件 | 10 | `NEW_MESSAGE`、`SEND_ACK`、`MESSAGE_READ`、`PING` 等 |

扫描未发现悬空路由；所有 route literal 均能在 Java 端找到对应 Controller（采样核对）。

---

## 6. 接口矩阵概览

证据文件：`.omo/audit/arkts-api/java-vue-contract.json`

### 6.1 按模块分布

| 模块 | 矩阵行数 | 主要来源 |
|------|:--------:|----------|
| auth | 9 | Java + Vue |
| task | 9 | Java + Vue |
| resume | 7 | Java + Vue |
| application | 6 | Java + Vue |
| chat | 8 | Java + Vue |
| enterprise | 6 | Java + Vue |
| favorite | 5 | Java + Vue |
| notification | 4 | Java + Vue |
| user | 2 | Java + Vue |
| region / category / upload | 3 / 1 / 2 | Java + Vue |
| admin / telemetry | 18 / 1 | `out-of-arkts-scope` |

**来源标签统计**：`java-source-truth` 42；`api-md-conflict` 20；`out-of-arkts-scope` 19。

### 6.2 典型接口采样

| HTTP | 端点 | 证据位置（Java） | 证据位置（ArkTS / Vue） |
|------|------|------------------|------------------------|
| POST | `/api/auth/login` | `AuthController.java` | `AuthService.ets` / `auth.ts` |
| GET | `/api/auth/current-user` | `AuthController.java` | `UserService.ets` / `user.ts` |
| GET | `/api/tasks` | `TaskController.java` | `TaskService.ets` / `task.ts` |
| POST | `/api/applications` | `ApplicationController.java` | `ApplicationService.ets` / `application.ts` |
| PUT | `/api/applications/{id}/status` | `ApplicationController.java` | `RecruiterService.ets` / `application.ts` |
| PUT | `/api/applications/{id}/complete` | `ApplicationController.java` | **ArkTS 未调用** / `application.ts` |
| GET | `/api/favorites` | `FavoriteController.java` | `FavoriteService.ets` / `favorite.ts` |
| GET | `/api/chat/sessions` | `ChatController.java` | `ChatService.ets` / `chat.ts` |
| POST | `/api/chat/sessions/{id}/messages` | `ChatController.java` | `ChatService.ets` / `chat.ts` |
| GET | `/ws/chat` | `ChatWebSocketHandler.java` | `ChatWebSocketService.ets` / `useChatWebSocket.ts` |

完整矩阵及每个字段/行号引用见 `.omo/audit/arkts-api/java-vue-contract.json`。

### 6.3 `api.md` 文档冲突汇总

| 端点 | 模块 | 冲突说明 |
|------|------|----------|
| `GET /api/applications/my` | application | `query.status` 在 `api.md` 中未定义 |
| `PUT /api/applications/{id}/complete` | application | `requestBody.settlementAmount` 未定义 |
| `GET /api/tasks/{taskId}/applications` | application | `query.status` 未定义 |
| `GET /api/auth/current-user` | auth | `token.ttl` 未定义 |
| `POST /api/auth/login` | auth | `requestBody.account` 未定义 |
| `GET /api/chat/sessions` 等 3 条 | chat | `responseData` 未定义 |
| `/api/favorites/**` 共 5 条 | favorite | 收藏接口在 `api.md` 中整体缺失 |
| `GET /api/messages/unread-count` | notification | `responseData` 未定义 |
| `PUT /api/resume` / `POST /api/resume/upload-attachment` | resume | 字段/响应未定义 |
| `GET /api/enterprise/tasks`、`GET /api/tasks`、`PUT /api/tasks/{id}/status` | task | 参数/请求体未定义 |
| `PUT /api/user/profile` | user | `requestParam.location` 未定义 |

这些项的标签为 `documentation-conflict`，审阅时未将 `api.md` 作为事实来源。

---

## 7. 验证方法与测试证据

### 7.1 静态核对
- 工具：文件遍历 + 正则/AST 安全提取 + CodeGraph 辅助采样。
- 产物路径：`.omo/audit/arkts-api/arkts-surface.json`、`.omo/audit/arkts-api/java-vue-contract.json`。

### 7.2 隔离 mock transport 测试
- 命令：`node .omo/audit/arkts-api/scripts/mock-transport-test.js`
- 结果文件：`.omo/audit/arkts-api/scripts/mock-transport-test-output.json`
- 结果：**7 / 7 通过**，覆盖 GET query + Bearer、POST JSON、PUT JSON、multipart、HTTP 200 + code=400、HTTP 401、非 JSON 响应。
- **状态标签**：`confirmed`（基于 Node 模拟，未在真实 ArkTS 运行时执行）。

### 7.3 聊天/WebSocket 帧隔离测试
- 命令：`node .omo/audit/arkts-api/scripts/chat-frame-test.js`
- 结果：**12 / 12 通过**。
- 覆盖：WS URL/token 解析、`PING/PONG`、`NEW_MESSAGE`、`SEND_ACK`、`MESSAGE_READ`、`ERROR` 帧字段映射、消息类型枚举、上传响应解析。
- **状态标签**：`confirmed`（同样为 Node 隔离测试，未在 DevEco/真机/真实后端执行）。

### 7.4 后端集成 / 设备测试
- 当前环境无运行中的 MySQL/Java 服务，无可用测试账号与 DevEco 模拟器。
- 所有依赖真实后端的 happy/failure 用例（如登录、投递、录用、WebSocket 真实帧收发）标记为 `blocked`。

---

## 8. 兼容性发现

### 8.1 传输/鉴权/错误协议

证据文件：`.omo/audit/arkts-api/transport-evidence.json`

| 编号 | 类别 | 严重 | 描述 | 状态 |
|------|------|:----:|------|------|
| T1 | configuration-divergence | 低 | ArkTS 默认后端地址硬编码 `http://192.168.246.118:8080`；Vue 使用相对路径 `/api`，运行时若未配置统一代理，两端可能连接不同实例。 | confirmed |
| T2 | error-handling-divergence | 中 | Java 通过业务包装返回 `code=403`；ArkTS 只针对 `code=401` 清理会话，对 `403` 仅作为通用错误 reject，用户可能看不到“无权限”提示。Vue 行为相同。 | confirmed |
| T3 | error-handling-divergence | 低 | ArkTS 未显式读取 HTTP `responseCode`；HTTP 非 200 且 body 非 JSON 时会抛出“响应解析失败”，不区分具体 HTTP 状态码。 | confirmed |
| T4 | upload-behavior-divergence | 低 | ArkTS 使用 `request.uploadFile` 上传，未显式设置上传超时，也未暴露上传进度；Vue 可通过 axios `onUploadProgress` 获知进度。 | confirmed |

### 8.2 求职者流程

证据文件：`.omo/audit/arkts-api/seeker-evidence.json`

| 编号 | 类别 | 严重 | 描述 |
|------|------|:----:|------|
| S1 | status-label-mismatch | 中 | `ApplicationService.statusLabel` 只定义 0-4，缺少 Java 状态机的 `5 已完成`，已完成的投递会显示为“未知状态”。 |
| S2 | filter-mismatch | 中 | `SubmittedPage` 筛选栏 `FILTER_OPTIONS` 仅提供 `-1/1/2/3/4`，缺少 `0 已投递` 与 `5 已完成`，与 Java 投递状态 0-5 不一致。 |
| S3 | missing-arkts-call | 低 | Java 与 Vue 均支持 `GET /api/applications/{id}` 投递详情；ArkTS 求职者端当前仅展示列表/展开卡片，未调用单条详情接口。 |
| S4 | missing-arkts-call | 低 | `FavoriteService` 未调用 `GET /api/favorites/count`；Java 与 Vue 均支持该接口。 |
| S5 | field-mapping-degradation | 中 | `FavoriteService.getFavorites` 将收藏记录转 `JobData` 时， `company/region/type/tag/totalQuota/enterpriseName/address/deadline` 等字段被写死为空/0，导致收藏卡片信息缺失。 |
| S6 | missing-arkts-call | 低 | `ResumeService.publishResume/unpublishResume` 已封装，但求职者可见页面未发现发布/下架简历的 UI 入口。 |
| S7 | status-label-mismatch | 低 | `JobDetailPage.statusLabel` 只定义 0-4，缺少 Java 定义的 `5 已驳回`。 |
| S8 | blocked-runtime | 信息 | 未执行真实后端集成验证；当前环境无运行 Java 服务、登录 token、求职者测试账号。 |

### 8.3 招聘者流程与投递状态机

证据文件：`.omo/audit/arkts-api/recruiter-evidence.json`

| 编号 | 类别 | 严重 | 描述 |
|------|------|:----:|------|
| F1 | missing-arkts-call | 中 | ArkTS 缺少 `/api/applications/{id}/complete` 调用入口。Java 状态机允许 `3 已录用 -> 5 已完成`，且 `ApplicationController.complete` 已实现；`BusinessPolicies.ApplicationActionPolicy` 未显示“完成”按钮，也未调用 complete 接口。 |
| F2 | condition-mismatch | **高** | ArkTS 在职位状态为 `0 待审核` 且存在 `rejectReason` 时显示“重新提交”按钮，但 Java `resubmit` 严格要求原职位 `status` 必须为 `5 已驳回`。点击后会收到业务异常。 |
| F3 | status-label-mismatch | 中 | `APPLICATION_STATUS_LABELS` 只定义 0-4，缺少 `5 已完成`。 |
| F4 | status-label-mismatch | 低 | `JOB_STATUS_LABELS/JOB_STATUS_MAP` 只覆盖 0-4，缺少 Java 定义的 `5 已驳回`。 |
| F5 | filter-mismatch | 低 | `RecruiterApplicationsPage` 过滤栏缺少 `2 待定`、`5 已完成`；`RecruiterRequestsPage` 简历池过滤栏同样缺少 5。 |
| F6 | documentation-conflict | 低 | Java `TaskRequest.java` 对工作类型/薪资单位的注释与 `Task` 实体、ArkTS、Vue 不一致。实际服务层未校验枚举，直接透传，暂未影响运行时。 |
| F7 | blocked-runtime | 信息 | 未执行真实后端集成验证。 |

### 8.4 聊天/WebSocket/上传协议

证据文件：`.omo/audit/arkts-api/chat-evidence.json`

| 编号 | 类别 | 严重 | 描述 |
|------|------|:----:|------|
| CHAT-001 | protocol-alignment | 低 | 三端 WS 路径一致：`/ws/chat?token=...`。 |
| CHAT-002 | potential-incompatibility | 低 | ArkTS 对 token 做 `encodeURIComponent`，Java `extractToken` 未 URLDecode；标准 JWT base64url 安全字符不受影响，但若 token 含特殊字符会校验失败。 |
| CHAT-003 | protocol-alignment | 低 | 两端均每 30 秒发送 `{"type":"PING","data":{}}`，Java 回复 PONG。 |
| CHAT-004 | protocol-alignment | 低 | `NEW_MESSAGE` 核心字段在三端一致；ArkTS 通过 `ChatProtocolMappers` 映射为 `ChatMessageVO`。 |
| CHAT-005 | documentation-conflict | 低 | ArkTS `ChatMessageVO` 与 Mapper 期望 `NEW_MESSAGE.data` 包含 `isRead`，但 Java 未下发该字段。Vue 使用 `?? 1` 兜底，ArkTS 当前映射为 `undefined`。 |
| CHAT-006 | protocol-alignment | 低 | `SEND_ACK.data` 字段与 ArkTS `WsSendAckData` 完全一致。 |
| CHAT-007 | behavior-divergence | 低 | Java 在 token/参数/业务异常时下发 `ERROR` 帧；ArkTS `ChatWebSocketService.handleMessage` 忽略 `ERROR` 类型，用户无法感知具体原因。 |
| CHAT-008 | protocol-usage-divergence | 低 | Java WS 支持 `SEND_MESSAGE`，但 ArkTS 与 Vue 均使用 REST 发送消息。互操作正常，但协议存在“WS 发送能力未用”的差异。 |
| CHAT-009 | protocol-usage-divergence | 低 | Java WS 支持 `READ_RECEIPT`，两端均使用 REST `PUT /api/chat/sessions/{id}/read`。 |
| CHAT-010 | enum-alignment | 低 | text=0、image=1、resume/attachment=2 在三端语义一致。 |
| CHAT-011 | upload-alignment | 低 | 三端均以字段名 `file` 使用 `multipart/form-data` 上传；服务端返回 `ApiResult<{url:string}>`。 |
| CHAT-012 | documentation-conflict | 低 | `UploadController.uploadFile` 注释声明支持 `pdf/doc/docx`，但 `UploadService.uploadFile` 的 `FILE_EXTENSIONS` 仅包含 `pdf`。 |
| CHAT-013 | behavior-divergence | 中 | Vue 发送简历消息时 `content=resume.attachmentUrl`；ArkTS `handleSendResume` 调用 `sendMessageWithType(..., 2, '', ...)`，`content` 传空字符串，导致服务端保存空内容，ArkTS 简历消息可能无法预览/下载。 |
| CHAT-014 | behavior-divergence | 低 | 未读数策略：Java 提供 `/api/chat/unread-count`；Vue 由 chatStore 在会话列表刷新时计算；ArkTS 通过 `/api/chat/sessions` 本地求和并上限 99。结果理论上可一致，实现路径不同。 |
| CHAT-015 | behavior-divergence | 低 | ArkTS WS 重连最多 5 次；Vue 无限重连；两者均无指数退避。 |
| CHAT-016 | blocked-missing-file | 中 | 任务要求读取的 `pages/ChatPage.ets` 不存在；聊天列表页拆分为 `pages/tab/recruiter/RecruiterChatTab.ets` 与求职者消息入口。本审计仅基于实际存在文件完成。 |
| CHAT-017 | behavior-alignment | 低 | `sessionType` 为 `null/空` 时，Java/ArkTS 均默认投递会话，兼容旧数据。 |

### 8.5 共享数据/通知/收藏/分页

证据文件：`.omo/audit/arkts-api/shared-evidence.json`

| 编号 | 类别 | 严重 | 描述 |
|------|------|:----:|------|
| FAV-001 | pagination | 中 | `FavoriteServiceImpl.listFavorites` 手动构造 `PageResult` 时未 `setTotalPages`，ArkTS `FavoriteService.ets:42-54` 依赖 `totalPages` 判断是否继续翻页；结果默认只加载第一页，超出部分静默不显示。 |
| FAV-002 | field-mapping-degradation | 低 | 收藏列表转 `JobData` 时，`totalQuota/enterpriseName/region/tag` 等字段被降级为空/0，与求职者端搜索结果卡片信息不一致。 |
| ENT-001 | role-check | 中 | `EnterpriseController.getEnterpriseById` 返回完整 `Enterprise` 实体，包含 `creditCode`、`licenseImgUrl`、`userId`、`rejectReason` 等敏感字段，未做角色或所有权校验。 |
| NOT-001 | notification-semantics | 低 | ArkTS 招聘端 `NotificationService.getNewDeliveries` 固定 `type=0`，但不传 `isRead`；若铃铛仅展示未读投递，应补 `isRead=0`。需产品确认。 |
| DOC-001 | documentation-conflict | 低 | `api.md` 未记录收藏相关接口。 |
| DOC-002 | documentation-conflict | 低 | `api.md` 未记录求职者公共接口 `GET /api/enterprise/list`、`GET /api/enterprise/{id}/tasks`、`GET /api/tasks/tags/all`。 |

---

## 9. 风险汇总（按严重级别）

| 严重 | 数量 | 关键问题 |
|------|:----:|----------|
| 高 | 1 | F2 招聘者“重新提交”按钮条件错误，会触发 Java 业务异常 |
| 中 | 7 | S1/S2 求职者状态/筛选缺失、F1/F3 招聘者完成与状态标签缺失、S5/FAV-002 收藏字段降级、CHAT-013 简历消息 content 为空、FAV-001 收藏分页终止、ENT-001 企业详情敏感字段暴露 |
| 低 | 23 | 标签/筛选缺失、默认地址不一致、403 错误处理、文档冲突、WS token URL 编码、未读数策略差异、重连策略差异等 |
| 信息 | 2 | S8/F7 后端集成验证阻塞 |

---

## 10. 阻塞项与未执行验证

| 阻塞项 | 原因 | 解除条件 |
|--------|------|----------|
| 后端集成验证（登录、投递、录用、complete、分页等） | 无运行中的 Java 服务与测试账号 | 启动 `uniseek_java`，初始化数据库，准备求职者/HR 测试账号 |
| 设备/Hvigor 测试 | 无 DevEco Studio / 模拟器 / 签名 | 提供可用鸿蒙设备或模拟器 |
| 真实网络/WebSocket 抓包 | 后端与设备均不可用 | 解除前两项后，使用代理或日志抓包 |

---

## 11. 复现指引

### 11.1 复现 F2（招聘者“重新提交”按钮条件错误）
1. 使用 HR 账号登录 ArkTS 端；
2. 进入招聘者职位列表，找到一条 `status=0 待审核` 且服务端无驳回原因或驳回原因为空的职位；
3. 由于 ArkTS 在 `status=0 && rejectReason 存在` 时显示重新提交按钮，手动构造 `rejectReason` 不为空的待审职位即可在 UI 看到按钮；
4. 点击后调用 `PUT /api/tasks/{id}/resubmit`，Java 返回业务异常：`"重新提交仅允许已驳回的职位"`。

### 11.2 复现 FAV-001（收藏分页只加载第一页）
1. 准备求职者账号，收藏超过 20 条职位；
2. 打开 ArkTS 收藏列表，调用 `GET /api/favorites?page=1&pageSize=20`；
3. 后端返回 `total=25`、`totalPages=1`（未设置），ArkTS 判断 `currentPage >= totalPages`，不再触发第二页请求。

### 11.3 复现 CHAT-013（简历消息内容为空）
1. 使用求职者账号进入与 HR 的聊天详情；
2. 点击“发送简历”按钮；
3. ArkTS 发送 `POST /api/chat/sessions/{id}/messages`，body 为 `{ "applicationId":... ,"content":"","messageType":2,... }`；
4. 服务端保存 content 为空字符串，导致对方无法预览/下载附件。

---

## 12. 结论与建议

1. **可确认的实现缺陷（需修复）**
   - 补齐 ArkTS 求职者/招聘者状态标签 `5 已完成`/`5 已驳回`。
   - 修正 `SubmittedPage` 与 `RecruiterApplicationsPage` 的筛选条件，使其与 Java 状态机 0-5 对齐。
   - 修正招聘端“重新提交”按钮显示条件为 `status===5`。
   - 修复 `FavoriteServiceImpl.listFavorites` 手动分页中漏设 `totalPages` 的问题（后端）。
   - 修正 ArkTS 收藏列表到 `JobData` 的字段映射，或后端直接返回 `Task`/`TaskVO` 列表。
   - ArkTS `ChatDetailPage.handleSendResume` 应发送简历附件 URL 作为 `content`。
   - ArkTS `ChatWebSocketService.handleMessage` 应处理 `ERROR` 帧并提示用户。
   - Java `EnterpriseController.getEnterpriseById` 应对 `Enterprise` 实体脱敏。

2. **文档冲突**
   - `api.md` 存在 20 处字段/端点缺失或与代码不一致，建议以 Java Controller/DTO 为准刷新文档，尤其是收藏、聊天、任务状态相关接口。

3. **协议/体验差异**
   - 403 权限不足、WS token URL 编码、重连策略、上传超时与进度、未读数计算路径在三端实现不同，建议统一或由产品明确各端行为。

4. **阻塞项**
   - 真实后端集成、设备/Hvigor、真实 WebSocket 抓包均未执行，建议在具备环境后补齐，以将当前 `blocked-runtime` 项升级为 `confirmed` 或排除。

---

## 13. 产物清单

| 产物 | 路径 |
|------|------|
| ArkTS 表面清单 | `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\arkts-surface.json` |
| Java-Vue 接口矩阵 | `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\java-vue-contract.json` |
| matrix 结构统计 | `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\java-vue-findings.json` |
| 传输协议证据 | `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\transport-evidence.json` |
| 求职者流程证据 | `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\seeker-evidence.json` |
| 招聘者流程证据 | `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\recruiter-evidence.json` |
| 聊天/WebSocket 证据 | `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\chat-evidence.json` |
| 共享数据/通知/收藏证据 | `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\shared-evidence.json` |
| mock transport 测试结果 | `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\scripts\mock-transport-test-output.json` |
| WS 帧隔离测试脚本 | `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\scripts\chat-frame-test.js` |
| 本审阅报告 | `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\arkts-api-compatibility-report.md` |

---

*本报告由只读审阅生成，未修改 `uniseek_arkts`、`uniseek_java`、`uniseek_vue`、`api.md` 中的任何产品代码。所有修复建议仅作为审阅结论，需用户决策后另行实施。*
