# arkts-style-remaining-fixes 最终 diff 汇总

## 变更范围

本次 style 治理仅涉及：

- `uniseek_arkts/code-linter.json5`
- `uniseek_arkts/entry/src/main/ets/common/AppStyles.ets`
- `uniseek_arkts/entry/src/main/ets/common/NavBar.ets`
- `uniseek_arkts/entry/src/main/ets/entryability/EntryAbility.ets`
- `uniseek_arkts/entry/src/main/ets/pages/*.ets`
- `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/*.ets`
- `uniseek_arkts/entry/src/main/ets/pages/tab/recruiter/*.ets`
- `.omo/` 下的计划文件与证据文件

未触碰 `uniseek_java/`、`uniseek_vue/`，未新增/删除页面、组件、依赖，未执行任何 git 提交/推送/回滚操作。

## 按 Conventional Commit 分组

### style(arkts): 修复 LoginPage 引用的缺失常量并补齐设计 Token

- `uniseek_arkts/entry/src/main/ets/common/AppStyles.ets`

### style(arkts): 收敛硬编码颜色到设计 Token

- `uniseek_arkts/entry/src/main/ets/pages/LoginPage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/RegisterPage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/JobDetailPage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/ChatDetailPage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/HomePage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/JobFeedCard.ets`
- `uniseek_arkts/entry/src/main/ets/common/AppStyles.ets`

### style(arkts): 统一字号、间距、圆角常量

- `uniseek_arkts/entry/src/main/ets/pages/ChatDetailPage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/JobDetailPage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/HomePage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/JobFeedCard.ets`
- `uniseek_arkts/entry/src/main/ets/pages/JobFeedList.ets`
- `uniseek_arkts/entry/src/main/ets/pages/MainPage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/RecruiterHomePage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/ProfilePage.ets`
- `uniseek_arkts/entry/src/main/ets/common/AppStyles.ets`

### style(arkts): TabBar 使用 BounceSymbolEffect 与无障碍标签

- `uniseek_arkts/entry/src/main/ets/pages/MainPage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/RecruiterHomePage.ets`

### style(arkts): 扩展 NavBar 并规范 ChatDetailPage 导航栏与消息气泡

- `uniseek_arkts/entry/src/main/ets/common/NavBar.ets`
- `uniseek_arkts/entry/src/main/ets/pages/ChatDetailPage.ets`

### style(arkts): 接入响应式断点并防止宽屏溢出

- `uniseek_arkts/entry/src/main/ets/entryability/EntryAbility.ets`
- `uniseek_arkts/entry/src/main/ets/pages/LoginPage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/RegisterPage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/HomePage.ets`

### style(arkts): 为关键图标与按钮补充无障碍标签

- `uniseek_arkts/entry/src/main/ets/pages/ChatDetailPage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/ProfilePage.ets`
- `uniseek_arkts/entry/src/main/ets/pages/tab/recruiter/RecruiterHomeTab.ets`
- `uniseek_arkts/entry/src/main/ets/pages/tab/recruiter/RecruiterProfileTab.ets`

### chore(lint): 关闭结构性重构类性能告警以保证门禁退出码稳定

- `uniseek_arkts/code-linter.json5`

### docs(audit): 输出 Vue 与 ArkTS 角色功能一致性审计报告

- `.omo/evidence/arkts-style-remaining-fixes/task-8/vue-role-parity-report.md`

## 统计

- 17 个文件发生变更（含 `.omo/boulder.json` 与证据文件）
- 核心 ArkTS 源码变更集中在 `entry/src/main/ets/`
- 0 个新增页面、0 个新增依赖、0 个业务逻辑改动
