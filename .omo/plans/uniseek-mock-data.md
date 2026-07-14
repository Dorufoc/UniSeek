# uniseek-mock-data - Work Plan

## TL;DR (For humans)

**What you'll get:**
0. ✅ 消除后端、文档、数据库之间的不一致（移除结算金额、统一状态定义、修正 Entity 注释）
1. ✅ 修复 `uniseek_schema.sql` 中职位分类种子数据，为全部 15 个顶级大类补全子分类
2. ✅ 一份可在本地开发/测试数据库独立运行的 SQL 脚本（`uniseek_mock_data.sql`），填充完整的测试模拟数据——包括求职者、企业 HR、管理员账号，企业资质，在线简历，兼职职位，简历投递与状态流转，聊天消息，通知消息，运营日报统计，用户投诉和操作审计日志。

**Why this approach:** 先消除代码库中现有的一致性债务（注释错误、字段缺失、值映射冲突），再以此为基础生成正确的 mock 数据。所有数据严格遵循数据库表结构、外键约束和后端状态机规则，密码使用 MySQL MD5 函数动态加密直接兼容 Java 后端的 `MD5(密码+盐)` 校验方式。

**What it will NOT do:** 不修改业务逻辑代码（仅修改注释和文档）；不重新插入已有的地区种子数据；不生成任何非 SQL 制品。

**Effort:** Medium
**Risk:** Low — 大部分工作是注释修复和数据填充，无架构风险
**Decisions to sanity-check:** 密码盐值使用统一的 `a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6`，测试密码统一为 `123456`

Your next move: 审批此计划，然后执行 `/start-work` 开始工作。

---

> TL;DR (machine): Medium effort, Low risk, 输出「修复后的 schema + mock 数据 SQL」+ Momus 高精度评审。

## Scope
### Must have
- **A. 移除结算金额**：从后端 Entity、DTO、Service、API 文档中彻底移除 `settlement_amount`/`settlementAmount`
- **B. 修正分类计数**：`uniseek_schema.sql` 分类种子数据修复（补全 11 个大类的子分类，注释改为 62 条）
- **C. 统一状态定义**：`task_application.status=2` 统一为 "面试通过"（同步 schema 注释和文档）
- **D. 修正 Entity 注释**：修复 Task.java/Resume.java/User.java 中与 Schema 矛盾的 JavaDoc 注释
- **E. 生成 mock 数据**：14 张业务表的完整模拟数据，覆盖所有业务状态和流转路径

### Must NOT have (guardrails, anti-slop, scope boundaries)
- 不修改业务逻辑代码（仅修改注释、文档、移除冗余字段）
- 不重新插入 `region` 表数据（已有种子数据）
- 不删除 `CompleteRequest.java` 以外的任何类或方法（仅移除字段和引用）
- 不使用 AI 常见的通用占位符数据，所有 mock 数据真实可信

## Verification strategy
- Test decision: 手动执行验证 + Momus 评审
- Evidence: `.omo/evidence/task-*-uniseek-mock-data.log`

## Execution strategy
### Parallel execution waves
Wave 0（并行）：A-移除结算金额 / B-修正分类计数 / C-统一状态定义 / D-修正 Entity 注释 — 4 个无相互依赖的修复任务
Wave 1：E1-基础 mock 数据表（user, real_name_auth, enterprise, resume）
Wave 2：E2-职位 + 投递数据（task, task_application）
Wave 3：消息与聊天 + 统计管理表（notification, chat_session, chat_message, daily_statistics, complaint, operation_log）
Wave 4：脚本收尾 + 最终验证

### Dependency matrix
| Todo | Depends on | Blocks | Can parallelize with |
| --- | --- | --- | --- |
| 1 | - | 5,6,7,8 | 2,3,4 |
| 2 | - | 5,6,7,8 | 1,3,4 |
| 3 | - | 6 | 1,2,4 |
| 4 | - | 5 | 1,2,3 |
| 5 | 1,4 | 6 | - |
| 6 | 1,2,3,5 | 7 | - |
| 7 | 1,5,6 | 8 | - |
| 8 | 1,5,6,7 | - | - |

## Todos

### — Wave 0：代码库一致性修复（4 项并行）—

- [x] 1. 从后端 Entity、DTO、Service、API 文档中移除 `settlementAmount`
  What to do / Must NOT do:
  - 以下文件需要修改：
    1. **`uniseek_java/.../entity/TaskApplication.java`**：删除第 52-53 行 `/** 结算金额 */ private BigDecimal settlementAmount;` 及相关 import（`java.math.BigDecimal` 如不再使用则移除）
    2. **`uniseek_java/.../dto/CompleteRequest.java`**：删除第 13-14 行 `/** 结算金额 */ private BigDecimal settlementAmount;` 及相关 import
    3. **`uniseek_java/.../service/impl/ApplicationServiceImpl.java`**：删除第 278 行 `application.setSettlementAmount(request.getSettlementAmount());`
    4. **`api.md`**：搜索 `settlementAmount` / `settlement_amount`，在 8.6 结算确认接口中移除相关字段描述和请求/响应示例中的对应行
  - 注意：`uniseek_schema.sql` 的 `task_application` 表中**原本就没有** `settlement_amount` 列，无需修改
  - 检查 BigDecima import 是否还有其他用途（Task.java 也有 BigDecima），只移除不再使用的 import
  Must NOT do: 不要误删 `settlementAmount` 以外的功能代码；不要影响结算接口的正常业务流程（仅将状态变为已完成，不携带金额字段）
  Parallelization: Wave 0 | Blocked by: - | Blocks: 5,6,7,8 | Can parallelize with: 2,3,4
  References:
  - `TaskApplication.java:52-53`（需删除的字段）
  - `CompleteRequest.java:13-14`（需删除的字段）
  - `ApplicationServiceImpl.java:278`（需删除的引用行）
  - `api.md`（全文搜索 settlementAmount）
  - `uniseek_schema.sql:196-222`（确认无 settlement_amount 列）
  Acceptance criteria:
  ```bash
  grep -r "settlementAmount" src/main/java --include="*.java"  # 应无结果（除可能的日志/注释）
  grep -r "settlementAmount" api.md  # 应无结果
  ```
  QA scenarios: 搜索确认无残留引用；检查编译是否通过（使用 Maven compile）；Evidence `.omo/evidence/task-A-uniseek-mock-data.log`
  Commit: N

- [x] 2. 修复 `uniseek_schema.sql` 中职位分类种子数据（补全所有顶级大类的子分类 + 修正计数）
  What to do / Must NOT do:
  - 定位 `uniseek_schema.sql` 中 "3.1 职位分类种子数据" 部分（当前约第 358-400 行）
  - 当前状态：15 个顶级大类中，仅有 4 个（餐饮服务/家教辅导/快递物流/设计创作）有子分类
  - 需要补全以下 **11 个大类**的子分类（每个大类 2-3 个子分类，ID 从 31 开始）：
    - 4-促销导购 → 导购员(31)、促销员(32)、地推推广(33)
    - 5-话务客服 → 电话客服(34)、在线客服(35)、售后客服(36)
    - 7-文案写作 → 公众号文案(37)、新闻稿撰写(38)、营销文案(39)
    - 8-技术支持 → IT运维(40)、软件测试(41)、技术助理(42)
    - 9-翻译校对 → 英语翻译(43)、日语翻译(44)、文件校对(45)
    - 10-美容美发 → 美发师(46)、美容师(47)、美甲师(48)
    - 11-家政保洁 → 家庭保洁(49)、月嫂(50)、钟点工(51)
    - 12-教育培训 → 课程顾问(52)、助教(53)、教务管理(54)
    - 13-活动策划 → 活动执行(55)、礼仪接待(56)、展会协助(57)
    - 14-摄影摄像 → 摄影助理(58)、后期修图(59)、摄像跟拍(60)
    - 15-其他 → 其他兼职(61)、其他临时工(62)
  - 子分类按 `parent_id` 分组、每组按 `sort_order` 排序
  - **修正注释**：将 "30条" → **"62条（15个顶级 + 47个子级）"**（因为原有 15 个子分类 + 新增 32 个子分类 = 47 个子级；15 顶级 + 47 子级 = 62 总记录）
  - 修正子分类 INSERT 注释：从 "子级分类（共15个）" → **"子级分类（共47个）"**
  Must NOT do: 不修改现有 30 条分类的 ID 和名称；不删除任何现有数据
  Parallelization: Wave 0 | Blocked by: - | Blocks: 5,6,7,8 | Can parallelize with: 1,3,4
  References:
  - `uniseek_schema.sql:358-400`（当前分类种子数据，15 顶级 + 15 子级）
  - 现有子分类 ID 范围：16-30；新子分类从 31 开始
  Acceptance criteria:
  ```sql
  SELECT COUNT(*) FROM category;  -- 应为 62
  -- 验证所有 15 个顶级大类均有子分类
  SELECT p.name AS parent, COUNT(c.id) AS child_count
  FROM category p LEFT JOIN category c ON p.id = c.parent_id
  WHERE p.parent_id IS NULL
  GROUP BY p.id, p.name;
  -- 应返回 15 行，每行 child_count >= 2
  ```
  QA scenarios: 检查 SQL 语法正确性；验证外键自引用 `fk_category_parent` 不报错；Evidence `.omo/evidence/task-B-uniseek-mock-data.log`
  Commit: N

- [x] 3. 统一 `task_application.status=2` 定义：Schema 注释 + API 文档同步为 "面试通过"
  What to do / Must NOT do:
  - 需要同步修改以下 3 处：
    1. **`uniseek_schema.sql:203`**：将 `'状态：0-已投递, 1-待面试, 2-待定, 3-已录用, 4-已淘汰, 5-已完成'` 改为 `'状态：0-已投递, 1-待面试, 2-面试通过, 3-已录用, 4-已淘汰, 5-已完成'`
    2. **`api.md`**（8.2 投递记录状态列表页 + 8.5 修改投递状态相关说明）中将状态 2 的描述从 "待定" 改为 "面试通过"
    3. **`兼职招聘平台需求规格说明书.md:990`** 状态 2 的名称从 "待定" 改为 "面试通过"
  - 注意：`TaskApplication.java:34` 已经是 `/** 状态：0 已投递 / 1 待面试 / 2 面试通过 / 3 已录用 / 4 已淘汰 / 5 已完成 */` — 正确，无需修改
  - 注意：`ApplicationStatusMachine.java:72` 已经是 `case 2: return "面试通过";` — 正确，无需修改
  Must NOT do: 不要修改数字值（仅修改文本注释），不修改任何业务逻辑代码
  Parallelization: Wave 0 | Blocked by: - | Blocks: 6 | Can parallelize with: 1,2,4
  References:
  - `uniseek_schema.sql:203`（需要修改的 schema 注释）
  - `api.md`（搜索 "待定" 定位相关段落）
  - `兼职招聘平台需求规格说明书.md:990-996`（状态定义表）
  - `TaskApplication.java:34`（已正确，供对照）
  - `ApplicationStatusMachine.java:72`（已正确，供对照）
  Acceptance criteria:
  ```bash
  grep -n "待定" uniseek_schema.sql  # 应无结果（已改为"面试通过"）
  grep -n "待定" api.md              # 应无结果（或仅为不相关的"待定"）
  ```
  QA scenarios: 全文搜索确认无残留 "待定" 引用（仅允许无关匹配）；Evidence `.omo/evidence/task-C-uniseek-mock-data.log`
  Commit: N

- [x] 4. 修正 Java Entity 注释与 Schema 值映射的冲突
  What to do / Must NOT do:
  修改以下 Entity 文件中的 JavaDoc 注释，使其与 `uniseek_schema.sql` 中定义的字段值完全一致：

  1. **`Task.java`** — 3 处注释更正：
     - Line 44-45：`salaryUnit` 注释从 `0 月薪 / 1 日薪 / 2 时薪` → `0 日结 / 1 时薪 / 2 月结`（与 schema 第 167 行一致）
     - Line 47-48：`jobType` 注释从 `0 全职 / 1 兼职 / 2 实习` → `1 全职 / 2 兼职 / 3 实习`（与 schema 第 168 行一致）
     - Line 69-70：`status` 注释从 `0 待审核 / 1 已发布 / 2 进行中 / 3 已截止 / 4 已下架` → `0 待审 / 1 招聘中 / 2 已满员 / 3 已过期 / 4 已下架`（与 schema 第 175 行一致）

  2. **`Resume.java`** — 1 处注释更正：
     - Line 25-26：`gender` 注释从 `0 女 / 1 男` → `0 男 / 1 女`（与 schema 第 110 行一致，注意 0→男 1→女）

  3. **`User.java`** — 1 处注释补充：
     - Line 38-39：`role` 注释从 `0 求职者 / 1 企业 HR` → `0 求职者 / 1 企业 HR / 9 管理员`（补充遗漏的管理员角色定义，与 schema 第 50 行一致）

  Must NOT do: 只修改 JavaDoc 注释文本，不修改任何字段名、类型、值逻辑或业务代码
  Parallelization: Wave 0 | Blocked by: - | Blocks: 5 | Can parallelize with: 1,2,3
  References:
  - `Task.java:44-70`（3 处需修正的注释）
  - `Resume.java:25-26`（1 处需修正的注释）
  - `User.java:38-39`（1 处需补充的注释）
  - `uniseek_schema.sql:167-175`（schema 标准值定义）
  - `uniseek_schema.sql:50`（role 定义：0-求职者, 1-企业HR, 9-管理员）
  Acceptance criteria:
  ```bash
  # Task.java 确认修正
  grep -A2 "salaryUnit" Task.java | head -4  # 应包含"0 日结 / 1 时薪 / 2 月结"
  grep -A2 "jobType" Task.java | head -4     # 应包含"1 全职 / 2 兼职 / 3 实习"
  grep -A2 "private Integer status" Task.java # 应包含"0 待审 / 1 招聘中 / 2 已满员"
  # Resume.java 确认修正
  grep -A2 "gender" Resume.java | head -4    # 应包含"0 男 / 1 女"
  # User.java 确认修正
  grep -A2 "role" User.java | head -4        # 应包含"9 管理员"
  ```
  QA scenarios: 逐文件确认注释修改无误；Evidence `.omo/evidence/task-4-uniseek-mock-data.log`
  Commit: N

### — Wave 1：Mock 数据—基础表 —

- [x] 5. 创建 `uniseek_mock_data.sql` 文件头部与基础表 mock 数据（user, real_name_auth, enterprise, resume）
  What to do / Must NOT do:
  - 在项目根目录创建 `uniseek_mock_data.sql` 文件
  - 文件头包含注释说明、脚本版本、创建日期、使用方式
  - 设置 `SET FOREIGN_KEY_CHECKS=0` / `SET NAMES utf8mb4`
  - 使用 `START TRANSACTION` 包裹全部操作
  - **user 表（25条）**：管理员 1 条(role=9)、企业 HR 8 条(role=1)、求职者 16 条(role=0)
    - 密码统一使用 `MD5(CONCAT('123456', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'))`
    - 盐值统一为 `'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'`
    - 手机号使用真实感号码（如 138xxxx 开头，各不相同）
    - 邮箱格式 `nickname@uniseek.com`
    - 昵称使用真实中文姓名（如：张三、李四、王五等）
    - 设置合理的 `create_time` 分布在近 30 天内
  - **real_name_auth 表（24条）**：管理员除外，其他用户每人 1 条实名认证
    - 身份证号使用 `110101`（北京市东城区）开头
    - 年龄 18-50 岁之间，Hutool 校验可通过（需包含合法校验码）
    - 真实姓名与 user.nickname 对应
  - **enterprise 表（8条）**：每个 HR 对应 1 家企业
    - 公司名称真实感（如"味美滋餐饮管理有限公司"、"飞速达物流有限公司"）
    - 统一社会信用代码 18 位（格式合规）
    - industry 字段填写对应行业
    - region_id 选取已有地区代码（区县级）
    - audit_status 混合：5家已认证、2家待审、1家驳回
  - **resume 表（16条）**：每个求职者 1 份简历
    - 使用不同的教育背景、学校、技能组合
    - skills 使用 JSON 数组格式（如 '["Java","Spring Boot","MySQL"]'）
    - experience 写一段富文本格式的工作经历（<p>标签）
    - gender（0-男, 1-女，注意修正后的 Entity 注释定义）
    - birth_date/education/school 均有值
  Must NOT do: 不使用重复手机号或邮箱；简历不包含真实个人隐私信息
  Parallelization: Wave 1 | Blocked by: 1,4 | Blocks: 6
  References:
  - schema: `uniseek_schema.sql:40-123` (user, real_name_auth, enterprise, resume 表结构)
  - entity: `User.java`, `RealNameAuth.java`, `Enterprise.java`, `Resume.java`
  - password: `PasswordUtil.java:37-40` (MD5 + salt 加密方式)
  - region seed: `uniseek_schema.sql:408-928` (已有地区代码)
  Acceptance criteria:
  ```sql
  SELECT COUNT(*)=25 FROM user;
  SELECT COUNT(*)=24 FROM real_name_auth;
  SELECT COUNT(*)=8  FROM enterprise;
  SELECT COUNT(*)=16 FROM resume;
  -- 验证密码可匹配
  SELECT COUNT(*) FROM user WHERE password = MD5(CONCAT('123456', salt));  -- 应为 25
  ```
  QA scenarios: 执行脚本后运行上述验证 SQL；Evidence `.omo/evidence/task-E1-uniseek-mock-data.log`
  Commit: N

### — Wave 2：Mock 数据—职位与投递 —

- [x] 6. 插入职位数据与投递/报名数据（task 表 20条 + task_application 表 50条）
  What to do / Must NOT do:
  - **task 表（20条）**：分布在 8 家企业下
    - 已有 category 种子数据（修复后 ID 1-62，含全部 15 个大类的子分类），引用子分类 ID（16-62）
    - 使用区县级 region ID
    - 覆盖不同 job_type（1-全职, 2-兼职, 3-实习）
    - 覆盖不同 salary_unit（0-日结, 1-时薪, 2-月结）
    - 覆盖不同 status（0-待审, 1-招聘中, 2-已满员, 3-已过期, 4-已下架）
    - 状态为 1(招聘中) 的需设置 audit_time
    - 状态为 2(已满员) 的 remaining_quota=0
    - 状态为 3(已过期) 的 deadline < NOW()
    - 合理的薪资范围（日结 80-500、时薪 15-50、月结 2000-15000）
    - title 和 description 使用真实感中文描述（富文本格式）
    - tag 使用 JSON 数组格式（如 '["兼职","周末","包吃"]'）
    - 有合理的 latitude/longitude 坐标、address 地址文本
    - total_quota 3-20 人，remaining_quota ≤ total_quota
    - deadline 设置在合理时间范围内
    - create_time 分布在近 15 天内
  - **task_application 表（50条）**：求职者投递各职位
    - 同一求职者对同一职位只能投递一次（UNIQUE KEY 约束）
    - 覆盖所有投递状态（0-已投递, 1-待面试, 2-面试通过, 3-已录用, 4-已淘汰, 5-已完成）
    - 状态流转遵循 `ApplicationStatusMachine.java:21-33` 的规则
    - resume_snapshot 字段为 JSON 格式，包含投递时简历的关键字段
    - 状态为 1 的需设置 interview_time（未来时间）和 interview_location
    - 状态为 4 的需设置 reject_reason
    - 状态为 3 的已录用，需确保对应 task 的 remaining_quota 减少
    - **注意：不再有 settlementAmount 字段**（已在 Todo 1 中移除）
    - 使用 version=0 作为初始乐观锁版本号
    - 对应 cht_session 将在后续步骤创建
  - **同时更新 task.remaining_quota**：每插入一条 status=3 或 5 的投递，对应 UPDATE task SET remaining_quota = remaining_quota - 1；若降为 0 则 UPDATE task SET status = 2
  Must NOT do: 不违反 uk_task_applicant 唯一约束；不插入状态流转不合法的组合（如 0→3 直接跳转）
  Parallelization: Wave 2 | Blocked by: 1,2,3,5 | Blocks: 7
  References:
  - schema: `uniseek_schema.sql:156-192` (task 表结构)
  - schema: `uniseek_schema.sql:196-222` (task_application 表结构，注意 status=2 已改为"面试通过")
  - entity: `Task.java`, `TaskApplication.java`
  - status machine: `ApplicationStatusMachine.java:21-33`（状态流转规则）
  - category seed: 修复后 ID 1-62
  Acceptance criteria:
  ```sql
  SELECT COUNT(*)=20 FROM task;
  SELECT COUNT(*)=50 FROM task_application;
  SELECT COUNT(*)=0 FROM task_application ta LEFT JOIN task t ON ta.task_id=t.id WHERE t.id IS NULL;
  SELECT COUNT(*) FROM task_application GROUP BY task_id, applicant_id HAVING COUNT(*)>1; -- 应为 0
  SELECT remaining_quota >= 0 FROM task;
  ```
  QA scenarios: 验证外键完整性 + 状态流转合法性 + 名额不超；Evidence `.omo/evidence/task-E2-uniseek-mock-data.log`
  Commit: N

### — Wave 3：Mock 数据—消息与聊天 + 统计与管理 —

- [x] 7. 插入通知、聊天会话与消息、运营统计、投诉、审计日志数据
  What to do / Must NOT do:
  - **notification 表（30条）**：
    - 涵盖所有 type（0-系统通知, 1-面试邀请, 2-录用通知, 3-淘汰通知）
    - 系统通知 sender_id=NULL；业务通知 sender_id=对应 HR 用户 ID
    - title/content 写真实感中文通知内容
    - is_read 混合未读/已读
  - **chat_session 表（15条）**：
    - 基于投递记录创建，task_application_id 唯一
    - employer_id = 对应职位企业 HR；seeker_id = 求职者
    - last_message 填入摘要，status=0（活跃）
  - **chat_message 表（60条）**：
    - 每个会话约 4 条消息，发送方轮流为 HR 和求职者
    - message_type=0（文本），内容为真实聊天对话
    - is_read 混合状态，send_time 按时间顺序递增
  - **daily_statistics 表（7条）**：最近 7 天运营日报
  - **complaint 表（5条）**：覆盖 target_type(1-企业,2-用户)、status(0-待处理,1-处理中,2-已结案)
  - **operation_log 表（20条）**：
    - 覆盖 REGISTER、LOGIN、SAVE_RESUME、APPLY、AUDIT_TASK、AUDIT_ENTERPRISE、HIRE、COMPLETE、COMPLAINT 等
    - detail 为 JSON 格式，ip_address 使用内网 IP
  Must NOT do: 聊天消息发送者必须为会话参与方；operation_log 的 operator_id 必须为有效用户或 NULL
  Parallelization: Wave 3 | Blocked by: 1,5,6 | Blocks: 8
  References:
  - schema: `uniseek_schema.sql:226-352`（notification, chat_session, chat_message, daily_statistics, complaint, operation_log 表结构）
  - entity: 对应的 6 个 Entity 文件
  - API doc: `api.md` 中定义的 operation_type 和审计场景
  Acceptance criteria:
  ```sql
  SELECT COUNT(*)=30 FROM notification;
  SELECT COUNT(*)=15 FROM chat_session;
  SELECT COUNT(*)=60 FROM chat_message;
  SELECT COUNT(*)=7  FROM daily_statistics;
  SELECT COUNT(*)=5  FROM complaint;
  SELECT COUNT(*)=20 FROM operation_log;
  ```
  QA scenarios: 验证外键完整性 + 消息发送者权限正确性；Evidence `.omo/evidence/task-E3-uniseek-mock-data.log`
  Commit: N

- [x] 8. 编写脚本尾部事务提交与收尾
  What to do / Must NOT do:
  - 使用 `COMMIT;` 提交事务
  - 恢复 `SET FOREIGN_KEY_CHECKS=1;`
  - 添加使用说明注释（如何运行脚本）
  - 添加数据量汇总注释（每个表的记录数）
  Must NOT do: 事务未 commit 前不要恢复外键检查
  Parallelization: Wave 4 | Blocked by: 1,5,6,7 | Blocks: -
  Acceptance criteria: 脚本无语法错误；可在 MySQL 8 上完整执行
  QA scenarios: 在 MySQL 8 实例上执行脚本并检查输出；Evidence `.omo/evidence/task-E4-uniseek-mock-data.log`
  Commit: N

## Final verification wave
- [x] F1. Plan compliance audit — 所有 Must have 已全部实现
- [x] F2. 编译验证 — `mvn compile` 通过
- [x] F3. Schema 语法验证 — 分类种子数据已修复为 62 条，status=2 已改为"面试通过"
- [x] F4. Mock 数据脚本验证 — 12 张表 280 条记录，结构完整
- [x] F5. Scope fidelity — 未越界修改非目标文件

## Commit strategy
本计划为纯生成和交付任务，不涉及 git 提交。所有修改由用户自行决定版本管理。

## Success criteria
- 所有 4 项代码库一致性修复（A/B/C/D）已完成
- `uniseek_mock_data.sql` 脚本已在项目根目录创建
- 脚本在 MySQL 8 上可完整执行且无错误
- 14 张业务表均已填充合理数量的测试数据
- 后端编译通过，无 compilation error
