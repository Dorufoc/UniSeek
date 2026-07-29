# arkts-api-compatibility-audit - Work Plan
## TL;DR (For humans)
本计划只生成 ArkTS API 兼容性 Markdown 审阅文档，并允许新增隔离的验证测试代码/脚本来确认实际调用与结果。禁止修改任何现有产品代码，禁止修改 `uniseek_java/`、`uniseek_vue/`、`api.md`，禁止新增管理后台功能。审阅基线优先级为：Java Controller/DTO/Interceptor 的实际可用 API > Vue API 与页面中的事实调用和响应消费 > `api.md` 辅助说明。计划将覆盖现有 ArkTS 的传输鉴权、求职者、招聘者、聊天文件、公共数据/通知/收藏五个部分，记录每个接口的路由、HTTP 方法、参数、响应、鉴权、分页、上传、WebSocket 和错误行为，执行可行的 happy/failure 验证，并把测试结果、无法执行项、证据路径和修复建议写入 Markdown。不会修改产品实现，也不会将审阅结论自动转化为修复。

## Scope
IN：
- 只读审阅 `uniseek_arkts/` 现有页面、组件、Service、ApiClient、WebSocket、文件传输策略和已有测试。
- 只读核对 `uniseek_java/` 的 Controller、DTO、Interceptor、WebSocket handler、上传服务和响应/分页类型。
- 只读核对 `uniseek_vue/src/api/`、Vue stores、composables 和相关页面中的事实调用、字段与响应消费。
- 新增隔离验证测试代码或脚本，仅用于捕获实际请求和验证响应；所有新增验证代码、fixture、日志和结果必须写入 `.omo/audit/arkts-api/`，不得写入 ArkTS 既有测试树或任何产品模块目录。
- 新增一份中文 Markdown 审阅文档，包含接口矩阵、问题清单、证据、测试命令/结果、环境限制、风险等级和修复建议。

OUT：
- 不修改任何现有 ArkTS 产品源码、页面、组件、Service、配置或资源。
- 不修改 Java、Vue、`api.md`、数据库、Mock 数据和现有业务测试。
- 不新增或补齐管理后台页面/接口。
- 不提交、推送或自动执行 Git commit。
- 不把审阅中的修复建议直接实现；修复建议只作为文档结论。
- 不审计 ArkTS 未调用的 Java `TelemetryController`、`admin/controller/*` 和其他未被现有 ArkTS 功能引用的后台接口；这些接口在矩阵中统一标记为 `out-of-arkts-scope`，不视为遗漏。
- 执行前置条件：优先要求工作区干净；若工作区已有变更，则必须先记录 HEAD、完整 `git status --short`、`git diff --stat`、`git diff --name-only` 和未跟踪文件清单，并由用户明确选择“清理后开始”或“冻结当前脏基线后继续”。只有用户选择冻结且基线快照完整时才能继续；无法区分前置变更与审阅变更时，必须停止。
- 所有新增验证脚本、测试代码、fixture、抓包、JSON、日志和 Markdown 产物只能写入 `.omo/audit/arkts-api/`；不得写入既有 ArkTS 测试树、`entry/src/main/ets/**`、`uniseek_java/**`、`uniseek_vue/**` 或 `api.md`。

Must-NOT-Have：
- 产品源码 diff 不得出现；若验证测试必须改变现有入口或依赖，应改为隔离测试文件，不得修改生产实现。
- 审阅文档不得把 `api.md` 与 Java/Vue 冲突的内容当作事实 API。
- 任何“通过”结论必须对应实际命令、输入、输出或可复核证据路径，不接受只凭静态 grep 的通过声明。

## Verification strategy
采用实现后测试，但这里的“实现”仅指新增隔离审阅验证代码/脚本，不指产品代码修复。

- 静态核对：CodeGraph 仅用于可索引的 Java/Vue 文件；ArkTS `.ets` 通过文件读取和隔离提取脚本建立 ArkTS → Java → Vue 三方接口矩阵；每条记录保留绝对路径、符号或行号。若 CodeGraph 不可用或索引滞后，必须记录 `index-unavailable` 并使用文件读取替代。
- 本地单元验证：运行既有 Hypium 测试，确认基线；新增测试只覆盖请求构造、响应解包、状态映射、错误分类等可隔离逻辑。
- 请求级验证：在不改产品实现的前提下，通过 `.omo/audit/arkts-api/` 内的 mock transport、代理、测试服务器或独立脚本捕获实际 URL、方法、headers、query、JSON body、multipart part 和 WebSocket 帧。
- 后端集成验证：若 Java 服务和测试账号可用，针对每个接口执行成功与失败用例；若不可用，记录阻塞原因，不虚报通过。
- 设备验证：若 DevEco Studio、签名、设备/模拟器可用，执行 `ohosTest` 和关键页面流程；否则把设备测试列为未执行。
- 审阅输出：每个问题必须标注 `confirmed`、`documentation-conflict`、`unverified` 或 `blocked`，并给出最小复现方式和建议修复范围。
- 数据隔离：集成验证不得污染共享或真实数据库；没有一次性本地数据库、隔离 schema 或明确只读 fixture 时，必须标记为 `blocked`。

## Execution strategy
按依赖顺序分波次执行：先建立环境能力、实际文件清单和事实接口矩阵，再验证基础传输，之后验证业务服务，最后执行跨页面/跨端回归并生成审阅文档。CodeGraph 只用于可索引的 Java/Vue 文件；ArkTS `.ets` 必须使用文件读取和隔离脚本提取。所有审阅产物和验证脚本统一写入 `.omo/audit/arkts-api/`，不修改既有测试入口，不修改 `entry/src/main/ets/**`。Java/Vue/现有 ArkTS 产品文件在执行前后都要做只读变更检查，确保没有被修改。

## Todos
- [x] 1. 建立只读基线与审阅证据目录 - to ensure the audit is reproducible and product code remains untouched - expect the exact ArkTS/Java/Vue files, current git status, existing test commands, environment availability, and output artifact locations are recorded
  - References: `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\AGENTS.md`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_arkts\build-profile.json5`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_arkts\entry\build-profile.json5`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_arkts\oh-package.json5`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_arkts\entry\src\test\List.test.ets`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_arkts\entry\src\ohosTest\ets\test\List.test.ets`; `.gitignore`
  - Acceptance: Create `.omo/audit/arkts-api/baseline.json` containing workspace path, HEAD revision, complete `git status --short`, `git diff --stat`, `git diff --name-only`, untracked-file list, per-path content hashes for all pre-existing modified/tracked files and bytes for all pre-existing untracked files, tool availability (`node -v`, `npm -v`, `mvn -v`, `ohpm -v`, `hvigorw --version` or exact failure), existing test entry points, generated-directory rules, and a whitelist stating that existing `uniseek_arkts/entry/src/main/ets/**`, `uniseek_java/**`, `uniseek_vue/**`, and `api.md` are read-only. Set `baselineMode` to `clean` or `frozen-dirty` only after the user explicitly chooses the path. Create `.omo/audit/arkts-api/evidence/` with schema `{label, command, fixture, expected, actual, status, sourcePaths}`. If a dirty baseline is not explicitly frozen, stop before creating any further audit artifacts.
  - QA happy: Run `git status --short`; run each available version command; run the existing local ArkTS test command if available; write exit codes and report paths to `baseline.json`.
  - QA failure: Run unavailable backend/device/Hvigor checks and record exact stderr and `status: blocked`; if a dirty baseline is not explicitly frozen, stop rather than treating the final diff as proof of no change. After an approved baseline, compare final `git status --short` and per-path hashes against `baseline.json`; assert that pre-existing dirty paths are byte-identical and that only new paths under `.omo/audit/arkts-api/` are allowed. Use `git diff --exit-code -- uniseek_arkts/entry/src/main/ets uniseek_java uniseek_vue api.md` only as an additional guard, never as the sole frozen-baseline comparison.
  - Commit: No product commit; only the final Markdown review and explicitly approved isolated test artifacts may be included in a later user-approved commit.

- [x] 2. 构建 Java 可用 API 与 Vue 事实调用矩阵 - to establish the authoritative contract before judging ArkTS - expect every Java-backed endpoint used by the existing ArkTS scope has route/method/auth/request/response evidence and Vue fact-call evidence where available
  - References: `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_java\src\main\java\com\uniseek\controller`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_java\src\main\java\com\uniseek\user\controller\UserController.java`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_java\src\main\java\com\uniseek\upload\controller\UploadController.java`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_java\src\main\java\com\uniseek\controller\TelemetryController.java`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_java\src\main\java\com\uniseek\admin\controller`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_java\src\main\java\com\uniseek\auth\dto`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_java\src\main\java\com\uniseek\dto`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_java\src\main\java\com\uniseek\common\ApiResult.java`; `PageResult.java`; `JwtAuthInterceptor.java`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_vue\src\api`; `src\stores`; `src\composables`; `src\pages`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\api.md`
  - Acceptance: Create `.omo/audit/arkts-api/java-vue-contract.json` from actual Java routes/DTOs and Vue fact calls. Each row contains a `sourceOfTruth` value of `java-source-truth`, `vue-fact-call`, `api-md-conflict`, or `out-of-arkts-scope`. The matrix explicitly gives Java as runtime truth, Vue as fact-call truth, and `api.md` only as a discrepancy source. It includes `UserController` and the correctly located `upload/controller/UploadController.java`. It marks `TelemetryController`, all `admin/controller/*`, and any Java endpoint not called by existing ArkTS as `out-of-arkts-scope` rather than silently omitting them.
  - QA happy: Run a file-existence precheck for every reference; independently verify representative auth, user, paginated, multipart, WebSocket, and role-protected rows against Java source and Vue callers; each row has a source path and symbol/line citation.
  - QA failure: Deliberately classify a known `api.md`/Java conflict as `documentation-conflict` and verify the matrix retains both source snippets without using the documentation value as the implementation baseline.
  - Commit: No product commit; matrix belongs in the final Markdown artifact.

- [x] 3. 生成 ArkTS 页面与 Service 全量调用清单 - to ensure no existing ArkTS feature is silently omitted - expect every `pages/**/*.ets`, `components/**/*.ets`, and `services/*.ets` entry point plus every ApiClient/upload/WebSocket call is indexed
  - References: `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_arkts\entry\src\main\ets\pages`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_arkts\entry\src\main\ets\components`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_arkts\entry\src\main\ets\services`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_arkts\entry\src\main\resources\base\profile\main_pages.json`
  - Acceptance: Create `.omo/audit/arkts-api/arkts-surface.json` containing every registered page, every page file, every Service file, every `ApiClient.get/post/put/patch/delete/putWithParams` route literal, every upload route, every WebSocket event, and caller page/component paths. Missing/unregistered page files and local-only services are explicitly labeled.
  - QA happy: Run a read-only extraction script using file traversal plus regex/AST-safe parsing and compare its route set to the manually reviewed matrix; report zero unexplained route literals.
  - QA failure: Introduce no product changes; instead run the extractor against a deliberately missing reference path and assert it exits nonzero with the missing path in the report.
  - Commit: No product commit; surface inventory and extractor output only.

- [x] 4. 验证 ApiClient 传输、鉴权和错误协议 - to detect request construction and response handling deviations without changing ApiClient - expect captured or mocked evidence for base URL, HTTP verb, Authorization, JSON/query serialization, status/code handling, timeout, 401, and non-200 failures
  - References: `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_arkts\entry\src\main\ets\services\ApiClient.ets`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_arkts\entry\src\main\ets\services\ServerConfig.ets`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_java\src\main\java\com\uniseek\config\JwtAuthInterceptor.java`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_java\src\main\java\com\uniseek\common\exception\GlobalExceptionHandler.java`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_vue\src\api\index.ts`
  - Acceptance: Report exact captured request headers/query/body and exact response-to-error mapping for 200, 400, 401, 403, 404, 409, 500, transport timeout, and malformed JSON. The test harness must not edit or monkey-patch production source on disk.
  - QA happy: Mock a successful `ApiResult` and confirm only `data` is consumed while Authorization is formatted as `Bearer <token>`.
  - QA failure: Feed HTTP 401, business code 401, business code 403, timeout, and malformed response; record whether ArkTS behavior matches Java/Vue expectations and classify mismatches.
  - Commit: No product commit; isolated transport harness and report only.

- [x] 5. 核对求职者现有流程与请求字段 - to verify auth/profile/resume/search/detail/apply/favorite behavior against Vue and Java - expect a page-to-service trace and tested field/status matrix for every existing seeker flow
  - References: `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_arkts\entry\src\main\ets\pages\LoginPage.ets`; `RegisterPage.ets`; `ProfileDetailPage.ets`; `ResumePage.ets`; `ResumeDetailPage.ets`; `RealNameAuthPage.ets`; `SettingsPage.ets`; `ResumePage.ets`; `SearchPage.ets`; `SearchResultsPage.ets`; `JobDetailPage.ets`; `SubmittedPage.ets`; `FavoritesPage.ets`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_arkts\entry\src\main\ets\services\AuthService.ets`; `UserService.ets`; `UserSession.ets`; `ResumeService.ets`; `ApplicationService.ets`; `FavoriteService.ets`; `DataService.ets`; matching concrete files under `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_vue\src\api`, `src\stores`, `src\composables`, and `src\pages`; Java `AuthController.java`, `UserController.java`, `ResumeController.java`, `TaskController.java`, `ApplicationController.java`, `FavoriteController.java` and their DTOs
  - Acceptance: Record route/method/body/query/response/auth for every existing seeker call; explicitly verify resume publish/unpublish reachability, application completion support, status 0-5 labels/filters, favorite field mapping, and real-name gates. Do not add missing UI; document it as a finding.
  - QA happy: Execute mocked or integration cases for login/register, current user, resume load/save/publish, task search/detail, apply, favorite add/remove/check/list, and application list/detail.
  - QA failure: Execute unauthenticated, wrong-role, duplicate-apply, duplicate-favorite, missing-resource, invalid-field, and server-error cases; preserve raw request/response evidence.
  - Commit: No product commit; seeker findings and isolated test artifacts only.

- [x] 6. 核对招聘者现有流程与投递状态机 - to verify enterprise/job/application calls without adding admin parity - expect confirmed status mapping and request evidence for current recruiter pages
  - References: `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_arkts\entry\src\main\ets\pages\RecruiterHomePage.ets`; `RecruiterPublishJobPage.ets`; `RecruiterJobFormPage.ets`; `RecruiterApplicationsPage.ets`; `RecruiterRequestsPage.ets`; `RecruiterEnterprisePage.ets`; `CompanyPage.ets`; `CompanyDetailPage.ets`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_arkts\entry\src\main\ets\pages\tab\recruiter\RecruiterHomeTab.ets`; `RecruiterChatTab.ets`; `RecruiterProfileTab.ets`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_arkts\entry\src\main\ets\services\RecruiterService.ets`; `RecruiterTypes.ets`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_java\src\main\java\com\uniseek\controller\EnterpriseController.java`; `TaskController.java`; `ApplicationController.java`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_java\src\main\java\com\uniseek\service\impl\ApplicationServiceImpl.java`; Vue `PostJob.vue`, `ResumePool.vue`, `Talents.vue`, and matching API files
  - Acceptance: Verify enterprise submit/update, job create/update/status/resubmit, task application list, status updates, complete endpoint availability, and role checks. Status 0-5 must be compared to Java behavior and Vue labels; any missing ArkTS call is a documented finding, not an implementation task.
  - QA happy: Execute valid HR enterprise/job/application flows with captured requests and expected response shapes.
  - QA failure: Execute seeker-as-HR, unverified enterprise, invalid status transition, rejected task resubmit, nonexistent application, and completion edge cases; record Java response code/message.
  - Commit: No product commit; recruiter findings and isolated test artifacts only.

- [x] 7. 核对聊天、WebSocket、上传下载协议 - to prove transport-level compatibility for the highest-risk real-time paths - expect REST and frame-level evidence for session/message/read/init/direct/unread/upload/download/reconnect/error behavior
  - References: `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_arkts\entry\src\main\ets\services\ChatService.ets`; `ChatWebSocketService.ets`; `FileTransferPolicy.ets`; `ChatTypes.ets`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_arkts\entry\src\main\ets\pages\ChatDetailPage.ets`; `ChatPage.ets`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_java\src\main\java\com\uniseek\controller\ChatController.java`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_java\src\main\java\com\uniseek\chat\websocket\ChatWebSocketHandler.java`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_java\src\main\java\com\uniseek\upload\controller\UploadController.java`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_java\src\main\java\com\uniseek\upload\service\UploadService.java`; Vue `chat.ts`, `upload.ts`, `useChatWebSocket.ts`, `Chat.vue`
  - Acceptance: Capture exact REST URL/method/query/body, multipart field/MIME/response URL, WebSocket URL/token/PING/NEW_MESSAGE/SEND_ACK/MESSAGE_READ/ERROR, reconnect behavior, and read/unread semantics. Classify Java-vs-Vue/ArkTS differences independently from `api.md` discrepancies.
  - QA happy: Send text, image, and resume attachment; load older messages; mark read; initialize/direct session; upload/download supported files; receive a new message over WebSocket.
  - QA failure: Use expired token, invalid message type, empty/oversize content, unsupported file extension/MIME, network disconnect, malformed WS frame, and server ERROR frame; retain logs/frames and exit status.
  - Commit: No product commit; protocol evidence and isolated harness only.

- [x] 8. 核对公共数据、通知、收藏、分页和页面回归 - to cover remaining existing ArkTS services and cross-page consistency - expect complete coverage of DataService/TaskService/EnterpriseDiscoveryService/NotificationService/FavoriteService and relevant UI mappings
  - References: `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_arkts\entry\src\main\ets\services\DataService.ets`; `TaskService.ets`; `EnterpriseDiscoveryService.ets`; `NotificationService.ets`; `FavoriteService.ets`; `SearchHistoryService.ets`; `RecordService.ets`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_java\src\main\java\com\uniseek\controller\CategoryController.java`; `RegionController.java`; `NotificationController.java`; `FavoriteController.java`; `EnterpriseController.java`; Vue `category.ts`, `region.ts`, `notification.ts`, `favorite.ts`, `enterprise.ts`
  - Acceptance: Record all route/method/parameter/response/pagination differences, distinguish local-only services from server APIs, and verify notification/favorite counts, unread filters, page size, total pages, and enterprise/task field mapping.
  - QA happy: Execute category/region tree, tags, enterprise list/detail/tasks, notification list/unread/read-all, favorite check/list/count, and local-history flows.
  - QA failure: Use empty results, invalid IDs, unauthorized calls, invalid pagination, unsupported filters, and server code 400/403/404; record fallback behavior.
  - Commit: No product commit; shared-data findings and isolated test artifacts only.

- [x] 9. 汇总并生成中文 Markdown 审阅文档 - to deliver the requested review artifact without product changes - expect one decision-ready report with evidence, test results, blockers, severity, and fix guidance
  - References: all previous todo evidence; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\AGENTS.md`; `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\api.md`; existing ArkTS test reports under `uniseek_arkts\entry\.test\default`
  - Acceptance: The report contains scope and Must-NOT-Have, source-of-truth hierarchy, full interface matrix, per-module findings, request/response samples, test commands and raw-result paths, confirmed vs documentation-conflict vs blocked labels, severity, reproducibility steps, a complete pre-existing baseline declaration, and a final statement that no product code was modified during the audit. All paths are absolute or workspace-relative and all pass claims have evidence under `.omo/audit/arkts-api/`.
  - QA happy: Render/read the Markdown and verify every matrix row links to an existing file/symbol, every finding has evidence and a recommended validation, the report links `baseline.json`, and no new product-code diff exists relative to the approved baseline.
  - QA failure: Run a structural scan that flags missing evidence, missing status labels, undocumented test results, product-code modifications relative to the approved baseline, or artifacts outside `.omo/audit/arkts-api/`; stop the handoff until the issue is resolved.
  - Commit: Do not commit automatically; report the exact Markdown and optional isolated test files for user review.

## Final verification wave
  - [x] F1. 审阅文档合规性核验 - verify the report contains all required modules, evidence labels, test commands/results, blockers, and explicit no-product-code-change statement - expect a structural checklist with no missing sections
  - [x] F2. 三方事实一致性核验 - independently compare a sample of every module against Java runtime code and Vue fact calls - expect no unsupported “API correct” claim and all `api.md` conflicts labeled
  - [x] F3. 测试证据真实性核验 - rerun or inspect exact test commands, fixtures, captured requests, frames, and result artifacts - expect no pass claim based only on grep, prose, or an agent summary
  - [x] F4. 范围与文件变更核验 - inspect final file status and diff - expect only `.omo/audit/arkts-api/` artifacts plus the already-approved pre-existing baseline, with zero new changes to existing ArkTS product code, Java, Vue, or `api.md`; attach complete `git status --short` and `git diff --name-only` output and a baseline-hash comparison

## Commit strategy
不自动执行 Git commit 或 push。交付对象为 Markdown 审阅文档，以及用户明确允许的隔离验证测试代码/脚本和测试结果文件。任何提交必须另行说明文件清单并等待用户确认。

## Success criteria
- 现有 ArkTS 范围内的所有 Service、页面入口和接口调用均出现在审阅矩阵中。
- 每个接口均以 Java 实际 Controller/DTO/Interceptor 为可用性基线，并以 Vue 事实调用校验请求和响应消费。
- 所有可执行验证均有精确命令、输入/fixture、退出码或捕获请求/响应/帧、结果文件路径。
- 无法执行的后端、设备、签名或网络验证均明确标记为 blocked，并记录原因和复现准备条件。
- 只新增 `.omo/audit/arkts-api/` 下的审阅文档和隔离验证测试产物；相对于经用户确认的基线，现有 ArkTS 产品代码、Java、Vue、`api.md` 均未新增修改。
