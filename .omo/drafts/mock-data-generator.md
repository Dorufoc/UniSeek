---
slug: mock-data-generator
status: awaiting-approval
intent: clear
pending-action: write .omo/plans/mock-data-generator.md
approach: 使用 Python + Faker(zh_CN) 编写独立的数据生成脚本，输出 SQL INSERT 文件
---

# Draft: mock-data-generator

## Components (topology ledger)
| id | outcome | status | evidence path |
|----|---------|--------|---------------|
| mock-gen-script | Python 独立脚本，生成 10W+ 真实业务 mock 数据 SQL 文件 | active | uniseek_mock_data.sql (884 lines, 280 records baseline) |
| crypto-module | 复刻 Java PasswordUtil 的 MD5+盐加密，统一密码 123456/admin | active | uniseek_java/PasswordUtil.java |
| ref-data | 复用现有的 category(62条) 和 region(3432条) 种子数据 | active | uniseek_schema.sql |
| sql-output | 输出 INSERT 语句文件，与现有 uniseek_mock_data.sql 风格一致 | active | uniseek_mock_data.sql (输出格式参考) |

## Open assumptions (announced defaults)
| assumption | adopted default | rationale | reversible? |
|------------|----------------|-----------|-------------|
| 脚本语言 | Python 3 + Faker zh_CN | Faker 对中文数据（姓名、公司、地址、技能）支持最好；独立于项目现有技术栈 | Yes — 但重构成本低，无外部依赖耦合 |
| 密码方案 | 统一默认密码: 普通用户=123456, 管理用户=admin; MD5+盐加密 | 用户明确要求统一密码，无需在注释中标注；MD5+盐方案与后端加密一致 | Yes — 可在 config.py 中修改 |
| 数据分布 | 用户5,000 + 企业200 + 职位3,000 + 投递45,000 + 其他辅助表 ≈ 172,715 条 | 在业务合理范围内最大化数据量，确保每种状态流转都有足够覆盖 | Yes — 配置化，一行修改即可调整 |
| 引用现有种子 | category 和 region 使用 schema 中的种子数据，脚本不生成 | 这两个表是固定引用数据，无需 mock | Yes — 可在脚本中硬编码或从 DB 读取 |
| 输出目录 | 生成至项目根目录 uniseek_mock_data_large.sql | 与现有 mock 数据文件并列，清晰可辨 | Yes |

## Findings (cited - path:lines)
- 现有 mock 数据 280 条，全部手写 SQL，分布在 14 张表中 (uniseek_mock_data.sql:862-875)
- 密码加密方案: MD5(password + salt)，salt=16字节随机数转32位hex (PasswordUtil.java:37-39)
- 业务表依赖链: user → real_name_auth/enterprise/resume → task → task_application → chat_session → chat_message/notification (uniseek_schema.sql)
- 项目有 3 端: Java 后端、Vue 3 前端、ArkTS 鸿蒙端 (README.md)
- 职位分类 62 条、行政区划 ~3432 条种子数据 (uniseek_schema.sql)
- 投递状态流转: 0=已投递 → 1=待面试 → 3=已录用/4=已淘汰 → 5=已完成 (uniseek_schema.sql:210)
- 业务文档覆盖 30 个功能模块的业务逻辑 (UniSeek全平台业务逻辑设计V2.md)
- 系统使用乐观锁 version 字段防超录 (task.version, task_application.version)

## Decisions (with rationale)
1. **Python + Faker zh_CN**: Faker 库内置中文姓名、地址、公司名称、职位等数据集，生成的 mock 数据逼真度远高于随机字符串
2. **单文件+轻模块结构**: 避免过度工程化，脚本应一目了然易于修改；采用 config + datapool + generators + sql_output 四模块组织
3. **密码统一化**: 所有普通用户密码=123456，管理员密码=admin，与现有种子数据一致，便于测试
4. **数据按业务权重分布**: 投递表(task_application)占总数据量约 45%，聊天消息约 28%，符合实际业务中投递和沟通是核心链路的特征

## Scope IN
- 一个独立的 Python mock 数据生成项目（目录: uniseek_mock_generator/）
- 14 张业务表全覆盖，满足外键约束和唯一索引
- 30W+ 总记录数（目标 ~32 万条）
- 输出为可直接执行的 SQL INSERT 文件
- 所有普通用户密码 123456，管理用户 admin（MD5+盐加密）
- 数据时间分布在 2010 年至 2026-07-15 之间，体现平台长期运营的时间积累，早期数据稀疏、近期数据密集，呈现真实业务增长曲线

## Scope OUT (Must NOT have)
- 不得修改任何现有产品代码（Java/Vue/ArkTS）
- 不得生成 category 和 region 数据（使用现有种子）
- 不得连接数据库直接插入（仅输出 SQL 文件）
- 不得覆盖/修改现有的 uniseek_mock_data.sql
- 不得使用深度学习/AI 生成内容（Faker + 预定义模板即可）

## Open questions
无 — 已通过用户确认。

## High-accuracy review results (Round 1)
### Momus 评审 (2026-07-15)
**VERDICT: REVISE** — 三个阻塞性问题：
1. remaining_quota 矛盾指令（Todo6 vs Todo10）
2. 投递状态是统计分布还是状态机模拟未明确
3. SQL 100W+ 输出缺少流式写入/分批策略

### Oracle 独立评审 (2026-07-15)
**VERDICT: REVISE** — 六个关键问题：
1. 缺少 BATCH_SIZE 批量 INSERT 分块策略
2. DELETE 顺序必须明确排除 category/region（种子数据）
3. uk_task_applicant 唯一性算法未指定
4. 验证策略完全依赖 MySQL 运行时，缺少基于文件的回退方案
5. 管理员手机号段可能和普通用户重叠
6. task.tag/longitude/latitude 字段未提及

### 用户补充需求
- SQL 文件超过 100MB，需引入 Git LFS 支持

### 修复摘要（Round 1 → 已修复）
- remaining_quota: 统一为 Task 生成时设 remaining_quota=total_quota，SQL 输出阶段用 UPDATE 按投递状态修正
- 投递状态: 明确为统计分布模式（非状态机模拟），按比例分配状态，按状态条件填充字段
- 分批策略: 新增 BATCH_SIZE=1000 配置，sql_output.py 实现分块写入
- DELETE 顺序: 显式列出 12 张表顺序，排除 category/region
- 唯一性算法: 指定 random.sample() O(n) 算法
- 文件验证: 新增 validate.py（基于文件的外键存在性和唯一性检查）
- 管理员手机号: 保留号段 13900000001-13900000299
- task 字段补充: tag/longitude/latitude 处理说明
- Git LFS: 新增 .gitattributes 配置跟踪 SQL 文件
- 表数量修正: 12 张业务表（非 14）
- 聊天消息: 调整至 100,000 条（平均 4 条/会话）
- 验证数据库: 推荐使用 uniseek_test
- 数据规模: 从 100W+ 调整为 30W+（~318K）
- 草稿矛盾: 删除 172K 旧引用

### Round 2 — Momus: **APPROVE** ✅ | Oracle: **APPROVE** ✅
Both reviewers confirmed all 7 issues are resolved and the plan is ready for execution.

## Approval gate
status: approved
