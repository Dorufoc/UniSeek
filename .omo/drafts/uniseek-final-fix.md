---
slug: uniseek-final-fix
status: awaiting-approval
user-feedback-applied: 2026-07-15
feedback-1: complaint.target_type 统一为1-企业, 2-用户，不含0-职位（task 6 已修正）
feedback-2: Mock 密码使用实际业务逻辑生成（MD5("123456"+随机盐)），已预生成至 _generated_users.sql（task 8 已修正）
feedback-3: ID 顺序自增 1~26，不使用随机生成（已确认现有 Mock 数据符合）
intent: clear
review_required: true
pending-action: user approval → execute plan + high-accuracy review
approach: 4-wave parallel — SQL清理修复 → Java依赖/注解修复 → 文档全面对齐 → 安全加固 + 最终高精度审查
---

# Draft: uniseek-final-fix

## Components (topology ledger)
| id | outcome | status | evidence path |
|----|---------|--------|--------------|
| DB-SEQ | enterprise 表建表顺序修复（放到 region 之后） | active | uniseek_schema.sql:86-105 vs 145 |
| DB-FILES | 删除废弃 SQL 文件 uniseek.sql / uniseeklv.sql | active | 根目录存在 4 个 SQL 文件 |
| DB-GITIGNORE | .gitignore 增加 Navicat dump 规则 | active | 无对应 gitignore 规则 |
| DB-CATEGORY | category 子分类数据补充完整 | active | uniseek.sql:30 条 vs uniseek_schema.sql:62 条 |
| DB-COMPLAINT | complaint target_type 注释统一（DB/Java/Doc） | active | 三处分别为 1-企业2-用户 / 0-职位1-企业2-用户 |
| DB-MOCK-SALT | Mock 数据统一盐值改为每用户独立随机盐值 | active | uniseek_mock_data.sql 全部用同一盐值 |
| DB-MOCK-ADMIN | Mock 数据超级管理员账号与文档一致 | active | 文档说 18688886666/admin，Mock 中是 13999999999 |
| DB-REGION-VERIFY | 地区数据完整性验证（3432条） | active | uniseek_schema.sql:448-449 声明 |
| JAVA-POM | pom.xml 补充 validation/test/maven-plugin 依赖 | active | pom.xml 缺少 3 个关键依赖 |
| JAVA-OPLOG-PKG | 统一 @OperationLog 注解包路径 | active | EnterpriseController vs ResumeController 不同包 |
| JAVA-FILE-UPLOAD | 文件上传增加配置默认值和文件大小校验 | active | ResumeController.java:40 upload.path 无默认值 |
| JAVA-STUBS | 删除 11 个空 Stub 类 | active | 分散在 controller/ws/config/service/impl 下 |
| JAVA-TASKVO | TaskVO 枚举注释对齐 SQL/API | active | TaskVO.java:39,42,63 |
| JAVA-APPCOUNT | applicationCount Mapper 实现确认 | active | TaskVO.java:88 & TaskMapper.xml |
| JAVA-ROLECONST | 创建 RoleConstant 常量类 | active | 全局魔法数字泛滥 |
| JAVA-ROLE-BUG | TaskServiceImpl role==2 修复 | active | TaskServiceImpl.java:209 |
| JAVA-SUPERADMIN | AdminService 支持 role==99 + 超管 API | active | AdminServiceImpl.java:71-76 |
| JAVA-OPLOG-CONST | OperationType 常量类标准化 | active | OperationLog.java:23 无约束 String |
| DOC-API-CHAPTER | API 文档 5 处章节编号修正（6.x→7.x） | active | api.md:832,885,957,989,1037 |
| DOC-API-DATA-TYPE | data 字段类型修正 Object→Object\|null | active | api.md:26-39 |
| DOC-API-MISSING | API 文档补充通知/聊天/投诉模块接口 | active | api.md 无对应章节 |
| DOC-BIZ-API-PATH | 业务逻辑文档 API 路径与代码对齐 | active | 文档 /register /info /update vs 代码无后缀 |
| DOC-README | README.md 补写完整项目说明 | active | README.md 缺少目录、账号、启动说明 |
| DOC-ROLE | 三份文档统一角色定义 + 超管 99 | active | 需求/API/业务逻辑文档 |
| DOC-SUPER-ADMIN-ACCT | 统一超级管理员账号信息 | active | 文档18688886666 vs Mock 13999999999 |
| SEC-OPLOG-MASK | 操作日志敏感字段脱敏文档说明 | active | uniseeklv.sql 含明文密码/手机号 |
| SEC-DELETE-PII | 从版本库中删除含 PII 的 uniseeklv.sql | active | 该文件含真实用户信息 |

## Open assumptions (announced defaults)
| assumption | adopted default | rationale | reversible? |
|-----------|----------------|-----------|-------------|
| 超级管理员账号 | 采用文档统一值 18688886666/admin，删除 Mock 中不一致的 13999999999 | 文档在前，Mock 在后，统一以文档为准 | 是（可通过 SQL 修改） |
| @OperationLog 正确包路径 | 使用 `com.uniseek.operationlog.annotation.OperationLog` | ResumeController 使用此路径且编译通过，EnterpriseController 的 `common.annotation` 可能不存在 | 是 |
| pom.xml 依赖版本 | validation 使用 Boot 2.2.2 传递版本（不指定），maven-plugin 使用当前 Boot 对应版本 | Spring Boot parent 已管理版本 | 是 |
| 操作日志脱敏方式 | 仅在文档中补充说明，不修改现有代码结构 | 修改日志存储逻辑影响审计完整性，需单独评审 | 是 |

## Findings (cited - path:lines)
- C-01: `uniseek_schema.sql:86-105` enterprise 表含 `fk_enterprise_region` 引用 region，但 region 在第 145 行才创建 → SQL 执行报错
- C-02: 根目录存在 4 个 SQL 文件，其中 uniseek.sql:30 条 category、uniseeklv.sql 含真实用户 PII
- C-03: `uniseeklv.sql:258-276` 存储了明文密码 "111111" 和真实手机号
- C-04: `pom.xml:28-77` 缺少 `spring-boot-starter-validation`、`spring-boot-starter-test`、`spring-boot-maven-plugin`
- C-05: `EnterpriseController.java` 导入 `com.uniseek.common.annotation.OperationLog`；`ResumeController.java` 导入 `com.uniseek.operationlog.annotation.OperationLog` — 不一致
- C-06: `UniSeek全平台业务逻辑设计V2.md:57,67,77` 写的 API 路径为 `/register`、`/info`、`/update`，但实际 `EnterpriseController.java:31,45,60` 为无后缀路径
- C-07: `api.md` 缺少通知(/api/messages)、聊天、投诉模块的接口文档
- C-08: `api.md:731-743` Region 树形结构示例含不存在的市级节点(110100)
- C-09: `兼职招聘平台需求规格说明书.md:25` 说超级管理员手机号 `18688886666` 密码 `admin`，但 uniseek_mock_data.sql 中无此记录
- C-10: `Complaint.java:23` target_type 注释与 SQL schema 不一致
- C-11: `uniseek.sql` 中 enterprise 表缺少 region_id 列和 fk_enterprise_region 外键
- M-01: `TaskServiceImpl.java:209` 硬编码 `role==2`（应为 `role>=9`）
- M-02: `ResumeController.java:40-41` upload.path 无 `@Value` 默认值，未配置则启动失败
- M-03: `api.md:832,885,957,989,1037` 5 处章节编号误标为 6.x（应为 7.x）
- X-01: 三份文档角色定义均缺少 `99-超级管理员` 说明
- X-02: `README.md` 内容为占位符，缺少启动说明、管理员账号、目录结构

## Decisions (with rationale)
1. **统一超级管理员账号**：以业务逻辑设计文档为准，手机号 `18688886666` 密码 `admin`。Mock 数据中现有不一致账号(13999999999)替换为此账号。
2. **删除废弃 SQL 文件**：uniseek.sql 和 uniseeklv.sql 是 Navicat 工具导出产物，结构不完整且含 PII，不应入版本库。删除后加入 .gitignore。
3. **@OperationLog 包路径统一**：使用 `com.uniseek.operationlog.annotation.OperationLog`（因为这是 ResumeController 编译通过的路径），修正 EnterpriseController 的 import。
4. **补充 pom.xml 兼顾向后兼容**：仅添加缺失依赖，不升级任何现有依赖版本。
5. **操作日志不修改代码**：仅文档说明敏感字段脱敏的必要性，代码修改需独立评审。
6. **文档 API 路径以代码为准**：修改业务逻辑文档中的路径描述对齐实际代码实现，而非反之。

## Scope IN
- 数据库：建表顺序修复、废弃 SQL 文件清理、category 补充、gitignore 更新、外键补齐、Mock 数据盐值随机化、超级管理员账号统一
- Java：pom.xml 依赖补充、@OperationLog 包路径统一、文件上传默认值、Stub 清理、TaskVO/Complaint 注释对齐、applicationCount 确认、RoleConstant/OperationType 常量类、TaskServiceImpl role bug 修复、AdminService 超管支持 + 超管 API
- 文档：API 文档章节/类型/内容补全、业务逻辑文档 API 路径对齐、README 重写、三份文档角色定义统一、Region 树形示例修正
- 安全：删除含 PII 的文件、补充操作日志脱敏文档说明

## Scope OUT (Must NOT have)
- ❌ 不修改 ArkTS 端任何代码
- ❌ 不实现完整的超管后台 UI（仅路由/权限级别）
- ❌ 不编写单元测试（单独计划）
- ❌ 不修改 WebSocket 权限逻辑
- ❌ 不修改 `chat_message.send_time` 字段设计
- ❌ 不修改 operation_log 存储逻辑（仅文档说明）

## High-Accuracy Review Record

### Momus 审查结论
**严重度评估: CONDITIONAL-APPROVE** — 发现 14 个问题
- 🔴 阻塞: 5（已存在常量覆盖、role bug 已修复、超管 API 已实现、Stub 已删除、注释矛盾）
- 🟡 警告: 4（FK 已存在、引用行号偏移、.gitignore 不明确、Scope 用户数）
- 🔵 建议: 5（依赖矩阵冗余、QA 场景可自动化等）

### Oracle 审查结论
**严重度评估: CONDITIONAL-APPROVE** — 发现 12 个问题
- 🔴 阻塞: 5（同 Momus + Todo 11 编译失败 + 超管密码不一致 + .gitignore 不存在）
- 🟡 警告: 4（OperationType 常量数不匹配、引用不明确、管理员密码全为123456、注释格式不匹配）
- 🔵 建议: 3（验证步骤增强等）

### 已应用的修复（审查后）
| # | 来源 | 严重度 | 问题 | 修复 |
|:-:|------|:------:|------|------|
| 1 | Momus+Oracle | 🔴 | Todo 16/17 要创建的常量类已存在 | 改为验证性任务，不覆盖文件 |
| 2 | Momus+Oracle | 🔴 | Todo 18 role==2 bug 已修复 | 删除任务，代码已使用 RoleConstant |
| 3 | Momus+Oracle | 🔴 | Todo 19/20 超管支持已实现 | 删除任务，AdminService/Controller 已完整实现 |
| 4 | Oracle | 🔴 | Todo 11 更改 import 会导致编译失败 | 删除任务，保留 common.annotation 不变 |
| 5 | Momus+Oracle | 🔴 | Todo 15 applicationCount 已实现 | 删除任务，Mapper 已包含映射 |
| 6 | Momus+Oracle | 🔴 | Todo 13 Stub 已删除 | 删除任务，文件已不存在 |
| 7 | Momus+Oracle | 🔴 | Todo 6 vs 14 注释矛盾 | 统一为 "1-企业, 2-用户"，删除 Todo 14 的矛盾变更 |
| 8 | Oracle | 🔴 | 超管密码 "admin" 但哈希对 "123456" | 重新生成用户 1(role=9) 和用户 26(role=99) 密码为 "admin" |
| 9 | Oracle | 🔴 | .gitignore 不存在（要创建非追加） | 改为创建新文件 |
| 10 | Momus+Oracle | 🟡 | Todo 4 FK 已存在于 schema | 删除任务，FK 已在第 104 行存在 |
| 11 | Momus+Oracle | 🟡 | 引用行号偏移（schema:50, TaskServiceImpl:209 等） | 全面校对引用行号 |
| 12 | Momus | 🟡 | Scope "25 用户" vs 实际 26 | 统一改为 26 |
| 13 | Oracle | 🟡 | Todo 9 role 注释已含 99-超级管理员 | 改为验证性任务 |
| 14 | Oracle | 🟡 | OperationType 常量名值不一致 | 改为"审计现有常量完整性"而非创建 |

### 修订后计划统计
- 原始任务数: 27
- 删除（已存在/已修复）: 10（Todo 4, 11, 13, 15, 16, 17, 18, 19, 20 + 14 的矛盾变更）
- 新增/保留: 17（含 2 个验证性任务）
- 修订后总任务数: 17

## Approval gate
status: approved (user approval received) + fixes applied from dual review
