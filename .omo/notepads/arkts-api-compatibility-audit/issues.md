# Issues — arkts-api-compatibility-audit

Problems and gotchas encountered during work on this plan.

_Auto-scaffolded by /start-work. Append new entries below - never overwrite._

---

## 2026-07-28 — extract-arkts-surface 扫描结果

产物：`D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\arkts-surface.json`。

### 未发现扫描异常
- 未解析的 import：0 条。
- 无法定位文件/行号的 route literal：0 条。
- `main_pages.json` 中所有 27 个注册页面均存在对应 `.ets` 文件。

### 已知说明
- 9 个未注册页面为 `pages/tab/**` 子页面，属于正常嵌入 tab 的组件式页面，不是遗漏。
- 6 个 `local-only` 服务（`UserSession`、`SearchHistoryService`、`RecordService`、`FileTransferPolicy`、`ChatTypes`、`RecruiterTypes`）仅做本地状态/类型/工具封装，无服务端调用，已单独标注。
- 部分 `.ets` 源文件在 PowerShell 控制台查看时出现中文显示乱码，但脚本使用 UTF-8 读取/写入，产物 JSON 编码正常。

### 扫描限制
- Route literal 提取基于静态字符串字面量；动态拼接路径（如 `'/api/tasks/' + taskId`）仅记录静态前缀部分，并附带完整行号。
- 非 `/api/`、`/ws/`、`ws://`/`wss://` 的字符串会被忽略，避免将 UI 文本（如 `/日`、`/时`、`/月`）误判为路由。

## 2026-07-29 — transport-evidence 不确定点

产物：`D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\transport-evidence.json`。

### 基线未冻结
- 当前工作树仍有大量未提交改动（详见产物 `meta.gitStatusSummary`），所有证据为 `baseline-pending`。

### ArkTS 与 Vue 的默认 base URL 不一致
- ArkTS 硬编码 `http://192.168.246.118:8080`（`ApiClient.ets:26`），Vue 使用 `/api`（`api/index.ts:10`）。
- 运行时若未配置 Nginx/Vite 代理到同一后端，会导致两端连接不同服务实例；暂无统一服务发现配置。

### 403 业务码处理不一致
- Java 通过 `BusinessException(ApiResult.FORBIDDEN, ...)` 返回 HTTP 200 + code=403。
- ArkTS 对 `code === 401` 有专门清理会话逻辑，但对 `403` 仅作为通用错误 reject（`ApiClient.ets:301-303`）。
- Vue 拦截器同样只区分 HTTP 401 和 5xx，对业务 403 仅弹通用错误提示（`api/index.ts:36-70`）。
- 风险：三端对鉴权失败（401）行为明确，但对权限不足（403）缺乏统一 UI 处理；用户可能看不到“无权限”提示。

### HTTP 非 200 与业务码的边界
- ArkTS 未显式读取 `HttpResponse.responseCode`；当 HTTP 非 200 但返回可解析 JSON 时，会按 `json.code` 处理。
- 若 HTTP 非 200 且 body 非 JSON（如 Nginx 502 HTML），ArkTS 将抛出“响应解析失败”而不是区分 HTTP 状态码。

### 文件上传进度与超时
- ArkTS 使用 `request.uploadFile`，超时控制与 `http.request` 不一致，未显式设置上传超时。
- Vue 通过 axios 上传大文件时可配置 `onUploadProgress`，ArkTS 缺少对上传进度的暴露。

### 测试限制
- mock transport 测试使用 Node.js 原生 http 客户端模拟三端行为，未在真实 ArkTS 运行时中执行；真实 `@ohos.net.http` 和 `request.uploadFile` 的边界行为（timeout、证书、缓存）需 DevEco 环境运行确认。

## 2026-07-29 — 共享数据/通知/收藏/分页核对问题

产物：`D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\shared-evidence.json`。

### 基线状态
- 产物顶部声明 `baseline-pending`；当前工作树仍有未提交改动（见 `java-vue-contract.json:meta.gitStatusSummary`），所有结论以当前工作树为准。

### 已确认实现问题
- **FAV-001 收藏分页 totalPages 缺失**
  - `FavoriteServiceImpl.java:80-85` 手动 `new PageResult` 时未 `setTotalPages`，ArkTS `FavoriteService.ets:42-54` 依赖 `totalPages` 判断是否继续翻页。
  - 结果：ArkTS 收藏列表默认只加载第一页（20 条），超出部分静默不显示。
- **FAV-002 收藏列表字段降级映射**
  - 收藏结果转 `JobData` 时，`totalQuota/enterpriseName/region/tag` 等均被写死为空/0，导致收藏卡片信息缺失。
- **ENT-001 公开企业详情未脱敏**
  - `EnterpriseController.java:86-93` 对 `/api/enterprise/{id}` 返回完整 `Enterprise`，包含 `creditCode`、`licenseImgUrl`、`userId`、`rejectReason` 等敏感字段，未做角色或所有权校验。

### 文档冲突（api.md）
- **DOC-001** `api.md` 未收录收藏接口（`/api/favorites`、`/api/favorites/check`、`/api/favorites/count`）。
- **DOC-002** `api.md` 未收录求职者公共接口 `GET /api/enterprise/list`、`GET /api/enterprise/{id}/tasks`、`GET /api/tasks/tags/all`。
- 核对时未将 `api.md` 作为字段真相来源，仅记录其与代码不一致之处。

### 待确认/阻塞项
- **NOT-001 招聘端铃铛未读过滤语义不明**
  - ArkTS `NotificationService.getNewDeliveries` 固定 `type=0`，但不传 `isRead`；若铃铛仅展示未读投递，应补 `isRead=0` 过滤；需产品确认后修改。

### 需要后端数据验证但未阻塞的项
- `FavoriteServiceImpl.listFavorites` 的 `totalPages` 问题、企业详情敏感字段暴露问题属于纯代码审查可确认，无需真实数据即可判定。

---

## 2026-07-29 — 招聘者流程核对发现

产物：`D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\recruiter-evidence.json`。

### 已确认问题
| 编号 | 类别 | 严重 | 说明 |
|------|------|------|------|
| F1 | missing-arkts-call | 中 | ArkTS 未调用 `/api/applications/{id}/complete`，Java 已支持 3→5 已完成 |
| F2 | condition-mismatch | 高 | ArkTS 在 `status=0` 且 `rejectReason` 存在时显示"重新提交"，但 Java 要求 `status=5` |
| F3 | status-label-mismatch | 中 | ArkTS `APPLICATION_STATUS_LABELS` 缺少 `5`，导致"已完成"显示为"未知" |
| F4 | status-label-mismatch | 低 | ArkTS `JOB_STATUS_LABELS` 缺少 `5`，导致"已驳回"显示为"未知" |
| F5 | filter-mismatch | 低 | ArkTS 投递筛选栏缺少 `2 待定`/`5 已完成`（后者因 complete 未接入） |
| F6 | documentation-conflict | 低 | `TaskRequest.java` 对工作类型/薪资单位注释与 `Task.java`、ArkTS、Vue 不一致 |
| F7 | blocked-runtime | 信息 | 后端/账号不可用，未执行实际请求抓包与 happy/failure 验证 |

### 记录约定
- 所有问题状态均写入 `recruiter-evidence.json`，未修改任何 ArkTS / Java / Vue 产品代码。
- 修复建议只是审阅结论，未在本次任务中落地。

---

## 2026-07-29 — 聊天 / WebSocket / 上传协议审计发现

产物：`D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\.omo\audit\arkts-api\chat-evidence.json`。

### 已发现问题

| 编号 | 类别 | 严重 | 说明 |
|------|------|------|------|
| C1 | blocked-missing-file | 中 | 任务要求读取 `pages/ChatPage.ets`，但工作树中不存在；聊天列表页拆分为 `RecruiterChatTab.ets` 与求职者入口 |
| C2 | documentation-conflict | 低 | `NEW_MESSAGE` 服务端未下发 `isRead`，ArkTS `ChatMessageVO`/`ChatProtocolMappers` 期望该字段；Vue 已做 `?? 1` 兜底 |
| C3 | documentation-conflict | 低 | Java `UploadService.uploadFile` 实际仅允许 `pdf`，但 `UploadController.uploadFile` 注释声明支持 `pdf/doc/docx` |
| C4 | behavior-divergence | 中 | ArkTS `handleSendResume` 发送 `messageType=2, content=''`，Vue 发送实际 `resume.attachmentUrl`；ArkTS 简历消息内容为空 |
| C5 | behavior-divergence | 低 | ArkTS `ChatWebSocketService.handleMessage` 忽略 `ERROR` 帧，用户无法感知 token/参数/业务错误 |
| C6 | behavior-divergence | 低 | ArkTS 限制 WS 重连最多 5 次，Vue `useChatWebSocket` 无限重连；策略不一致 |
| C7 | behavior-divergence | 低 | ArkTS 与 Vue 使用 REST 发送消息和标记已读，Java WS 同时提供 `SEND_MESSAGE` / `READ_RECEIPT` 但未被前端使用 |
| C8 | potential-incompatibility | 低 | ArkTS 对 WS URL 的 token 做 `encodeURIComponent`，Java `extractToken` 未解码；标准 JWT 字符安全，特殊字符会失败 |
| C9 | behavior-divergence | 低 | 未读数策略：Java 提供 `/api/chat/unread-count`，ArkTS 本地拉取 `/api/chat/sessions` 求和，Vue 由 store 维护 |

### 测试限制
- 后端集成/WS 真机测试标记为 `blocked`：环境无运行中的 MySQL/后端，且无 DevEco 模拟器。
- Java `uniseek_java/src/test/java/com/uniseek/chat/` 下仅有 `ChatSessionTypeTest`，已通过；缺少 `ChatWebSocketHandler` 相关单元/集成测试。
- ArkTS 协议逻辑已通过 Node 隔离脚本 `chat-frame-test.js` 验证（12 项通过）。

### 记录约定
- 所有发现均写入 `chat-evidence.json`，未修改任何 ArkTS / Java / Vue 产品代码。
