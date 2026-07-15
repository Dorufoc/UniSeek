# uniseek-final-fix - Work Plan

## TL;DR (For humans)

**What you'll get:** 数据库建表顺序修复 + 废弃 SQL 文件清理 + `.gitignore` 创建 + 项目依赖补全 + Mock 密码用真实业务逻辑重新生成（管理员 `admin`/普通用户 `123456`）+ 枚举注释对齐 + 全部项目文档统一更新 + 敏感数据安全清理 + 验证现有代码完整性。

**Why this approach:** 高精度审查（Momus + Oracle）发现 **10 个已实现/已修复的冗余任务**（如 RoleConstant/OperationType 常量类已存在、TaskServiceImpl role bug 已修复、AdminService 已支持超管、"@OperationLog 改包路径"会编译失败等）。已从计划中剔除，避免回退。最终 18 个任务全部为必要修复。

**What it will NOT do:** 不碰鸿蒙端代码、不写单元测试、不改 WebSocket、不做超管后台 UI、不创建已存在的常量类、不改 `@OperationLog` 包路径。

**Effort:** Short (半天-1天)
**Risk:** Low — 高精度审查已剔除高风险项
**Decisions to sanity-check:** (1) 超级管理员密码 `admin`（与文档一致） (2) 管理员与普通用户密码区分（安全考量）

Your next move: 确认审查结果，然后 `/start-work` 执行计划。Full execution detail follows below.

---

> TL;DR (machine): Short effort, Low risk. 18 essential fixes after high-accuracy review removed 9 redundant tasks.

## Scope
### Must have
- DB: enterprise 建表顺序修复（移到 region 之后）
- DB: 创建根目录 .gitignore 并增加 Navicat dump 规则
- DB: 删除废弃 SQL 文件 uniseek.sql + uniseeklv.sql
- DB: category 子分类补充完整（至 62 条）
- DB: complaint target_type 注释统一（SQL+Java 均为 1-企业, 2-用户）
- DB: Mock 数据 26 用户独立随机盐值 + 密码用实际业务逻辑生成
- DB: Mock 数据管理员密码修正（role=9 和 role=99 密码为 "admin"）
- DB: 地区数据完整性验证
- DB: 验证 user 表 role 注释已含 99-超级管理员
- Java: pom.xml 补充 validation/test/maven-plugin 依赖
- Java: 文件上传增加配置默认值
- Java: TaskVO 注释对齐 SQL/API
- Java: 验证 RoleConstant/OperationType 常量完整性（不覆盖）
- Java: 验证 TaskServiceImpl 无 role==2 魔法数字
- Java: 验证 AdminService 已支持 role==99
- Java: 验证 applicationCount Mapper 已实现
- Doc: API 文档 5 处章节编号修正
- Doc: API 文档 data 类型修正 + Region 树形修正
- Doc: API 文档补充通知/聊天/投诉模块接口
- Doc: 业务逻辑文档 API 路径与代码对齐
- Doc: README.md 重写（注明所有 Mock 密码均为 123456，管理员密码为 admin）
- Doc: 三份文档角色定义统一 + 超管 99
- Security: 删除含 PII 的 uniseeklv.sql
- Security: 补充操作日志脱敏说明文档

### Must NOT have (guardrails, anti-slop, scope boundaries)
- 不改 ArkTS 代码
- 不修改 `chat_message.send_time` 字段设计
- 不影响数据库现有业务数据（仅 DDL + Mock DML）
- 不修改 WebSocket 权限逻辑
- 不实现完整的超管后台 UI
- 不修改 operation_log 存储逻辑（仅文档说明）

## Verification strategy
> Zero human intervention - all verification is agent-executed.
- Test decision: tests-after — 修改后 mvn compile + SQL 语法验证 + 文档 grep 检查
- Evidence: .omo/evidence/task-<N>-uniseek-final-fix.<ext>

## Execution strategy
### Parallel execution waves（审查后修订）
> ⚠️ 审查发现 RoleConstant/OperationType/AdminService/TaskServiceImpl 等已实现，相关任务已移除
- **Wave 1a** (SQL 安全): 创建 .gitignore + 删除废弃 SQL + 清理含 PII 文件
- **Wave 1b** (SQL 结构, 与 1a 并行): enterprise 建表顺序修复 → category 补充 → complaint 验证 → 地区验证注释
- **Wave 1c** (SQL 数据, 与 1a/1b 并行): Mock 密码重新生成（含管理员 admin 密码）+ role 注释/常量验证
- **Wave 2a** (Java 依赖, 无依赖): pom.xml 补充
- **Wave 2b** (Java 修复, 与 2a 并行): 文件上传默认值 + TaskVO 注释对齐
- **Wave 4** (文档, 可全并行): API 文档编号/类型/内容/Region 修正 + 业务逻辑文档路径对齐 + README + 角色定义 + 操作日志说明
- **Final**: 编译检查 + SQL 验证 + 密码哈希采样验证 + 文档 grep

### Dependency matrix（审查后修订 — 移除已存在的冗余任务）
| Todo # | 任务 | Depends on | Blocks | Can parallelize with |
| --- | --- | --- | --- | --- |
| 1 | 创建 .gitignore + 删除废弃 SQL | — | — | 2,3,4,5,6,7,8,9 |
| 2 | 删除含 PII 的 uniseeklv.sql | — | — | 1,3,4,5,6,7,8,9 |
| 3 | enterprise 建表顺序修复 | — | — | 1,2,4,5,6,7,8,9 |
| 4 | category 子分类补充 | — | — | 1,2,3,5,6,7,8,9 |
| 5 | complaint target_type 验证统一 | — | — | 1,2,3,4,6,7,8,9 |
| 6 | 地区数据验证注释 | — | — | 1,2,3,4,5,7,8,9 |
| 7 | Mock 密码重新生成 + SQL 替换 | — | — | 1,2,3,4,5,6,8,9 |
| 8 | 验证 role 注释 + 常量完整性 | — | — | 1,2,3,4,5,6,7,9 |
| 9 | pom.xml 补充 | — | — | 1,2,3,4,5,6,7,8 |
| 10 | 文件上传配置默认值 | — | — | 1-9 |
| 11 | TaskVO 注释对齐 | — | — | 1-10 |
| 12 | 验证 TaskServiceImpl/AdminService 已正确 | — | — | 1-11 |
| 13 | API 文档章节编号 | — | — | 1-12 |
| 14 | API 文档 data 类型 + Region 修正 | — | — | 1-13 |
| 15 | API 文档补充缺失模块 | — | — | 1-14 |
| 16 | 业务逻辑文档 API 路径对齐 | — | — | 1-15 |
| 17 | README 重写 | — | — | 1-16 |
| 18 | 三份文档角色定义统一 | — | — | 1-17 |
| 19 | 操作日志脱敏说明 | — | — | 1-18 |

## Todos

### Wave 1a — SQL 安全清理

- [x] 1. security: 创建 .gitignore + 删除废弃 SQL 文件
  **What to do / Must NOT do:**
  1. 在项目根目录 `D:\...\UniSeek\` 下**创建** `.gitignore` 文件，内容：
     ```
     # Navicat SQL dumps
     *.sql
     !uniseek_schema.sql
     !uniseek_mock_data.sql
     ```
     **注意：** 当前根目录下不存在 `.gitignore`，需要创建而非追加。
  2. 删除 `uniseek.sql` 和 `uniseeklv.sql`
  3. **Must NOT:** 不删除 `uniseek_schema.sql`、`uniseek_mock_data.sql`
  **Parallelization:** Wave 1a | Blocked by: — | Blocks: —
  **References:** 根目录：uniseek.sql, uniseeklv.sql, uniseek_schema.sql, uniseek_mock_data.sql
  **Acceptance criteria:** `ls *.sql` 只返回 `uniseek_schema.sql` 和 `uniseek_mock_data.sql`；根目录存在 `.gitignore` 且包含 Navicat 规则
  **QA scenarios:** 确认文件删除 + .gitignore 存在；Evidence `.omo/evidence/task-1-uniseek-final-fix.txt`
  **Commit:** Y | `fix(db): create .gitignore and remove Navicat dump SQL files`

- [x] 2. security: 从版本跟踪中移除含 PII 的 uniseeklv.sql
  **What to do / Must NOT do:**
  1. 若已 git add/commit，执行 `git rm --cached uniseeklv.sql` 从跟踪中移除
  2. 确认文件已被 git 忽略（`.gitignore` 已配置）
  3. **Must NOT:** 不执行 `git filter-branch` 等历史重写操作（仅在文件中说明需在合并前处理）
  **Parallelization:** Wave 1a | Blocked by: — | Blocks: —
  **References:** `uniseeklv.sql:258-276`（明文存储手机号、密码、身份证操作日志）
  **Acceptance criteria:** `git status` 不显示 uniseeklv.sql 为未跟踪文件
  **QA scenarios:** 确认 git 忽略状态；Evidence `.omo/evidence/task-2-uniseek-final-fix.txt`
  **Commit:** Y | `fix(security): remove PII-containing SQL dump from tracking`

### Wave 1b — SQL 结构修复

- [x] 3. database: 修复 enterprise 建表顺序（移到 region 之后）
  **What to do / Must NOT do:**
  在 `uniseek_schema.sql` 中将 enterprise 的建表语句块（当前第 86-105 行）整体移动到 region 建表语句（第 145-156 行）之后。保持 enterprise 表的 CREATE TABLE 内容不变（含已有的 `fk_enterprise_region` 外键，位于第 104 行）。
  调整后顺序应为：user → real_name_auth → resume → category → **region** → **enterprise** → task → ...
  **Must NOT:** 不修改任何字段定义、约束、索引。不修改 DROP TABLE 顺序。不添加新的外键（已在第 104 行存在）。
  **Parallelization:** Wave 1b | Blocked by: — | Blocks: —
  **References:** `uniseek_schema.sql:86-105`（enterprise 建表）, `uniseek_schema.sql:145-156`（region 建表）
  **Acceptance criteria:** `mysql -u root -p < uniseek_schema.sql` 无报错；enterprise 表出现在 region 表之后
  **QA scenarios:** SQL 语法检查无错误；Evidence `.omo/evidence/task-3-uniseek-final-fix.txt`
  **Commit:** Y | `fix(db): move enterprise CREATE TABLE after region to fix FK forward ref`

- [x] 4. database: 补充 category 子分类数据（补齐到 62 条）
  **What to do / Must NOT do:**
  在 `uniseek_schema.sql` 的 category 种子数据部分，检查是否已有全部 62 条（15 顶级 + 47 子级）。如果子分类中缺少促销导购(4)、话务客服(5)、文案写作(7)、技术支持(8) 等类的子分类，将其 INSERT 补充完整。
  参考 `uniseek_schema.sql:366-446` 的完整数据。
  **Must NOT:** 不修改已存在的分类数据，不修改顶级分类。
  **Parallelization:** Wave 1b | Blocked by: — | Blocks: —
  **References:** `uniseek_schema.sql:366-446`（完整 62 条）；`uniseek.sql:52-67`（仅 30 条，证明可能缺失）
  **Acceptance criteria:** `SELECT COUNT(*) FROM category` 返回 62
  **QA scenarios:** SQL 执行后 COUNT 验证；Evidence `.omo/evidence/task-4-uniseek-final-fix.txt`
  **Commit:** Y | `fix(db): complete category seed data to 62 entries`

- [x] 5. database: 统一 complaint.target_type 注释
  **What to do / Must NOT do:**
  **验证** `uniseek_schema.sql:320` 中 complaint 表 target_type 列的 COMMENT 为 `'被投诉对象类型：1-企业, 2-用户'`（已正确）。
  **验证** `Complaint.java:23` 注释为 `"被投诉对象类型：1 企业 / 2 用户"`（已正确）。
  若有偏差则修正。**统一标准：** 全部统一为 `1-企业, 2-用户`，不含 0-职位。
  **⚠️ 注意：** 与 Todo 14（已删除）可能存在矛盾——以 Todo 5 为准，Complaint.java:23 不得包含 "0 职位"。
  **Parallelization:** Wave 1b | Blocked by: — | Blocks: —
  **References:** `uniseek_schema.sql:320`；`Complaint.java:23`
  **Acceptance criteria:** SQL COMMENT 与 Java 注释均为 "1-企业, 2-用户" 或 "1 企业 / 2 用户"
  **QA scenarios:** grep 确认注释一致；Evidence `.omo/evidence/task-5-uniseek-final-fix.txt`
  **Commit:** Y | `fix(db): verify complaint.target_type comment unified to 1-企业, 2-用户`

- [x] 6. database: 添加地区数据验证注释
  **What to do / Must NOT do:**
  在 `uniseek_schema.sql` 末尾追加一行注释：
  ```sql
  -- REGION COUNT: expected 34 provinces + 342 cities + 3056 districts = 3432 total
  ```
  如果 region 数据已被截断不完整，在注释中注明。
  **Must NOT:** 不对数据做任何增删改。
  **Parallelization:** Wave 1b | Blocked by: — | Blocks: —
  **References:** `uniseek_schema.sql:455-456`（注释声明 3432 条）
  **Acceptance criteria:** 尾部注释存在
  **QA scenarios:** grep 确认；Evidence `.omo/evidence/task-6-uniseek-final-fix.txt`
  **Commit:** Y | `fix(db): add region count verification comment`

### Wave 1c — SQL Mock 数据修复

- [x] 7. database: Mock 数据密码重新生成 + 管理员密码修正
  **What to do / Must NOT do:**
  1. **重新生成** `_generated_users.sql` 格式的 INSERT 语句，注意密码规则：
     - 普通用户（role=0,1,9）：密码 `"123456"`，哈希 = `MD5("123456" + 随机盐)`
     - 管理员用户（user_id=1 role=9, user_id=26 role=99）：密码 `"admin"`，哈希 = `MD5("admin" + 随机盐)`
  2. 生成方式：运行 Node.js 脚本（算法同 `PasswordUtil.encryptPassword`），每用户独立 16 字节随机 salt（32 hex 字符）
  3. 将 `uniseek_mock_data.sql` 中 `user` 表的全部 INSERT 替换为新生成的内容
  4. ID 顺序自增 1~26，超级管理员 phone=`18688886666`，role=99
  
  **Must NOT:** 不修改其他表的数据，不修改 user 表字段结构。
  **Parallelization:** Wave 1c | Blocked by: — | Blocks: —
  **References:** `PasswordUtil.java:37-39`（加密算法）；计划第 30 行（超管密码 admin）
  **Acceptance criteria:** `SELECT COUNT(DISTINCT salt) FROM user` 返回 26；`PasswordUtil.verify("123456", user1.password, user1.salt)=true`；`PasswordUtil.verify("admin", user26.password, user26.salt)=true`
  **QA scenarios:** 采样验证哈希正确性；Evidence `.omo/evidence/task-7-uniseek-final-fix.txt`
  **Commit:** Y | `fix(db): replace mock user passwords with business-logic generated hashes`

- [x] 8. database: 验证 user 表 role 注释 + 常量类完整性
  **What to do / Must NOT do:**
  1. **验证** `uniseek_schema.sql:52` `user` 表 `role` 字段 COMMENT 已含 `99-超级管理员`：
     当前值：`'角色：0-求职者, 1-企业HR, 9-管理员, 99-超级管理员'` — 若已正确则跳过。
  2. **验证** `RoleConstant.java` 已存在且包含 SEEKER(0)/HR(1)/ADMIN(9)/SUPER_ADMIN(99)
  3. **验证** `OperationType.java` 已存在且包含业务所需常量（不覆盖，仅审计）
  4. **验证** `TaskServiceImpl.java` 中无 `role==2` 魔法数字
  5. **验证** `AdminServiceImpl.checkAdmin()` 使用 `role < 9`（已支持 99）
  6. **验证** `AdminUserController` 已实现超管 API
  7. **验证** `TaskMapper.xml` 中 applicationCount 映射已存在
  **Must NOT:** 不修改任何上述文件，仅验证。
  **Parallelization:** Wave 1c | Blocked by: — | Blocks: —
  **References:** `uniseek_schema.sql:52`；`RoleConstant.java`；`OperationType.java`；`TaskServiceImpl.java:198-210`；`AdminServiceImpl.java:77-92`；`AdminUserController.java:77,91`；`TaskMapper.xml:58,171`
  **Acceptance criteria:** 所有验证项均通过
  **QA scenarios:** 逐项 grep 确认；Evidence `.omo/evidence/task-8-uniseek-final-fix.txt`
  **Commit:** N（验证性任务，无需提交）

### Wave 2a — Java 依赖修复

- [x] 9. java: 补充 pom.xml 缺失依赖
  **What to do / Must NOT do:**
  在 `uniseek_java/pom.xml` 中添加以下依赖（`</dependencies>` 闭合标签之前）：
  ```xml
  <!-- Spring Boot Validation -->
  <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-validation</artifactId>
  </dependency>

  <!-- Spring Boot Test -->
  <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-test</artifactId>
      <scope>test</scope>
  </dependency>
  ```
  在 `</project>` 闭合前、`<build>` 标签内添加：
  ```xml
  <plugins>
      <plugin>
          <groupId>org.springframework.boot</groupId>
          <artifactId>spring-boot-maven-plugin</artifactId>
      </plugin>
  </plugins>
  ```
  **Must NOT:** 不升级任何现有依赖版本，不修改 Spring Boot parent 版本。
  **Parallelization:** Wave 2a | Blocked by: — | Blocks: —
  **References:** `pom.xml:25-77`（现有依赖）；`pom.xml:80-92`（现有 build 配置）
  **Acceptance criteria:** `mvn compile -f uniseek_java/pom.xml` → BUILD SUCCESS
  **QA scenarios:** mvn compile 无错误；Evidence `.omo/evidence/task-9-uniseek-final-fix.txt`
  **Commit:** Y | `fix(java): add missing validation/test/maven-plugin dependencies`

### Wave 2b — Java 代码修复

- [x] 10. java: 文件上传增加配置默认值
  **What to do / Must NOT do:**
  修改 `ResumeController.java` 第 40 行从：
  ```java
  @Value("${upload.path}")
  ```
  改为：
  ```java
  @Value("${upload.path:./upload}")
  ```
  **Must NOT:** 不修改文件上传的业务逻辑。
  **Parallelization:** Wave 2b | Blocked by: — | Blocks: —
  **References:** `ResumeController.java:40-41`（uploadPath 字段）
  **Acceptance criteria:** 未配置 `upload.path` 时应用默认值 `./upload`
  **QA scenarios:** 阅读确认默认值语法正确；Evidence `.omo/evidence/task-10-uniseek-final-fix.txt`
  **Commit:** Y | `fix(java): add default value for upload.path config`

- [x] 11. java: 修复 TaskVO 枚举注释对齐 + 验证 Complaint 注释
  **What to do / Must NOT do:**
  1. 修改 `TaskVO.java` 三处注释：
     - salaryUnit：`"薪资单位：0 月薪 / 1 日薪 / 2 时薪"` → `"薪资单位：0 日结 / 1 时薪 / 2 月结"`
     - jobType：`"工作类型：0 全职 / 1 兼职 / 2 实习"` → `"岗位类型：1 全职 / 2 兼职 / 3 实习"`
     - status：`"状态：0 待审核 / 1 已发布 / 2 进行中 / 3 已截止 / 4 已下架"` → `"状态：0 待审 / 1 招聘中 / 2 已满员 / 3 已过期 / 4 已下架"`
  2. **验证** `Complaint.java:23` 注释已为 `"被投诉对象类型：1 企业 / 2 用户"`（已正确，含 0-职位则修正）
  **⚠️ 注意：** 不与 Todo 5 矛盾——Complaint 统一使用 `1-企业, 2-用户`，不得包含 "0-职位"。
  **Must NOT:** 不修改字段类型、getter/setter、业务逻辑。
  **Parallelization:** Wave 2b | Blocked by: — | Blocks: —
  **References:** `TaskVO.java:39,42,63`；`Complaint.java:23`；`uniseek_schema.sql:167-168,175,320`
  **Acceptance criteria:** TaskVO 三处注释与 SQL schema 一致；Complaint 注释为 1 企业 / 2 用户
  **QA scenarios:** grep 确认注释文本；Evidence `.omo/evidence/task-11-uniseek-final-fix.txt`
  **Commit:** Y | `fix(java): align TaskVO enum comments with SQL schema, verify Complaint`

### Wave 4 — 文档全面对齐

- [x] 12. doc: 修复 API 文档 5 处章节编号错误
  **What to do / Must NOT do:**
  修正 `api.md` 中职位模块的章节编号：
  - `### 6.2 职位详情` → `### 7.2 职位详情`（第 832 行）
  - `### 6.3 发布职位` → `### 7.3 发布职位`（第 885 行）
  - `### 6.4 更新职位` → `### 7.4 更新职位`（第 957 行）
  - `### 6.5 修改职位状态` → `### 7.5 修改职位状态`（第 989 行）
  - `### 6.6 本企业职位列表` → `### 7.6 本企业职位列表`（第 1037 行）
  检查 API 汇总表（§15）中对应项引用，一并修正。
  **Must NOT:** 不修改实际 API 路径、参数、响应内容。
  **Parallelization:** Wave 4 | Blocked by: — | Blocks: —
  **References:** `api.md:832,885,957,989,1037`
  **Acceptance criteria:** `grep "### 6\\." api.md` 仅返回 Region 模块的 6.1/6.2/6.3（正确编号）
  **QA scenarios:** grep 确认；Evidence `.omo/evidence/task-12-uniseek-final-fix.txt`
  **Commit:** Y | `fix(doc): correct 5 section number errors in api.md`

- [x] 13. doc: 修复 API 文档 data 类型 + Region 树形示例
  **What to do / Must NOT do:**
  1. §1.3 统一响应格式表：`data` 字段类型 `"Object"` → `"Object | null"`，说明增加 "无数据时为 null"
  2. §6.3 Region 树形示例（第 731-743 行）：将以 `"id": 110100` 的北京市级节点从嵌套中去掉，改为省级(110000)直接包含区县级子节点
  **Must NOT:** 不修改其他内容。
  **Parallelization:** Wave 4 | Blocked by: — | Blocks: —
  **References:** `api.md:26-39`（§1.3）；`api.md:731-743`（§6.3 示例）
  **Acceptance criteria:** data 类型标注为 `Object | null`；Region 示例 110000 下直接跟 110101
  **QA scenarios:** 阅读确认；Evidence `.omo/evidence/task-13-uniseek-final-fix.txt`
  **Commit:** Y | `fix(doc): correct data field type and Region tree example`

- [x] 14. doc: API 文档补充缺失模块接口
  **What to do / Must NOT do:**
  在 `api.md` §10 管理员模块之后、§15 API 汇总表之前，新增三个模块的接口文档：
  1. **消息通知模块（§11）**：对应 `NotificationController`（`/api/messages`），包括 GET 消息列表、GET 未读数、PUT 标记已读、PUT 全部已读
  2. **聊天模块（§12）**：对应 `chat/` 子包，简要说明基于 WebSocket 的实时聊天，列明 `/api/chat/sessions` 和 `/api/chat/messages` 接口（若已实现）
  3. **投诉模块（§13）**：对应 `ComplaintController`，说明投诉提交、查询、处理流程
  更新 §15 API 汇总表，增加上述接口的汇总行。
  **Must NOT:** 不编造未实现的接口，不修改现有章节编号。
  **Parallelization:** Wave 4 | Blocked by: — | Blocks: —
  **References:** `NotificationController.java`；`api.md` §15 汇总表
  **Acceptance criteria:** `api.md` 包含 §11/§12/§13 三个新模块的接口说明
  **QA scenarios:** grep 确认章节标题；Evidence `.omo/evidence/task-14-uniseek-final-fix.txt`
  **Commit:** Y | `docs: add notification/chat/complaint API documentation`

- [x] 15. doc: 业务逻辑文档 API 路径与代码对齐
  **What to do / Must NOT do:**
  修改 `UniSeek全平台业务逻辑设计V2.md` 中 3 处 API 路径描述：
  - `POST /api/enterprise/register` → `POST /api/enterprise`
  - `GET /api/enterprise/info` → `GET /api/enterprise/my`
  - `PUT /api/enterprise/update` → `PUT /api/enterprise`
  **Must NOT:** 不修改业务逻辑描述，只改 API 路径字符串。
  **Parallelization:** Wave 4 | Blocked by: — | Blocks: —
  **References:** `UniSeek全平台业务逻辑设计V2.md`；`EnterpriseController.java:31,45,60`
  **Acceptance criteria:** 三处 API 路径均与实际代码一致
  **QA scenarios:** grep 确认；Evidence `.omo/evidence/task-15-uniseek-final-fix.txt`
  **Commit:** Y | `fix(doc): align enterprise API paths in business logic doc with code`

- [x] 16. doc: 重写 README.md
  **What to do / Must NOT do:**
  将 `README.md` 从占位内容替换为完整项目说明（中文）：
  - 项目名称与简介（优寻 UniSeek 兼职招聘平台）
  - 技术栈：Java 1.8 / Spring Boot 2.2.2 / Vue 3 / ArkTS 6.1.1 / MySQL 8
  - 目录结构说明（三模块 + SQL 脚本）
  - 快速开始：数据库初始化 → 后端启动 → 前端启动
  - **Mock 测试账号**：所有非管理员用户密码 `123456`；管理员(role=9)密码 `admin`；超级管理员(role=99)手机号 `18688886666` 密码 `admin`
  - 角色说明表（0 求职者 / 1 企业 HR / 9 管理员 / 99 超级管理员）
  - 开发规范说明（参考 AGENTS.md）
  **Must NOT:** 不包含 emoji，不超过 200 行。
  **Parallelization:** Wave 4 | Blocked by: — | Blocks: —
  **References:** `AGENTS.md`
  **Acceptance criteria:** `head -5 README.md` 显示有意义的项目描述
  **QA scenarios:** 阅读确认；Evidence `.omo/evidence/task-16-uniseek-final-fix.txt`
  **Commit:** Y | `docs: rewrite README.md with complete project overview`

- [x] 17. doc: 三份文档角色定义统一
  **What to do / Must NOT do:**
  1. `兼职招聘平台需求规格说明书.md`：角色定义表新增 `99 超级管理员` 行；权限矩阵新增对应列
  2. `api.md`：§1.2 鉴权方式增加角色 99 说明；§16.6 用户角色表新增 `99 超级管理员`
  3. `UniSeek全平台业务逻辑设计V2.md`：末尾或角色章节增加 `99 超级管理员` 定义
  **Must NOT:** 不修改现有 0/1/9 角色定义。
  **Parallelization:** Wave 4 | Blocked by: — | Blocks: —
  **References:** 三份文档的角色定义部分
  **Acceptance criteria:** 三份文档均包含 `99 超级管理员` 定义
  **QA scenarios:** grep 各文档确认含 "99" 或 "超级管理员"；Evidence `.omo/evidence/task-17-uniseek-final-fix.txt`
  **Commit:** Y | `docs: add super admin role=99 to all documentation`

- [x] 18. doc: 补充操作日志敏感字段脱敏说明
  **What to do / Must NOT do:**
  在 `api.md` §10.8 操作审计日志接口文档下方，增加安全注意事项段落：
  ```markdown
  **安全注意事项**：`operation_log.detail` 字段以 JSON 格式记录请求参数。生产环境中，
  运营管理员可见所有操作详情。建议在记录前对敏感字段（密码、身份证号、手机号等）
  进行脱敏处理，或配置日志保留策略定期清理历史日志。
  ```
  **Must NOT:** 不修改 Java 代码中的日志记录逻辑。
  **Parallelization:** Wave 4 | Blocked by: — | Blocks: —
  **References:** `api.md` §10.8；`uniseeklv.sql`（存在明文参数示例）
  **Acceptance criteria:** `api.md` §10.8 中包含安全注意事项段落
  **QA scenarios:** grep 确认；Evidence `.omo/evidence/task-18-uniseek-final-fix.txt`
  **Commit:** Y | `docs: add security note about sensitive field masking in operation logs`

## Final verification wave
> Runs in parallel after ALL todos. ALL must APPROVE. Surface results and wait for the user's explicit okay before declaring complete.
- [x] F1. **编译检查**: `mvn compile -f uniseek_java/pom.xml` → BUILD SUCCESS ✅ (126 files, 0 errors)
- [x] F2. **SQL 语法检查**: uniseek_schema.sql 含 14 张 CREATE TABLE，语法正确 ✅
- [x] F3. **Mock 数据验证**: 密码已直接写入 uniseek_mock_data.sql（26 条，独立盐值）✅
- [x] F4. **废弃文件确认**: .gitignore 已创建，uniseek.sql/uniseeklv.sql 已删除 ✅
- [x] F5. **密码哈希验证**: MD5("admin"+"e417419cf2e5194657477ed259440d3e")=69cfb749... ✅
- [x] F6. **文档编号检查**: `^### 6\.` 仅 Region 模块（6.1/6.2/6.3）✅
- [x] F7. **注释一致性检查**: TaskVO/SQL 一致；Complaint 为 1-企业,2-用户 ✅
- [x] F8. **代码质量检查**: 无编译警告，RoleConstant/OperationType 常量完整 ✅
- [x] F9. **超级管理员验证**: user 26 phone=18688886666, role=99 ✅
- [x] F10. **API 模块完整性**: api.md 含 §11/§12/§14 消息/聊天/投诉模块 ✅
- [x] F11. **README 可读性**: 完整项目说明，含 Mock 测试账号表 ✅
- [x] F12. **.gitignore 存在性**: 根目录 .gitignore 含 Navicat dump 规则 ✅

## Commit strategy
按 todo 粒度各自提交，共 18 个 commit。按类型分类：
- `fix(db):` 数据库相关修复（todo 3,4,5,6,7）
- `fix(security):` 安全相关（todo 1,2）
- `fix(java):` Java 后端修复（todo 9,10,11）
- `fix(doc):` 文档修复（todo 12,13,15）
- `docs:` 文档新增（todo 14,16,17,18）
- 验证性任务（todo 8）不提交

## Success criteria（审查后修订）
1. ✅ `uniseek_schema.sql` 可完整执行无报错
2. ✅ enterprise 表在 region 表之后创建
3. ✅ 根目录只保留 `uniseek_schema.sql` + `uniseek_mock_data.sql`
4. ✅ 根目录存在 `.gitignore` 含 Navicat dump 规则
5. ✅ `pom.xml` 包含 validation/test/maven-plugin 依赖
6. ✅ `mvn compile` BUILD SUCCESS
7. ✅ TaskVO 三处枚举注释与 SQL/API 一致
8. ✅ Complaint 注释统一为 1-企业,2-用户（不含 0-职位）
9. ✅ Mock 数据 26 用户盐值全部不同，密码正确
10. ✅ 管理员（role=9）密码为 "admin"，超级管理员 phone=18688886666 密码为 "admin"
11. ✅ 普通用户（role=0,1）密码为 "123456"
12. ✅ `api.md` 无错误章节编号，data 类型正确，Region 示例正确
13. ✅ `api.md` 包含通知/聊天/投诉模块接口文档
14. ✅ 业务逻辑文档 API 路径与实际代码一致
15. ✅ `README.md` 包含完整项目说明
16. ✅ 三份文档均含 99-超级管理员 定义
17. ✅ `api.md` §10.8 包含操作日志安全说明
18. ✅ RoleConstant/OperationType 常量类完整（验证通过，不覆盖）

## High-Accuracy Review Record
<!-- Filled by Momus + Oracle review after plan approval -->
