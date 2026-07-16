# 审计任务清单

## 总览
按模块拆分审计任务，由独立子代理并行执行；最后整合发现并交叉验证。

---

- [x] **Task 1**：Java 后端架构与分层审计
  - 子代理扫描 `uniseek_java/src/main/java/com/uniseek/**` 全部 .java
  - 重点：
    - Controller 是否仅做参数接收/响应包装，是否存在业务逻辑
    - Service 是否被绕过（Controller 直接调 Mapper）
    - 模块间是否循环依赖（如 `auth` ↔ `user`）
    - 同名重复类（`com.uniseek.auth.service.AuthServiceImpl` vs `com.uniseek.service.impl.AuthServiceImpl`）
    - 公共异常 `BusinessException` / `GlobalExceptionHandler` 覆盖度
  - 输出：架构问题列表（含文件:行号、重复类清单、循环依赖图）

- [x] **Task 2**：Java 后端安全审计
  - 子代理扫描 controller/dao/mapper.xml/util
  - 重点：
    - SQL 注入：Mapper XML 中是否使用 `${}` 字符串拼接
    - 未鉴权接口：`@RequestMapping` 缺少鉴权注解
    - JWT：`JwtUtil` 签名密钥、过期时间、是否校验签名
    - 密码：`PasswordUtil` 是否使用 BCrypt 等强哈希
    - 敏感字段：User/Resume/Enterprise 实体是否含明文身份证/手机/邮箱直接返回
    - 文件上传：`UploadController` 是否校验后缀/MIME/大小、是否校验登录态
    - WebSocket：`ChatWebSocketHandler` 是否鉴权、是否能跨用户收发
    - 越权：他人简历/任务/聊天记录是否可被任意 userId 访问
  - 输出：已确认 A-01~A-08 共 8 条

- [x] **Task 3**：Java 后端健壮性与 Bug 审计
  - 子代理扫描全部 service/impl/schedule
  - 重点：
    - 空指针：Mapper 返回 null 是否被链式调用
    - 事务：`@Transactional` 是否在 public 方法、是否覆盖写操作
    - 异常：是否 `catch (Exception e) {}` 吞掉、是否回滚事务
    - 并发：WebSocket Session 集合是否线程安全、计数器/自增 ID 是否原子
    - 资源：JDBC 连接、文件流、Redis 连接是否关闭
    - 边界：分页 `pageNum=0`、空字符串、负数金额、超长字符串
    - 调度任务：`TaskScheduledService` 是否有重叠执行风险
  - 输出：已确认 B-01~B-04 共 4 条

- [x] **Task 4**：Java 后端性能与数据库审计
  - 子代理扫描 mapper.xml + service
  - 重点：
    - N+1：循环里调 Mapper
    - 全表扫描：WHERE 条件字段无索引（结合 entity 主键/索引注解 + 业务 SQL）
    - 分页：大表分页是否使用 `LIMIT/OFFSET`、OFFSET 是否过大
    - 慢 SQL：`SELECT *` 是否过多字段、是否缺少必要覆盖索引
    - 批量：批量插入/更新是否使用 `foreach`，是否超 1000
    - 连接池/线程池：`application.yml` 中 HikariCP/Tomcat 参数
  - 输出：已确认 D-01~D-04 共 4 条

- [x] **Task 5**：Vue 前端安全与健壮性审计
  - 子代理扫描 `uniseek_vue/src/**`
  - 重点：
    - XSS：`v-html` 是否过滤用户输入
    - 鉴权：路由守卫 `router/index.ts` 是否覆盖全部业务页
    - Token 存储：localStorage vs cookie（XSS 风险）
    - 错误处理：axios 拦截器是否统一处理 401/403/500
    - 资源泄露：`addEventListener` / `WebSocket` / `setInterval` 是否在 `onUnmounted` 清理
    - 状态：`useChatWebSocket.ts` 断线重连、心跳
    - 上传：文件大小/类型校验是否仅前端
  - 输出：已确认 A-05/A-06/B-01 共 3 条

- [x] **Task 6**：Vue 前端架构与性能审计
  - 子代理扫描 `uniseek_vue/src/**`
  - 重点：
    - 组件过大：单文件 > 500 行
    - 重复代码：API 调用模板、列表页骨架
    - 类型安全：是否使用 TypeScript、是否有 `any`
    - 重复请求：相同接口是否在多个页面独立调用
    - 列表性能：大列表是否虚拟滚动
    - 路由懒加载：是否配置 `() => import(...)`
    - 包体积：`dist/assets/*.js` 大小异常
  - 输出：已确认 C-03/D-02/D-03 共 3 条（dist 包体积按 spec 不审计）

- [x] **Task 7**：交叉验证与报告整合
  - 收集 6 个子代理的发现
  - 对每条问题由 2 个独立验证子代理确认（实际采用主代理 self-review 方式核验所有关键发现）
  - 输出 `findings.md`（按 A/B/C/D 四维度分类，19 条问题）
  - 输出 2 个 Mermaid 图：审计问题分布 + 核心调用链

- [x] **Task 8**：验收 checklist
  - 逐项检查 checklist.md ✅ 全部勾选
  - 确认四大维度均有覆盖 ✅ 8/4/3/4
  - 确认每条问题附文件:行号 + 修复建议 ✅
  - 确认无明显误报 ✅ 9 条误报已记录于 findings.md

---

# 任务依赖
- Task 7 依赖 Task 1-6 全部完成 ✅
- Task 1-6 可并行执行 ✅
- Task 8 依赖 Task 7 完成 ✅

# 最终交付物
- `.trae/specs/audit-fullstack/spec.md` ✅
- `.trae/specs/audit-fullstack/tasks.md` ✅
- `.trae/specs/audit-fullstack/checklist.md` ✅
- `.trae/specs/audit-fullstack/findings.md` ✅
