# uniseek-backend-full - Work Plan

## TL;DR (For humans)

**What you'll get:** 一个完整的 Spring Boot 兼职招聘平台后端系统，包含 54 个 REST API、14 张数据库表的 CRUD、JWT 鉴权、MD5+盐密码加密、职位投递状态机、乐观锁并发控制、聊天 WebSocket 实时推送、定时统计任务、操作审计日志等功能模块。

**Why this approach:** 按功能模块垂直分包（auth/user/task/application/chat 等），每个模块独立 controller→service→dao→entity，高内聚低耦合，方便未来微服务拆分。状态机使用枚举预定义所有合法流转路径，防御性编程防止非法状态跳转。

**What it will NOT do:** 不引入 Redis/缓存层、不集成第三方短信/邮件服务、不做单元测试、不做 Docker 容器化、不生成 Swagger 文档、不实现前端页面。不自动修改 uniseek_java/ 之外的文件（修改 schema 需请示用户）。

**Effort:** XL (12个Wave，约60+个Java文件)
**Risk:** Medium - 投递状态机规则复杂，乐观锁并发场景需要精细处理
**Decisions to sanity-check:** 包结构按模块分包、本地文件存储方案、WebSocket纯原生实现、状态机校验策略

Your next move: 审批通过后执行 `/start-work` 开始实施。

---

## Scope
### Must have
- 完整的14张数据库表 Entity/Mapper (MyBatis-Plus)
- 54个REST API接口，覆盖所有需求模块
- JWT鉴权拦截器 + 角色权限矩阵
- MD5+随机盐密码加密存储与校验
- 简历快照机制（投递时冻结简历内容）
- 投递状态机（6个状态间的严格流转规则）
- 乐观锁并发控制（职位名额扣减）
- 聊天 WebSocket 实时推送
- 定时任务（过期职位自动标记 + 日报统计）
- AOP 操作审计日志
- 文件上传（本地存储）
- 统一响应格式 + 全局异常处理 + CORS

### Must NOT have (guardrails, anti-slop, scope boundaries)
- 不引入 Redis 或其他缓存
- 不实现第三方短信/邮件发送
- 不编写单元测试（仅做接口级验证）
- 不引入 Docker/Swagger/消息队列
- 不修改任何 Vue/ArkTS 前端代码
- 数据库 Schema 变更（如新增 audit_time 字段）需先通过 question 工具请示用户，获批后方可执行
- 每个文件不超过 300 行，service 层复杂逻辑拆分为内部方法
- **严禁逃逸工作路径**：如需修改 `uniseek_java/` 目录之外的文件（如根目录的 `uniseek_schema.sql`、`uniseek_vue/`、`uniseek_arkts/`），必须先通过 `question` 工具调用向用户请示，获得明确批准后方可执行

## Verification strategy
- Test decision: 人工接口验证（使用 curl/HTTP Client 测试每个API的 happy path 和异常场景）
- Evidence: .omo/evidence/ 目录下保存每个模块的验证截图或日志

## Execution strategy
### Parallel execution waves
- Wave 1-3: 基础架构串行 (pom.xml → common → auth)
- Wave 4-5: 可并行 (category+region, enterprise)
- Wave 6-8: 核心业务串行 (task → application → notification)
- Wave 9-11: 可并行 (chat, complaint+operationlog, admin)
- Wave 12: 收尾任务 (statistics + 定时任务)
- Wave 13: 最终验证

## Todos

- [x] 1. Wave 1.1 - 项目骨架与 POM 依赖
  What to do / Must NOT do: 重构现有 pom.xml，移除 mybatis-spring-boot-starter 2.1.1 和 pagehelper-spring-boot-starter 1.2.13，替换为 mybatis-plus-boot-starter 3.3.0（自带分页 PaginationInterceptor，不再需要 PageHelper）。保留已有依赖：spring-boot-starter-web、spring-boot-starter-websocket、mysql-connector-java 8.0.19、jjwt 0.9.1、hutool-all 5.8.26、lombok。新增依赖：spring-boot-starter-aop（用于@OperationLog切面）。创建 UniSeekApplication.java 启动类。创建 application.yml 配置（MySQL连接、JWT密钥secret、文件上传路径、服务器端口8080）。创建 MyBatis-Plus 分页配置类 MyBatisPlusConfig.java（@Bean PaginationInterceptor）。清理 application.properties 中的 PageHelper 配置。必须使用 JDK 8 编译级别。
  Parallelization: Wave 1 | Blocked by: 无 | Blocks: 2
  References: uniseek_java/pom.xml:1-17
  Acceptance criteria: `mvn compile` 通过，无依赖缺失
  QA scenarios: 执行 mvn compile，观察 BUILD SUCCESS
  Commit: Y | build(maven): 初始化Spring Boot项目骨架与全部依赖

- [x] 2. Wave 1.2 - 公共基础模块 (common)
  What to do / Must NOT do: 创建以下文件：
  - ApiResult.java: 统一响应类 {code, message, data}，静态工厂方法 success()/error()
  - PageResult.java: 分页响应类 {records, total, page, pageSize, totalPages}
  - BusinessException.java: 运行时异常，含 code 和 message
  - UnauthorizedException.java: 401 异常
  - GlobalExceptionHandler.java: @RestControllerAdvice，处理 BusinessException → 400, UnauthorizedException → 401, MethodArgumentNotValidException → 400, Exception → 500
  - JwtUtil.java: 生成Token/解析Token/验证Token，HMAC-SHA256签名
  - PasswordUtil.java: generateSalt() / encryptPassword(password, salt) / verify()，MD5+随机盐
  - JwtAuthInterceptor.java: extends HandlerInterceptorAdapter，从Authorization头提取Token，解析userId/role存入ThreadLocal，白名单跳过（/api/auth/register, /api/auth/login, /api/region/**）
  - WebMvcConfig.java: implements WebMvcConfigurer，注册拦截器，配置CORS允许所有来源（开发环境）
  - ThreadLocal 工具类 UserContext.java: get/set/clear 当前用户ID和角色
  MyBatis-Plus 3.3.0 分页配置 MyBatisPlusConfig.java: @Bean PaginationInterceptor
  Must NOT: 不要引入任何业务逻辑
  Parallelization: Wave 1 | Blocked by: 1 | Blocks: 3
  References: api.md:12-76 (通用约定)
  Acceptance criteria: Spring Boot 启动无异常，ApiResult 序列化正确
  QA scenarios: POSTMAN 测试 GET /api/auth/current-user 返回401（无Token时）
  Commit: Y | feat(common): 实现公共基础模块（统一响应/异常/工具/鉴权拦截器）

- [x] 3. Wave 2 - 认证模块 (Auth)
  What to do / Must NOT do: 创建 auth 包下全部文件：
  - entity/User.java: @TableName("user")，全部字段映射，@TableId
  - entity/RealNameAuth.java: @TableName("real_name_auth")
  - dao/UserMapper.java: extends BaseMapper<User>
  - dao/RealNameAuthMapper.java: extends BaseMapper<RealNameAuth>
  - dto/RegisterRequest.java: phone, email, password, confirmPassword, nickname, role（必填：0求职者/1企业HR，含@NotBlank等校验注解）
  - dto/LoginRequest.java: phone, password
  - dto/RealNameAuthRequest.java: realName, idCard
  - dto/ChangePasswordRequest.java: oldPassword, newPassword, confirmPassword
  - dto/UserVO.java: id, phone(脱敏), email(脱敏), nickname, avatar, role, status, creditScore, lastLoginTime, createTime
  - dto/RealNameAuthVO.java: realName, idCard(脱敏), authTime
  - service/AuthService.java: 接口
  - service/impl/AuthServiceImpl.java: 实现
    注册：校验手机号格式(11位1开头)、邮箱格式、手机号唯一性、邮箱唯一性、密码长度6-20位、两次密码一致 → 生成随机盐 → MD5(password+salt) → 插入User → 生成JWT返回
    登录：phone查询 → 校验状态 → MD5(password+salt)比对 → 更新last_login_time → 生成JWT返回
    实名认证：Hutool IdcardUtil校验格式+校验码+年龄≥16 → 写入real_name_auth表
  - controller/AuthController.java: 7个接口
  - 手机号脱敏：138****8000；邮箱脱敏：zha***@example.com
  Must NOT: 不实现短信验证码，不引入第三方认证服务。密码不得明文存储。
  Parallelization: Wave 2 | Blocked by: 2 | Blocks: 4,5,6
  References: 需求文档3.1/7.1/7.2/7.3, api.md:78-387
  Acceptance criteria: 注册→登录→获取当前用户→实名认证 完整流程通过
  QA scenarios: 注册(手机号已存在→409)、登录(密码错误→400)、实名认证(身份证格式错误→400)
  Commit: Y | feat(auth): 实现认证模块（注册/登录/实名认证/JWT）

- [x] 4. Wave 3.1 - 用户模块 (User)
  What to do / Must NOT do: 创建 user 包：
  - controller/UserController.java: PUT /api/user/profile（更新昵称、头像）
  - service/UserService.java + impl
  使用 MyBatis-Plus 的 UpdateWrapper 更新。
  Must NOT: 不实现修改手机号/邮箱功能
  Parallelization: Wave 3 | Blocked by: 3 | Blocks: 7
  References: api.md:389-428
  Acceptance criteria: PUT /api/user/profile 更新成功
  QA scenarios: 更新昵称→200, 不传参数→200(无变更)
  Commit: Y | feat(user): 实现用户资料更新接口

- [x] 5. Wave 3.2 - 简历模块 (Resume)
  What to do / Must NOT do: 创建 resume 包：
  - entity/Resume.java: @TableName("resume")
  - dao/ResumeMapper.java: extends BaseMapper<Resume>
  - dto/ResumeRequest.java: realName, gender, birthDate, education, school, skills, experience, attachmentUrl
  - service/ResumeService.java + impl: 
    getUserResume(): 查询 resume 表 LEFT JOIN real_name_auth 获取 realName（不存储在resume表）
    saveOrUpdateResume(): 更新简历信息。若请求体包含 realName 字段，服务端忽略该字段（实名信息以 real_name_auth 表为准，如需修改需重新实名认证）。skills 字段存储为 JSON 数组字符串。
  - controller/ResumeController.java: GET /api/resume, PUT /api/resume, POST /api/resume/upload-attachment
  Resume 与 User 一对一关系，通过 user_id 唯一约束。
  POST /api/resume/upload-attachment 接收 multipart/file，保存到本地 upload/resumes/ 目录，返回URL。
  Must NOT: 简历中的 realName/idCard 从 real_name_auth 获取，不存储在 resume 表
  Parallelization: Wave 3 | Blocked by: 3 | Blocks: 7
  References: api.md:430-558
  Acceptance criteria: GET/PUT/POST 三个接口均正常工作
  QA scenarios: 未创建简历时返回空对象、更新简历后字段正确
  Commit: Y | feat(resume): 实现在线简历CRUD及附件上传

- [x] 6. Wave 4.1 - 职位分类模块 (Category)
  What to do / Must NOT do: 创建 category 包：
  - entity/Category.java: @TableName("category")
  - dao/CategoryMapper.java
  - dto/CategoryVO.java: id, parentId, name, sortOrder, children(List<CategoryVO>)
  - service/CategoryService.java + impl: getTree() 递归组装树形结构
  - controller/CategoryController.java: GET /api/categories
  顶级分类 parent_id = NULL，子级分类 parent_id 指向父级。Service 层查询所有分类，在Java内存中组装树。
  Must NOT: 不使用数据库递归查询，使用Java内存组装
  Parallelization: Wave 4 | Blocked by: 2 | Blocks: 7
  References: api.md:561-613, uniseek_schema.sql:357-396
  Acceptance criteria: GET /api/categories 返回完整树形结构
  QA scenarios: 返回数据包含15个顶级分类及其子分类
  Commit: Y | feat(category): 实现职位分类树形结构接口

- [x] 7. Wave 4.2 - 地区数据模块 (Region)
  What to do / Must NOT do: 创建 region 包：
  - entity/Region.java: @TableName("region")
  - dao/RegionMapper.java
  - dto/RegionVO.java: id, name, level, children
  - service/RegionService.java + impl: getProvinces(), getChildren(parentId), getTree()
  - controller/RegionController.java: GET /api/region/provinces, GET /api/region/children/{parentId}, GET /api/region/tree
  Region表数据由SQL种子数据导入，3432条记录。Tree接口按 level=1→level=2→level=3 三层组装。
  Must NOT: 地区接口无需鉴权（白名单）
  Parallelization: Wave 4 | Blocked by: 2 | Blocks: 7
  References: api.md:614-755, uniseek_schema.sql:398-784+
  Acceptance criteria: 三个地区接口均返回正确数据
  QA scenarios: provinces返回34个省、tree返回完整三级结构
  Commit: Y | feat(region): 实现行政区划三级树形数据接口

- [x] 8. Wave 5 - 企业模块 (Enterprise)
  What to do / Must NOT do: 创建 enterprise 包：
  - entity/Enterprise.java: @TableName("enterprise")
  - dao/EnterpriseMapper.java
  - dto/EnterpriseRequest.java: companyName, creditCode, licenseImgUrl, industry, description
  - service/EnterpriseService.java + impl: submit()创建/更新/查询，audit_status管理
  - controller/EnterpriseController.java: POST /api/enterprise, GET /api/enterprise/my, PUT /api/enterprise
  提交企业资质前检查用户是否已实名认证（查询real_name_auth.status=1），未实名则提示先认证。
  creditCode唯一性校验，companyName唯一性校验。
  Must NOT: 企业审核操作在Admin模块，此处仅提交/更新
  Parallelization: Wave 5 | Blocked by: 3 | Blocks: 9
  References: api.md:1426-1551, 需求文档UC-EMPLOYER-01
  Acceptance criteria: 提交企业资质→查询→更新 完整流程
  QA scenarios: 未实名提交→提示实名、信用代码重复→409
  Commit: Y | feat(enterprise): 实现企业资质认证提交与管理

- [x] 9. Wave 6 - 职位模块 (Task)
  What to do / Must NOT do: 创建 task 包：
  - entity/Task.java: @TableName("task"), @Version 乐观锁注解
  - dao/TaskMapper.java: extends BaseMapper<Task> + 自定义XML查询（多表关联搜索）
  - dto/TaskRequest.java: categoryId, regionId, title, description, salaryMin, salaryMax, salaryUnit, jobType, totalQuota, address, longitude, latitude, deadline
  - dto/TaskVO.java: 含 enterpriseName, categoryName, regionName 等关联字段
  - dto/TaskSearchRequest.java: keyword, categoryId, regionId, jobType, salaryMin, salaryMax, salaryUnit, address, sortBy(create_time/salary_max/popular), sortOrder, page, pageSize
  - TaskMapper.xml 中添加热门排序支持：LEFT JOIN (SELECT task_id, COUNT(*) as app_count FROM task_application GROUP BY task_id) ON task.id = task_id，sortBy=popular 时按 app_count DESC 排序
  - service/TaskService.java + impl: 
    - 发布职位：校验企业已认证 → 创建Task(status=0, remaining_quota=total_quota)
    - 搜索职位：多条件组合分页查询（LEFT JOIN enterprise/category/region）
    - 职位详情：带 hasApplied 字段（当前用户是否已投递）
    - 更新职位：仅限待审核/已下架状态
  - controller/TaskController.java: GET /api/tasks, GET /api/tasks/{id}, POST /api/tasks, PUT /api/tasks/{id}, PUT /api/tasks/{id}/status, GET /api/enterprise/tasks
  TaskMapper.xml 中写复杂关联查询SQL。修改职位状态接口根据角色（HR/Admin）执行不同逻辑。
  Must NOT: 投递逻辑在application模块，不要混入
  Parallelization: Wave 6 | Blocked by: 6,7,8 | Blocks: 10
  References: api.md:756-1079, 需求文档3.3 UC-EMPLOYER-02
  Acceptance criteria: 发布职位→搜索→详情→更新→下架 完整流程
  QA scenarios: 企业未认证时发布→403、搜索按分类/薪资筛选正确
  Commit: Y | feat(task): 实现职位发布/搜索/详情/状态管理

- [x] 10. Wave 7 - 投递模块 (Application) - 核心复杂逻辑
  What to do / Must NOT do: 创建 application 包：
  - entity/TaskApplication.java: @TableName("task_application"), @Version
  - dao/TaskApplicationMapper.java: extends BaseMapper<TaskApplication>
  - service/ApplicationStatusMachine.java: 定义状态流转规则
    使用枚举+Map定义：
    0(已投递)→[1(待面试), 2(待定), 4(已淘汰)]
    1(待面试)→[2(待定), 3(已录用), 4(已淘汰)]
    2(待定)→[1(待面试), 3(已录用), 4(已淘汰)]
    3(已录用)→[5(已完成)]
    4(已淘汰)→[] (终态)
    5(已完成)→[] (终态)
    非法流转抛BusinessException
  - service/ApplicationService.java + impl:
    投递：校验实名→校验简历存在→校验职位可投递(未过期/招聘中/未满员)→校验不重复→生成简历快照→插入TaskApplication→创建ChatSession→创建Notification给HR
    简历快照：查询Resume对象→Jackson序列化为JSON字符串→存入resume_snapshot
    修改状态：校验权限(HR属于该企业)→校验状态机规则→录用时扣减名额(乐观锁)→更新TaskApplication→名额归零则Task状态变更为已满员→创建Notification给求职者(面试邀请type=1/录用通知type=2/淘汰通知type=3)
    结算确认：校验状态=3→更新为5
  - controller/ApplicationController.java: POST, GET /my, GET /{id}, GET /tasks/{taskId}/applications, PUT /{id}/status, PUT /{id}/complete
  - dto/ApplyRequest.java: taskId
  - dto/UpdateStatusRequest.java: status, interviewTime, interviewLocation, rejectReason, hrNote
  - dto/CompleteRequest.java: settlementAmount, hrNote
  乐观锁：录用时先查Task的version，UPDATE task SET remaining_quota-1, version+1 WHERE id=? AND version=oldVersion，影响行数为0则重试或报并发冲突
  Must NOT: 不跳过状态机规则直接修改状态
  Parallelization: Wave 7 | Blocked by: 5,9 | Blocks: 11,12
  References: api.md:1081-1425, 需求文档第6章状态机说明
  Acceptance criteria: 投递→查看→修改状态(面试/录用/淘汰)→结算 完整流程，乐观锁冲突正确处理
  QA scenarios: 重复投递→409、跳过状态→400、名额耗尽→400
  Commit: Y | feat(application): 实现投递/状态机/乐观锁/简历快照

- [x] 11. Wave 8 - 消息通知模块 (Notification)
  What to do / Must NOT do: 创建 notification 包：
  - entity/Notification.java: @TableName("notification")
  - dao/NotificationMapper.java
  - service/NotificationService.java + impl:
    sendNotification(receiverId, senderId, title, content, type, bizId) 创建消息
    getUserNotifications(receiverId, type, isRead, page) 分页查询
    getUnreadCount(receiverId) 按type分组统计未读数
    markAsRead(id) / markAllAsRead(receiverId)
  - controller/NotificationController.java: GET /api/messages, GET /api/messages/unread-count, PUT /api/messages/{id}/read, PUT /api/messages/read-all
  - 未读数接口 GET /api/messages/unread-count 响应 DTO 字段名：
    { totalUnread（总数）, systemUnread（系统通知type=0）, interviewUnread（面试邀请type=1）, offerUnread（录用通知type=2）, rejectUnread（淘汰通知type=3） }
  - 分组统计 SQL: SELECT type, COUNT(*) FROM notification WHERE receiver_id=? AND is_read=0 GROUP BY type
  ApplicationService 和 AdminService 在关键操作后调用 NotificationService 创建消息。
  Must NOT: 不实现WebSocket推送通知（Chat模块的WebSocket只负责聊天消息）
  Parallelization: Wave 8 | Blocked by: 3 | Blocks: 后续均可并行依赖
  References: api.md:2006-2137, 需求文档3.5
  Acceptance criteria: 消息列表/未读数/标记已读/全部标记已读
  QA scenarios: 发送消息后查询到新消息、标记已读后未读数减少
  Commit: Y | feat(notification): 实现站内消息通知系统

- [x] 12. Wave 9.1 - 聊天模块 - 数据层 (Chat)
  What to do / Must NOT do: 创建 chat 包：
  - entity/ChatSession.java: @TableName("chat_session")
  - entity/ChatMessage.java: @TableName("chat_message")
  - dao/ChatSessionMapper.java
  - dao/ChatMessageMapper.java
  - dto/ChatSessionVO.java: applicationId, taskId, taskTitle, taskStatus, applicationStatus, counterpartId, counterpartName, counterpartAvatar, lastMessage, lastMessageTime, unreadCount
  - dto/ChatMessageVO.java: id, senderId, senderName, senderAvatar, messageType, content, isRead, sendTime
  - dto/SendMessageRequest.java: messageType, content
  - service/ChatService.java + impl:
    getSessions(userId, role, page): HR查本企业相关会话，求职者查自己的会话。LEFT JOIN chat_session + task_application + task 查询。未读数通过 SELECT COUNT(*) FROM chat_message WHERE session_id=? AND is_read=0 AND sender_id!=currentUserId 计算。
    getMessages(sessionId, userId, role, beforeId, pageSize): 权限校验后分页查询，自动标记对方消息已读
    sendMessage(sessionId, userId, role, request): 权限校验→插入ChatMessage→更新ChatSession的last_message/last_message_time
    getSessionDetail(applicationId, userId, role): 查询会话详情
    markSessionRead(sessionId, userId): UPDATE chat_message SET is_read=1 WHERE session_id=? AND sender_id!=? AND is_read=0
  创建聊天会话的方法 createChatSession(applicationId, employerId, seekerId) 在ApplicationService投递成功后调用
  Must NOT: WebSocket在下一个todo实现，此处只做HTTP API
  Parallelization: Wave 9 | Blocked by: 10 | Blocks: 14
  References: api.md:2138-2556, 需求文档3.5.4
  Acceptance criteria: HTTP聊天接口全部正常工作
  QA scenarios: 发送消息→查询消息列表→标记已读→未读数变为0
  Commit: Y | feat(chat): 实现聊天HTTP API（会话/消息/已读）

- [x] 13. Wave 9.2 - 聊天WebSocket实时推送
  What to do / Must NOT do: 创建 chat/websocket/ChatWebSocketHandler.java：
  - extends TextWebSocketHandler
  - 连接时从URL参数提取Token并鉴权
  - 用户连接存入 ConcurrentHashMap<Long, Set<WebSocketSession>> 连接池
  - 处理 SEND_MESSAGE 事件：权限校验→存库→推送给接收方 NEW_MESSAGE 事件→推送给发送方 SEND_ACK
  - 处理 READ_RECEIPT 事件：标记已读→推送给发送方 MESSAGE_READ 事件
  - 处理心跳：Ping/Pong 帧，90秒无心跳断开
  - 断线重连支持：连接池管理，重连后重新绑定
  创建 WebSocketConfig.java: implements WebSocketConfigurer，注册 ChatWebSocketHandler 到 /ws/chat
  消息格式：统一的JSON帧 {type, data, timestamp}
  ⚠️ 安全备注：URL参数传Token是开发阶段的简化方案（Token会在Web服务器日志/浏览器历史中留下记录）。生产环境建议改用STOMP协议或wss+自定义Header鉴权。当前开发阶段此方案可接受。
  推送事件：NEW_MESSAGE, MESSAGE_READ, SESSION_UPDATE, NOTIFICATION, ERROR
  Must NOT: 不引入STOMP协议，不使用第三方WebSocket库
  Parallelization: Wave 9 | Blocked by: 12 | Blocks: 14
  References: api.md:2433-2555 (12.6 WebSocket实时推送)
  Acceptance criteria: WebSocket连接建立→发送消息→接收方实时收到
  QA scenarios: 连接时无Token→断开、发送空消息→ERROR事件
  Commit: Y | feat(chat): 实现WebSocket实时聊天推送

- [x] 14. Wave 10.1 - 投诉模块 (Complaint)
  What to do / Must NOT do: 创建 complaint 包：
  - entity/Complaint.java: @TableName("complaint")
  - dao/ComplaintMapper.java
  - dto/ComplaintRequest.java: targetType, targetId, type, content
  - service/ComplaintService.java + impl: submit() / getList() / getDetail() / handle()
  - controller/ComplaintController.java: POST /api/complaints
  管理员操作在Admin模块。
  Must NOT: 不实现投诉的自动处理逻辑
  Parallelization: Wave 10 | Blocked by: 3 | Blocks: 15
  References: api.md:2620-2821, 需求文档UC-ADMIN-04
  Acceptance criteria: 用户提交投诉成功
  QA scenarios: 投诉内容为空→400、提交成功后查询到
  Commit: Y | feat(complaint): 实现用户投诉提交功能

- [x] 15. Wave 10.2 - 操作审计日志 (OperationLog AOP)
  What to do / Must NOT do: 创建 operationlog 包：
  - annotation/OperationLog.java: @Target(METHOD), @Retention(RUNTIME)，含 operationType, targetType 属性
  - entity/OperationLog.java: @TableName("operation_log")
  - dao/OperationLogMapper.java
  - aspect/OperationLogAspect.java: @Around("@annotation(operationLog)")，获取方法参数/返回值/当前用户/IP，构建detail JSON，异步插入数据库
  在关键Controller方法上添加 @OperationLog 注解：
  AuthController.register → @OperationLog(type="REGISTER", target="USER")
  AuthController.login → @OperationLog(type="LOGIN", target="USER")
  ApplicationController.apply → @OperationLog(type="APPLY", target="APPLICATION")
  ...以及其他关键操作
  IP地址从 HttpServletRequest.getRemoteAddr() 获取。
  Must NOT: 注解不在非关键操作上使用，避免日志表数据膨胀
  Parallelization: Wave 10 | Blocked by: 2 | Blocks: 15
  References: 需求文档3.7, api.md:2001-2005
  Acceptance criteria: 执行关键操作后 operation_log 表有对应记录
  QA scenarios: 注册后查询日志表有 REGISTER 记录
  Commit: Y | feat(operationlog): 实现AOP操作审计日志

- [x] 16. Wave 11 - 管理后台模块 (Admin)
  What to do / Must NOT do: 创建 admin 包：
  - 6个Controller，角色限制均为管理员(role=9)：
    AdminEnterpriseController.java: GET /api/admin/enterprises, PUT /api/admin/enterprises/{id}/audit
    AdminTaskController.java: GET /api/admin/tasks/pending, PUT /api/admin/tasks/{id}/audit
    AdminUserController.java: GET /api/admin/users, PUT /api/admin/users/{id}/status
    AdminStatisticsController.java: GET /api/admin/statistics
    AdminOperationLogController.java: GET /api/admin/operation-logs
    AdminComplaintController.java: GET /api/admin/complaints, GET /api/admin/complaints/{id}, PUT /api/admin/complaints/{id}/handle
  - service/AdminService.java + impl: auditEnterprise, auditTask, listUsers, toggleUserStatus, getStatistics, listOperationLogs, listComplaints, getComplaintDetail, handleComplaint
  企业审核：更新enterprise.audit_status，审核通过时发送系统通知给HR
  职位审核：审核通过→task.status=1（招聘中），同时记录 audit_time=NOW()。驳回→task.status保持0（待审核），通过NotificationService发送驳回原因通知给HR。
  用户管理：更新user.status = 0/1
  操作日志查询：多条件组合筛选 + 分页
  投诉处理：更新complaint.status/handler_id/handle_result，处理完成后调用NotificationService发送处理结果通知给投诉人（type=0系统通知）
  Must NOT: 管理接口不做数据权限隔离（管理员可查看全部）
  Parallelization: Wave 11 | Blocked by: 5,8,9,14,15 | Blocks: 17
  References: api.md:1553-1991, 需求文档3.4
  Acceptance criteria: 管理员审核企业/职位、管理用户、查看统计和日志、处理投诉全部正常
  QA scenarios: 非管理员调用→403、审核企业通过/驳回→状态更新
  Commit: Y | feat(admin): 实现管理后台全部功能

- [x] 17. Wave 12.1 - 定时统计任务 (DailyStatistics)
  What to do / Must NOT do: 创建 statistics 包：
  - entity/DailyStatistics.java: @TableName("daily_statistics")
  - dao/DailyStatisticsMapper.java
  - service/DailyStatisticsService.java: @Scheduled(cron="0 0 2 * * ?") 每日凌晨2点执行
    统计口径说明：
    - 新增职位数：基于 task.audit_time 字段统计昨日通过审核的职位（status=1）
    - 新增认证企业数：基于 enterprise.audit_time 字段（需在 Todo 20 中同步为 enterprise 表增加该字段），统计昨日 audit_status 变更为 1 的记录
    - 新增面试数/入职数：基于 task_application.update_time + status 组合查询。注意：如果一条记录在同一天内多次变更状态，此方案可能产生近似值。精确方案需增加 status_change_time 字段，当前阶段可接受此精度
    - task 表新增了 audit_time DATETIME DEFAULT NULL 字段，用于记录职位审核通过时间。需要同步修改 uniseek_schema.sql 和 Task.java 实体
    统计逻辑：
    - 新增用户数：SELECT COUNT(*) FROM user WHERE DATE(create_time) = CURDATE() - 1
    - 新增认证企业数：SELECT COUNT(*) FROM enterprise WHERE DATE(update_time) = CURDATE() - 1 AND audit_status=1
    - 新增职位数：SELECT COUNT(*) FROM task WHERE DATE(audit_time) = CURDATE() - 1 AND status = 1（基于新增的 audit_time 字段统计通过审核的职位）
    - 新增简历数：同上
    - 新增投递数：SELECT COUNT(*) FROM task_application WHERE DATE(create_time) = CURDATE() - 1
    - 新增面试数：SELECT COUNT(*) FROM task_application WHERE DATE(update_time) = CURDATE() - 1 AND status=1
    - 新增入职数：SELECT COUNT(*) FROM task_application WHERE DATE(update_time) = CURDATE() - 1 AND status=3
    使用 REPLACE INTO 或先查后插避免重复。
  Must NOT: 定时任务不阻塞主业务，使用异步执行
  Parallelization: Wave 12 | Blocked by: 全部 | Blocks: 18
  References: 需求文档3.6, uniseek_schema.sql:287-304
  Acceptance criteria: 定时任务执行后daily_statistics表有数据
  QA scenarios: 手动触发定时任务，查看统计结果正确
  Commit: Y | feat(statistics): 实现每日运营数据统计定时任务

- [x] 18. Wave 12.2 - 过期职位定时任务
  What to do / Must NOT do: 在TaskService或专门ScheduledService中：
  @Scheduled(cron="0 0 * * * ?") 每小时执行一次
  UPDATE task SET status=3 WHERE status=1 AND deadline IS NOT NULL AND deadline < NOW()
  Must NOT: 不逐个遍历，使用批量更新SQL
  Parallelization: Wave 12 | Blocked by: 9 | Blocks: 18
  References: 需求文档4.3, uniseek_schema.sql:156-188
  Acceptance criteria: 过期职位自动变更为"已过期"状态
  QA scenarios: 设置过去deadline的职位，触发定时任务后status变为3
  Commit: Y | feat(task): 实现过期职位自动标记定时任务

- [x] 19. Wave 13 - 文件上传模块 (Upload)
  What to do / Must NOT do: 创建 upload 包：
  - service/UploadService.java: uploadImage(MultipartFile) / uploadFile(MultipartFile)
    文件类型校验（图片：jpg/png/webp，文件：pdf/doc/docx），大小校验（图片5MB，文件10MB）
    文件名生成：UUID + 原始扩展名
    存储路径：upload/images/YYYYMMDD/ 或 upload/files/YYYYMMDD/
    返回可访问URL：http://host:port/api/files/{relativePath}
  - controller/UploadController.java: POST /api/upload/image, POST /api/upload/file
  配置静态资源映射：在WebMvcConfig中 addResourceHandlers 映射 /api/files/** → file:upload/
  Must NOT: 不引入OSS，不使用第三方存储
  Parallelization: Wave 13 | Blocked by: 2 | Blocks: 5,8（简历和企业需要上传功能）
  References: api.md:2557-2618
  Acceptance criteria: 上传图片/文件成功，返回可访问URL
  QA scenarios: 上传非图片类型→400、超过大小限制→400
  Commit: Y | feat(upload): 实现文件上传（图片/文档）本地存储

- [x] 20. Wave 0.5 - 同步修改数据库 Schema（新增 audit_time 字段）
  What to do / Must NOT do: ⚠️ 此操作涉及修改 uniseek_java/ 之外的根目录文件（uniseek_schema.sql），需先通过 question 工具请示用户批准。批准后在 task 表（第156-188行）的 deadline 字段之后新增 audit_time 字段：
  `audit_time` DATETIME DEFAULT NULL COMMENT '审核通过时间（职位状态变更为招聘中的时间）'
  同时修改 enterprise 表新增 audit_time 字段：
  `audit_time` DATETIME DEFAULT NULL COMMENT '企业认证通过时间（audit_status变更为1的时间）'
  修改 Task.java 实体类，增加 auditTime 字段（类型 LocalDateTime，@TableField("audit_time")）。
  修改 Enterprise.java 实体类，增加 auditTime 字段。
  Must NOT: 不修改其他表的结构。修改 uniseek_schema.sql 前必须先通过 question 工具请示用户。
  Parallelization: Wave 0.5 | Blocked by: 1 | Blocks: 2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19
  References: 需求文档3.6.2, uniseek_schema.sql:156-188
  Acceptance criteria: task 表新增 audit_time 字段，实体类有对应字段
  QA scenarios: 管理员审核通过职位后，audit_time 自动记录当前时间
  Commit: Y | feat(schema): task表新增audit_time审核时间字段

## Final verification wave
- [x] F1. 编译验证: mvn clean compile 无错误
- [x] F2. 启动验证: mvn spring-boot:run 启动无异常
- [x] F3. 核心流程E2E验证: 注册→登录→发布职位→审核→投递→处理投递→录用→聊天→结算 完整链路
- [x] F4. 异常场景验证: 重复投递、非法状态流转、乐观锁冲突、无权限访问、参数校验失败
- [x] F5. 定时任务验证: 手动触发统计任务和过期职位任务

## Commit strategy
采用 1 commit per todo 的粒度：`<type>(<scope>): <message>`
- 整个开发过程禁止自动 git commit，每个commit前均向用户展示变更内容
- 开发结束后，按模块逐个commit

## Success criteria
- Spring Boot 应用正常启动，无依赖缺失
- 全部54个API接口可调用
- 投递状态机严格遵循需求文档6.2状态流转图
- 乐观锁在并发场景下正确防止超录
- WebSocket 实时消息推送正常工作
- 定时任务正确执行
- 操作审计日志正确记录关键操作
