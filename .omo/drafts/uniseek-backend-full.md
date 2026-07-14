---
slug: uniseek-backend-full
status: awaiting-approval
intent: clear
pending-action: write .omo/plans/uniseek-backend-full.md
approach: 分12个Wave并行+串行执行，从项目骨架→公共基础→各业务模块→最终验证
---

# Draft: uniseek-backend-full

## Components (topology ledger)
| id | outcome (one line) | status | evidence path |
|---|---|---|---|
| pom.xml | Spring Boot 2.2.2 + 全部依赖声明 | active | uniseek_java/pom.xml |
| common | 统一响应、异常、工具类、配置 | active | src/main/java/com/uniseek/common/ |
| auth | JWT鉴权 + MD5盐加密 + 注册/登录/实名认证 | active | src/main/java/com/uniseek/auth/ |
| user | 用户资料管理 | active | src/main/java/com/uniseek/user/ |
| resume | 在线简历CRUD + 附件上传 | active | src/main/java/com/uniseek/resume/ |
| category | 职位分类树形结构 | active | src/main/java/com/uniseek/category/ |
| region | 行政区划三级树 | active | src/main/java/com/uniseek/region/ |
| enterprise | 企业资质认证 | active | src/main/java/com/uniseek/enterprise/ |
| task | 职位发布/搜索/状态管理 | active | src/main/java/com/uniseek/task/ |
| application | 投递/状态机/乐观锁/简历快照 | active | src/main/java/com/uniseek/application/ |
| notification | 站内信系统 | active | src/main/java/com/uniseek/notification/ |
| chat | 会话+消息+WebSocket实时推送 | active | src/main/java/com/uniseek/chat/ |
| admin | 管理后台审核/统计/用户管理 | active | src/main/java/com/uniseek/admin/ |
| complaint | 投诉提交+处理 | active | src/main/java/com/uniseek/complaint/ |
| operation-log | AOP操作审计日志 | active | src/main/java/com/uniseek/operationlog/ |
| statistics | 定时统计任务 | active | src/main/java/com/uniseek/statistics/ |
| upload | 文件上传 | active | src/main/java/com/uniseek/upload/ |

## Open assumptions (announced defaults)
| assumption | adopted default | rationale | reversible? |
|---|---|---|---|
| 文件上传存储 | 本地文件系统存储（upload/目录），URL路径映射 | 避免引入OSS依赖，开发阶段够用 | 是，可替换为OSS |
| WebSocket实现 | Spring WebSocket (原生实现, 不使用STOMP) | 轻量级，文档中未要求STOMP | 是，可升级 |
| MyBatis vs MyBatis-Plus | MyBatis-Plus 3.3.0 | 减少样板代码，提升开发效率 | 是，纯MyBatis也兼容 |
| 分页方案 | MyBatis-Plus PaginationInterceptor | 与MyBatis-Plus配套使用 | 是 |
| JWT密钥 | 固定密钥字符串存储于application.yml | 开发环境简化，生产环境应注入环境变量 | 是，生产需替换 |
| Hutool版本 | 5.8.26 | 需求文档明确指定 | 否，需求已锁定 |
| 定时任务框架 | Spring @Scheduled | 需求文档指定Spring Schedule | 否，需求已锁定 |
| 数据库连接池 | HikariCP (Spring Boot默认) | 高性能，零配置 | 是 |

## Findings (cited - path:lines)
- pom.xml当前为空骨架，无任何依赖 (uniseek_java/pom.xml:1-17)
- SQL Schema V1.1包含14张业务表及完整索引/外键/种子数据 (uniseek_schema.sql:1-784+)
- API文档包含54个接口，覆盖认证/用户/简历/分类/地区/职位/投递/企业/管理/投诉/消息/聊天/上传 (api.md:1-2991)
- 需求规格说明书 V1.2 包含完整状态机定义、认证流程、数据字典 (兼职招聘平台需求规格说明书.md)
- 项目工作路径必须限制在 uniseek_java/ 下 (AGENTS.md:4)

## Decisions (with rationale)
1. **包结构按功能模块分包**而非按层级分包：com.uniseek.{module}.controller/service/dao/entity — 高内聚低耦合，方便未来微服务拆分
2. **实体/DTO分离**：entity映射数据库，DTO用于请求/响应，VO用于视图展示 — 避免API暴露内部字段
3. **状态机校验使用枚举+Map预定义**：ApplicationStatusMachine 枚举定义所有合法流转路径，运行时校验，防御性编程
4. **乐观锁通过MyBatis-Plus @Version注解实现**：自动在更新时校验version字段
5. **简历快照使用Jackson ObjectMapper**：投递时将Resume对象序列化为JSON字符串存入resume_snapshot字段
6. **操作审计日志通过Spring AOP @OperationLog注解实现**：切面编程，业务代码无侵入
7. **聊天未读计数通过SQL COUNT查询**：不维护冗余计数器，避免并发不一致
8. **注册需传入 role**（用户确认）：遵照 API 文档，注册时 role 为必填参数（0求职者/1企业HR），需求文档 UC-AUTH-01 的字段列表已过时
9. **支持热门排序**（用户确认）：职位列表 sortBy 增加 popular 选项，按 task_application 投递计数降序排列，需 LEFT JOIN 子查询
10. **新增 audit_time 字段**（用户确认）：task 表增加 audit_time DATETIME 字段记录审核通过时间，用于精确统计每日通过审核上架的职位数
11. **简历 realName 通过 JOIN 获取**（用户确认）：ResumeService 查询时 LEFT JOIN real_name_auth 获取 realName，resume 表不冗余存储
12. **逃逸工作路径约束**（用户要求）：如需修改 uniseek_java/ 之外的文件，必须先通过 question 工具请示用户

## Scope IN
- 全部14张Entity/Mapper/Service/Controller
- 54个REST API接口
- JWT认证拦截器
- MD5+随机盐密码加密
- 简历快照机制
- 投递状态机（含严格流转规则）
- 乐观锁并发控制（名额扣减）
- 聊天WebSocket实时推送
- 定时任务（过期职位+日报统计）
- AOP操作审计日志
- 文件上传（本地存储）
- 统一异常处理与全局响应格式
- CORS跨域配置
- 权限矩阵校验（基于角色注解或拦截器）

## Scope OUT (Must NOT have)
- 不引入Redis/缓存层
- 不实现第三方短信/邮件服务
- 不做单元测试（仅做手动接口级验证，因需求文档未要求）
- 不做Docker容器化
- 不做Swagger/API文档自动生成
- 不实现前端页面（纯后端）
- 不做数据库分库分表
- 不实现消息队列（RabbitMQ/Kafka）
- 不实现第三方OSS存储
- **逃逸工作路径约束**：严禁自动修改 `uniseek_java/` 之外的文件。如需修改根目录的 `uniseek_schema.sql`、`uniseek_vue/`、`uniseek_arkts/` 等，必须先通过 `question` 工具请示用户并获得明确批准

## Open questions
无 — 需求规格说明书和API文档已完全覆盖所有细节，无歧义。

## Approval gate
status: awaiting-approval
pending-action: 用户审批通过后，编写 .omo/plans/uniseek-backend-full.md 的完整Todos
