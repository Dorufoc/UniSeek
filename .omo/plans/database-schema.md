# database-schema - Work Plan

## TL;DR (For humans)
**What you'll get:** 一个生产级 MySQL 8 初始化 SQL 脚本（uniseek_schema.sql），包含 13 张业务表、完整的外键约束、索引、中文注释，以及职位分类和地区数据种子。放在项目根目录下，可直接在 MySQL 8 中执行建库建表。

**Why this approach:** 你的需求文档和表设计已经非常详细，只需规范化为标准的 MySQL 8 DDL 语法，修复几个设计缺陷（parent_id 与 FK 冲突、孤岛表关联），补充需求文档中提到的缺失表（操作日志、投诉），并添加开箱即用的种子数据。

**What it will NOT do:** 不包含存储过程/触发器/事件/视图；不包含业务数据（用户/企业/职位）；不包含分库分表或主从配置；不包含 Flyway/Liquibase 迁移工具配置。

**Effort:** Short（单文件生成）
**Risk:** Low — 所有表结构由你确认 + Metis 审核 + 双重高精度审核

**Decisions to sanity-check:**
1. `t_user.credit_score` 保留但规则待补充
2. `t_complaint` + `t_operation_log` 两张新增表（需求文档提及但未定义数据字典）
3. `t_task` 增加 `region_id` FK→t_region 实现按地区筛选
4. `parent_id` 改为 DEFAULT NULL 修复 FK 冲突
5. **`t_chat_message` 重构**：原有设计用 `application_id`+`receiver_id` 直连投递记录，改为通过 `t_chat_session` 中间表间接关联（`session_id`），移除 `receiver_id` 改为从会话推导。优点：减少冗余、支持会话关闭/状态管理。代价：查询未读消息需 JOIN 会话表。
6. **新增 `t_user.real_name` + `t_user.id_card`**：身份证号（UNIQUE）+ 实名认证真实姓名，用户级身份信息。`t_resume.real_name` 保留作为简历展示名，两者可不同。

---

> TL;DR (machine): Short effort, Low risk. Generate uniseek_schema.sql with 13 tables (user/enterprise/resume/category/task/application/message/chat_session/chat_message/stats/region/complaint/operation_log) + FK + indexes + Chinese comments + seed data.

## Scope
### Must have
- 完整的 MySQL 8 DDL 脚本（`uniseek_schema.sql`），包含 13 张表
- 每张表的外键约束（FK + 合理 ON DELETE 策略）
- 所有索引（PK、UK、普通索引、全文索引、复合索引）
- 所有字段的中文注释，关键业务约束标注
- 职位分类初始数据（30 条，2 级树形）
- 地区初始数据（省级 + 主要城市 + 区县）
- DROP TABLE IF EXISTS 逆向依赖顺序，支持幂等执行
- SQL 语法可通过 MySQL 8 命令行/客户端验证

### Must NOT have (guardrails, anti-slop, scope boundaries)
- 不添加任何存储过程、触发器、事件、视图
- 不插入任何业务表或测试数据（t_user/t_enterprise/t_resume/t_task 等）
- 不添加分库分表、读写分离、主从备份等架构配置
- 不生成 MyBatis/MyBatis-Plus 的 XML 映射文件或 Java 实体类
- 不使用 MySQL 已废弃或不推荐使用的特性（如 TYPE=MyISAM、PARTITION BY LIST 等）
  - 允许使用 MySQL 8 生产级特性：JSON 类型、FULLTEXT 索引、InnoDB 引擎、utf8mb4 字符集

## Verification strategy
> Zero human intervention - all verification is agent-executed.
- Test decision: none (DDL only — verification = syntax validation + structural audit)
- Evidence: .omo/evidence/task-1-database-schema.sql (SQL syntax check output)

## Execution strategy
### Parallel execution waves
- **Wave 1** (single todo since all content goes into one file): Write complete uniseek_schema.sql

### Dependency matrix
| Todo | Depends on | Blocks | Can parallelize with |
| --- | --- | --- | --- |
| 1. Generate uniseek_schema.sql | None | Final verification | N/A (single file) |

## Todos
> Implementation + Test = ONE todo. Never separate.
<!-- APPEND TASK BATCHES BELOW THIS LINE WITH edit/apply_patch - never rewrite the headers above. -->
- [x] 1. **生成 uniseek_schema.sql 文件到项目根目录**
  **What to do / Must NOT do:**
  - 在 `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\` 根目录下创建 `uniseek_schema.sql`
  - 包含 13 张表的完整 CREATE TABLE（按 FK 依赖顺序：t_user → t_enterprise/t_resume → t_category/t_region → t_task → t_task_application → t_message → t_chat_session → t_chat_message → t_statistics_daily → t_complaint → t_operation_log）
  - 每张表必须包含：ENGINE=InnoDB, CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci, 中文注释
  - 所有外键约束带合理的 ON DELETE 策略
  - 所有用户指定的索引（不允许遗漏或多余）
  - DROP TABLE IF EXISTS 段，按 FK 逆向依赖顺序
  - 不要包含存储过程、触发器、事件、视图
  - 不要插入任何业务测试数据

  **SQL 细节规范（按表）：**
  - `t_user`: BIGINT(20) PK AUTO_INCREMENT, phone VARCHAR(11) UNIQUE NOT NULL, password VARCHAR(64) NOT NULL, salt VARCHAR(32) NOT NULL, nickname VARCHAR(50) NULL, **real_name VARCHAR(20) NULL**（实名认证真实姓名）, **id_card VARCHAR(18) UNIQUE NULL**（身份证号，建议加密存储，前6+后4位可明文用于脱敏显示）, avatar_url VARCHAR(255) NULL, role TINYINT(1) NOT NULL DEFAULT 0 (0-求职者/1-企业HR/9-管理员), credit_score INT(10) NOT NULL DEFAULT 100 (保留字段，业务规则待补充), status TINYINT(1) NOT NULL DEFAULT 1 (0-禁用/1-正常), last_login_time DATETIME NULL, create_time/update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(update_time加ON UPDATE). INDEX: uk_phone, **uk_id_card**, idx_role.
  - `t_enterprise`: BIGINT(20) PK AUTO_INCREMENT, user_id BIGINT(20) FK UNIQUE NOT NULL, company_name VARCHAR(100) **NOT NULL**, credit_code VARCHAR(18) **UNIQUE NOT NULL**, license_img_url VARCHAR(255) NULL, industry VARCHAR(50) NULL, description TEXT NULL, audit_status TINYINT(1) NOT NULL DEFAULT 0 (0-待审/1-已认证/2-驳回), create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, **update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP**. INDEX: uk_user_id, uk_credit_code, idx_audit_status. FK→t_user.id RESTRICT.
  - `t_resume`: BIGINT(20) PK AUTO_INCREMENT, user_id BIGINT(20) FK UNIQUE NOT NULL, real_name VARCHAR(20) NULL, gender TINYINT(1) NULL (0-男/1-女), birth_date DATE NULL, education VARCHAR(20) NULL, school VARCHAR(50) NULL, skills VARCHAR(500) NULL, experience TEXT NULL, attachment_url VARCHAR(255) NULL, **create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP**, update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP. INDEX: uk_user_id, FULLTEXT ft_experience. FK→t_user.id RESTRICT.
  - `t_category`: BIGINT(20) PK AUTO_INCREMENT, parent_id BIGINT(20) **DEFAULT NULL** (FK→t_category.id SET NULL, NOT default 0!), name VARCHAR(50) NOT NULL, sort_order INT(10) DEFAULT 0, create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP. INDEX: idx_parent_id.
  - `t_region`: BIGINT(20) PK AUTO_INCREMENT, parent_id BIGINT(20) **DEFAULT NULL** (FK→t_region.id SET NULL, NOT default 0!), name VARCHAR(50) NOT NULL, level TINYINT(1) NOT NULL (1-省/2-市/3-区县), sort_order INT(10) DEFAULT 0, create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP. INDEX: idx_parent_id, idx_level_parent.
  - `t_task`: BIGINT(20) PK AUTO_INCREMENT, enterprise_id BIGINT(20) FK NOT NULL, category_id BIGINT(20) FK NOT NULL, **region_id BIGINT(20) DEFAULT NULL FK→t_region.id SET NULL**（新增，按地区筛选职位）, title VARCHAR(100) NOT NULL, description TEXT NOT NULL, salary_min DECIMAL(10,2) NOT NULL, salary_max DECIMAL(10,2) NOT NULL (注释标注业务约束 salary_min ≤ salary_max + remaining_quota ≥ 0), salary_unit TINYINT(1) NOT NULL DEFAULT 0 (0-日结/1-时薪/2-月结), total_quota INT(10) **NOT NULL**, remaining_quota INT(10) **NOT NULL**, address VARCHAR(200) NULL, longitude DECIMAL(10,7) NULL, latitude DECIMAL(10,7) NULL, status TINYINT(1) NOT NULL DEFAULT 0 (0-待审/1-招聘中/2-已满员/3-已过期/4-已下架), version INT(10) NOT NULL DEFAULT 0, deadline DATETIME NULL, create_time/update_time DATETIME NOT NULL. INDEX: idx_enterprise_id, idx_category_id, idx_status, idx_status_create(status,create_time), idx_region_id, **idx_category_status(category_id,status)**, **idx_region_status(region_id,status)**. FK→t_enterprise.id RESTRICT, t_category.id RESTRICT, t_region.id SET NULL.
  - `t_task_application`: BIGINT(20) PK AUTO_INCREMENT, task_id BIGINT(20) FK NOT NULL, applicant_id BIGINT(20) FK NOT NULL, resume_snapshot JSON NOT NULL, attachment_url VARCHAR(255) NULL, status TINYINT(1) NOT NULL DEFAULT 0 (0-已投递/1-待面试/2-待定/3-已录用/4-已淘汰/5-已完成), hr_id BIGINT(20) FK NULL SET NULL, interview_time DATETIME NULL, interview_location VARCHAR(200) NULL, reject_reason VARCHAR(500) NULL, hr_note VARCHAR(500) NULL, version INT(10) NOT NULL DEFAULT 0, create_time/update_time DATETIME NOT NULL. INDEX: uk_task_applicant(task_id,applicant_id), idx_task_id, idx_applicant_id, idx_status, idx_hr_id, **idx_task_status(task_id,status)**. FK→t_task.id RESTRICT, t_user.id RESTRICT(applicant), t_user.id SET NULL(hr).
  - `t_message`: BIGINT(20) PK AUTO_INCREMENT, receiver_id BIGINT(20) FK NOT NULL, **sender_id BIGINT(20) DEFAULT NULL FK→t_user.id SET NULL**（新增，标识消息发送人，系统通知为NULL）, title VARCHAR(100) NOT NULL, content TEXT NOT NULL, type TINYINT(1) NOT NULL DEFAULT 0 (0-系统通知/1-面试邀请/2-录用通知/3-淘汰通知), is_read TINYINT(1) NOT NULL DEFAULT 0, biz_id BIGINT(20) NULL, create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP. INDEX: idx_receiver_id, idx_type, idx_receiver_read(receiver_id,is_read), idx_biz_id, **idx_receiver_time(receiver_id,create_time)**. FK→t_user.id RESTRICT(receiver), t_user.id SET NULL(sender).
  - `t_chat_session`: BIGINT(20) PK AUTO_INCREMENT, task_application_id BIGINT(20) FK UNIQUE NOT NULL, employer_id BIGINT(20) FK NOT NULL, seeker_id BIGINT(20) FK NOT NULL, last_message VARCHAR(500) NULL, last_message_time DATETIME NULL, status TINYINT(1) NOT NULL DEFAULT 0 (0-活跃/1-已关闭), create_time/update_time DATETIME NOT NULL. INDEX: uk_task_application_id, idx_employer_id, idx_seeker_id, idx_session_status, **idx_employer_status(employer_id,status)**, **idx_seeker_status(seeker_id,status)**. FK→t_task_application.id **CASCADE**（投递删除 → 会话删除）, t_user.id RESTRICT(employer), t_user.id RESTRICT(seeker).
  - `t_chat_message`: BIGINT(20) PK AUTO_INCREMENT, session_id BIGINT(20) FK NOT NULL, sender_id BIGINT(20) FK NOT NULL, message_type TINYINT(1) NOT NULL DEFAULT 0 (0-文本/1-图片), content TEXT NOT NULL, is_read TINYINT(1) NOT NULL DEFAULT 0, send_time DATETIME NOT NULL（仅用send_time，不保留create_time避免冗余）. INDEX: idx_session_id, **idx_session_time(session_id,send_time)**（聊天历史分页核心索引）, idx_session_read(session_id,is_read). FK→t_chat_session.id CASCADE, t_user.id RESTRICT.
  - `t_statistics_daily`: BIGINT(20) PK AUTO_INCREMENT, stat_date DATE UNIQUE NOT NULL, new_user_count INT(10) NOT NULL DEFAULT 0, new_enterprise_count INT(10) NOT NULL DEFAULT 0, new_task_count INT(10) NOT NULL DEFAULT 0, completed_order_count INT(10) NOT NULL DEFAULT 0, total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00, create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP. INDEX: uk_stat_date.
  - `t_complaint`（新增 — 运营投诉处理）: BIGINT(20) PK AUTO_INCREMENT, complainant_id BIGINT(20) FK NOT NULL→t_user.id RESTRICT, target_type TINYINT(1) NOT NULL (0-职位/1-企业/2-用户), target_id BIGINT(20) NOT NULL, type TINYINT(1) NOT NULL, content TEXT NOT NULL, status TINYINT(1) NOT NULL DEFAULT 0 (0-待处理/1-处理中/2-已结案), handler_id BIGINT(20) FK NULL→t_user.id SET NULL, handle_result TEXT NULL, create_time/update_time DATETIME NOT NULL. INDEX: idx_complainant, idx_status, idx_handler, **idx_target(target_type,target_id)**.
  - `t_operation_log`（新增 — 关键业务操作日志，需求 §4.3）: BIGINT(20) PK AUTO_INCREMENT, operator_id BIGINT(20) FK NULL→t_user.id SET NULL, operation_type VARCHAR(50) NOT NULL, target_type VARCHAR(50) NOT NULL, target_id BIGINT(20) NULL, detail JSON NULL, ip_address VARCHAR(45) NULL (IPv6兼容), create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP. INDEX: idx_operator, idx_target(target_type,target_id), idx_create_time.

  **种子数据：**
  - `t_category`: 30 条记录（15 个顶级 + 15 个子级），覆盖餐饮服务/家教辅导/快递物流/促销导购/设计创作等常见兼职分类
  - `t_region`: 34 个省级行政区 + 主要城市（北京/上海/广州/深圳/杭州等）+ 部分区县示例
  - **不插入**任何 t_user/t_enterprise/t_resume/t_task/t_task_application/t_message/t_chat_session/t_chat_message/t_statistics_daily/t_complaint/t_operation_log 的数据

  **DROP TABLE IF EXISTS 顺序**（逆向 FK 依赖）：
  t_operation_log → t_complaint → t_statistics_daily → t_chat_message → t_chat_session → t_message → t_task_application → t_task → t_region → t_category → t_resume → t_enterprise → t_user

  **References (executor has NO interview context - be exhaustive):**
  - 需求文档: `兼职招聘平台需求规格说明书.md` 完整内容（907 行）
  - 草稿状态: `.omo/drafts/database-schema.md`（记录了所有决策）
  - 外键策略: Metis 审核报告 session_id=ses_0a6d99ebaffejKIqwqqSIvaFBm
  - MySQL 8 文档: https://dev.mysql.com/doc/refman/8.0/en/create-table.html
  - JSON 类型: https://dev.mysql.com/doc/refman/8.0/en/json.html
  - 全文索引: https://dev.mysql.com/doc/refman/8.0/en/innodb-fulltext-index.html

  **Acceptance criteria (agent-executable):**
  1. 文件存在: `D:\Temps\yaoshi\Desktop\code\istone\AAAAAAAAAA\UniSeek\uniseek_schema.sql`
  2. 文件编码为 UTF-8（无 BOM）
  3. SQL 语法验证通过：`mysql -u root -e "SET GLOBAL character_set_server=utf8mb4; SOURCE D:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_schema.sql"` 无报错
  4. 表数量验证：`SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='uniseek'` 返回 13
  5. 索引完整性：所有指定的 UK/INDEX 出现在 `SHOW INDEX FROM` 输出中，包括新增的 `uk_id_card` 及 7 个复合索引（`idx_category_status`, `idx_region_status`, `idx_task_status`, `idx_receiver_time`, `idx_employer_status`, `idx_seeker_status`, `idx_session_time`）
  6. 外键完整性：所有 FK 约束出现在 `information_schema.TABLE_CONSTRAINTS` 中

  **QA scenarios:**
  - **Happy path**: 在新 MySQL 8 数据库中完整执行 SQL 文件 → 13 张表全部创建成功，无警告/无错误。Evidence: `.omo/evidence/task-1-database-schema/syntax-ok.txt`
  - **Idempotent re-run**: 再次执行同一个 SQL 文件 → DROP TABLE IF EXISTS 无报错，重建成功，种子数据正确。Evidence: `.omo/evidence/task-1-database-schema/idempotent.txt`
  - **FK constraint test**: INSERT INTO t_enterprise(user_id=999) → 外键错误拒绝插入。Evidence: `.omo/evidence/task-1-database-schema/fk-violation.txt`
  - **Data type test**: INSERT INTO t_task(salary_min=100.50, salary_max=200.00) → 成功。Salary 超出 DECIMAL(10,2) 范围 → 被拒绝。Evidence: `.omo/evidence/task-1-database-schema/data-types.txt`
  - **Seed data check**: SELECT COUNT(*) FROM t_category → 30; SELECT COUNT(*) FROM t_region → ≥34. Evidence: `.omo/evidence/task-1-database-schema/seed-data.txt`

  Commit: Y | `feat(db): 初始化 UniSeek 数据库完整架构（13张表+种子数据）`
