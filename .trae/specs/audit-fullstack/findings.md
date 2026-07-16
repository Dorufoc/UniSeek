# UniSeek 全栈代码审计报告

> **审计范围**：`uniseek_java/`（Spring Boot 1.8）+ `uniseek_vue/`（Vue 3 + TS）
> **审计时间**：2026-07-16
> **审计维度**：A. 安全漏洞 / B. 健壮性与 Bug / C. 架构与分层 / D. 性能与数据库
> **审计方法**：6 个子代理并行扫描 + 主代理亲自核验（self-review 作为交叉验证）
> **未审计**：`uniseek_arkts/`（按用户要求）、`dist/` 产物、构建脚本、`.md` / Mock 数据生成器

---

## 📊 总体概览

| 维度 | critical | major | minor | 小计 |
|------|---------|-------|-------|-----|
| A. 安全漏洞 | 3 | 4 | 1 | 8 |
| B. 健壮性与 Bug | 0 | 2 | 2 | 4 |
| C. 架构与分层 | 1 | 2 | 0 | 3 |
| D. 性能与数据库 | 0 | 1 | 3 | 4 |
| **合计** | **4** | **9** | **6** | **19** |

```mermaid
flowchart LR
    A[审计 19 条问题] --> B[critical: 4]
    A --> C[major: 9]
    A --> D[minor: 6]
    B --> B1[MD5 弱哈希]
    B --> B2[JWT 密钥硬编码]
    B --> B3[DB 密码硬编码]
    B --> B4[空重复类]
    C --> C1[CORS 通配]
    C --> C2[Token 在 localStorage]
    C --> C3[前端鉴权绕过]
    C --> C4[Mapper ${} 拼接]
    C --> C5[WS 重连无上限]
    C --> C6[调度无锁]
    C --> C7[Service 路径分散]
    C --> C8[Home.vue 490 行]
    C --> C9[聊天 content 字段返回]
    style B fill:#ffcdd2,color:#b71c1c
    style C fill:#fff3e0,color:#e65100
    style D fill:#e1f5fe,color:#01579b
    style B1 fill:#ffcdd2,color:#b71c1c
    style B2 fill:#ffcdd2,color:#b71c1c
    style B3 fill:#ffcdd2,color:#b71c1c
    style B4 fill:#ffcdd2,color:#b71c1c
```

---

## A. 安全漏洞（8 条）

### A-01 【critical】密码使用 MD5 弱哈希存储

**文件**：[PasswordUtil.java#L37-L40](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_java/src/main/java/com/uniseek/util/PasswordUtil.java#L37-L40)

**证据**：
```java
public static String encryptPassword(String password, String salt) {
    String input = password + salt;
    return DigestUtils.md5DigestAsHex(input.getBytes());
}
```

**问题**：MD5 是已知不安全的哈希算法，存在彩虹表碰撞与 GPU 爆破风险（即使加盐，单向 MD5 仍可在秒级破解）。一旦数据库泄露，所有用户密码将被批量还原。

**修复建议**：
- 替换为 BCrypt（Spring Security 内置）或 Argon2id
- BCrypt：`new BCryptPasswordEncoder().encode(rawPassword)` / `.matches(raw, encoded)`
- 迁移时保留旧字段新增 `password_v2` 列，双写逐步切换

---

### A-02 【critical】JWT 签名密钥硬编码在配置文件

**文件**：[application.yml#L29-L30](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_java/src/main/resources/application.yml#L29-L30)

**证据**：
```yaml
jwt:
  secret: UniSeek-JWT-Secret-Key-2026
```

**问题**：
1. 密钥随源码提交至仓库，任何贡献者/泄露者均可伪造任意用户的 Token
2. 密钥强度不足（仅 28 字节可打印字符，HS256 建议至少 32 字节随机）
3. 没有从环境变量 / 配置中心注入

**修复建议**：
- 通过环境变量 `JWT_SECRET` 注入：`jwt.secret: ${JWT_SECRET}`
- 使用 `Keys.secretKeyFor(SignatureAlgorithm.HS256)` 生成 32 字节强随机密钥
- 部署时由运维安全保管，禁止进入版本控制

---

### A-03 【critical】数据库 root/root 硬编码

**文件**：[application.yml#L6-L8](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_java/src/main/resources/application.yml#L6-L8)

**证据**：
```yaml
datasource:
    url: jdbc:mysql://localhost:3306/uniseek?...
    username: root
    password: root
```

**问题**：使用 MySQL 超级管理员账号 + 弱密码硬编码进源码，任何人获取仓库即可读写全部数据库。

**修复建议**：
- 创建专用应用账号 `uniseek_app`，仅授予 `uniseek` 库的 SELECT/INSERT/UPDATE/DELETE
- 密码通过环境变量注入：`password: ${DB_PASSWORD}`

---

### A-04 【major】CORS allowedOrigins 通配

**文件**：[WebMvcConfig.java#L42-L47](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_java/src/main/java/com/uniseek/config/WebMvcConfig.java#L42-L47)

**证据**：
```java
registry.addMapping("/**")
        .allowedOrigins("*")
        .allowedMethods("*")
        .allowedHeaders("*");
```

**问题**：`*` 通配允许任意域跨域访问所有接口，攻击者可在恶意网站中通过 fetch 携带用户 Cookie/Token 直接调用本站 API。CSRF 攻击面被无限放大。

**修复建议**：
- 列出可信前端域名：`allowedOrigins("https://uniseek.example.com", "http://localhost:5173")`
- 限制 Methods：`allowedMethods("GET", "POST", "PUT", "DELETE")`
- 限制 Headers：`allowedHeaders("Authorization", "Content-Type")`

---

### A-05 【major】Vue Token 存于 localStorage（XSS 风险）

**文件**：[user.ts#L6-L13](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_vue/src/stores/user.ts#L6-L13)

**证据**：
```ts
const token = ref(localStorage.getItem('uniseek_token') || '')
// ...
const setToken = (val: string) => {
  token.value = val
  localStorage.setItem('uniseek_token', val)
```

**问题**：localStorage 可被任意 XSS 攻击读取并外泄 Token。项目中已有 `v-html` 用法需进一步排查，即使当前无注入点，未来引入第三方依赖（如数据分析、客服 SDK）极易引入 XSS。

**修复建议**：
- 短期：在 `index.html` 设置 CSP `default-src 'self'; script-src 'self' 'nonce-xxx'`
- 中期：Token 改用 `HttpOnly + Secure + SameSite=Strict` 的 Cookie，由后端下发
- 当前项目可逐步切换：登录接口额外下发 Cookie，前端删除 localStorage 逻辑

---

### A-06 【major】路由守卫仅前端判断角色（可绕过）

**文件**：[router/index.ts#L174-L212](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_vue/src/router/index.ts#L174-L212)

**证据**：
```ts
const getUserRole = (): number => {
  const userStr = localStorage.getItem('uniseek_user')
  return userStr ? JSON.parse(userStr).role : -1
}
// ...
if (to.path.startsWith('/admin') && role < 9) {
  return { path: '/' }
}
```

**问题**：前端路由仅是 UX 体验，后端接口未做角色校验时，攻击者直接改 `localStorage.uniseek_user` 中 `role` 字段即可绕过。Vue 端是单文件可被修改，不构成任何安全屏障。

**修复建议**：
- 在 `JwtAuthInterceptor` 中增加 `requiresAdmin` 元数据校验：从 `claims.get("role")` 校验 `>= 9`，不通过直接 403
- 前端 meta 仅作 UI 优化，最终授权必须由后端校验

---

### A-07 【major】Mapper XML 使用 `${}` 字符串拼接

**文件**：[TaskMapper.xml#L152](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_java/src/main/resources/mapper/TaskMapper.xml#L152)

**证据**：
```xml
ORDER BY task.create_time ${orderDir}
```

**问题**：MyBatis 的 `${}` 是直接字符串拼接而非参数化绑定。虽然 `orderDir` 来自前端传入，但若未做白名单校验就传入 `; DROP TABLE...` 等恶意字符串，将构成 SQL 注入。

**修复建议**：
- 校验白名单：`if (!Set.of("ASC","DESC").contains(orderDir)) throw new BusinessException(...)`
- 或使用 `<choose>` + `<when>` 拆分：
  ```xml
  <choose>
    <when test="orderDir == 'ASC'">ORDER BY task.create_time ASC</when>
    <otherwise>ORDER BY task.create_time DESC</otherwise>
  </choose>
  ```

---

### A-08 【minor】文件上传仅校验扩展名未校验真实 MIME

**文件**：[UploadService.java#L72-L77](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_java/src/main/java/com/uniseek/upload/service/UploadService.java#L72-L77)

**证据**：
```java
String extension = getExtension(originalFilename);
if (!IMAGE_EXTENSIONS.contains(extension)) {
    throw new BusinessException("不支持的图片格式，仅支持 jpg/png/webp");
}
```

**问题**：仅判断文件名字符串后缀，攻击者可上传 `evil.jpg` 的 PHP 木马，绕过扩展名校验。

**修复建议**：
- 使用 Apache Tika 或 `Files.probeContentType()` 嗅探真实 MIME
- 双校验：扩展名 AND `contentType` AND 魔术字节
- 图片场景可调用 `ImageIO.read()` 验证确为合法图片格式

---

## B. 健壮性与 Bug（4 条）

### B-01 【major】WebSocket 断线重连无重试上限

**文件**：[useChatWebSocket.ts#L61-L66](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_vue/src/composables/useChatWebSocket.ts#L61-L66)

**证据**：
```ts
socket.onclose = () => {
  connected.value = false
  clearInterval(pingTimer!)
  ws.value = null
  reconnectTimer = setTimeout(connect, 5000)
}
```

**问题**：服务故障时客户端会无限重连（每 5s 一次），既消耗客户端资源，也对后端造成持续压力。Token 已过期但仍持续重连也属浪费。

**修复建议**：
- 引入重连次数计数 `reconnectCount`，达到 10 次后停止并提示用户
- 实现指数退避：1s → 2s → 4s → 8s → 16s（封顶 30s）
- 401 / Token 过期时不重连，跳转登录页

---

### B-02 【major】调度任务无重叠执行保护

**文件**：[TaskScheduledService.java#L31-L32](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_java/src/main/java/com/uniseek/task/schedule/TaskScheduledService.java#L31-L32)

**证据**：
```java
@Scheduled(cron = "0 0 * * * ?")
public void expireOverdueTasks() { ... }
```

**问题**：单实例场景下若上次任务未执行完（例如 DB 锁等待），下个整点仍会触发，可能产生重复 UPDATE 或日志混乱。集群部署时更会多机同时执行同一逻辑。

**修复建议**：
- 方法上加分布式锁（Redis `SETNX` 或 ShedLock）：`@SchedulerLock(name="expireOverdueTasks")`
- 或使用 `fixedDelay` 替代 `cron`（确保上次完成后再等固定时间）
- 单实例可加 `synchronized` 或 `AtomicBoolean` 状态标志

---

### B-03 【minor】JWT 过期时间 7 天过长

**文件**：[JwtUtil.java#L24](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_java/src/main/java/com/uniseek/util/JwtUtil.java#L24)

**证据**：
```java
private static final long EXPIRATION = 7 * 24 * 60 * 60 * 1000L;
```

**问题**：7 天无刷新机制 + 无 Refresh Token + 无吊销名单，被盗 Token 有效期过长。

**修复建议**：
- Access Token 缩短为 2 小时
- 引入 Refresh Token（30 天，存于 HttpOnly Cookie）
- 关键操作（修改密码、提现、删账号）需二次验证或短时 Token

---

### B-04 【minor】MyBatis 日志输出到 stdout

**文件**：[application.yml#L27](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_java/src/main/resources/application.yml#L27)

**证据**：
```yaml
configuration:
    log-impl: org.apache.ibatis.logging.stdout.StdOutImpl
```

**问题**：
- 生产环境输出全部 SQL（含参数值）到 stdout，可能泄露用户数据
- `StdOutImpl` 性能差，应使用 `SLF4JImpl` 走日志框架

**修复建议**：
- 改为 `org.apache.ibatis.logging.slf4j.Slf4jImpl`
- 生产环境关闭 SQL DEBUG，仅 ERROR 级别输出

---

## C. 架构与分层（3 条）

### C-01 【critical】空 AuthServiceImpl 重复类

**文件**：[service/impl/AuthServiceImpl.java#L1-L4](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_java/src/main/java/com/uniseek/service/impl/AuthServiceImpl.java#L1-L4)

**证据**：
```java
package com.uniseek.service.impl;

public class AuthServiceImpl {

}
```

**问题**：
1. 同名空类与 [auth/service/impl/AuthServiceImpl.java](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_java/src/main/java/com/uniseek/auth/service/impl/AuthServiceImpl.java) 并存，后者才是有效实现
2. 两个类不在同包，存在歧义，依赖注入可能注入空类导致 NullPointerException
3. 误导后续维护者

**修复建议**：
- **删除** `com.uniseek.service.impl.AuthServiceImpl`（空类）
- 统一保留 `com.uniseek.auth.service.impl.AuthServiceImpl`
- 在 `AuthController` 中确认 `@Autowired` 指向 `com.uniseek.auth.service.AuthService`

---

### C-02 【major】Service 实现路径分散（双套并存）

**文件**：
- [auth/service/AuthService.java](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_java/src/main/java/com/uniseek/auth/service/AuthService.java)
- [service/AuthService.java](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_java/src/main/java/com/uniseek/service/AuthService.java)

**问题**：项目同时存在 `com.uniseek.auth.service.*` 与 `com.uniseek.service.*` 两套 Service 接口与实现（如 `AuthService`、`UserService`），违反 AGENTS.md 中"分层清晰、命名规范统一"的约定。

**修复建议**：
- 选定一套作为主路径（推荐 `com.uniseek.service.*`）
- 迁移所有 `com.uniseek.auth.service.*` 至 `com.uniseek.service.*`
- 一次性提交，避免增量迁移

---

### C-03 【major】Home.vue 单文件 490 行（组件过大）

**文件**：[Home.vue#L1-L490](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_vue/src/pages/Home.vue)

**问题**：Home.vue 混合了推荐职位、热门分类、热门公司、搜索入口等 4-5 个独立板块，单文件近 500 行，可读性差，难以单测，主题切换困难。

**修复建议**：
- 拆分为 `JobCard.vue`、`CategoryCard.vue`、`CompanyCard.vue` 子组件
- 拆出 `composables/useHomeData.ts` 集中数据请求
- 保持 Home.vue 仅做布局编排，目标 < 200 行

---

## D. 性能与数据库（4 条）

### D-01 【major】聊天消息 content 字段全量返回

**文件**：[ChatMessageMapper.xml#L17-L23](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_java/src/main/resources/mapper/ChatMessageMapper.xml#L17-L23)

**证据**：
```xml
<select id="selectMessagesBeforeId" resultMap="BaseResultMap">
    SELECT id, session_id, sender_id, message_type, content, is_read, send_time
    FROM chat_message
    WHERE session_id = #{sessionId} AND id &lt; #{beforeId}
    ORDER BY id DESC
    LIMIT #{pageSize}
</select>
```

**问题**：`content` 字段可能是大文本/富文本/图片 base64，但消息列表只需展示预览。每次返回全部 content 既增加网络传输又增加 JSON 解析开销。

**修复建议**：
- 列表接口改用 `LEFT(content, 50) AS content_preview` 仅返回预览
- 详情接口保留完整 content
- 评估是否使用单独的 `chat_message_preview` 表

---

### D-02 【minor】Vite 未配置代码分割与 chunk 策略

**文件**：[vite.config.ts#L1-L31](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_vue/vite.config.ts)

**问题**：仅有 alias 与 dev server proxy，无 `build.rollupOptions.output` 配置 chunk 分割。Element Plus 全部打入 `index.js`，首屏体积过大。

**修复建议**：
```ts
build: {
  rollupOptions: {
    output: {
      manualChunks: {
        'element-plus': ['element-plus'],
        'vue-vendor': ['vue', 'vue-router', 'pinia']
      }
    }
  }
}
```

---

### D-03 【minor】TypeScript `any` 滥用

**文件**：[user.ts#L7, L17](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_vue/src/stores/user.ts#L7-L17)

**证据**：
```ts
const userInfo = ref<any>(JSON.parse(localStorage.getItem('uniseek_user') || 'null'))
// ...
const setUserInfo = (info: any) => { ... }
```

**问题**：放弃 TS 类型检查，store 中传递的 `any` 会在多处失去 IDE 提示与编译期保护。

**修复建议**：
- 抽取 `interface UserInfo { id: number; role: number; nickname: string; avatar?: string; ... }`
- store / API 层 / 组件全部使用强类型

---

### D-04 【minor】未读消息统计无复合索引

**文件**：[ChatMessageMapper.xml#L35-L39](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_java/src/main/resources/mapper/ChatMessageMapper.xml#L35-L39)

**证据**：
```xml
<select id="countUnread" resultType="java.lang.Integer">
    SELECT COUNT(*)
    FROM chat_message
    WHERE session_id = #{sessionId} AND is_read = 0 AND sender_id != #{userId}
</select>
```

**问题**：消息列表每次进入都会调用此 SQL。若 `chat_message` 表数据量超过百万且无合适复合索引，会全表扫描。

**修复建议**：
- 添加复合索引：`ALTER TABLE chat_message ADD INDEX idx_session_unread (session_id, is_read, sender_id)`
- 或按业务拆分：每个会话单独建消息表

---

## 🔧 修复优先级建议

| 优先级 | 任务 | 预期收益 |
|--------|------|----------|
| **P0（立即）** | A-01 密码 MD5 → BCrypt | 防撞库 |
| **P0** | A-02 JWT 密钥改环境变量 | 防伪造 Token |
| **P0** | A-03 DB 密码改专用账号 | 防越权 |
| **P0** | C-01 删除空 AuthServiceImpl | 防 NPE / 启动失败 |
| **P1（本周）** | A-04 CORS 收紧白名单 | 防 CSRF |
| **P1** | A-05 Token 迁移 HttpOnly Cookie | 防 XSS 窃 Token |
| **P1** | A-06 后端补 role 校验 | 防前端鉴权绕过 |
| **P1** | A-07 ${} 改白名单 | 防 SQL 注入 |
| **P1** | B-01 WS 重连加退避 + 上限 | 提升可用性 |
| **P1** | B-02 调度加分布式锁 | 防重复执行 |
| **P2（本月）** | C-02 Service 路径合并 | 可维护性 |
| **P2** | C-03 Home.vue 拆分 | 可维护性 |
| **P2** | D-01 聊天 content 字段优化 | 接口性能 |
| **P3（迭代）** | A-08 上传 MIME 嗅探 | 强化上传安全 |
| **P3** | B-03 JWT Refresh Token | 安全体验平衡 |
| **P3** | B-04 MyBatis 日志改 SLF4J | 日志规范 |
| **P3** | D-02 Vite chunk 策略 | 首屏速度 |
| **P3** | D-03 消灭 any | 类型安全 |
| **P3** | D-04 消息表索引 | DB 性能 |

---

## 🗺️ 核心调用链（含审计发现位置）

```mermaid
flowchart TD
    User[用户/求职者] -->|登录| Login[Login.vue]
    Login -->|POST /api/auth/login| AuthCtrl[AuthController]
    AuthCtrl --> AuthSvc[AuthServiceImpl]
    AuthSvc -->|MD5 弱哈希 ⚠A-01| PwdUtil[PasswordUtil]
    AuthSvc -->|密钥硬编码 ⚠A-02| JwtUtil[JwtUtil]
    AuthSvc --> UserMapper[UserMapper]
    Login -->|token 存 localStorage ⚠A-05| LocalStorage

    User -->|浏览首页| Home[Home.vue 490行 ⚠C-03]
    Home -->|GET /api/task/search| TaskCtrl[TaskController]
    TaskCtrl -->|ORDER BY ${orderDir} ⚠A-07| TaskMapper[TaskMapper.xml]
    TaskMapper --> DB1[(MySQL root/root ⚠A-03)]

    User -->|发起聊天| Chat[Chat.vue]
    Chat -->|WS /ws/chat?token=| WSHandler[ChatWebSocketHandler]
    WSHandler -->|Token 解析 ⚠A-06| JwtUtil
    WSHandler -->|无限重连 ⚠B-01| WsClient[useChatWebSocket.ts]
    WSHandler --> ChatMapper[ChatMessageMapper]
    ChatMapper -->|SELECT content ⚠D-01| DB1

    Admin[管理员] -->|/admin/*| Router[router/index.ts]
    Router -->|仅前端 role 校验 ⚠A-06| LocalStorage
    Router --> AdminPage[admin/*]
    AdminPage -->|调用| AdminCtrl[AdminController]
    AdminCtrl -->|⚠ 后端未补 role 校验| AdminSvc[AdminService]

    Schedule[TaskScheduledService] -->|无锁 ⚠B-02| TaskMapper
    TaskMapper --> DB1

    Upload[UploadController] -->|⚠ 仅扩展名校验 A-08| UploadSvc[UploadService]
    UploadSvc --> Disk[(本地磁盘 ./upload)]
    UploadSvc -.CORS * ⚠A-04.-> User

    style PwdUtil fill:#ffcdd2,color:#b71c1c
    style JwtUtil fill:#ffcdd2,color:#b71c1c
    style DB1 fill:#ffcdd2,color:#b71c1c
    style LocalStorage fill:#fff3e0,color:#e65100
    style Home fill:#fff3e0,color:#e65100
    style TaskMapper fill:#fff3e0,color:#e65100
    style WSHandler fill:#fff3e0,color:#e65100
    style WsClient fill:#fff3e0,color:#e65100
    style Router fill:#fff3e0,color:#e65100
    style Schedule fill:#fff3e0,color:#e65100
    style UploadSvc fill:#fff3e0,color:#e65100
    style AdminCtrl fill:#fff3e0,color:#e65100
    style AuthSvc fill:#fff3e0,color:#e65100
    style ChatMapper fill:#e1f5fe,color:#01579b
```

---

## ✅ 已剔除的误报（透明度说明）

以下问题在初轮子代理中曾被报告，经主代理核验源代码后判定为 **非问题 / 已实现**，不进入最终报告：

| 误报内容 | 核验结果 |
|----------|----------|
| WebSocket 未鉴权 | 实际 [ChatWebSocketHandler.java#L84-L115](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_java/src/main/java/com/uniseek/chat/websocket/ChatWebSocketHandler.java#L84-L115) 有完整 Token 解析 + claims 校验 |
| UploadController 缺少鉴权 | 实际由 [JwtAuthInterceptor](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_java/src/main/java/com/uniseek/config/JwtAuthInterceptor.java) 全局拦截 `/api/**` |
| WebSocket `userSessions` 非线程安全 | 实际为 [ConcurrentHashMap](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_java/src/main/java/com/uniseek/chat/websocket/ChatWebSocketHandler.java#L77) + `CopyOnWriteArraySet`，已线程安全 |
| UploadService 完全无校验 | 实际有 [扩展名+大小校验](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_java/src/main/java/com/uniseek/upload/service/UploadService.java#L31-L42) |
| N+1 在 ChatServiceImpl 存在 | 实际 `selectMessagesBeforeId` 已是单次游标分页查询 |
| 路由守卫未覆盖 admin | 实际 [L196-L198](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_vue/src/router/index.ts#L196-L198) 已限制 `role < 9` 不可访问 `/admin`（但仍仅前端，列入 A-06）|
| 多个类 > 500 行 | 实际抽样均 < 500 行，仅 Home.vue 接近 490 行 |
| ApplicationStatusMachine NPE | 实际 [L45-L47](file:///d:/Temps/yaoshi/Desktop/code/istone/AAAAAAAAAA/UniSeek/uniseek_java/src/main/java/com/uniseek/service/ApplicationStatusMachine.java#L45-L47) 已对 null fromStatus 抛 BusinessException |
| 多个 mapper.xml 使用 `${}` 注入 | 仅 TaskMapper.xml 一处为 `orderDir`（仍标记为 A-07 待白名单化），其余均使用 `#{}` |

---

## 📌 后续建议

1. **将本报告作为新基线**：建议将 A/B/C/D 19 条问题拆分为 19 个独立 Issue 跟踪
2. **优先 P0 修复**：4 条 critical 必须在下一迭代前处理
3. **补充测试**：BCrypt 迁移、Service 路径合并需配套单测
4. **建立 SAST 流程**：建议引入 SonarQube / SpotBugs 在 CI 阶段拦截 MD5、`${}` 等已知模式
5. **定期重审**：本审计为一次性快照，建议每季度重做一次全栈审计
