# mock-data-generator - Work Plan

## TL;DR (For humans)

**What you'll get:** 一个独立的 Python 脚本工具（`uniseek_mock_generator/`），运行后输出包含 **~32万条记录** 的 SQL 文件（~120-150MB）。数据覆盖 UniSeek 平台全部 12 张业务表，记录从 2010 年到 2026 年 7 月的时间跨度。SQL 文件通过 Git LFS 管理，确保推送 GitHub 不报错。所有普通用户密码统一为 `123456`，管理员密码为 `admin`。

**Why this approach:** Python + Faker(zh_CN) 是生成中文 mock 数据的最佳组合 —— 能产生逼真的中文姓名、公司名称、技能标签和工作经历。脚本结构清晰可配置，不同数据量级只需修改一行配置。Git LFS 跟踪大文件避免仓库膨胀。

**What it will NOT do:** 不会修改任何现有代码（Java/Vue/ArkTS）；不会覆盖现有的 `uniseek_mock_data.sql`；不会直接连接数据库；不会重新生成分类和地区种子数据。

**Effort:** Medium（约 1000-1500 行 Python 代码）
**Risk:** Low - 独立脚本，不影响现有系统
**Decisions to sanity-check:** 数据分布比例、密码方案、Git LFS 配置

Your next move: 审阅并批准本计划，然后执行 `$start-work` 开始实现。

---

> TL;DR (machine): Effort=Medium, Risk=Low, Deliverable=Python 脚本 + Git LFS，生成 32万+ 条 SQL mock 数据

## Scope
### Must have
- Python 独立脚本项目 `uniseek_mock_generator/`，包含 generator 和 SQL 输出功能
- 覆盖 12 张业务表：user, real_name_auth, enterprise, resume, task, task_application, notification, chat_session, chat_message, daily_statistics, complaint, operation_log（category 和 region 使用现有种子数据，不重新生成）
- 总记录数 30万+（目标 ~318K，分布见下文）
- 时间跨度 2010-01-01 至 2026-07-15，呈现真实增长曲线（早期稀疏、近年密集）
- 所有外键约束、唯一索引、自增 ID 关系正确
- 密码使用 MD5+盐加密（与 Java PasswordUtil 兼容），普通用户密码=123456，管理员=admin
- 输出为 `uniseek_mock_data_large.sql`，导入命令：`mysql -u root -p uniseek_test < uniseek_mock_data_large.sql`
- 脚本配置文件化（`config.py`），可调整各表数据量
- 引入 Git LFS，通过 `.gitattributes` 跟踪 `*.sql` 大文件

### Must NOT have (guardrails, anti-slop, scope boundaries)
- 不得修改任何现有产品代码（Java/Vue/ArkTS）
- 不得覆盖/修改现有的 `uniseek_mock_data.sql`
- 不得连接数据库直接插入数据
- 不得重新生成 category（62条种子）和 region（~3432条种子）数据
- 不得删除或修改 category 和 region 种子数据（DELETE 语句显式排除这 2 张表）
- 不得使用 AI/LLM API 生成内容 —— 全部使用 Faker + 预定义模板
- 脚本长度控制在 1500 行以内，不过度工程化
- 生成的 SQL 文件不提交至 Git 普通存储，必须通过 Git LFS 管理

## 数据分布目标（总计 ~318,065 条）

| 表名 | 数量 | 说明 |
|------|------|------|
| user | 8,000 | 7,500 求职者 + 400 HR + 98 管理员 + 2 超级管理员 |
| real_name_auth | 7,000 | ~87% 用户完成实名认证 |
| enterprise | 400 | 每 HR 用户对应 1 家企业 |
| resume | 7,000 | 每求职者 1 份简历 |
| task | 5,000 | 每企业 ~12 个职位，按分类/地区/状态分布 |
| task_application | 80,000 | 每求职者 ~10 条投递，覆盖所有状态 |
| notification | 60,000 | 从业务事件生成 |
| chat_session | 25,000 | 约 30% 的投递产生会话（status≥1 的投递中抽样） |
| chat_message | 100,000 | 每活跃会话 ~4 条消息 |
| complaint | 300 | 少量投诉记录 |
| operation_log | 25,000 | 每关键操作 1 条审计日志 |
| daily_statistics | 365 | 从 2025-07-16 到 2026-07-15 每日一条 |

## Verification strategy
- **Test decision**: tests-after —— 运行脚本后验证 SQL 输出文件
- **Evidence**: .omo/evidence/task-N-mock-data-generator.md
- **验证方式**: 
  1. **基于文件的统计验证**（无需 MySQL）：逐表提取 INSERT 行数统计，与配置目标对比（偏差 < 5%）
  2. **基于文件的外键存在性验证**（无需 MySQL）：扫描 INSERT 中的 FK ID 值，提取所有父表 ID 集合做交集，断言每条引用都存在对应父记录
  3. **基于文件的唯一性验证**（无需 MySQL）：提取 phone/email/credit_code/uk_task_applicant 等唯一字段的值集合，断言集合大小 = 记录数
  4. **MySQL 语法验证**：在 `uniseek_test` 数据库上执行 `mysql -u root -p uniseek_test < uniseek_mock_data_large.sql` 检查无语法错误
  5. **MySQL 完整性验证**：执行自定义 CHECK 查询验证外键引用和唯一索引
  6. **密码验证**：抽检 5 个用户，用 Python crypto.py 验证 MD5(password + salt) 匹配
  7. **Git LFS 验证**：确认 `uniseek_mock_data_large.sql` 被 `.gitattributes` 跟踪，`git lfs track` 配置正确

## Execution strategy
### Parallel execution waves
- **Wave 1**: 基础设施 —— 创建脚本项目结构、密码工具、SQL 写入器、Git LFS 配置
- **Wave 2**: 核心数据生成 —— user → real_name_auth → enterprise → resume → task
- **Wave 3**: 业务数据生成 —— task_application → notification → chat_session → chat_message
- **Wave 4**: 辅助数据 + 集成 —— complaint → operation_log → daily_statistics + 主编排脚本 + validate.py
- **Wave 5**: 运行生成 + 验证

### Dependency matrix
| Todo | Depends on | Blocks | Can parallelize with |
| --- | --- | --- | --- |
| 1. 项目骨架+工具+Git LFS | - | 2~11 | - |
| 2. 用户+实名数据 | 1 | 3, 4, 5, 6, 7, 8, 9 | - |
| 3. 企业数据 | 2 | 5 | - |
| 4. 简历数据 | 2 | 6 | 3 |
| 5. 职位数据 | 2, 3 | 6 | 4 |
| 6. 投递+通知+聊天 | 4, 5 | 7, 9 | - |
| 7. 投诉+日志+统计 | 2, 5 | 8 | 6 |
| 8. 主编排+SQL输出+validate.py | 2~7 | 9, 10 | - |
| 9. 运行生成 | 8 | 10 | - |
| 10. 验证 | 8, 9 | - | - |

## Todos

- [x] 1. 创建脚本项目骨架、基础工具模块和 Git LFS 配置
  What / Must NOT do: 创建 `uniseek_mock_generator/` 目录，包含：
    - `requirements.txt`：依赖声明（faker）
    - `config.py`：所有可配置参数（BATCH_SIZE=1000, 各表目标数量, 手机号段配置等）
    - `crypto.py`：MD5+盐密码工具（与 Java PasswordUtil 完全兼容：`MD5(password + salt)`，salt=16字节→32位hex）
    - `sql_output.py`：SQL 写入器
      - 支持批量 INSERT（每 BATCH_SIZE=1000 行自动 flush 并开始新的 INSERT 语句）
      - 自增 ID 管理器（为每个表维护独立计数器，确保 ID 连续不冲突）
      - 增量文件写入（每批数据立即写入磁盘，避免 OOM）
      - INSERT 值自动格式化（字符串转义、NULL 处理、日期格式化）
    - `.gitattributes`：`uniseek_mock_data_large.sql filter=lfs diff=lfs merge=lfs -text`
    - 在项目根 `.gitignore` 中追加 `uniseek_mock_data_large.sql`（已由 LFS 管理，防止重复跟踪）
    Must NOT: 使用外部依赖以外的非标准库；写入器不包含业务逻辑
  Parallelization: Wave 1 | Blocked by: - | Blocks: 2~11
  References: uniseek_java/PasswordUtil.java:37-39, uniseek_mock_data.sql:12-15(START TRANSACTION/COMMIT 模式)
  Acceptance criteria (agent-executable): crypto.py 中 encrypt_password("123456", "test_salt_32chars_test_salt_") 输出确定值且与 Java 版一致；BATCH_SIZE=1000 配置生效
  QA scenarios: 
    - Happy: 验证 MD5("123456" + salt) 输出 32 位十六进制字符串
    - 边缘: 空密码、超长密码处理
  Commit: N

- [x] 2. 实现数据池模块 (datapool.py)
  What / Must NOT do: 为生成逼真中文数据所需的静态数据池：
    - 200+ 中文姓氏和名字组合模板
    - 100+ 企业名称模板（含行业词，如「XX餐饮管理有限公司」「XX科技有限公司」）
    - 200+ 技能标签（按分类组织，与 category 表对应）
    - 100+ 职位标题模板（按分类组织，如餐饮→"周末餐厅服务员""后厨帮工"）
    - 50+ 工作经历模板（HTML 富文本格式，含不同行业版本）
    - 30+ 公司简介模板
    - 30+ 职位描述模板（HTML 富文本格式，覆盖工作内容、任职要求等）
    - 面试/录用/淘汰通知消息模板
    - 聊天消息模板（HR 和求职者双视角）
    Must NOT: 硬编码数量限制（应在 generator 中控制）；不包含 AI 生成内容
  Parallelization: Wave 1 | Blocked by: - | Blocks: 2~7
  References: uniseek_mock_data.sql 中各类数据的模式, uniseek_schema.sql 中 category 表 62 条种子数据
  Acceptance criteria: 每个数据池至少 20 个非重复条目，总计 700+ 条模板数据
  QA: 检查所有模板字符串格式正确（HTML 标签闭合、JSON 格式正确）
  Commit: N

- [x] 3. 实现用户和实名认证生成器 (generators/user_gen.py + real_name_gen.py)
  What / Must NOT do: 
    - user: 生成 8,000 条用户记录，含 7,500 求职者 + 400 HR + 98 管理员 + 2 超级管理员
    - 手机号格式 1xx + 8位数字，无重复
    - **管理员保留号段**：`13900000001~13900000299`（共 299 个保留号），**严禁普通用户使用此号段**
    - 普通用户手机号从 `13000000000~13999999999` 范围中排除保留号段后随机生成
    - 邮箱: nickname@uniseek.com 格式，无重复
    - 密码统一: 普通用户 123456，管理用户 admin（MD5+盐加密）
    - 时间分布在 2010-2026，早期用户少、后期多（按指数增长曲线分布）
    - 信用分 100（默认），约 5% 用户因违规扣分到 60-99
    - avatar_url: 20% 用户填充 Faker 生成的占位头像 URL，其余 NULL
    - last_login_time: 活跃用户随机分布在近期，不活跃用户 NULL
    - real_name_auth: ~87% 用户完成实名认证，身份证号使用 Faker 生成（符合大陆身份证规则）
    - 管理员和超级管理员手机号使用保留号段
    Must NOT: 不生成重复手机号/邮箱；管理员号段与普通用户号段不重叠
  Parallelization: Wave 2 | Blocked by: 1, 2 | Blocks: 3, 4, 5
  References: uniseek_schema.sql:44-62(user表), :67-81(real_name_auth表)
  Acceptance criteria: 生成 8,000 条 user + 7,000 条 real_name_auth，uk_phone/uk_email 无重复
  QA: 随机抽检 10 条 phone/email 确认唯一；验证管理员号段无普通用户占用；抽检 3 条密码用 PasswordUtil.verify() 验证通过
  Commit: N

- [x] 4. 实现企业生成器 (generators/enterprise_gen.py)
  What / Must NOT do:
    - 400 条企业记录，每 HR 对应 1 家企业
    - 统一社会信用代码 18 位字母数字，无重复
    - 行业分布: 餐饮 20%、物流 12%、IT 15%、教育 12%、设计 10%、家政 8%、美容 8%、其他 15%
    - region_id 从现有 region 种子数据中随机引用区县级
    - audit_status: 80% 已认证, 15% 待审, 5% 驳回
    - 公司描述从模板池中随机组合
    - license_img_url: 模拟生成 URL（如 `https://cdn.uniseek.com/licenses/{id}.jpg`）
  Parallelization: Wave 2 | Blocked by: 2, 3 | Blocks: 5
  References: uniseek_schema.sql:141-160(enterprise表)
  Acceptance criteria: 400 条企业记录，uk_user_id 唯一，uk_credit_code 格式正确
  QA: 验证每条 region_id 在 region 表中存在；credit_code 匹配 18 位字母数字正则
  Commit: N

- [x] 5. 实现简历生成器 (generators/resume_gen.py)
  What / Must NOT do:
    - 7,000 条简历，每求职者 1 条（uk_user_id 唯一）
    - 性别随机 (男/女)，出生日期 1985-2005
    - 学历匹配年龄合理性规则：
      - 2002年后出生 → 最高本科
      - 1997-2002年出生 → 最高硕士
      - 1997年前出生 → 博士或硕士
    - 技能标签从数据池中按分类随机组合 3-8 个
    - 工作经历使用模板 + 随机填充（富文本 HTML 格式）
    - is_published: 60% 已发布到人才市场
  Parallelization: Wave 2 | Blocked by: 2, 3 | Blocks: 6
  References: uniseek_schema.sql:86-103(resume表)
  Acceptance criteria: 7,000 条简历，uk_user_id 无重复
  QA: 抽检 10 条验证 skills 为合法 JSON/逗号分隔；experience 为合法 HTML；年龄-学历关系逻辑正确
  Commit: N

- [x] 6. 实现职位生成器 (generators/task_gen.py)
  What / Must NOT do:
    - 5,000 条职位，平均每企业 ~12 条
    - 分类分布: 餐饮服务~18%、家教辅导~12%、快递物流~15%、其他分类合理分配
    - 地区分布: 集中在北上广深+新一线城市（占 60%），其余散布全国
    - 薪资范围真实（餐饮日结 100-300、家教时薪 30-150、技术月薪 3000-15000 等）
    - 状态分布: 50% 招聘中, 15% 待审, 12% 已满员, 13% 已过期, 10% 已下架
    - total_quota: 3-50 人
    - **remaining_quota**: 统一初始化为 `total_quota`（生成阶段不做调整）。**SQL 输出阶段**（见 Todo 10）通过 UPDATE 语句按实际录用人数扣减
    - 职位描述从数据池模板随机组合（HTML 富文本），必须为非空
    - 职位标签(tag): 从数据池按分类组合 2-4 个标签，格式如 `["包吃","周末","日结"]`
    - 经纬度(longitude/latitude): 根据 region_id 对应的城市中心坐标 + 随机偏移生成（或 50% 填充、50% NULL）
    - 职位标题从模板池按分类随机组合
    - 时间分布符合业务节奏（工作日上午发布居多）
    - version 字段使用 DEFAULT 0
  Parallelization: Wave 3 | Blocked by: 3, 4 | Blocks: 6
  References: uniseek_schema.sql:165-199(task表)
  Acceptance criteria: 5,000 条职位，外键 enterprise_id/category_id/region_id 全部有效；description 均非空
  QA: 验证 salary_min ≤ salary_max；remaining_quota = total_quota；tag 格式为合法 JSON 数组
  Commit: N

- [x] 7. 实现投递表生成器 (generators/application_gen.py)
  What / Must NOT do:
    - 80,000 条投递记录（核心数据量之一）
    - **唯一性算法（必须）**：
      - 对每名求职者，使用 `random.sample(available_tasks, k=min(10, len(available_tasks)))` 抽取不重复职位
      - 不同求职者可投递相同职位（uk 约束是 `(task_id, applicant_id)` 联合唯一）
      - 复杂度 O(N_applicants × 10) ≈ 75K 次采样，无跨用户碰撞风险
    - 投递时间在职位发布时间之后、截止时间之前
    - **状态分配方式（明确为统计分布模式，非状态机模拟）**：
      - 按以下比例直接分配最终状态：30% 已投递(0), 15% 待面试(1), 8% 面试通过(2), 15% 已录用(3), 20% 已淘汰(4), 12% 已完成(5)
      - 状态为 1/2/3 的记录：填充 interview_time（随机未来时间）和 interview_location（从模板池选取）
      - 状态为 4 的记录：填充 reject_reason（从淘汰原因模板池选取）
      - 状态为 3/5 的记录：设置 hr_id 为负责该职位所在企业的 HR 用户 ID
      - 状态为 0 的记录：hr_id=NULL，其他业务字段均为 NULL
    - 简历快照(resume_snapshot)：从 resume 表读取字段序列化为 JSON（投递时快照）
    - version 字段使用 DEFAULT 0
  Parallelization: Wave 3 | Blocked by: 5, 6 | Blocks: 7, 8
  References: uniseek_schema.sql:204-229(task_application表), UniSeek全平台业务逻辑设计V2.md 二十节
  Acceptance criteria: 80,000 条投递，uk_task_applicant 无重复，所有外键有效
  QA: 抽查 20 条验证：status 0 的 hr_id=NULL、status 4 的有 reject_reason、status 3/5 的有 hr_id；resume_snapshot JSON 格式正确
  Commit: N

- [x] 8. 实现通知、聊天和投诉生成器
  What / Must NOT do: 三个生成器（可合并在一个文件中）:
    - notification (60,000条): 从投递事件自动生成
      - schema 类型映射: type=0(系统通知) 占 55%, type=1(面试邀请) 占 20%, type=2(录用通知) 占 10%, type=3(淘汰通知) 占 15%
      - 通知内容从模板池按类型选取，填充具体信息（用户名、职位名、时间地点等）
      - is_read: 50% 已读, 50% 未读
      - sender_id: 系统通知为 NULL，业务通知为对应 HR 的 user_id
      - biz_id: 关联对应的投递记录 ID
    - chat_session (25,000条): 
      - 从 status≥1 的投递记录中抽样创建（约 45% 的合格投递产生会话）
      - 按投递记录 1:1 创建（uk_task_application_id 唯一）
      - employer_id=对应职位的 HR 用户 ID, seeker_id=求职者用户 ID
    - chat_message (100,000条):
      - 每活跃会话 ~4 条消息（100K/25K=4.0，实现允许 2-6 条的随机波动）
      - HR 和求职者交替发送（sender_id 在 employer_id 和 seeker_id 之间交替）
      - 内容从聊天模板池组合
      - 部分消息标记为未读（最近的消息未读，较早的消息已读）
    - complaint (300条):
      - target_type: 70% 企业(1), 30% 用户(2)
      - status: 50% 待处理(0), 20% 处理中(1), 30% 已结案(2)
      - handler_id: 已结案的填充管理员 user_id
  Parallelization: Wave 3 | Blocked by: 7 | Blocks: 8
  References: uniseek_schema.sql:234-296(notification/chat_session/chat_message), :320-339(complaint)
  Acceptance criteria: 通知/会话/消息各表记录数达标，外键全部有效，chat_session.uk_task_application_id 唯一
  QA: 通知类型映射正确（5类分布→4种schema type）；聊天消息 sender_id 交替模式正确；抽检 5 个聊天会话验证消息时间顺序
  Commit: N

- [x] 9. 实现操作日志和日报统计生成器
  What / Must NOT do:
    - operation_log (25,000条): 
      - 从用户注册→登录→投递→HR处理→审核 全链路覆盖
      - 操作类型 15+ 种（REGISTER, LOGIN, SAVE_RESUME, APPLY, HIRE, REJECT, AUDIT_TASK 等）
      - IP 地址随机生成（IPv4 格式）
      - detail 字段为 JSON 格式，记录变更内容（如 `{"fromStatus":0,"toStatus":1}`）
      - operator_id: 对应操作用户 ID，系统操作为 NULL
    - daily_statistics (365条):
      - 覆盖 2025-07-16 至 2026-07-15 每天一条
      - 数据量呈增长趋势（近期数值更大，早期数值小）
      - 各指标数值与生成的业务数据量级成比例（用户数、投递数等）
  Parallelization: Wave 4 | Blocked by: 3, 5, 6, 7 | Blocks: 8
  References: uniseek_schema.sql:302-315(daily_statistics), :344-358(operation_log)
  Acceptance criteria: 25,000 条日志 + 365 条统计，外键有效，uk_stat_date 唯一
  QA: 抽检日志 JSON detail 格式正确；统计数值非负且合理（与业务数据量成比例）
  Commit: N

- [x] 10. 实现主编排脚本 (generate.py) 和验证脚本 (validate.py)
  What / Must NOT do:
    - **generate.py**（主入口）:
      - 从 config.py 读取数据量配置
      - 按依赖顺序调用各生成器，将 ID 映射在生成器间传递
      - 使用 sql_output.py 写入 `uniseek_mock_data_large.sql`
      - SQL 文件结构（各步骤严格按顺序）:
        ```
        SET FOREIGN_KEY_CHECKS = 0;
        SET NAMES utf8mb4;
        START TRANSACTION;

        -- DELETE 顺序（显式写死，排除 category/region）
        DELETE FROM `chat_message`;
        DELETE FROM `chat_session`;
        DELETE FROM `notification`;
        DELETE FROM `task_application`;
        DELETE FROM `complaint`;
        DELETE FROM `operation_log`;
        DELETE FROM `daily_statistics`;
        DELETE FROM `task`;
        DELETE FROM `resume`;
        DELETE FROM `enterprise`;
        DELETE FROM `real_name_auth`;
        DELETE FROM `user`;
        -- 注意：category 和 region 不删除（种子数据）

        -- 各表 INSERT（每 BATCH_SIZE=1000 行 flush 一次）
        INSERT INTO `user` ... VALUES ...;  -- 每批1000行
        ...
        INSERT INTO `task_application` ... VALUES ...;  -- 每批1000行
        ...

        -- 按实际录用/完成人数修正 remaining_quota
        UPDATE `task` t
        SET t.`remaining_quota` = t.`total_quota` - (
          SELECT COUNT(*) FROM `task_application` a
          WHERE a.`task_id` = t.`id` AND a.`status` IN (3, 5)
        );

        -- 将已满员的职位标记为 status=2
        UPDATE `task` SET `status` = 2 WHERE `remaining_quota` = 0 AND `status` = 1;

        SET FOREIGN_KEY_CHECKS = 1;
        COMMIT;
        ```
      - 输出完成打印各表实际记录数统计
    - **validate.py**（独立验证脚本，无需 MySQL 即可运行部分检查）:
      1. 统计验证：逐表统计 INSERT 行数 vs 配置目标（偏差 < 5%）
      2. 外键存在性验证（基于文件）：扫描各表 INSERT 中的 FK ID，提取父表 ID 集合，断言每条 FK 引用都存在
      3. 唯一性验证（基于文件）：提取 uk_phone/uk_email/uk_credit_code/uk_task_applicant 的值集合，断言去重后大小 = INSERT 行数
      4. MySQL 验证（可选，需 `uniseek_test` 数据库）：导入并执行 CHECK SQL
    Must NOT: 覆盖现有 `uniseek_mock_data.sql`；不包含任何交互式输入；不删除 category 和 region
  Parallelization: Wave 4 | Blocked by: 2~9 | Blocks: 9, 10
  References: uniseek_mock_data.sql 整体结构作为输出格式参考
  Acceptance criteria: 运行 generate.py 后生成 sql 文件，总行数 > 30万条记录；validate.py 全部验证通过
  QA: 运行 generate.py → 运行 validate.py（统计+外键+唯一性验证）→ 记录结果
  Commit: N

- [x] 11. Git LFS 配置验证和完整数据生成
  What / Must NOT do:
    - 在项目根目录初始化 Git LFS（如尚未初始化）：`git lfs install`
    - 确认 `.gitattributes` 已正确配置：`uniseek_mock_data_large.sql filter=lfs diff=lfs merge=lfs -text`
    - 运行 `git lfs track` 确认跟踪规则生效
    - 运行 `python generate.py` 生成数据
    - 运行 `python validate.py` 执行全部验证
    - 验证结果记录到 `.omo/evidence/task-11-mock-data-generator.md`
    Must NOT: 将大文件直接加入 git 普通存储（必须走 LFS）
  Parallelization: Wave 5 | Blocked by: 10 | Blocks: -
  References: 无
  Acceptance criteria: `git lfs track` 输出包含 `uniseek_mock_data_large.sql`；generate.py 成功运行；validate.py 全部通过
  QA: 
    - Happy: `git lfs ls-files` 确认 SQL 文件由 LFS 管理
    - 验证: `validate.py` 全部 7 项检查通过
  Commit: N — 整体确认后由用户决定是否提交

## Final verification wave
- [x] F1. 计划合规性审计——交付物是否按计划完成
- [x] F2. 代码质量审查——Python 代码风格、Faker 使用是否合理、SQL 输出格式是否规范
- [x] F3. 数据质量审查——记录数达标（30万+）、外键完整、数据真实感
- [x] F4. 范围保真度——检查无越界行为（修改了产品代码、删除了种子数据等）

## Commit strategy
本次任务属于独立工具脚本，不涉及现有产品代码的修改。`uniseek_mock_generator/` 代码目录可提交至 git（普通存储），`uniseek_mock_data_large.sql` 由 Git LFS 管理。整体由用户确认后再决定是否提交。

## Success criteria
1. `python generate.py` 一键生成 SQL 文件（约 120-150MB）
2. 总记录数超过 30万 条
3. `validate.py` 全部验证项通过（统计、外键、唯一性、MySQL 语法）
4. `mysql -u root -p uniseek_test < uniseek_mock_data_large.sql` 无错误
5. 所有测试账号可用 123456/admin 登录
6. 数据在 2010年至2026-07-15 之间合理分布
7. `git lfs track` 正确跟踪 SQL 文件，推送 GitHub 无大小限制报错
8. 数据符合 UniSeek 全平台业务逻辑
