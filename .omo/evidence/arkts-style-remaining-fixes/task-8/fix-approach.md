# Task 8 Vue 与 ArkTS 角色功能一致性校验 — 校验方案

## 1. 校验目标

- 对照 Vue 端 HR / 求职者 / 平台管理员核心页面，检查 ArkTS 端对应角色页面是否具备等价的功能入口、操作按钮、状态展示与跳转逻辑。
- 本次校验为**只读审计**，不在 ArkTS 端新增 Vue 没有的功能，不改动后端接口。

## 2. 校验范围

| 角色 | Vue 端文件 | ArkTS 端文件 |
|------|------------|--------------|
| 求职者 | `Home.vue`、`Jobs.vue`、`JobDetail.vue`、`MyApplications.vue`、`Resume.vue`、`Messages.vue`、`Chat.vue`、`Profile.vue`、`FavoritesPage.vue`、`Company.vue` 等 | `MainPage.ets`、`tab/seeker/HomePage.ets`、`SearchPage.ets`、`SearchResultsPage.ets`、`JobDetailPage.ets`、`SubmittedPage.ets`、`ResumePage.ets`、`tab/seeker/ChatPage.ets`、`ChatDetailPage.ets`、`tab/seeker/ProfilePage.ets`、`ProfileDetailPage.ets`、`FavoritesPage.ets`、`SettingsPage.ets`、`RealNameAuthPage.ets`、`CompanyPage.ets` |
| 企业 HR | `JobManagement.vue`、`PostJob.vue`、`EnterpriseCertification.vue`、`Talents.vue`、`ResumePool.vue`、`MyApplications.vue`、`Messages.vue`、`Chat.vue`、`Profile.vue`、`Company.vue` 等 | `RecruiterHomePage.ets`、`tab/recruiter/RecruiterHomeTab.ets`、`RecruiterPublishJobPage.ets`、`RecruiterJobFormPage.ets`、`RecruiterEnterprisePage.ets`、`RecruiterSearchPage.ets`、`ResumeDetailPage.ets`、`RecruiterApplicationsPage.ets`、`RecruiterRequestsPage.ets`、`tab/recruiter/RecruiterChatTab.ets`、`tab/recruiter/RecruiterProfileTab.ets`、`ChatDetailPage.ets`、`CompanyPage.ets` |
| 平台管理员 | `admin/Dashboard.vue`、`admin/UserManagement.vue`、`admin/TaskAudit.vue`、`admin/EnterpriseAudit.vue`、`admin/OperationLogs.vue` 等 | 无对应页面 |

## 3. 校验方法

1. 使用 PowerShell 枚举两端 `pages` 目录，建立文件清单。
2. 逐角色阅读 Vue 页面源码，提取核心功能入口、操作按钮、状态字段。
3. 在 ArkTS 端匹配对应页面，确认是否存在等价路由、按钮、数据展示。
4. 对无法匹配的功能，记录为“缺失”并给出具体文件级定位或“页面不存在”结论。
5. 仅输出审计报告，不修改源码。

## 4. 预期产出

- `.omo/evidence/arkts-style-remaining-fixes/task-8/vue-role-parity-report.md`
- 覆盖 11+ 功能域的对比表、缺口说明与优先级建议。
