---
slug: fix-java-db-docs
status: awaiting-approval
intent: clear
pending-action: write .omo/plans/fix-java-db-docs.md
approach: 4-wave parallel execution — DB/Mock → Java清理 → 文档修复 → 代码质量
---

# Draft: fix-java-db-docs

## Components (topology ledger)
| id | outcome | status | evidence path |
|----|---------|--------|--------------|
| DB-SCHEMA | enterprise.region_id 补充外键 | active | uniseek_schema.sql:101-102 |
| DB-MOCK | Mock 数据独立盐值 | active | uniseek_mock_data.sql:24-54 |
| DB-REGION | 地区数据完整性验证 | active | uniseek_schema.sql:832+ |
| JAVA-STUBS | 删除 11 个空 Stub 类 | active | uniseek_java/.../controller/*.java ×7, ws/*.java ×2, config/*.java ×1, service/impl/*.java ×1 |
| JAVA-COMPLAINT | 修复 target_type 注释 | active | Complaint.java:23 |
| JAVA-TASKVO | 对齐枚举值注释 | active | TaskVO.java:39-43,63 |
| JAVA-APPCOUNT | 确认 applicationCount 实现 | active | TaskMapper.xml (待查) |
| JAVA-ROLE-BUG | 修复 TaskServiceImpl 中 role==2 应为 role==9 | active | TaskServiceImpl.java:209 |
| JAVA-ROLE-CONST | 创建 RoleConstant 常量类 + SuperAdmin=99 | active | 全局 |
| JAVA-SUPERADMIN | AdminService 支持 role==99 超级管理员 + 管理员管理 API | active | AdminServiceImpl.java, AdminUserController.java |
| DOC-API-SECT | 修复章节编号 | active | api.md:832-881 |
| DOC-API-DATA | 修复 data 类型说明 | active | api.md:26-39 |
| DOC-README | 补写 README.md | active | README.md |
| DOC-ROLE | 更新三份文档的角色定义和权限矩阵 | active | 需求/API/业务逻辑文档 |
| VUE-ROLE | 前端路由/导航/页面支持 role==99 超管 | deferred | router/index.ts, stores/user.ts, layouts/ |
| JAVA-OPTYPE | 标准化 operation_type 枚举 | deferred | OperationLog.java:23 |

## Open assumptions (announced defaults)
| assumption | adopted default | rationale | reversible? |
|-----------|----------------|-----------|-------------|
| operation_type 枚举取值 | 按业务逻辑文档 §27 的 12 个操作类型字符串创建常量类 | 文档已有明确列举，无需再问 | 可逆（后续可追加） |
| TaskVO.salaryUnit 注释值 | 对齐 SQL/API: 0日结/1时薪/2月结 | 当前注释写 0月薪/1日薪/2时薪，与 SQL/API 反向 | 可逆 |
| TaskVO.jobType 注释值 | 对齐 SQL/API: 1全职/2兼职/3实习 | 当前注释 0全职/1兼职/2实习，偏移一位 | 可逆 |
| TaskVO.status 注释值 | 对齐 SQL/API: 0待审/1招聘中/2已满员/3已过期/4已下架 | 当前注释有偏差 | 可逆 |

## Findings (cited - path:lines)
- C-01: Complaint.java:23 注释为 "0职位/1企业/2用户"；SQL uniseek_schema.sql:316 及 API doc 均为 "1企业/2用户"
- C-02: api.md:832-881 区间 5 处编号 6.2-6.6 应为 7.2-7.6
- C-03: README.md:1 内容仅为 "UniSeek 134555 jhih"
- C-04: uniseek_mock_data.sql:24-54 全部 25 条 user 共享同一盐值
- C-05: uniseek_schema.sql:84-102 enterprise 表无 region_id 外键（对比 task:190-191 有 fk_task_region）
- M-01: 11 个空 Stub 类确认：controller/ 下 7 个、ws/ 下 2 个、config/ 下 1 个、service/impl/ 下 1 个
- M-03: TaskVO.java:88 已有 applicationCount 字段，需验证 Mapper XML 中是否填充
- m-04: api.md:35 data 字段定义为 "Object"，但多处示例展示 null
- X-04: OperationLog.java:23 operationType 为无约束 String；业务逻辑文档 §27 列出 12 种操作类型名

## Decisions (with rationale)
1. **超级管理员角色值 = 99**：与现有 9(管理员) 保持明显差距，`role >= 9` 可统一判断"管理权限"，支持未来扩展更多管理级别
2. **新建 RoleConstant 常量类**：统一管理 0/1/9/99 所有角色值，消除魔法数字，同时修复 TaskServiceImpl 中硬编码 `role==2` 的 bug
3. **删除而非迁移 Stub**：真实实现在子包中 (admin/controller/、chat/websocket/ 等)，Stub 所在包本质是错误位置，直接删除最安全，不影响编译
4. **operation_type 用常量类而非枚举**：枚举会迫使所有存储的值必须匹配有限集，而未来可能追加新操作类型。常量类 + Service 层 if-校验更灵活
5. **Mock 盐值生成方式**：使用 `SUBSTRING(MD5(RAND()), 1, 32)` 替代手写，保证每用户随机
6. **超级管理员权限边界**：继承管理员全部权限，额外拥有"管理员管理"（创建/禁用管理员账号）、"系统配置"查看权限。不影响业务数据（投递、职位等）的读写逻辑

## Scope IN
- 数据库：外键修复、Mock 盐值随机化、地区数据验证、user 表 role 注释更新
- Java：Stub 清理、Complaint/TaskVO 注释、applicationCount 确认、**RoleConstant 常量类**、**TaskServiceImpl role==2 bug 修复**、**AdminService 支持 role==99**、**超级管理员 API**、operation_type 常量
- 文档：API 文档编号/类型修复、README 补写、**三份文档角色定义更新 + 权限矩阵扩展**
- Vue 前端：**路由守卫增加 role==99 支持 + 超管管理页入口**

## Scope OUT (Must NOT have)
- ❌ ArkTS 端改动
- ❌ 实际管理后台页面的完整 UI 实现（仅做路由和权限拦截）
- ❌ 单元测试编写（X-01）—— 新功能，单独计划
- ❌ `chat_message.send_time` 重新命名（m-05）
- ❌ WebSocket 的角色权限增强

## High-Accuracy Review Record
### Round 1
**Momus verdict:** CONDITIONAL-APPROVE — 6 issues found
**Oracle verdict:** CONDITIONAL-APPROVE — 4 issues found

### Fixes applied (Round 1 → Round 2)
| # | Source | Issue | Fix |
|:-:|--------|-------|-----|
| 1 | Momus 🔴 | `业务逻辑设计文档.md` 文件不存在 | 改为 `UniSeek全平台业务逻辑设计.md`（2 处） |
| 2 | Momus 🟡 | 依赖矩阵编号与待办编号不匹配 | 矩阵重建：统一编号 + 新增 `Todo #` 列 + 合并 SQL 注释到 Todo 17 |
| 3 | Momus 🟡 | Todo 15 自引用 Blocks:15 | 改为 Blocks:16 |
| 4 | Momus 🟡 | Todo 10 wave 不匹配（Wave 3 vs Wave 4） | 统一为 Wave 4 |
| 5 | Momus 🔵 | F3 期望 "3 行" 但列表 4 个值 | 改为 "4 行" |
| 6 | Momus 🔵 | RegisterRequest 行号不精确（42→43） | 改为 41-43 + 写明 import 需添加 |
| 7 | Oracle 🟡 | Todo 7 缺少 F-wave 验证步骤 | 新增 F9 |
| 8 | Oracle 🟡 | Todo 18 Vue 路由低估工作量 | 扩充描述：说明需新建路由子树 + admin 路由定义 + 守卫分支 |
| 9 | Oracle 🔵 | Todo 2 非确定性密码副作用 | 添加备注说明 |
| 10 | Oracle 🔵 | Todo 13 @Min/@Max import 注意 | 已在描述中写入 import 语句 |

### Round 2
Momus verdict: ✅ **APPROVE** — "全部 6 个问题已正确修复。计划已具备可执行性。"
Oracle verdict: ✅ **APPROVE** — "全部 4 项 Round 1 问题均已修复，计划文档内容完整、方案可行。"

## Approval gate
status: awaiting-approval
