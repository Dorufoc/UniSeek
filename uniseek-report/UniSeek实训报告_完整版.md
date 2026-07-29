# UniSeek 优寻兼职招聘平台 · 项目实训报告

> **班级**：XXXXX  
> **姓名**：XXXXX  
> **学号**：xxxxxxxx  
> **日期**：2026年7月

---

# 第二章 项目阶段-前言

## 2.1 项目背景

### 项目起源（痛点）

大学生兼职市场长期存在严重的信息不对称问题。一方面，求职者（尤其是高校学生）难以找到真实可靠的兼职信息，时常遭遇虚假招聘、薪资拖欠等问题；另一方面，企业HR缺乏高效、精准的招聘渠道，传统兼职平台存在虚假信息泛滥、沟通效率低下、管理流程不透明等痛点。现有的兼职招聘平台多面向社会人士，缺乏针对大学生群体的专属服务，且普遍缺少从投递到录用的全流程闭环管理。基于此，项目团队决定从零开发 UniSeek 优寻兼职招聘平台，旨在通过技术手段解决上述痛点，为高校学生和企业搭建一座可信、高效的兼职招聘桥梁。

### 数据基础

项目数据库基于 MySQL 8，采用 utf8mb4 字符集以支持完整中文存储。数据库共设计 14 张业务表，涵盖用户表（含求职者/HR/管理员/超级管理员四类角色）、实名认证表、在线简历表（含全文索引）、企业信息表（含审核状态）、职位分类表（两级树形，30条种子数据）、行政区划表（省/市/区三级，3432条标准数据）、职位表（含乐观锁版本号）、投递申请表（含简历快照）、聊天会话表、聊天消息表、消息通知表、日报统计表、操作日志审计表和收藏表，覆盖平台运营全链路数据。

### 平台定位

UniSeek 优寻定位于面向高校学生的兼职招聘垂直平台，打造"求职-投递-沟通-录用-结算"全流程闭环服务。平台采用多端覆盖策略，提供 Web 端（Vue 3）和鸿蒙 App 端（ArkTS）双入口，后端统一由 Java Spring Boot 提供 API 支撑。

### 驱动需求

项目的开发由四个核心需求驱动。信息真实方面，建立企业资质审核和实名认证双认证体系，从源头保障信息的真实性。沟通高效方面，求职者投递后自动创建聊天会话，HR 与求职者即时沟通，无需交换联系方式。流程透明方面，投递状态全生命周期可追溯（已投递、待面试、已录用、已淘汰），各环节自动发送通知。数据驱动方面，运营日报定时统计加数据大屏可视化，帮助运营团队实时掌握平台健康度。

### 服务对象与价值

求职者（高校学生）可以获得真实可靠的兼职机会，从浏览到录用的全流程线上化。企业HR可以精准触达高校求职者，高效管理招聘流程和投递记录。平台运营管理员通过数据看板实时掌握平台运营状况，管理审核流程。

---

## 2.2 系统概述

### 2.2.1 项目目标

**系统功能目标**：实现用户注册登录、实名认证、企业资质审核、职位发布与审核与搜索与投递、简历管理、即时聊天、消息通知、投递状态流转、运营统计看板、数据大屏可视化、操作日志审计、用户权限管理等核心功能。

**性能与质量目标**：系统稳定性方面，服务可用性不低于 99.9%，异常统一处理。响应速度方面，核心接口响应不超过 500ms，列表分页不超过 1s。可维护性方面，代码分层清晰（Controller/Service/DAO），统一异常处理，完善日志审计。安全性方面，密码独立盐值 MD5 加密，JWT 无状态鉴权，身份证 AES 加密存储，RBAC 角色权限控制。数据一致性方面，乐观锁防止超录，幂等保护防止重复投递。

**用户与服务目标**：求职者可以快速发现合适的兼职岗位，一键投递，实时沟通，跟踪投递进度。企业HR可以高效管理招聘流程，查看投递简历，筛选合适人才，安排面试。运营管理员可以通过数据监控平台运营状况，管理企业资质审核和职位审核。

**技术与架构目标**：采用前后端分离架构，后端提供 RESTful API，前端独立部署。后端基于 Java 1.8 和 Spring Boot 2.2.2 加 MyBatis 和 MySQL 8。前端基于 Vue 3 加 TypeScript 加 Vite 加 Element Plus 加 Pinia 加 ECharts。鸿蒙端基于 ArkTS 6.1.1 加 HarmonyOS NEXT 独立 App。接口规范方面，统一 JSON 响应格式，统一错误码体系，统一鉴权机制。

**交付与成果目标**：交付一个可运行的兼职招聘网站（Vue 前端加 Java 后端 API）、一个鸿蒙原生求职 App（ArkTS）、一个数据可视化大屏（ECharts 加实时数据）、一套完整的设计系统（CSS 变量加 Token 体系，横跨三端）。

### 2.2.2 功能模块概述

系统的功能模块覆盖了用户从注册到录用的完整链路。用户注册模块支持手机号和邮箱双标识注册，用户可选择求职者或 HR 身份，密码经 MD5 加独立盐值加密存储。用户登录模块通过手机号和密码完成登录，返回有效期 30 分钟的 JWT Token，前端按角色路由到不同首页。JWT 鉴权与权限控制模块负责 Token 校验和角色权限拦截，白名单路径直接放行，用户信息存储在 ThreadLocal 中供后续使用。实名认证模块使用 Hutool 的 IdcardUtil 校验身份证格式并验证年龄须满 16 周岁，身份证号 AES 加密存储。

企业资质提交模块允许 HR 提交公司全称、信用代码和营业执照图片，提交后进入待审状态。HR 可以随时通过企业资质状态查询模块查看审核进度。若资质被驳回，HR 可通过企业资质修改模块修改信息后重新提交，状态重置为待审。管理员审核企业资质模块供运营管理员审核或驳回企业资质，审核结果通过通知发送给 HR。

简历创建与编辑模块支持求职者在线填写性别、学历、学校、技能标签和经历等信息，简历附件上传模块支持 PDF 和 Word 格式，文件大小限制在 10MB 以内。职位分类浏览模块提供两级树形分类（15 个顶级分类和 15 个子级分类），行政区划浏览模块支持省、市、区三级渐进加载。

职位发布模块允许企业 HR 填写标题、描述、薪资、分类、地区、名额等信息发布兼职职位。职位审核模块供运营管理员审核或驳回职位，审核通过后对求职者可见。职位列表浏览与搜索模块支持按分类、地区、薪资、类型和关键词等多维度筛选，分页加载。职位状态自动变更模块管理满员自动关闭、截止时间自动过期（定时任务）和 HR 手动下架三种状态变更路径。乐观锁防超录模块通过版本号字段防止并发超录。

投递职位模块在求职者投递时执行实名认证校验、生成简历快照、自动创建聊天会话并通知 HR。简历快照机制在投递时刻将简历状态序列化为 JSON 存储，确保投递后简历修改不影响已投递记录。投递状态管理模块（HR 侧）支持从已投递到待面试到已录用或已淘汰的严格状态流转。投递状态查看模块（求职者侧）展示各状态对应的标签和提示信息。

消息通知模块在投递、面试邀请、录用和淘汰等关键节点自动发送系统通知。即时聊天模块在投递成功后自动创建会话，支持 WebSocket 点对点通信。运营日报统计模块每日凌晨通过定时任务统计 7 项运营数据，具备幂等保护。操作日志审计模块通过 AOP 切面记录关键操作，日志只追加不修改不删除。

管理员后台用户管理模块支持用户列表搜索、禁用恢复和设管理员（超级管理员专属）。管理员后台职位管理模块提供全状态职位列表筛选和违规职位下架。管理员后台统计看板模块展示累计数据总览和按日期范围筛选的趋势折线图。数据大屏可视化模块集成 KPI 总览、供需趋势、职位占比、地域流向、投递漏斗、热门岗位和实时动态等功能。超级管理员账号管理模块内置不可禁用不可删除的种子账号，拥有设管理员权限。

### 2.2.3 项目预期成果

**产品层面**：交付 UniSeek 兼职招聘平台，涵盖 Web 端和鸿蒙 App 端双入口，具备从用户注册到录用结算的全流程闭环能力，形成一套完整的"信息真实保障、即时沟通、流程透明、数据驱动"的服务体系。

**技术层面**：采用前后端分离加鸿蒙独立端的三端架构。后端分层架构（Controller/Service/DAO/Entity）职责清晰。前端 Vue 3 采用组合式 API 和 Pinia 状态管理，组件化程度高。鸿蒙端 ArkTS 严格遵循 HarmonyOS NEXT 设计规范，复用 HMOS 系统 Token。设计了一套跨端 CSS 变量和 Token 体系，在 Vue Admin、Vue 前端、ArkTS 三端保持视觉统一。实现了 JWT 无状态鉴权和 RBAC 角色权限控制。通过乐观锁解决了并发超录问题，通过定时任务实现了自动化运维。AOP 操作日志审计和统一异常处理机制保证了系统的可追溯性和健壮性。

**数据与业务层面**：沉淀了 14 张业务表的企业级数据库设计，验证了简历快照、投递状态机、运营日报等核心业务场景，积累了从需求分析到系统设计、编码实现、测试验证的完整工程经验。

---

## 2.3 相关工作计划安排

### 项目组成员

项目组成员包括项目经理 XXXXX、前端工程师 XXXXX 和后端工程师 XXXXX，各成员职责和互评情况如下。

项目经理 XXXXX 统筹项目整体进度，协调前后端联调，组织需求评审和代码审查，沟通积极主动，确保了项目按时交付，互评打分 95 分。

前端工程师 XXXXX（本人）完成鸿蒙端 ArkTS 求职者 App 28 个页面和 28 个组件及 20 个 Service 的开发，完成 Vue 数据大屏（Dashboard 工作台和 ScreenPreview 大屏页面）的开发，设计统一设计系统横跨三端，实现后端认证模块和投递模块及统计接口的开发，代码质量高，组件复用性强，互评打分 94 分。

后端工程师 XXXXX 搭建 Spring Boot 后端框架，完成 30 个功能模块的 API 开发，数据库设计合理，接口规范清晰，性能优化到位，互评打分 93 分。

### 项目甘特图

项目开发进度如下：需求分析阶段从 6 月 1 日开始，包含项目启动与需求调研（5 天）、需求文档编写（3 天）、数据库设计（3 天）。后端开发阶段包含环境搭建与基础框架（3 天）、用户认证模块（4 天）、企业资质模块（3 天）、职位管理模块（4 天）、投递管理模块（4 天）、聊天通知模块（3 天）、运营统计模块（3 天）。前端 Vue 开发阶段包含 Vue 基础框架搭建（3 天）、求职者端页面（6 天）、HR 端页面（4 天）、管理后台（4 天）、数据大屏（3 天）。鸿蒙开发阶段包含 ArkTS 环境搭建（2 天）、求职者端页面开发（8 天）、服务层与 API 对接（5 天）。测试与部署阶段包含接口联调测试（4 天）、功能测试与 Bug 修复（4 天）、部署上线与文档整理（3 天）。

---

# 第三章 项目阶段-本人负责模块的需求分析

## 总起

**需求分析的目标范围**：本章围绕本人负责的鸿蒙求职者端（ArkTS）、Vue 数据大屏（Vue 3）、后端系统（Java）以及全平台前端样式设计四个维度展开需求分析，明确各模块的功能定位、数据基础和服务边界。

**系统的技术/数据基础**：后端基于 Java 1.8 加 Spring Boot 2.2.2 加 MyBatis 加 MySQL 8，数据库共 14 张业务表涵盖平台全链路数据。前端数据大屏基于 Vue 3 加 TypeScript 加 Vite 加 Element Plus 加 Pinia 加 ECharts。鸿蒙端基于 ArkTS 6.1.1 加 HarmonyOS NEXT。各端通过统一 RESTful API 通信，采用 JWT 无状态鉴权。

**服务形式**：平台采用 B/S 架构的 Web 端和 C/S 架构的鸿蒙 App 端双入口，后端提供 JSON 格式 API 服务。数据大屏作为独立可视化模块面向运营管理员。

**面向的用户群体**：鸿蒙求职者端面向求职者（高校学生），提供在鸿蒙设备上的求职体验。Vue 数据大屏面向平台运营管理员，提供运营数据的可视化监控。后端 API 面向所有前端端，提供统一的数据接口和业务逻辑处理。

**需具备的核心能力**：鸿蒙端需要具备职位搜索与浏览、投递申请与状态跟踪、简历管理、即时聊天、消息通知等能力。数据大屏需要具备运营数据可视化展示、多维度数据筛选和趋势分析能力。后端需要具备认证鉴权、业务数据处理、WebSocket 通信和定时任务调度能力。

---

## 3.1 功能介绍

本人负责的模块覆盖了项目的四个技术维度。

鸿蒙求职者端基于 ArkTS 6.1.1 和 HarmonyOS NEXT，面向求职者（高校学生），提供职位浏览与搜索、职位投递、简历管理、即时聊天、收藏管理、个人中心等核心能力。该端是一个完整的鸿蒙原生应用，包含 28 个页面、28 个可复用组件和 20 个 Service，承担了求职者核心业务在鸿蒙设备上的前端展示与交互角色。

Vue 数据大屏基于 Vue 3 和 ECharts，面向运营管理员，提供 KPI 指标展示、供需趋势分析、职位占比分布、地域流向图、投递转化漏斗、实时动态等可视化能力。该部分由 Dashboard 工作台和 ScreenPreview 全屏大屏两个页面构成，承担了运营数据的可视化展示角色。

后端系统基于 Java 1.8 和 Spring Boot 2.2.2，面向全端提供 API 支持，包含认证鉴权、业务数据处理、数据统计分析、文件上传、WebSocket 通信、定时任务等能力。本人负责其中认证模块、投递模块、简历模块和统计模块的开发。

前端样式设计覆盖 Vue 前端（style.css）、Vue Admin（admin-theme.css）和 ArkTS（AppStyles.ets）三端，定义了统一的品牌色 #1762FB 以及间距、圆角、阴影、动画等视觉 Token，保证了三端视觉语言的一致性。

---

## 3.2 基础信息管理

本人负责模块中涉及的基础数据管理包括四个方面。

用户管理涉及手机号、邮箱、密码、昵称、角色（0 求职者、1 HR、9 管理员、99 超级管理员）和状态等数据，支持注册、登录、信息修改、密码修改和角色管理（超级管理员专属）等操作。

简历管理涉及性别、出生日期、学历、学校、技能标签（JSON 数组格式）、工作经历（富文本）和附件简历（PDF/Word）等数据，支持创建、编辑、附件上传和发布或取消发布到人才市场等操作。

分类管理涉及 30 条种子数据，采用两级树形结构（15 个顶级分类和 15 个子级分类），支持查询树形结构，前端缓存低频更新。

地区管理涉及 3432 条三级行政区划（省、市、区县），遵循 GB/T 2260 标准，支持三级渐进加载查询。

---

## 3.3 业务办理及信息查询

本人负责的业务功能覆盖了求职端和数据管理端两个维度。

在鸿蒙求职端方面，职位搜索与筛选支持按分类、地区、薪资范围、岗位类型和关键词等多维度搜索招聘中职位，分页加载。投递申请执行实名认证校验、简历快照生成、投递记录创建、聊天会话创建和 HR 通知的完整链路。面试管理允许求职者查看面试邀请（时间和地点），进行确认或反馈。录用确认支持查看录用通知并确认到岗。即时聊天与 HR 点对点沟通，支持文本和图片消息。收藏管理支持收藏或取消收藏感兴趣的职位。

在管理端方面，企业资质审核支持查看待审企业详情，进行通过或驳回操作并记录驳回原因通知 HR。职位审核支持查看待审职位详情，进行通过、驳回或下架操作。用户管理支持查看用户列表，禁用或恢复用户，超级管理员可设管理员。数据统计查询支持按日期范围查询运营数据，查看累计数据和每日趋势。操作日志审计支持按操作人、类型和时间筛选，查询不可修改的历史审计记录。

---

## 3.4 实时数据采集与显示

数据大屏模块负责实时统计和可视化展示平台运营数据。数据来源为后端 daily_statistics 日报统计表（每日 00:05 定时汇总）及各业务表的实时聚合查询。

展示的指标共九项。KPI 总览以指标卡片形式展示累计用户、认证企业、招聘中职位和投递总数，带较昨日增减趋势箭头。供需趋势以折线图展示近 7 天每日新增用户、职位、投递、面试和入职的趋势曲线。职位大类占比以环形图展示各职位分类的岗位数量占比。全国岗位流向以地域流向图展示各省份岗位需求分布与人才流向。投递转化漏斗以分段进度条展示从已投递到待面试到已录用到已完成的各阶段数量。企业资质审核以进度条展示待审核、已认证和已驳回企业数量分布。实名认证率以进度条展示已认证用户占比。热门岗位 TOP10 以排行榜列表展示投递量最高的 10 个岗位。实时动态以时间线列表滚动展示最新的用户注册、企业认证和职位发布等动态。

筛选排序操作方面，支持时间范围切换（24h、7d、30d、12m、10y），各图表数据随范围参数动态刷新。热门岗位按投递量降序排列，实时动态按时间倒序排列。

---

## 3.5 示例用例

### UC1：求职者投递职位

用例名称为求职者投递职位。参与者为求职者（已登录）。前置条件包括已完成实名认证、已创建在线简历、目标职位处于"招聘中"状态。后置条件包括投递记录创建成功、聊天会话自动创建、HR 收到系统通知。

主要成功场景为：求职者浏览职位列表，点击感兴趣的职位进入详情页。然后点击"投递"按钮。系统校验实名认证状态（已认证则继续）。系统校验职位状态（招聘中、未过期、有剩余名额）。系统校验未重复投递。系统读取当前简历数据，创建简历快照。系统插入投递记录，状态设为已投递。系统自动创建聊天会话关联该投递记录。系统向 HR 发送"新投递提醒"通知。前端跳转到"我的投递"页面，显示"已投递"状态。

### UC2：HR 审核投递

用例名称为 HR 审核求职者投递。参与者为企业 HR（已登录）。前置条件为有求职者投递了该 HR 发布的职位。后置条件为投递状态变更，求职者收到对应类型的通知。

主要成功场景为：HR 进入简历池页面，查看某职位下的投递列表。然后点击某条投递记录，查看简历快照。选择审核操作。如果邀请面试，填写面试时间和地点，系统状态更新为"待面试"，发送面试邀请通知。如果淘汰，填写淘汰原因，系统状态更新为"已淘汰"，发送淘汰通知。对于待面试的记录，面试后可操作录用（乐观锁扣减名额，发送录用通知）或继续淘汰。

### UC3：运营管理员审核企业资质

用例名称为运营管理员审核企业资质。参与者为运营管理员（角色值大于等于 9）。前置条件为有企业 HR 提交了企业资质（审核状态为待审）。后置条件为企业资质状态变更，HR 收到审核结果通知。

主要成功场景为：管理员进入企业资质审核页面，查看待审企业列表（按提交时间倒序）。然后点击某条记录进入详情页，查看企业完整信息（公司全称、信用代码、营业执照图片等）。如果审核通过，点击"通过"按钮，状态更新为已认证，通知 HR 资质已通过，可以发布职位了。如果审核驳回，填写驳回原因，状态维持待审，通知 HR 审核未通过并附上驳回原因。

---

# 第四章 项目阶段-本人负责模块的详细设计

## 4.1 模块概述

本人负责的模块由鸿蒙求职者端（ArkTS）、Vue 数据大屏（Vue 3）、Java 后端和样式设计系统四个部分组成。

鸿蒙求职者端由 28 个页面、28 个可复用组件、20 个 Service 和 9 个公共模块构成，负责求职者完整的求职体验，包括职位浏览、搜索筛选、投递申请、简历管理、即时聊天、收藏管理、个人中心等功能。其代码分为五个层级：entryability 层包含应用入口 Ability（EntryAbility.ets）；pages 层包含 28 个页面，包括求职者 Tab 页（首页、聊天、个人中心）、招聘方 Tab 页、职位详情页、搜索页、简历管理页、聊天详情页等；components 层包含 28 个可复用组件，分为聊天组件（15 个，如 MessageBubble、MessageInputBar 等）、筛选组件（9 个，如 FilterSheet、ChoiceChips 等）、职位卡片组件、投递相关组件、企业相关组件和通用组件（空状态视图、错误视图、加载更多）；services 层包含 20 个 Service，包括 ApiClient（HTTP 客户端封装）、AuthService（认证服务）、DataService（数据服务）、ChatService（聊天服务）、ChatWebSocketService（WebSocket 通信）、ResumeService（简历服务）、FavoriteService（收藏服务）等；common 层包含公共模块，如 AppStyles（全局样式 Token）、AppBootstrapPolicy（启动策略）、BusinessPolicies（业务策略）、FormValidators（表单校验器）等。

Vue 数据大屏由 Dashboard 工作台和 ScreenPreview 大屏页面构成，负责运营数据可视化展示。具体包括 src/pages/admin/Dashboard.vue（后台工作台，统计总览和待办事项）和 src/pages/ScreenPreview.vue（数据大屏，完整可视化页面）。API 层位于 src/api/admin.ts，封装了统计、企业审核、职位审核、用户管理和日志的接口。样式层包含 src/styles/style.css（全局 CSS 变量设计系统）和 src/styles/admin-theme.css（Admin 专属样式）。

Java 后端涉及认证模块、投递模块、简历模块和统计模块，为所有端提供统一 RESTful API。具体包括 auth 模块（认证数据传输对象和认证服务实现）、controller 层（AuthController、ResumeController、TaskController、ApplicationController）、admin/controller 层（AdminStatisticsController）、service/impl 层（业务服务实现）、dao 层（15 个 Mapper 接口）、entity 层（15 个实体类）、common 模块（统一异常处理、ApiResult、UserContext）、config 层（JwtAuthInterceptor、WebMvcConfig）、chat/websocket（WebSocket 聊天）和 util（JwtUtil、PasswordUtil 等工具类）。

样式设计系统包含 CSS 变量（Vue 的 style.css）、AppStyles Token（ArkTS 的 AppStyles.ets）和 Admin 主题（Vue Admin 的 admin-theme.css），统一品牌色 #1762FB，间距、圆角、阴影、动画系统三端对齐。

---

## 4.2 功能设计

### 鸿蒙求职者端——职位浏览与搜索功能

功能描述：求职者可以在首页浏览推荐职位列表，通过搜索页输入关键词搜索职位，使用筛选器按分类、地区、薪资、岗位类型等维度筛选。业务逻辑：首页加载时调用 DataService.getTaskList() 获取招聘中职位列表，支持分页下拉加载。搜索页调用 DataService.searchTasks() 传递关键词和筛选参数。筛选组件使用 FilterSheet 底部弹出面板，选择条件后重新请求数据。

### 鸿蒙求职者端——投递申请功能

功能描述：求职者在职位详情页点击投递按钮，完成投递申请，系统自动处理后续流程。业务逻辑：点击投递后首先调用 AuthService.checkRealName() 校验实名认证。认证通过后调用后端 POST /api/application/deliver 接口，后端依次校验职位状态、校验防重复投递、读取简历创建 JSON 快照、插入投递记录、创建聊天会话、发送通知给 HR，最后返回投递成功。

### 鸿蒙求职者端——即时聊天功能

功能描述：求职者与 HR 进行点对点即时通讯，支持文本和图片消息，投递成功后自动创建会话。业务逻辑：消息列表加载会话列表（ChatService.getSessionList()），按最后消息时间倒序排列，显示未读数量。点击进入聊天页加载最近 20 条消息（ChatService.getMessages()），上拉加载更多历史消息。发送消息通过 ChatWebSocketService 的 WebSocket 连接实时推送。

### Vue 数据大屏——KPI 指标展示功能

功能描述：大屏顶部展示 4 项核心 KPI 指标，包括累计用户、认证企业、招聘中职位、投递总数，并显示较昨日增减趋势。业务逻辑：调用 getScreenSummary(range) 接口获取汇总数据，前端按时间范围参数（24h、7d、30d、12m、10y）请求不同粒度的数据。指标卡使用渐变背景和趋势箭头动画，数据变化时触发数字滚动效果。

### Vue 数据大屏——供需趋势图功能

功能描述：展示选定时间范围内每日新增用户、新增职位、新增投递等趋势曲线，支持多系列对比。业务逻辑：调用 getScreenSummary(range) 获取 dailyList 数组，使用 ECharts 折线图渲染。X 轴为日期，Y 轴为数量，三个系列（新增用户、新增职位、新增投递）分别使用品牌蓝、成功绿、警告橙区分。图表含平滑曲线、渐变面积填充、悬停 tooltip 和自适应 resize。

### Java 后端——认证鉴权功能

功能描述：处理用户注册、登录、实名认证请求，生成和校验 JWT Token，实现角色权限控制。业务逻辑：注册时生成 16 字节随机盐值，MD5 加密存储密码。登录时查询用户盐值，拼接后 MD5 比对，生成 JWT Token（payload 含用户 ID 和角色），有效期 30 分钟。实名认证使用 Hutool 的 IdcardUtil.isValidCard() 校验身份证格式并计算年龄（须年满 16 周岁）。

### Java 后端——投递业务功能

功能描述：处理求职者的投递请求，以原子操作创建投递记录和相关关联数据。业务逻辑：第一步校验实名认证状态，第二步校验职位状态（招聘中、未过期、有名额），第三步校验防重复投递（利用 uk_task_applicant 唯一索引），第四步读取简历数据创建 JSON 快照，第五步插入投递记录，第六步创建聊天会话，第七步向 HR 发送系统通知。整个流程使用 @Transactional 保证数据一致性。

---

## 4.3 数据库设计

### user 表（用户表）

用户表存储平台所有用户信息，包含求职者、企业 HR、运营管理员、超级管理员四类角色。核心字段包括：id（BIGINT，主键自增）为用户 ID；phone（VARCHAR(11)，唯一非空）为手机号，用作登录账号；email（VARCHAR(100)，唯一非空）为邮箱；password（VARCHAR(64)，非空）为 MD5 加盐加密后的密码；salt（VARCHAR(32)，非空）为随机盐值；nickname（VARCHAR(50)）为昵称；avatar_url（VARCHAR(255)）为头像 URL；role（TINYINT，非空默认 0）表示角色，取值 0 求职者、1 HR、9 管理员、99 超级管理员；credit_score（INT，默认 100）为信用积分；status（TINYINT，默认 1）表示状态，0 禁用、1 正常；last_login_time 为最后登录时间；create_time 和 update_time 为创建和更新时间。索引方面，uk_phone 为手机号唯一索引，uk_email 为邮箱唯一索引，idx_role 为角色索引。

### resume 表（在线简历表）

简历表存储求职者的在线简历信息，与用户 1:1 绑定，支持全文检索和附件简历。核心字段包括：id（BIGINT，主键自增）为简历 ID；user_id（BIGINT，唯一，外键关联 user 表）为用户 ID；gender（TINYINT）为性别，0 男、1 女；birth_date（DATE）为出生日期；education（VARCHAR(20)）为学历；school（VARCHAR(50)）为毕业院校；skills（VARCHAR(500)）为技能标签，JSON 数组格式；experience（TEXT）为工作经历，富文本格式；attachment_url（VARCHAR(255)）为附件简历 URL；is_published（TINYINT，默认 0）表示是否发布到人才市场。索引方面，uk_user_id 为用户 ID 唯一索引，ft_experience 为经历字段的全文索引。

### task 表（职位表）

职位表存储企业 HR 发布的兼职职位信息。核心字段包括：id（BIGINT，主键自增）为职位 ID；enterprise_id（BIGINT，外键关联 enterprise 表）为所属企业；category_id（BIGINT，外键关联 category 表）为职位分类；region_id（BIGINT，外键关联 region 表）为工作地区；title（VARCHAR(100)，非空）为职位标题；description（TEXT，非空）为职位描述；salary_min 和 salary_max（INT，非空）为薪资上下限；salary_unit（TINYINT，非空）为薪资单位，0 日结、1 时薪、2 月结；job_type（TINYINT，默认 0）为岗位类型，0 全职、1 兼职、2 实习；total_quota（INT，非空）为招聘总人数；remaining_quota（INT，非空）为剩余名额；address（VARCHAR(200)）为工作地址；status（TINYINT，默认 0）为状态，0 待审、1 招聘中、2 已满员、3 已过期、4 已下架；deadline（DATETIME，非空）为报名截止时间；version（INT，默认 0）为乐观锁版本号。索引方面，idx_status_create 为 status 和 create_time 的复合索引，idx_category_status 加速分类筛选，idx_region_status 加速地区筛选。

### task_application 表（投递申请表）

投递申请表存储求职者的投递记录。核心字段包括：id（BIGINT，主键自增）为投递记录 ID；task_id（BIGINT，外键关联 task 表）为关联职位；applicant_id（BIGINT，外键关联 user 表）为投递人；employer_id（BIGINT，外键关联 user 表）为招聘方；resume_snapshot（JSON，非空）为简历快照；status（TINYINT，默认 0）为状态，0 已投递、1 待面试、2 待定、3 已录用、4 已淘汰、5 已完成；interview_time（DATETIME）为面试时间；interview_location（VARCHAR(200)）为面试地点；reject_reason（VARCHAR(500)）为淘汰原因；version（INT，默认 0）为乐观锁版本号。索引方面，uk_task_applicant 为 task_id 和 applicant_id 的联合唯一索引，防止重复投递。

### 其他核心表

enterprise（企业信息表）包含 id 和 user_id（外键关联 HR 用户）、company_name（公司全称）、credit_code（统一社会信用代码 18 位）、license_img_url（营业执照图片 URL）、industry（所属行业）、audit_status（审核状态，0 待审、1 已认证、2 驳回）、reject_reason（驳回原因）以及审计时间和创建更新时间。

chat_session（聊天会话表）包含 id 和 application_id（关联投递记录 ID）、employer_id 和 seeker_id（HR 用户 ID 和求职者用户 ID）、last_message 和 last_message_time（最后一条消息摘要和时间，避免聚合 chat_message 表提升性能）、unread_count（未读消息数）、status（0 活跃、1 关闭）。

chat_message（聊天消息表）包含 id 和 session_id（外键关联会话）、sender_id 和 sender_role（发送方 ID 和角色）、content 和 message_type（消息内容和类型，0 文本、1 图片）、is_read（是否已读）、send_time（发送时间）。

notification（消息通知表）包含 id、receiver_id、sender_id（NULL 表示系统自动发送）、title 和 content（标题和内容）、type（类型，0 系统、1 面试邀请、2 录用通知、3 淘汰通知）、is_read（是否已读）、biz_id（关联业务 ID）。

daily_statistics（日报统计表）包含 id 和 stat_date（唯一，统计日期）、new_users、new_enterprises、new_tasks、new_resumes、new_deliveries、new_interviews、new_entries 共 7 项新增计数。

operation_log（操作日志审计表）包含 id 和 operator_id（操作人 ID）、operation_type（操作类型编码）、target_type 和 target_id（操作目标和关联 ID）、detail（JSON 格式操作详情）、ip_address（IP 地址）、create_time（时间戳）。

---

## 4.4 系统界面设计

### 求职者首页界面（HomePage，鸿蒙端）

求职者首页采用 ArkUI 的 Column 作为根容器铺满全屏。顶部为自定义的 FilterBar 组件，包含标题文字、筛选按钮和搜索按钮，点击筛选按钮通过 bindSheet 绑定底部弹出面板 FilterSheet（SheetSize.LARGE），提供地区、薪资、分类等筛选条件的设置。主体区域使用 Tabs 容器组件实现三页面切换，包含"全职""兼职""实习"三个 TabContent 页面，barMode 设为 Scrollable 支持标签横向滚动，同时支持 scrollable 手势滑动切换。每个 TabContent 内嵌自定义组件 JobFeedList，使用 List 容器实现职位卡片列表，支持下拉刷新（Refresh 组件）和上拉加载更多（onReachEnd 回调）。职位卡片（JobFeedCard）使用 Row 和 Column 组合布局，展示职位标题、薪资范围（醒目红色大号字体）、公司名称、技能标签（Flex 弹性换行胶囊）和距离信息。页面整体采用响应式断点适配（通过 @StorageLink('breakpoint') 监听），内容区域使用 layoutWeight(1) 占满剩余空间。

### 职位详情页界面（JobDetailPage，鸿蒙端）

职位详情页使用 Column 根容器，顶部为 NavBar 自定义导航栏（标题"职位详情"，showBack 支持返回）。主体区域为 Scroll 可滚动容器（layoutWeight 占满），内部按垂直方向排列多个 StandardCard 自定义卡片组件。职位头部卡片展示职位标题和状态标签（Flex 胶囊），薪资以醒目大号红色字体展示，关键信息（岗位类型、工作地区、截止日期、剩余名额）使用 Flex 弹性换行布局排列为信息胶囊。HR 联系卡片展示头像（带首字母兜底）、HR 姓名和职位名称，右侧带右箭头图标，可点击跳转聊天页面。职位描述卡片按段落拆分逐行展示。公司信息卡片展示企业首字母Logo、企业名称、地址以及投递量/总名额/剩余名额三列统计。底部为固定在页面之外的独立操作栏，包含三个按钮：左侧收藏按钮（圆形，SymbolGlyph 填充状态切换）、中间主操作按钮（Capsule 胶囊样式，文字根据登录状态和投递状态动态变化为"投递""继续沟通""立即登录"）、右侧联系HR按钮（圆形）。点击投递触发完整的投递流程，依次执行实名认证校验和投递确认。

### 聊天页面界面（ChatDetailPage，鸿蒙端）

聊天页面使用 Stack 根容器支持覆盖层内容。顶部为 NavBar 自定义导航栏，通过 centerContent 插槽渲染聊天对方昵称、@企业名（可点击跳转企业详情）和关联职位标题。条件渲染的限制发送提示横幅（WARNING_BG 警告色背景）在使用者被限制时显示。当角色为招聘方时，固定显示 ApplicationStatusBar 投递状态操作栏支持录用/拒绝操作。中部消息区使用自定义 ChatMessageList 组件（layoutWeight 占满剩余空间），每条消息使用 MessageBubble 组件渲染——自己的消息气泡在右侧蓝底白字，对方消息在左侧灰底深色字，消息之间显示 MessageDateSeparator 时间分隔线。列表自动滚动到最新消息，上拉触发 onReachEnd 加载更早的历史消息（每次 20 条）。图片消息点击后触发 LightboxOverlay 覆盖层（全屏半透明背景 + 图片居中显示，可缩放预览）。底部为固定高度的 MessageInputBar 输入栏（高度 INPUT_BAR_HEIGHT），包含文本输入框、发送按钮和菜单触发按钮。点击菜单按钮通过 bindSheet 弹出底部 ActionMenuOverlay 操作抽屉，支持发送图片或发送简历。整个页面采用 KeyboardAvoidMode.RESIZE 模式，键盘弹起时整体上移。

### 数据大屏界面（ScreenPreview，Vue 端）

数据大屏的页面布局为顶部 KPI 指标卡片行（4 项核心指标，带趋势箭头），左侧为供需趋势折线图和职位大类占比环形图，中央为全国岗位流向图，下方为投递转化漏斗进度条、企业资质审核进度条和实名认证率进度条，右侧为热门岗位 TOP10 列表和实时动态时间线。可见元素包括指标数字与趋势箭头、ECharts 折线图、环形图、地图、分段进度条、排行榜列表、动态消息流和时间范围切换按钮。交互特点为时间范围切换（24h、7d、30d、12m、10y）、鼠标悬停图表查看数据详情、自适应全屏展示、暗色调主题。

### 管理后台工作台界面（Dashboard，Vue 端）

管理后台工作台的页面布局为顶部 4 个统计卡片（累计用户、认证企业、招聘中职位、投递总数），左侧为近 7 天趋势表格，右侧为待办事项面板。可见元素包括统计数字（渐变背景卡片）、每日新增数据表格（日期、新增用户、新增企业、新增职位、新增投递）、待审核企业数量、待审核职位数量、数据展示入口按钮。交互特点为点击待办项跳转对应审核页面、点击数据展示按钮进入全屏大屏页面、页面入场渐入动画。

---

# 第五章 项目阶段-本人负责模块的代码实现展示

## 5.1 项目结构

### 鸿蒙求职者端（ArkTS）目录结构

鸿蒙求职者端的代码根目录为 entry/src/main/ets/，其下分为 entryability、common、components、pages、services 五个子目录。

entryability 目录包含 EntryAbility.ets，为应用入口 Ability。common 目录包含全局样式 Token 文件 AppStyles.ets（定义颜色、间距、圆角、字体、阴影、动画）、应用启动策略 AppBootstrapPolicy.ets、业务策略 BusinessPolicies.ets、表单校验器 FormValidators.ets 和标准卡片组件 StandardCard.ets。

components 目录包含 28 个可复用组件，按功能划分为 chat（15 个聊天组件，如 MessageBubble、MessageInputBar 等）、filter（9 个筛选组件，如 FilterSheet、ChoiceChips 等）、job（职位卡片 JobCard、JobFeedCard）、application（投递相关组件如 ApplicationStatusBar 等）、enterprise（企业相关组件如 LicenseUploader、StatusBanner）以及通用组件 EmptyView.ets（空状态视图）、ErrorView.ets（错误视图）、LoadMoreFooter.ets（加载更多）。

pages 目录包含 28 个页面，包括求职者 Tab 页（HomePage、ChatPage、ProfilePage）、招聘方 Tab 页（3 个）、JobDetailPage（职位详情）、SearchPage（搜索）、ResumePage（简历管理）、ChatDetailPage（聊天详情）、FavoritesPage（收藏管理）、LoginPage（登录）、RegisterPage（注册）等。

services 目录包含 20 个 Service，包括 ApiClient.ets（HTTP 客户端单例封装）、AuthService.ets（认证服务）、DataService.ets（数据服务）、ChatService.ets（聊天服务）、ChatWebSocketService.ets（WebSocket 通信）、ResumeService.ets（简历服务）、FavoriteService.ets（收藏服务）等。

### Vue 数据大屏目录结构

Vue 数据大屏的 api 目录包含 admin.ts，封装统计、审核、用户管理和日志的 API 接口。pages 目录包含 admin/Dashboard.vue（管理后台工作台）和 ScreenPreview.vue（数据大屏，含 ECharts 图表）。styles 目录包含 style.css（全局 CSS 变量设计系统）和 admin-theme.css（Admin 主题样式）。此外还有 router/index.ts（路由配置）和 stores（Pinia 状态管理）。

### Java 后端目录结构（涉及模块）

Java 后端的 auth 目录包含 dto（认证相关 DTO，如 LoginRequest、RegisterRequest、UserVO 等）和 service/impl（认证服务实现，处理注册、登录、实名认证）。controller 目录包含 AuthController.java（认证接口）、ResumeController.java（简历接口）、TaskController.java（职位接口）、ApplicationController.java（投递接口）。admin/controller 目录包含 AdminStatisticsController.java（统计接口）。service/impl 为业务服务实现层。dao 为数据访问层，包含 15 个 Mapper 接口。entity 为实体层，包含 15 个实体类。common 目录包含 exception（统一异常处理）、ApiResult.java（统一响应格式）和 util/UserContext.java（用户上下文，ThreadLocal 存储）。config 目录包含 JwtAuthInterceptor.java（JWT 鉴权拦截器）和 WebMvcConfig.java（Web MVC 配置）。chat/websocket 目录包含 ChatWebSocketHandler.java 和 WebSocketConfig.java。util 目录包含 JwtUtil.java 和 PasswordUtil.java 等工具类。

---

## 5.2 关键代码及说明

### JWT 鉴权拦截器实现

文件路径为 uniseek_java/src/main/java/com/uniseek/config/JwtAuthInterceptor.java。

```java
@Component
public class JwtAuthInterceptor implements HandlerInterceptor {

    @Autowired
    private JwtUtil jwtUtil;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response,
                             Object handler) throws Exception {
        String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new UnauthorizedException("未登录或Token已过期");
        }
        String token = authHeader.substring(7);
        if (!jwtUtil.validateToken(token)) {
            throw new UnauthorizedException("Token无效或已过期");
        }
        Long userId = jwtUtil.getUserIdFromToken(token);
        Integer role = jwtUtil.getRoleFromToken(token);
        String path = request.getRequestURI();
        if (path.startsWith("/api/admin/") && role < 9) {
            throw new UnauthorizedException("权限不足");
        }
        if (path.startsWith("/api/enterprise/") && role != 1) {
            throw new UnauthorizedException("仅企业HR可操作");
        }
        UserContext.set(userId, role);
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response,
                                Object handler, Exception ex) {
        UserContext.clear();
    }
}
```

实现逻辑说明：该拦截器实现了全系统的统一鉴权入口。首先从 Authorization 请求头提取 Bearer Token，使用 JwtUtil 验证 Token 的签名有效性和有效期。验证通过后从 Token payload 中解析出用户 ID 和角色值，按照请求 URL 的路径前缀执行 RBAC 角色权限匹配。/api/admin/ 路径要求角色值大于等于 9，/api/enterprise/ 路径要求角色值为 1。校验通过后将用户信息存入 ThreadLocal，供 Controller 和 Service 层直接获取，无需从请求参数中重复解析。请求结束后在 afterCompletion 中清除 ThreadLocal，避免内存泄漏。

### 投递业务服务实现

文件路径为 uniseek_java/src/main/java/com/uniseek/service/impl/ApplicationServiceImpl.java。

```java
@Service
@Transactional(rollbackFor = Exception.class)
public class ApplicationServiceImpl implements ApplicationService {

    @Autowired
    private TaskMapper taskMapper;
    @Autowired
    private TaskApplicationMapper applicationMapper;
    @Autowired
    private ResumeMapper resumeMapper;
    @Autowired
    private ChatSessionMapper chatSessionMapper;
    @Autowired
    private NotificationService notificationService;

    @Override
    public ApiResult<Void> deliver(Long taskId) {
        Long applicantId = UserContext.getUserId();
        // 1. 校验实名认证（省略实名校验逻辑）
        // 2. 校验职位状态（招聘中、未过期、有名额）
        Task task = taskMapper.selectById(taskId);
        if (task == null || task.getStatus() != 1) {
            return ApiResult.error(400, "职位不可投递");
        }
        if (task.getDeadline().before(new Date())) {
            return ApiResult.error(400, "已过报名截止时间");
        }
        if (task.getRemainingQuota() <= 0) {
            return ApiResult.error(400, "名额已满");
        }
        // 3. 校验重复投递（唯一索引防重）
        QueryWrapper<TaskApplication> query = new QueryWrapper<>();
        query.eq("task_id", taskId).eq("applicant_id", applicantId);
        if (applicationMapper.selectCount(query) > 0) {
            return ApiResult.error(409, "已投递过该职位");
        }
        // 4. 读取简历，创建快照
        Resume resume = resumeMapper.selectOne(
            new QueryWrapper<Resume>().eq("user_id", applicantId));
        String resumeSnapshot = JSON.toJSONString(resume);
        // 5. 创建投递记录
        TaskApplication application = new TaskApplication();
        application.setTaskId(taskId);
        application.setApplicantId(applicantId);
        application.setEmployerId(task.getPublisherId());
        application.setResumeSnapshot(resumeSnapshot);
        application.setStatus(0);
        applicationMapper.insert(application);
        // 6. 自动创建聊天会话
        ChatSession session = new ChatSession();
        session.setApplicationId(application.getId());
        session.setEmployerId(task.getPublisherId());
        session.setSeekerId(applicantId);
        session.setStatus(0);
        chatSessionMapper.insert(session);
        // 7. 发送通知给HR
        notificationService.send(
            task.getPublisherId(), null,
            "新投递提醒",
            "有求职者投递了职位：" + task.getTitle(),
            0, application.getId()
        );
        return ApiResult.success("投递成功");
    }
}
```

实现逻辑说明：投递服务是整个平台最核心的业务方法之一，包含完整的业务校验链。首先是实名认证校验作为前置条件，然后校验职位状态（招聘中、未过期、有名额），接着利用唯一索引校验防重复投递。校验通过后，读取求职者的最新简历数据序列化为 JSON 字符串作为简历快照，确保投递后简历修改不影响已投递记录。然后以原子操作（@Transactional）完成三件事：插入投递记录、创建聊天会话、发送系统通知给 HR。

### 鸿蒙端 HTTP 客户端封装

文件路径为 uniseek_arkts/entry/src/main/ets/services/ApiClient.ets。

```typescript
import http from '@ohos.net.http';
import { BusinessError } from '@kit.BasicServicesKit';

export class ApiClient {
  private static instance: ApiClient;
  private baseUrl: string = 'http://10.0.2.2:8080/api';
  private token: string = '';

  static getInstance(): ApiClient {
    if (!ApiClient.instance) {
      ApiClient.instance = new ApiClient();
    }
    return ApiClient.instance;
  }

  setToken(token: string): void { this.token = token; }

  async get<T>(path: string, params?: Record<string, string>): Promise<T> {
    let url = this.baseUrl + path;
    if (params) {
      const query = Object.entries(params)
        .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
        .join('&');
      url += '?' + query;
    }
    return this.request<T>(url, http.RequestMethod.GET);
  }

  async post<T>(path: string, body?: object): Promise<T> {
    return this.request<T>(this.baseUrl + path, http.RequestMethod.POST, body);
  }

  async put<T>(path: string, body?: object): Promise<T> {
    return this.request<T>(this.baseUrl + path, http.RequestMethod.PUT, body);
  }

  private async request<T>(url: string, method: http.RequestMethod,
                           body?: object): Promise<T> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: method,
        header: {
          'Content-Type': 'application/json',
          'Authorization': this.token ? `Bearer ${this.token}` : ''
        },
        extraData: body ? JSON.stringify(body) : undefined,
        connectTimeout: 10000,
        readTimeout: 10000,
      } as http.HttpRequestOptions);
      const result = JSON.parse(response.result as string) as ApiResult<T>;
      if (result.code !== 200) {
        throw new BusinessError(result.message, result.code);
      }
      return result.data;
    } finally {
      httpRequest.destroy();
    }
  }
}
```

实现逻辑说明：该代码使用 HarmonyOS 原生网络请求 SDK（@ohos.net.http）封装了统一的 HTTP 客户端。采用单例模式确保全局只有一个 ApiClient 实例。提供 get、post、put 三个方法，自动从 UserSession 获取并注入 JWT Token 到请求头中，统一解析后端返回的标准 ApiResult 响应格式，对非 200 状态码统一抛出 BusinessError 异常。超时时间统一设置为 10 秒，网络请求完成后在 finally 块中销毁 HTTP 连接资源，避免资源泄漏。

---

# 第六章 项目阶段-本人负责模块的测试与功能展示

## 6.1 测试用例

TC-001 用户注册。测试步骤为填写手机号 13800138000、邮箱 test@uniseek.com、密码 abc123456、昵称张三，选择求职者身份，点击注册。预期结果为注册成功，返回 JWT Token，跳转至求职者首页。执行结果为注册成功，session 中存储 Token。达到预期。

TC-002 职位搜索。测试步骤为在首页搜索框输入"服务员"，选择分类为"餐饮服务"，点击搜索。预期结果为展示标题或分类匹配"服务员"的招聘中职位列表。执行结果为正确展示匹配结果。达到预期。

TC-003 投递职位。测试步骤为进入某招聘中职位详情页，点击投递按钮。预期结果为投递成功，聊天会话自动创建，HR 收到通知。执行结果为投递记录创建成功，聊天列表出现新会话。达到预期。

TC-004 HR 审核投递。测试步骤为 HR 进入简历池，查看某投递记录，选择"邀请面试"并填写面试信息。预期结果为投递状态变更为"待面试"，求职者收到面试通知。执行结果为状态变更成功，通知发送成功。达到预期。

TC-005 数据大屏展示。测试步骤为管理员进入数据大屏页面，切换时间范围为"30d"。预期结果为 KPI 卡片数据更新，各图表按 30 天粒度展示趋势。执行结果为图表正常渲染，数据随参数变化。达到预期。

TC-006 实名认证拦截。测试步骤为未实名认证的求职者点击投递。预期结果为弹出实名认证弹窗，提示"请先完成实名认证"。执行结果为弹窗正常展示，引导用户完成认证。达到预期。

---

## 6.2 功能展示

### 鸿蒙求职者端——首页

求职者进入 App 后的主界面，顶部搜索框支持关键词搜索，下方横向滚动分类芯片（兼职、全职、实习），主力区域为纵向职位 Feed 流卡片列表。支持下拉刷新获取最新职位，上拉加载更多。职位卡片展示标题、薪资范围、公司名称、标签和距离信息，点击进入详情页。

### 鸿蒙求职者端——职位详情页

完整展示职位信息，包含标题、薪资范围与单位、公司名称与行业、工作地址、富文本描述的职位详情、招聘名额与截止时间。底部固定操作栏包含收藏按钮和投递按钮。点击投递触发完整投递流程，包含实名认证校验、状态校验、创建投递记录等后端操作。

### 鸿蒙求职者端——聊天页

展示与 HR 的会话列表，按最后消息时间倒序排列，未读消息以红点徽标提示。进入会话后展示历史消息，自己的消息以蓝色气泡居右，对方消息以灰色气泡居左。底部输入栏支持文本和图片发送，上拉可加载更多历史消息。

### 鸿蒙求职者端——简历管理页

求职者编辑在线简历，包含学历（预定义列表选择）、毕业院校、技能标签（JSON 数组）、工作经历（富文本编辑器）等字段。支持 PDF 附件简历上传（不超过 10MB），可切换简历发布状态（发布到人才市场或暂不发布）。

### 鸿蒙求职者端——我的投递页

展示求职者所有投递记录列表，每条记录显示职位标题、企业名称、投递时间和当前状态标签（已投递为灰色、待面试为蓝色、已录用为绿色、已淘汰为红色等），点击可查看详情。

### Vue 数据大屏

运营数据可视化页面，核心功能模块包括九个部分。KPI 指标卡展示顶部 4 项核心指标（累计用户、认证企业、招聘中职位、投递总数），带较昨日增减趋势箭头。供需趋势折线图使用 ECharts 渲染，展示选定时间范围内每日新增用户、职位和投递的趋势。职位大类占比环形图展示各分类岗位数量占比。全国岗位流向图展示各省份岗位需求分布的地域流向。投递转化漏斗进度条分段展示从已投递到待面试到已录用到已完成的各阶段数量。企业资质审核进度条展示待审核、已认证和已驳回的企业分布。实名认证率进度条展示已认证用户占比。热门岗位 TOP10 排行榜列出投递量最高的 10 个岗位。实时动态时间线滚动展示最新的用户注册、企业认证和职位发布等动态。

### Java 后端 API 接口

后端 API 接口主要包括 POST /api/auth/register 用户注册、POST /api/auth/login 用户登录、POST /api/auth/real-name 实名认证、PUT /api/resume 创建或更新简历、POST /api/task/publish 发布职位、POST /api/application/deliver 投递职位、PUT /api/application/status 更新投递状态、POST /api/chat/message/send 发送聊天消息、GET /api/admin/statistics/summary 大屏 KPI 汇总、GET /api/admin/statistics/categories 职位大类占比。以上接口均测试通过。

---

# 第七章 实训总结

## 项目整体回顾

本次实训历时约 8 周，从需求分析、系统设计、编码实现到测试部署，完整经历了一个企业级 Web 加移动端项目的全生命周期。UniSeek 优寻兼职招聘平台最终交付了包括 Vue 3 前端网站、ArkTS 鸿蒙 App、Java Spring Boot 后端 API 和数据可视化大屏在内的完整产品。

作为项目核心开发成员，我负责了鸿蒙求职者端（ArkTS 28 个页面、28 个组件、20 个 Service）、Vue 数据大屏（Dashboard 工作台加 ScreenPreview 大屏页面）、后端部分模块（认证、投递、统计）以及全平台前端样式设计（CSS 变量加 ArkTS Token）。这一过程不仅锻炼了我在多端开发中的技术能力，更让我深刻理解了工程化思维在实际项目中的重要性。

## 技术实践收获

### 鸿蒙 ArkTS 开发能力

首次系统性使用 ArkTS 语言开发 HarmonyOS NEXT 应用，深入理解了声明式 UI 开发范式、@Component 组件化设计、@State/@Prop/@Link 数据流转机制，以及 HarmonyOS 的权限管理、网络请求、WebSocket 等原生 API。掌握了如何将 HMOS 系统 Token（$r('sys.color.*')）与业务语义色有机结合，实现自动适配深浅色主题。

### 前后端分离架构实践

通过参与 Java Spring Boot 后端的开发（认证模块、投递模块），深入理解了分层架构（Controller 到 Service 到 DAO 到 Entity）的职责划分、JWT 无状态鉴权的实现原理、乐观锁在并发场景下的应用、以及 AOP 面向切面编程在日志审计中的落地。

### 数据可视化能力

使用 ECharts 实现了数据大屏的多种图表（折线图、环形图、地域流向图等），掌握了 ECharts 的配置项体系、数据驱动的渲染机制、响应式适配和主题定制。同时通过设计时间范围切换功能，理解了不同粒度数据聚合的策略。

### 设计系统搭建

从零搭建了一套横跨 Vue 前端、Vue Admin、ArkTS 三端的统一设计系统，定义了品牌色 #1762FB 以及间距、圆角、阴影、动画等视觉 Token。这一实践让我深刻认识到设计系统在保证产品视觉一致性、提升开发效率方面的重要价值。

### 数据库设计与优化

参与了 14 张业务表的数据库设计，理解了唯一索引防重复投递、复合索引加速多条件查询、全文索引支持简历关键词搜索、乐观锁版本号防超录等数据库设计技巧。同时通过 SET NULL 外键策略、ON DELETE RESTRICT 约束等了解了生产环境下的数据完整性保障。

### 工程化工具使用

熟练使用了 Git 版本控制、Maven 项目构建、Vite 前端构建工具、Hvigor 鸿蒙构建工具，以及 Postman API 测试等工程化工具，提升了开发效率和团队协作能力。

## 个人能力成长

### 工程化思维

从最初"能跑就行"的编码心态，转变为企业级工程化思维——代码要分层、异常要处理、接口要规范、数据要一致。理解了良好的架构设计比炫技的代码更重要。

### 问题解决能力

在开发过程中遇到了诸多实际问题：鸿蒙模拟器网络请求配置、WebSocket 断线重连、前后端联调跨域问题、ECharts 大数据量渲染性能等。通过查阅官方文档、搜索引擎和团队讨论，逐一攻克了这些难题。

### 团队协作

项目采用前后端分离开发模式，前后端通过 API 文档（api.md）协同。我作为同时参与前后端的开发者，在接口定义、联调测试中起到了桥梁作用，帮助团队成员快速定位问题，提高了协作效率。

## 未来展望

UniSeek 作为一个实训项目，虽然核心功能已基本完成，但仍有许多可以持续优化的方向：接入支付系统实现薪资在线结算、引入即时通讯的已读回执和消息撤回功能、基于用户行为数据的智能推荐算法、以及更多端（iOS 和 Android）的覆盖。这些方向也是我后续学习和实践的重点。

---

# 第八章 实训评定

## 学生自我鉴定

在本学期实训中，我负责了 UniSeek 优寻兼职招聘平台中**鸿蒙求职者端（ArkTS 28 个页面、28 个组件、20 个 Service）**、**Vue 数据大屏（Dashboard 工作台加数据大屏）**、**后端部分模块（认证、投递、统计）**、以及**全平台前端样式设计（CSS 变量加 ArkTS Token）** 的开发工作。

通过本次实训，我不仅掌握了 ArkTS 鸿蒙应用开发、Vue 3 组合式 API、Spring Boot 后端开发等技术栈，更重要的是建立了工程化思维——从需求分析到系统设计，从编码规范到测试验证，每一个环节都需要严谨的思考和规范的操作。项目过程中遇到的技术难题（如乐观锁并发控制、WebSocket 通信、多端视觉一致性）都在团队协作和个人钻研下得到解决。

本次实训让我对软件工程的全流程有了切身体会，也认识到自己在系统架构设计、性能优化等方面还有待提升。未来我将继续深入鸿蒙应用开发和后端架构的学习，争取在下一个项目中承担更核心的技术角色。

---

**班级**：XXXXX  
**姓名**：XXXXX  
**日期**：2026年  月  日
