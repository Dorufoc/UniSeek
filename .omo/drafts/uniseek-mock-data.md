---
slug: uniseek-mock-data
status: awaiting-approval
intent: clear
pending-action: write .omo/plans/uniseek-mock-data.md
approach: 先消除代码库不一致（移除结算金额、修正分类计数、统一状态定义、修复 Entity 注释），再生成 mock 数据 SQL
---

# Draft: uniseek-mock-data

## Components (topology ledger)
| id | outcome | status | evidence path |
|----|---------|--------|---------------|
| clean-backend | 移除 settlementAmount（Entity/DTO/Service/API文档） | active | TaskApplication/CompleteRequest/ApplicationServiceImpl/api.md |
| schema-fix | 修正分类种子数据+计数 | active | uniseek_schema.sql |
| status-unify | task_application.status=2 统一为"面试通过" | active | schema/api.md/需求文档 |
| entity-comment | 修正 Entity JavaDoc 注释冲突 | active | Task.java/Resume.java/User.java |
| mock-sql | uniseek_mock_data.sql | active | 项目根目录 |

## Open assumptions (announced defaults)
| assumption | adopted default | rationale | reversible? |
|------------|----------------|-----------|-------------|
| 子分类数量 | 每个顶级大类 2-5 个子分类 | 保持覆盖度且不膨胀 | 是 |
| 测试密码 | 统一 `123456` | 便于登录测试 | 是 |
| 密码加密 | MySQL `MD5(CONCAT('123456', salt))` | 兼容 Java 后端 | 否 |
| 数据量级 | 25用户/8企业/20职位/50投递 | 覆盖测试场景且不过度 | 是 |
| 外键约束处理 | SET FOREIGN_KEY_CHECKS=0/1 + 事务 | 可重复执行 | 是 |

## Decisions (with rationale)
1. **移除 settlementAmount** — 后端 Entity 和 Service 有此字段但 Schema 建表语句中没有，属于不一致。移除后端引用而非补充 Schema，因为用户明确要求移除
2. **status=2 统一为"面试通过"** — Java 状态机实际使用此定义，Schema 注释和文档应同步
3. **Entity 注释以 Schema 为准** — Schema 是数据库的源真理，Entity 注释应与其一致
4. **分类总数为 62** — 15 顶级 + 15 已有子级 + 32 新增子级 = 62

## Scope IN
- 移除 settlementAmount（Entity/DTO/Service/API文档）
- 补全分类子分类 + 修正计数
- 统一 status=2 定义为"面试通过"
- 修正 Entity 注释（Task.java/Resume.java/User.java）
- 生成 uniseek_mock_data.sql

## Scope OUT (Must NOT have)
- 不修改业务逻辑代码
- 不删除 CompleteRequest.java 以外的任何类
- 不修改 region 数据

## Approval gate
status: awaiting-approval
