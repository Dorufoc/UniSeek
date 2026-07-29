---
slug: arkts-api-compatibility-audit
intent: clear
review_required: true
status: awaiting-approval
classification: architecture
test_strategy: tests-after
scope: 仅产出 ArkTS API 兼容性 Markdown 审阅文档；允许新增专用测试代码/测试脚本用于验证实际调用和结果；禁止修改任何产品代码、Java、Vue、api.md
approach: 以 Java Controller/DTO/Interceptor 的实际运行时代码作为接口可用性基线，以 Vue API/页面的事实请求、字段、响应消费和交互流程作为行为基线，分五个功能波次只读核对 ArkTS 路由、方法、字段、响应、鉴权、分页、上传、WebSocket、状态机和错误处理；通过新增隔离的验证测试代码或脚本执行可行的 happy/failure 请求检查，最终把静态证据、测试命令、实际结果、无法执行项和修复建议写入 Markdown 审阅文档
approval_gate: 用户已收到审批简报；等待明确批准后生成完整 .omo/plans/arkts-api-compatibility-audit.md
next_action: approval_then_scaffold_plan_metis_todos_high_accuracy_review
components:
  - id: transport-auth
    outcome: HTTP/响应/Token/401/错误/地址配置与 Java 契约的差异被完整记录并有可执行验证证据
    status: pending
    evidence: uniseek_arkts/entry/src/main/ets/services/ApiClient.ets; uniseek_java/src/main/java/com/uniseek/config/JwtAuthInterceptor.java
  - id: seeker
    outcome: 现有求职者认证、资料、简历、搜索、投递、收藏调用与 Vue/Java 基线的差异被完整记录
    status: pending
    evidence: uniseek_arkts/entry/src/main/ets/pages; uniseek_arkts/entry/src/main/ets/services/AuthService.ets; ResumeService.ets; ApplicationService.ets; uniseek_vue/src/pages
  - id: recruiter
    outcome: 现有招聘者企业、职位、投递审核调用与 Java 状态机的差异被完整记录
    status: pending
    evidence: uniseek_arkts/entry/src/main/ets/pages/Recruiter*; uniseek_arkts/entry/src/main/ets/services/RecruiterService.ets; uniseek_java/src/main/java/com/uniseek/controller
  - id: chat-files
    outcome: 聊天 REST/WebSocket、文件上传下载、未读已读与权限行为的差异被测试或证据确认
    status: pending
    evidence: uniseek_arkts/entry/src/main/ets/services/ChatService.ets; ChatWebSocketService.ets; FileTransferPolicy.ets; uniseek_java/src/main/java/com/uniseek/chat; uniseek_vue/src/composables/useChatWebSocket.ts
  - id: shared-data
    outcome: 地区分类、通知、收藏、分页、状态映射及页面回归差异被记录并形成审阅结论
    status: pending
    evidence: uniseek_arkts/entry/src/main/ets/services/DataService.ets; NotificationService.ets; FavoriteService.ets; uniseek_java/src/main/java/com/uniseek/controller
decisions:
  - 用户选择仅审计现有 ArkTS，不补齐 Vue 已有但 ArkTS 缺失的管理后台
  - 用户要求不修改任何代码；允许新增隔离测试代码和测试脚本，仅用于验证实际调用和结果
  - 审阅文档以 Java 实际可用 API 与 Vue 事实调用为准；api.md 只作为辅助材料并记录过期内容
  - 测试采用实现后测试，但“实现”仅指新增审阅验证代码/脚本，不指产品修复
  - Java、Vue、api.md 与现有 ArkTS 产品代码均为只读对象
---
