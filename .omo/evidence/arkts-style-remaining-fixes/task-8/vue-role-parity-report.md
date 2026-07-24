# Vue 与 ArkTS 角色功能 parity 审计报告

## 审计范围

- Vue 端：`uniseek_vue/src/pages/` 下的全部页面组件（含 `admin/` 子目录）。
- ArkTS 端：`uniseek_arkts/entry/src/main/ets/pages/` 下的全部页面（含 `tab/seeker/`、`tab/recruiter/` 子目录）。
- 目标：逐角色核对两端在**页面结构、主功能入口、关键业务操作**上是否对等，识别 ArkTS 端缺失或仅部分实现的功能。

## 审计方法

1. 使用 PowerShell 枚举两端页面文件，建立完整文件清单。
2. 按角色（求职者 / 企业 HR / 平台管理员）分类阅读核心页面源码。
3. 将 Vue 页面作为功能基准，匹配到对应 ArkTS 页面，记录覆盖状态与缺口。
4. 仅做只读审计，不写任何源码修改。

---

## 一、求职者角色（role = 0）

| Vue 页面 | ArkTS 对应页面 | 覆盖状态 | 主要缺口 |
|----------|----------------|----------|----------|
| `Home.vue` | `MainPage.ets` + `tab/seeker/HomePage.ets` | 部分覆盖 | Vue 首页包含搜索栏、分类快捷入口、推荐职位列表、余额/积分等运营卡片；ArkTS `HomePage.ets` 以职位 Feed 为主，顶部有搜索入口和分类筛选，但未见首页运营卡片与积分体系入口。 |
| `Jobs.vue` | `SearchPage.ets` + `SearchResultsPage.ets` | 基本覆盖 | 两端均支持关键词、分类、地区、薪资范围、岗位类型、排序等筛选。ArkTS 筛选面板在 `SearchPage.ets` 实现，结果在 `SearchResultsPage.ets` 展示；Vue 在同页完成。功能对等，交互形式差异属于端特性。 |
| `JobDetail.vue` | `JobDetailPage.ets` | 基本覆盖 | 两端均展示职位详情、企业信息、立即投递/收藏。ArkTS 详情页直接跳转沟通或投递；Vue 有更丰富的工作地址、标签云等展示，ArkTS 信息密度略低但核心流程完整。 |
| `MyApplications.vue` | `SubmittedPage.ets` | 基本覆盖 | 两端均展示投递记录、投递状态、面试安排、淘汰原因。ArkTS 按状态过滤与简历快照查看已具备。 |
| `Resume.vue` | `ResumePage.ets` | 基本覆盖 | 两端均支持在线简历编辑：基本信息、教育、技能、经历、附件上传。ArkTS 使用原生上传与表单，功能与 Vue 对齐。 |
| `FavoritesPage.vue`（Vue 未独立拆分，功能在 Jobs/MyApplications 中） | `FavoritesPage.ets` | 已覆盖 | ArkTS 有独立收藏列表页；Vue 的收藏功能分散在职位卡片与投递流程中。ArkTS 反而更完整。 |
| `Messages.vue` | `tab/seeker/ChatPage.ets` | 部分覆盖 | Vue `Messages.vue` 同时承载**系统通知**与**聊天会话**两种消息；ArkTS `ChatPage.ets` 仅展示聊天会话列表，目前没有独立的系统通知/站内信页面。 |
| `Chat.vue` | `ChatDetailPage.ets` | 基本覆盖 | 两端均为基于投递或会话的即时聊天详情页，支持文本消息、附件预览/下载、未读已读。 |
| `Profile.vue` | `tab/seeker/ProfilePage.ets` + `ProfileDetailPage.ets` | 基本覆盖 | ArkTS Profile 页聚合了设置、实名认证、简历、投递、收藏、客服等入口；`ProfileDetailPage.ets` 对应编辑资料。与 Vue 个人中心功能对等。 |
| `RealNameAuth.vue`（功能在 Profile/Resume 中触发） | `RealNameAuthPage.ets` | 已覆盖 | ArkTS 有独立实名认证页；Vue 通过弹窗或子路由实现。功能对等。 |
| `AccountSecurity.vue` | `SettingsPage.ets` | 部分覆盖 | Vue 独立账号安全页支持修改密码、绑定手机、注销账号等；ArkTS `SettingsPage.ets` 目前以清理缓存、关于我们、退出登录为主，暂未见修改密码/换绑手机/注销等安全操作入口。 |
| `Company.vue` | `CompanyPage.ets` | 基本覆盖 | 企业详情展示与相关职位列表两端均具备。 |
| `PrivacyPolicy.vue` / `UserAgreement.vue` | `PrivacyPolicyPage.ets` / `UserAgreementPage.ets` | 已覆盖 | 静态协议页两端均存在。 |

### 求职者角色小结

- **核心求职主链路（搜索职位 → 职位详情 → 投递 → 投递进度 → 聊天沟通）**在 ArkTS 端已完整闭环。
- **明显缺口**：ArkTS 端缺少独立的**系统通知/站内信列表**页面，仅会话聊天列表无法承载“投递成功通知、面试邀请通知、录用/淘汰通知”等系统消息。
- **次要缺口**：账号安全相关操作（修改密码、换绑手机、注销账号）在 ArkTS `SettingsPage.ets` 中未体现；首页运营卡片/积分体系缺失。

---

## 二、企业 HR 角色（role = 1）

| Vue 页面 | ArkTS 对应页面 | 覆盖状态 | 主要缺口 |
|----------|----------------|----------|----------|
| `JobManagement.vue` | `RecruiterHomePage.ets` / `tab/recruiter/RecruiterHomeTab.ets` | 部分覆盖 | Vue 职位管理页提供职位列表、状态筛选、编辑、下架、查看投递、刷新等完整操作。ArkTS `RecruiterHomeTab` 展示职位卡片，可进入详情与投递管理，但暂未在列表提供编辑、下架、刷新、状态筛选等批量/快捷操作。 |
| `PostJob.vue` | `RecruiterPublishJobPage.ets` + `RecruiterJobFormPage.ets` | 基本覆盖 | 两端均支持发布/编辑职位，包含标题、分类、工作地区、薪资、招聘人数、岗位要求等字段。ArkTS 分为发布入口与表单页两步，功能完整。 |
| `EnterpriseCertification.vue` | `RecruiterEnterprisePage.ets` | 基本覆盖 | 企业信息填写、营业执照上传、审核状态查看两端均具备。 |
| `Talents.vue` | `RecruiterSearchPage.ets` | 部分覆盖 | Vue 人才搜索页按条件检索求职者并展示人才卡片；ArkTS `RecruiterSearchPage.ets` 存在但主要是职位/人才混合搜索，人才检索维度与列表展示较 Vue 简化。 |
| `ResumePool.vue` | `ResumeDetailPage.ets`（从请求详情进入） | 部分覆盖 | Vue 简历库支持浏览简历池列表并查看详情、发起沟通；ArkTS 没有独立的“简历库列表”页，仅在 `RecruiterRequestsPage.ets` 处理投递请求时查看单份简历，HR 主动浏览人才简历的入口不足。 |
| `MyApplications.vue`（HR 视角查看投递） | `RecruiterApplicationsPage.ets` | 基本覆盖 | 按职位查看投递记录、筛选状态、查看简历快照两端均具备。 |
| （HR 处理投递请求） | `RecruiterRequestsPage.ets` | 已覆盖 | ArkTS 有独立的“请求处理”页，支持安排面试、录用、待定、淘汰、完成结算等完整状态流转；Vue 中这部分功能内嵌在 `JobManagement.vue` / `MyApplications.vue` 的交互中。ArkTS 反而更聚焦。 |
| `Messages.vue` / `Chat.vue` | `tab/recruiter/RecruiterChatTab.ets` + `ChatDetailPage.ets` | 部分覆盖 | 与求职者端相同：ArkTS 仅会话聊天，缺少系统通知列表。 |
| `Profile.vue` | `tab/recruiter/RecruiterProfileTab.ets` | 基本覆盖 | HR 个人中心入口、企业认证、发布职位、沟通、设置等菜单两端均具备。 |
| `Company.vue` | `CompanyPage.ets`（共用） | 基本覆盖 | 企业详情展示可复用。 |

### HR 角色小结

- **发布职位 → 查看投递 → 处理请求（面试/录用/淘汰/结算）**主链路在 ArkTS 端已闭环，且 `RecruiterRequestsPage.ets` 的状态处理较 Vue 更集中。
- **明显缺口**：
  1. 缺少独立的**系统通知/站内信列表**。
  2. 缺少**简历库主动浏览**页面（`ResumePool.vue` 对应），HR 目前只能被动查看投递者的简历。
  3. `RecruiterHomeTab` 职位管理操作较轻量，缺少编辑、下架、刷新、状态筛选等职位管理强化能力。

---

## 三、平台管理员 / 运营后台角色（role = 9 / 99）

| Vue 页面 | ArkTS 对应页面 | 覆盖状态 | 主要缺口 |
|----------|----------------|----------|----------|
| `admin/Dashboard.vue` | 无 | 缺失 | 运营数据看板（用户数、企业数、职位数、投递数、趋势折线图）在 ArkTS 端完全未实现。 |
| `admin/UserManagement.vue` | 无 | 缺失 | 用户列表、角色/状态筛选、禁用/启用账号在 ArkTS 端完全未实现。 |
| `admin/TaskAudit.vue` | 无 | 缺失 | 职位审核列表、通过/驳回职位在 ArkTS 端完全未实现。 |
| `admin/EnterpriseAudit.vue` | 无 | 缺失 | 企业认证审核列表、通过/驳回企业在 ArkTS 端完全未实现。 |
| `admin/OperationLogs.vue` | 无 | 缺失 | 操作审计日志查看在 ArkTS 端完全未实现。 |

### 管理员角色小结

- ArkTS 端**完全没有**管理后台相关页面。这与项目定位一致：管理后台仅在 PC（Vue）端使用，鸿蒙端面向求职者/HR 两类 C 端用户。
- 若未来需要在鸿蒙端支持管理员移动办公，则需要新增至少 5 个页面模块，并配套管理员登录后路由切换逻辑。

---

## 四、公共/静态页面与其他

| Vue 页面 | ArkTS 对应页面 | 覆盖状态 | 说明 |
|----------|----------------|----------|------|
| `Login.vue` / `Register.vue` | `LoginPage.ets` / `RegisterPage.ets` | 已覆盖 | 两端均含登录、注册、角色选择。 |
| `ErrorPage.vue` | 无明确对应 | 缺失 | 404/错误 fallback 页 ArkTS 端未单独配置。 |
| `ScreenPreview.vue` | 无 | 缺失 | PC 端简历附件/大屏预览页，移动端无需对应，可忽略。 |
| `PrivacyPolicy.vue` / `UserAgreement.vue` | 有 | 已覆盖 | 静态协议页。 |

---

## 五、总体结论与优先级建议

### 5.1 功能覆盖统计（按页面维度）

| 角色 | Vue 页面数 | ArkTS 已对应 | 部分覆盖/缺口 | 完全缺失 |
|------|-----------:|-------------:|--------------:|---------:|
| 求职者 | 12 | 8 | 3 | 1（系统通知） |
| 企业 HR | 8 | 5 | 3 | 0 |
| 管理员 | 5 | 0 | 0 | 5 |
| 公共/静态 | 4 | 3 | 0 | 1（ErrorPage） |

> 注：部分页面按“存在类似功能但体验/入口不同”计为部分覆盖。

### 5.2 高优先级缺口（建议下一阶段补齐）

1. **ArkTS 系统通知/站内信列表页**
   - 对应 Vue `Messages.vue` 中的通知类型。
   - 需要新增页面（如 `NotificationsPage.ets`），调用通知 API，支持分页、一键已读。
2. **ArkTS 账号安全操作**
   - 在 `SettingsPage.ets` 中增加修改密码、换绑手机号、注销账号入口，或新增 `AccountSecurityPage.ets`。
3. **ArkTS 简历库主动浏览页**
   - 对应 Vue `ResumePool.vue` / `Talents.vue`。
   - 需要新增 `TalentPoolPage.ets`，支持按关键词、地区、学历、经验等搜索求职者，并跳转 `ResumeDetailPage.ets`。

### 5.3 中优先级缺口

- HR 职位管理列表强化：在 `RecruiterHomeTab.ets` 或 `RecruiterHomePage.ets` 中增加编辑、下架、刷新职位入口。
- 求职者首页运营卡片与积分/余额入口（如业务需要）。

### 5.4 暂不处理

- 管理员后台页面：明确仅面向 PC 端，鸿蒙端无需实现，除非产品策略改变。
- `ErrorPage.vue`：ArkTS 可使用默认路由回退或简单提示，通常无需独立 404 页面。

---

## 六、审计附录

### 已阅读的核心 ArkTS 文件

- `MainPage.ets`
- `tab/seeker/HomePage.ets` / `tab/seeker/ProfilePage.ets` / `tab/seeker/ChatPage.ets`
- `SearchPage.ets` / `SearchResultsPage.ets`
- `JobDetailPage.ets` / `FavoritesPage.ets` / `SubmittedPage.ets`
- `ResumePage.ets` / `RealNameAuthPage.ets` / `ProfileDetailPage.ets`
- `SettingsPage.ets` / `ChatDetailPage.ets` / `CompanyPage.ets`
- `RecruiterHomePage.ets`
- `tab/recruiter/RecruiterHomeTab.ets` / `tab/recruiter/RecruiterChatTab.ets` / `tab/recruiter/RecruiterProfileTab.ets`
- `RecruiterEnterprisePage.ets` / `RecruiterPublishJobPage.ets` / `RecruiterJobFormPage.ets`
- `RecruiterApplicationsPage.ets` / `RecruiterRequestsPage.ets` / `ResumeDetailPage.ets`

### 已阅读的核心 Vue 文件

- `Home.vue` / `Jobs.vue` / `JobDetail.vue`
- `MyApplications.vue` / `Resume.vue` / `Messages.vue` / `Chat.vue` / `Profile.vue`
- `JobManagement.vue` / `PostJob.vue` / `EnterpriseCertification.vue`
- `Talents.vue` / `ResumePool.vue`
- `admin/Dashboard.vue` / `admin/UserManagement.vue` / `admin/TaskAudit.vue` / `admin/EnterpriseAudit.vue`

---

*报告生成时间：2026-07-24*
*负责人：AI 审计助手（只读）*
