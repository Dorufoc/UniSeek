# 第三章 项目阶段——本人负责模块的需求分析

## 总起

**需求分析的目标范围**：本章围绕本人负责的鸿蒙求职者端（ArkTS）、Vue 数据大屏（Vue 3）以及后端系统（Java）三个维度展开需求分析，明确各模块的功能定位、数据基础和服务边界。

**系统的技术/数据基础**：后端基于 Java 1.8 + Spring Boot 2.2.2 + MyBatis + MySQL 8，数据库共 14 张业务表涵盖平台全链路数据；前端基于 Vue 3 + TypeScript + Vite + Element Plus + Pinia + ECharts；鸿蒙端基于 ArkTS 6.1.1 + HarmonyOS NEXT。各端通过统一 RESTful API 通信，采用 JWT 无状态鉴权。

**服务形式**：平台采用 B/S 架构的 Web 端 + C/S 架构的鸿蒙 App 端双入口，后端提供 JSON 格式 API 服务。管理后台和数据大屏仅限运营管理员访问。

**面向的用户群体**：求职者（高校学生）——使用鸿蒙 App 或 Web 端浏览和投递职位；运营管理员——使用管理后台和数据大屏进行审核与数据监控。

**需具备的核心能力**：职位搜索与浏览、投递申请与状态跟踪、简历管理、即时聊天、消息通知、运营数据可视化展示、企业资质审核、用户权限管理。

---

## 3.1 功能介绍

本人负责的模块覆盖了项目的三个技术端，各端的核心功能定位如下：

| 端 | 技术栈 | 面向用户 | 核心能力 |
|----|--------|---------|---------|
| **鸿蒙求职者端** | ArkTS 6.1.1 + HarmonyOS NEXT | 求职者（高校学生） | 职位浏览与搜索、职位投递、简历管理、即时聊天、收藏管理、个人中心 |
| **Vue 数据大屏** | Vue 3 + ECharts | 运营管理员 | KPI 指标展示、供需趋势分析、职位占比分布、地域流向图、投递转化漏斗、实时动态 |
| **后端系统** | Java 1.8 + Spring Boot 2.2.2 | 全端（提供 API 支持） | 认证鉴权、业务数据处理、数据统计分析、文件上传、WebSocket 通信、定时任务 |

在整个系统中，鸿蒙求职者端承担了求职者核心业务的前端展示与交互角色，Vue 数据大屏承担了运营数据的可视化展示角色，后端系统则为所有端提供统一的数据接口和业务逻辑处理能力。

---

## 3.2 基础信息管理

本人负责模块中涉及的基础数据管理包括：

| 数据类型 | 管理内容 | 支持操作 |
|---------|---------|---------|
| **用户管理** | 手机号、邮箱、密码、昵称、角色（0 求职者 / 1 HR / 9 管理员 / 99 超级管理员）、状态 | 注册、登录、信息修改、密码修改、角色管理（超级管理员专属） |
| **简历管理** | 性别、出生日期、学历、学校、技能标签（JSON 数组）、工作经历（富文本）、附件简历（PDF/Word） | 创建、编辑、附件上传、发布/取消发布到人才市场 |
| **分类管理** | 30 条种子数据，两级树形结构（15 个顶级分类 + 15 个子级分类） | 查询树形结构（前端缓存，低频更新） |
| **地区管理** | 3432 条三级行政区划（省/市/区县），GB/T 2260 标准 | 三级渐进加载查询 |

---

## 3.3 业务办理及信息查询

### 求职端（鸿蒙 App + Vue Web）

| 业务功能 | 说明 |
|---------|------|
| **职位搜索与筛选** | 按分类、地区、薪资范围、岗位类型、关键词多维度搜索招聘中职位，分页加载 |
| **投递申请** | 实名认证校验 → 简历快照 → 创建投递记录 → 创建聊天会话 → 通知 HR |
| **面试管理** | 查看面试邀请（时间/地点），确认或反馈 |
| **录用确认** | 查看录用通知，确认到岗 |
| **即时聊天** | 与 HR 点对点沟通，支持文本和图片消息 |
| **收藏管理** | 收藏/取消收藏感兴趣的职位 |

### 管理端（Vue 后台 + 数据大屏）

| 业务功能 | 说明 |
|---------|------|
| **企业资质审核** | 查看待审企业详情，通过/驳回，记录驳回原因并通知 HR |
| **职位审核** | 查看待审职位详情，通过/驳回/下架违规职位 |
| **用户管理** | 查看用户列表，禁用/恢复用户，超级管理员可设管理员 |
| **数据统计查询** | 按日期范围查询运营数据，查看累计数据（总览）和每日趋势（列表/折线图） |
| **操作日志审计** | 按操作人/类型/时间筛选，查询不可修改的历史审计记录 |

---

## 3.4 实时数据采集与显示

数据大屏模块负责实时统计和可视化展示平台运营数据，数据来源为后端 `daily_statistics` 日报统计表（每日 00:05 定时汇总）及各业务表的实时聚合查询。

| 数据指标 | 呈现形式 | 说明 |
|---------|---------|------|
| KPI 总览 | 指标卡片（数字 + 趋势箭头） | 累计用户、认证企业、招聘中职位、投递总数 |
| 供需趋势 | 折线图 | 近 7 天每日新增用户/职位/投递/面试/入职趋势 |
| 职位大类占比 | 环形图 | 各职位分类的岗位数量占比 |
| 全国岗位流向 | 地域流向图 | 各省份岗位需求分布与人才流向 |
| 投递转化漏斗 | 进度条 | 已投递 → 待面试 → 已录用 → 已完成各阶段数量 |
| 企业资质审核 | 进度条 | 待审核/已认证/已驳回企业数量分布 |
| 实名认证率 | 进度条 | 已认证用户占比 |
| 热门岗位 TOP10 | 排行榜列表 | 投递量最高的 10 个岗位 |
| 实时动态 | 时间线列表 | 最新的用户注册、企业认证、职位发布等动态 |

**筛选排序操作**：支持时间范围切换（24h / 7d / 30d / 12m / 10y），各图表数据随范围参数动态刷新。热门岗位按投递量降序排列，实时动态按时间倒序排列。

---

## 3.5 示例用例

### UC1：求职者投递职位

| 项目 | 内容 |
|------|------|
| **用例名称** | 求职者投递职位 |
| **参与者** | 求职者（已登录） |
| **前置条件** | 已完成实名认证，已创建在线简历，目标职位处于"招聘中"状态 |
| **后置条件** | 投递记录创建成功，聊天会话自动创建，HR 收到系统通知 |
| **主要成功场景** | ① 求职者浏览职位列表，点击感兴趣的职位进入详情页 → ② 点击"投递"按钮 → ③ 系统校验实名认证状态（已认证则继续） → ④ 系统校验职位状态（招聘中、未过期、有剩余名额） → ⑤ 系统校验未重复投递 → ⑥ 系统读取当前简历数据，创建简历快照 → ⑦ 系统插入投递记录（status=0 已投递） → ⑧ 系统自动创建聊天会话（关联该投递记录） → ⑨ 系统向 HR 发送"新投递提醒"通知 → ⑩ 前端跳转到"我的投递"页面，显示"已投递"状态 |

### UC2：HR 审核投递

| 项目 | 内容 |
|------|------|
| **用例名称** | HR 审核求职者投递 |
| **参与者** | 企业 HR（已登录） |
| **前置条件** | 有求职者投递了该 HR 发布的职位 |
| **后置条件** | 投递状态变更，求职者收到对应类型的通知 |
| **主要成功场景** | ① HR 进入简历池页面，查看某职位下的投递列表 → ② 点击某条投递记录，查看简历快照 → ③ 选择审核操作：**邀请面试**（填写面试时间地点）→ 系统状态更新为"待面试（1）"→ 发送面试邀请通知；或**淘汰**（填写淘汰原因）→ 系统状态更新为"已淘汰（4）"→ 发送淘汰通知 → ④ 对于待面试的记录，面试后可操作：**录用**（乐观锁扣减名额，发送录用通知）或继续淘汰 |

### UC3：运营管理员审核企业资质

| 项目 | 内容 |
|------|------|
| **用例名称** | 运营管理员审核企业资质 |
| **参与者** | 运营管理员（role ≥ 9） |
| **前置条件** | 有企业 HR 提交了企业资质（audit_status=0） |
| **后置条件** | 企业资质状态变更，HR 收到审核结果通知 |
| **主要成功场景** | ① 管理员进入企业资质审核页面 → ② 查看待审企业列表（按提交时间倒序） → ③ 点击某条记录进入详情页 → ④ 查看企业完整信息（公司全称、信用代码、营业执照图片等） → ⑤ **审核通过**：点击"通过"→ 状态更新为已认证（1）→ 通知 HR"资质已通过，可以发布职位了"；**审核驳回**：填写驳回原因 → 状态维持待审（0）→ 通知 HR"审核未通过，原因：[驳回原因]" |

---

# 第四章 项目阶段——本人负责模块的详细设计

## 4.1 模块概述

本人负责的模块由以下部分组成：

| 模块 | 构成 | 简要职责 |
|------|------|---------|
| **鸿蒙求职者端** | 28 个页面 + 28 个组件 + 20 个 Service + 9 个公共模块 | 求职者完整的求职体验，包括职位浏览、搜索筛选、投递申请、简历管理、即时聊天、收藏、个人中心等 |
| **Vue 数据大屏** | Dashboard 工作台 + ScreenPreview 大屏页面 | 运营数据可视化展示，KPI 指标、趋势图、饼图、地域流向、转化漏斗 |
| **Java 后端** | 认证模块 + 用户模块 + 企业模块 + 职位模块 + 投递模块 + 聊天模块 + 通知模块 + 统计模块 + 日志模块 | 为所有端提供统一 RESTful API，处理业务逻辑、数据持久化、鉴权控制 |
| **样式设计系统** | CSS 变量（Vue）+ AppStyles Token（ArkTS）+ Admin 主题（Vue Admin） | 统一品牌色 #1762FB，间距/圆角/阴影/动画系统三端对齐 |

### 鸿蒙求职者端架构

```
ets/
├── entryability/         # 应用入口 Ability（EntyAbility.ets）
├── pages/                # 28 个页面
│   ├── tab/seeker/       # 求职者 Tab 页（首页/聊天/个人中心）
│   ├── tab/recruiter/    # 招聘方 Tab 页（首页/聊天/个人中心）
│   ├── JobDetailPage.ets # 职位详情
│   ├── SearchPage.ets    # 搜索
│   ├── ResumePage.ets    # 简历管理
│   ├── ChatDetailPage.ets# 聊天详情
│   └── ...               # 其他功能页
├── components/           # 28 个可复用组件
│   ├── chat/             # 聊天组件（15 个：MessageBubble、MessageInputBar 等）
│   ├── filter/           # 筛选组件（9 个：FilterSheet、ChoiceChips 等）
│   ├── job/              # 职位卡片组件
│   ├── application/      # 投递相关组件
│   └── common/           # 通用组件（EmptyView、ErrorView、LoadMoreFooter）
├── services/             # 20 个 Service
│   ├── ApiClient.ets     # HTTP 客户端封装
│   ├── AuthService.ets   # 认证服务
│   ├── DataService.ets   # 数据服务
│   ├── ChatService.ets   # 聊天服务
│   ├── ResumeService.ets # 简历服务
│   └── ChatWebSocketService.ets  # WebSocket 通信
└── common/               # 公共模块（样式常量、业务策略、表单校验）
```

### Vue 数据大屏架构

```
src/
├── pages/
│   ├── admin/
│   │   └── Dashboard.vue     # 后台工作台（统计总览 + 待办事项）
│   └── ScreenPreview.vue     # 数据大屏（完整可视化页面）
├── api/
│   └── admin.ts              # 管理后台 API（统计/企业审核/职位审核/用户管理/日志）
├── styles/
│   ├── style.css             # 全局 CSS 变量（设计系统）
│   └── admin-theme.css       # Admin 专属样式
├── router/index.ts           # 路由配置
└── stores/                   # Pinia 状态管理
```

### Java 后端（涉及模块）架构

```
com.uniseek/
├── auth/dto/            # 认证数据传输对象
├── auth/service/impl/   # 认证服务实现
├── controller/          # 控制器层
│   ├── AuthController.java
│   ├── ResumeController.java
│   ├── TaskController.java
│   └── ApplicationController.java
├── admin/controller/    # 管理后台控制器
│   ├── AdminStatisticsController.java
│   └── AdminTaskController.java
├── service/impl/        # 业务服务实现层
├── dao/                 # 数据访问层（15 个 Mapper 接口）
├── entity/              # 实体层（15 个实体类）
├── common/              # 公共模块（统一异常处理、ApiResult、UserContext）
├── config/              # 配置层（JWT 拦截器、WebMvc 配置）
├── chat/websocket/      # WebSocket 聊天
└── util/                # 工具类（JwtUtil、PasswordUtil）
```

---

## 4.2 功能设计

### 4.2.1 鸿蒙求职者端——职位浏览与搜索功能

| 项目 | 内容 |
|------|------|
| **功能描述** | 求职者可以在首页浏览推荐职位列表，通过搜索页输入关键词搜索职位，使用筛选器按分类、地区、薪资、岗位类型等维度筛选 |
| **业务逻辑** | 首页加载时调用 `DataService.getTaskList()` 获取招聘中职位列表（status=1），支持分页下拉加载。搜索页调用 `DataService.searchTasks()` 传递关键词和筛选参数。筛选组件使用 FilterSheet 底部弹出面板，选择条件后重新请求数据 |

### 4.2.2 鸿蒙求职者端——投递申请功能

| 项目 | 内容 |
|------|------|
| **功能描述** | 求职者在职位详情页点击投递按钮，完成投递申请，系统自动处理后续流程 |
| **业务逻辑** | 点击投递 → 调用 `AuthService.checkRealName()` 校验实名认证 → 认证通过后调用后端 `POST /api/application/deliver` → 后端校验职位状态 → 校验防重复投递 → 读取简历创建 JSON 快照 → 插入投递记录（status=0）→ 创建聊天会话 → 发送通知给 HR → 返回投递成功 |

### 4.2.3 鸿蒙求职者端——即时聊天功能

| 项目 | 内容 |
|------|------|
| **功能描述** | 求职者与 HR 进行点对点即时通讯，支持文本和图片消息，投递成功后自动创建会话 |
| **业务逻辑** | 消息列表加载会话列表（`ChatService.getSessionList()`），按 `last_message_time` 倒序排列，显示未读数量。点击进入聊天页加载最近 20 条消息（`ChatService.getMessages()`），上拉加载更多历史消息。发送消息通过 `ChatWebSocketService` 的 WebSocket 连接实时推送 |

### 4.2.4 Vue 数据大屏——KPI 指标展示功能

| 项目 | 内容 |
|------|------|
| **功能描述** | 大屏顶部展示 4 项核心 KPI 指标：累计用户、认证企业、招聘中职位、投递总数，并显示较昨日增减趋势 |
| **业务逻辑** | 调用 `getScreenSummary(range)` 接口获取汇总数据，前端按时间范围参数（24h / 7d / 30d / 12m / 10y）请求不同粒度的数据。指标卡使用渐变背景和趋势箭头动画，数据变化时触发数字滚动效果 |

### 4.2.5 Vue 数据大屏——供需趋势图功能

| 项目 | 内容 |
|------|------|
| **功能描述** | 展示选定时间范围内每日新增用户、新增职位、新增投递等趋势曲线，支持多系列对比 |
| **业务逻辑** | 调用 `getScreenSummary(range)` 获取 `dailyList` 数组，使用 ECharts 折线图渲染。X 轴为日期，Y 轴为数量，三个系列（新增用户/职位/投递）分别使用品牌蓝、成功绿、警告橙区分。图表含平滑曲线、渐变面积填充、悬停 tooltip、自适应 resize |

### 4.2.6 Java 后端——认证鉴权功能

| 项目 | 内容 |
|------|------|
| **功能描述** | 处理用户注册、登录、实名认证请求，生成和校验 JWT Token，实现角色权限控制 |
| **业务逻辑** | 注册时生成 16 字节随机盐值，MD5 加密存储密码；登录时查询用户盐值，拼接后 MD5 比对，生成 JWT Token（payload 含用户 ID 和角色），有效期 30 分钟；实名认证使用 Hutool `IdcardUtil.isValidCard()` 校验身份证格式并计算年龄（≥16 周岁） |

### 4.2.7 Java 后端——投递业务功能

| 项目 | 内容 |
|------|------|
| **功能描述** | 处理求职者的投递请求，以原子操作创建投递记录和相关关联数据 |
| **业务逻辑** | ① 校验实名认证状态 → ② 校验职位状态（status=1、deadline>NOW、remaining_quota>0）→ ③ 校验防重复投递（uk_task_applicant 唯一索引）→ ④ 读取简历数据创建 JSON 快照 → ⑤ 插入 `task_application` 记录（status=0）→ ⑥ 创建 `chat_session` 聊天会话 → ⑦ 向 HR 发送系统通知。整个流程使用 `@Transactional` 保证数据一致性 |

---

## 4.3 数据库设计

### 4.3.1 user 表（用户表）

**功能描述**：存储平台所有用户信息，包含求职者、企业 HR、运营管理员、超级管理员四类角色。

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | BIGINT(20) | PK, AUTO_INCREMENT | 用户 ID |
| phone | VARCHAR(11) | UNIQUE, NOT NULL | 手机号（登录账号） |
| email | VARCHAR(100) | UNIQUE, NOT NULL | 邮箱 |
| password | VARCHAR(64) | NOT NULL | 密码（MD5 + 盐加密） |
| salt | VARCHAR(32) | NOT NULL | 随机盐值 |
| nickname | VARCHAR(50) | DEFAULT NULL | 昵称 |
| avatar_url | VARCHAR(255) | DEFAULT NULL | 头像 URL |
| role | TINYINT(1) | NOT NULL, DEFAULT 0 | 角色：0 求职者 / 1 HR / 9 管理员 / 99 超级管理员 |
| credit_score | INT(10) | NOT NULL, DEFAULT 100 | 信用积分 |
| status | TINYINT(1) | NOT NULL, DEFAULT 1 | 状态：0 禁用 / 1 正常 |
| last_login_time | DATETIME | DEFAULT NULL | 最后登录时间 |
| create_time | DATETIME | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| update_time | DATETIME | NOT NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE | 更新时间 |

**索引**：`uk_phone`（唯一）、`uk_email`（唯一）、`idx_role`

### 4.3.2 resume 表（在线简历表）

**功能描述**：存储求职者的在线简历信息，与用户 1:1 绑定，支持全文检索和附件简历。

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | BIGINT(20) | PK, AUTO_INCREMENT | 简历 ID |
| user_id | BIGINT(20) | UNIQUE, FK→user | 用户 ID（1:1 关系） |
| gender | TINYINT(1) | DEFAULT NULL | 性别：0 男 / 1 女 |
| birth_date | DATE | DEFAULT NULL | 出生日期 |
| education | VARCHAR(20) | DEFAULT NULL | 学历 |
| school | VARCHAR(50) | DEFAULT NULL | 毕业院校 |
| skills | VARCHAR(500) | DEFAULT NULL | 技能标签（JSON 数组） |
| experience | TEXT | DEFAULT NULL | 工作经历（富文本） |
| attachment_url | VARCHAR(255) | DEFAULT NULL | 附件简历 URL |
| is_published | TINYINT(1) | DEFAULT 0 | 是否发布到人才市场：0 未发布 / 1 已发布 |
| create_time | DATETIME | NOT NULL | 创建时间 |
| update_time | DATETIME | NOT NULL ON UPDATE | 更新时间 |

**索引**：`uk_user_id`（唯一）、`ft_experience`（全文索引，支持简历关键词搜索）

### 4.3.3 task 表（职位表）

**功能描述**：存储企业 HR 发布的兼职职位信息，包含薪资、分类、地区、名额和状态。

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | BIGINT(20) | PK, AUTO_INCREMENT | 职位 ID |
| enterprise_id | BIGINT(20) | FK→enterprise | 所属企业 |
| category_id | BIGINT(20) | FK→category | 职位分类 |
| region_id | BIGINT(20) | FK→region | 工作地区 |
| title | VARCHAR(100) | NOT NULL | 职位标题 |
| description | TEXT | NOT NULL | 职位描述（富文本） |
| salary_min | INT(10) | NOT NULL | 薪资下限 |
| salary_max | INT(10) | NOT NULL | 薪资上限 |
| salary_unit | TINYINT(1) | NOT NULL | 薪资单位：0 日结 / 1 时薪 / 2 月结 |
| job_type | TINYINT(1) | DEFAULT 0 | 岗位类型：0 全职 / 1 兼职 / 2 实习 |
| total_quota | INT(10) | NOT NULL | 招聘总人数 |
| remaining_quota | INT(10) | NOT NULL | 剩余名额 |
| address | VARCHAR(200) | DEFAULT NULL | 工作地址描述 |
| status | TINYINT(1) | DEFAULT 0 | 状态：0 待审 / 1 招聘中 / 2 已满员 / 3 已过期 / 4 已下架 |
| deadline | DATETIME | NOT NULL | 报名截止时间 |
| version | INT(10) | DEFAULT 0 | 乐观锁版本号 |
| create_time | DATETIME | NOT NULL | 创建时间 |
| update_time | DATETIME | NOT NULL ON UPDATE | 更新时间 |

**索引**：`idx_status_create`（status, create_time，加速按状态+时间排序查询）、`idx_category_status`（加速分类筛选）、`idx_region_status`（加速地区筛选）

### 4.3.4 task_application 表（投递申请表）

**功能描述**：存储求职者的投递记录，包含简历快照、投递状态流转和面试信息。

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | BIGINT(20) | PK, AUTO_INCREMENT | 投递记录 ID |
| task_id | BIGINT(20) | FK→task | 关联职位 |
| applicant_id | BIGINT(20) | FK→user | 投递人（求职者） |
| employer_id | BIGINT(20) | FK→user | 招聘方（HR） |
| resume_snapshot | JSON | NOT NULL | 简历快照（投递时刻的 JSON 序列化） |
| status | TINYINT(1) | DEFAULT 0 | 状态：0 已投递 / 1 待面试 / 2 待定 / 3 已录用 / 4 已淘汰 / 5 已完成 |
| interview_time | DATETIME | DEFAULT NULL | 面试时间 |
| interview_location | VARCHAR(200) | DEFAULT NULL | 面试地点 |
| reject_reason | VARCHAR(500) | DEFAULT NULL | 淘汰原因 |
| version | INT(10) | DEFAULT 0 | 乐观锁版本号 |
| create_time | DATETIME | NOT NULL | 创建时间 |
| update_time | DATETIME | NOT NULL ON UPDATE | 更新时间 |

**索引**：`uk_task_applicant`（task_id, applicant_id，唯一，防重复投递）

### 4.3.5 其他核心表

**enterprise（企业信息表）**
| 字段 | 说明 |
|------|------|
| id, user_id(FK) | 企业 ID、关联 HR 用户 |
| company_name | 公司全称 |
| credit_code | 统一社会信用代码（18 位） |
| license_img_url | 营业执照图片 URL |
| industry | 所属行业 |
| audit_status | 审核状态：0 待审 / 1 已认证 / 2 驳回 |
| reject_reason | 驳回原因 |
| audit_time, create_time, update_time | 时间戳 |

**chat_session（聊天会话表）**
| 字段 | 说明 |
|------|------|
| id, application_id | 会话 ID、关联投递记录 ID |
| employer_id, seeker_id | HR 用户 ID、求职者用户 ID |
| last_message, last_message_time | 最后一条消息摘要和时间（避免聚合 chat_message 表） |
| unread_count | 未读消息数 |
| status | 状态：0 活跃 / 1 关闭 |

**chat_message（聊天消息表）**
| 字段 | 说明 |
|------|------|
| id, session_id(FK) | 消息 ID、所属会话 |
| sender_id, sender_role | 发送方 ID 和角色 |
| content, message_type | 消息内容和类型（0 文本 / 1 图片） |
| is_read | 是否已读 |
| send_time | 发送时间 |

**notification（消息通知表）**
| 字段 | 说明 |
|------|------|
| id, receiver_id, sender_id | 通知 ID、接收方、发送方（NULL 表示系统） |
| title, content | 标题和内容 |
| type | 类型：0 系统 / 1 面试邀请 / 2 录用通知 / 3 淘汰通知 |
| is_read | 是否已读 |
| biz_id | 关联业务 ID |

**daily_statistics（日报统计表）**
| 字段 | 说明 |
|------|------|
| id, stat_date(唯一) | 统计 ID、统计日期 |
| new_users/enterprises/tasks/resumes/deliveries/interviews/entries | 7 项新增计数 |

**operation_log（操作日志审计表）**
| 字段 | 说明 |
|------|------|
| id, operator_id | 日志 ID、操作人 ID |
| operation_type | 操作类型编码 |
| target_type, target_id | 操作目标和关联 ID |
| detail(JSON) | 操作详情 |
| ip_address, create_time | IP 地址和时间戳 |

---

## 4.4 系统界面设计

### 4.4.1 求职者首页界面（HomePage）

| 项目 | 内容 |
|------|------|
| **页面布局结构** | 顶部搜索栏 + 分类快捷入口（横向滚动芯片） + 推荐职位列表（纵向 Feed 流） |
| **可见元素** | 搜索框、分类选择芯片（兼职/全职/实习）、职位信息卡片（标题/薪资/公司/标签/距离）、底部 Tab 导航栏 |
| **交互特点** | 下拉刷新、上拉加载更多、点击卡片进入详情页、左右滑动切换分类 Tab |

### 4.4.2 职位详情页界面（JobDetailPage）

| 项目 | 内容 |
|------|------|
| **页面布局结构** | 顶部职位图片轮播 → 职位信息区 → 公司信息区 → 职位描述区 → 底部固定操作栏 |
| **可见元素** | 职位标题、薪资范围与单位、公司名称与行业、工作地址、职位描述（富文本渲染）、招聘名额与剩余名额、报名截止时间、收藏按钮、底部"投递"按钮 |
| **交互特点** | 点击投递触发完整投递流程（实名校验 → 投递确认），收藏按钮点击切换状态，点击公司名称跳转公司详情页 |

### 4.4.3 聊天页面界面（ChatDetailPage）

| 项目 | 内容 |
|------|------|
| **页面布局结构** | 顶部导航栏（对方昵称） + 消息列表（居中滚动） + 底部输入栏 |
| **可见元素** | 对方头像和昵称、消息气泡（自己的在右侧蓝色，对方的在左侧灰色）、时间分隔线、文本输入框、发送按钮、图片附件按钮 |
| **交互特点** | 自动滚动到最新消息、上拉加载历史消息（每次 20 条）、图片消息可点击放大查看、未读消息自动标记已读 |

### 4.4.4 数据大屏界面（ScreenPreview）

| 项目 | 内容 |
|------|------|
| **页面布局结构** | 顶部 KPI 指标卡片行（4 项核心指标，带趋势箭头）+ 左侧供需趋势折线图 + 左侧职位大类占比环形图 + 中央全国岗位流向图 + 下方投递转化漏斗进度条 + 企业资质审核进度条 + 实名认证率进度条 + 右侧热门岗位 TOP10 列表 + 右侧实时动态时间线 |
| **可见元素** | 指标数字与趋势箭头、ECharts 折线图/环形图/地图、分段进度条、排行榜列表、动态消息流、时间范围切换按钮 |
| **交互特点** | 时间范围切换（24h / 7d / 30d / 12m / 10y）、鼠标悬停图表查看数据详情、自适应全屏展示、暗色调主题 |

### 4.4.5 管理后台工作台界面（Dashboard）

| 项目 | 内容 |
|------|------|
| **页面布局结构** | 顶部 4 个统计卡片（累计用户 / 认证企业 / 招聘中职位 / 投递总数）+ 左侧近 7 天趋势表格 + 右侧待办事项面板 |
| **可见元素** | 统计数字（渐变背景卡片）、每日新增数据表格（日期/新增用户/新增企业/新增职位/新增投递）、待审核企业数量、待审核职位数量、"数据展示"入口按钮 |
| **交互特点** | 点击待办项跳转对应审核页面、点击"数据展示"按钮进入全屏大屏页面、页面入场渐入动画 |

---

# 第五章 项目阶段——本人负责模块的代码实现展示

## 5.1 项目结构

### 鸿蒙求职者端（ArkTS）目录结构

```
entry/src/main/ets/
├── entryability/
│   └── EntryAbility.ets              # 应用入口 Ability
├── common/                           # 公共模块
│   ├── AppStyles.ets                 # 全局样式 Token（颜色/间距/圆角/字体/阴影/动画）
│   ├── AppBootstrapPolicy.ets        # 应用启动策略
│   ├── BusinessPolicies.ets          # 业务策略
│   ├── FormValidators.ets            # 表单校验器
│   └── StandardCard.ets              # 标准卡片组件
├── components/                       # 可复用组件（28 个）
│   ├── chat/                         # 聊天组件（15 个：MessageBubble, MessageInputBar 等）
│   ├── filter/                       # 筛选组件（9 个：FilterSheet, ChoiceChips 等）
│   ├── job/                          # 职位卡片（JobCard, JobFeedCard）
│   ├── application/                  # 投递相关组件（ApplicationStatusBar 等）
│   ├── enterprise/                   # 企业相关组件（LicenseUploader, StatusBanner）
│   ├── EmptyView.ets                 # 空状态视图
│   ├── ErrorView.ets                 # 错误视图
│   └── LoadMoreFooter.ets            # 加载更多
├── pages/                            # 页面（28 个）
│   ├── tab/seeker/                   # 求职者 Tab 页（HomePage, ChatPage, ProfilePage）
│   ├── tab/recruiter/                # 招聘方 Tab 页（3 个）
│   ├── JobDetailPage.ets             # 职位详情
│   ├── SearchPage.ets                # 搜索
│   ├── ResumePage.ets                # 简历管理
│   ├── ChatDetailPage.ets            # 聊天详情
│   ├── FavoritesPage.ets             # 收藏管理
│   ├── LoginPage.ets                 # 登录
│   ├── RegisterPage.ets              # 注册
│   └── ...                           # 其他功能页
├── services/                         # 服务层（20 个）
│   ├── ApiClient.ets                 # HTTP 客户端（单例封装）
│   ├── AuthService.ets               # 认证服务
│   ├── DataService.ets               # 数据服务
│   ├── ChatService.ets               # 聊天服务
│   ├── ChatWebSocketService.ets      # WebSocket 通信
│   ├── ResumeService.ets             # 简历服务
│   ├── FavoriteService.ets           # 收藏服务
│   └── ...                           # 其他服务
```

### Vue 数据大屏目录结构

```
src/
├── api/
│   └── admin.ts                # 统计/审核/用户管理/日志 API
├── pages/
│   ├── admin/
│   │   └── Dashboard.vue       # 管理后台工作台
│   └── ScreenPreview.vue       # 数据大屏（含 ECharts 图表）
├── styles/
│   ├── style.css               # 全局 CSS 变量（设计系统）
│   └── admin-theme.css         # Admin 主题样式
├── router/index.ts             # 路由配置
└── stores/                     # Pinia 状态管理
```

### Java 后端目录结构（涉及模块）

```
src/main/java/com/uniseek/
├── auth/
│   ├── dto/                    # 认证相关 DTO（LoginRequest, RegisterRequest, UserVO 等）
│   └── service/impl/           # 认证服务实现（注册/登录/实名认证）
├── controller/                 # 控制器层
│   ├── AuthController.java     # 认证接口
│   ├── ResumeController.java   # 简历接口
│   ├── TaskController.java     # 职位接口
│   └── ApplicationController.java # 投递接口
├── admin/controller/           # 管理后台控制器
│   └── AdminStatisticsController.java # 统计接口
├── service/impl/               # 业务服务实现层
├── dao/                        # 数据访问层（15 个 Mapper 接口）
├── entity/                     # 实体层（15 个实体类）
├── common/                     # 公共模块
│   ├── exception/              # 统一异常处理
│   ├── ApiResult.java          # 统一响应格式
│   └── util/UserContext.java   # 用户上下文（ThreadLocal）
├── config/                     # 配置层
│   ├── JwtAuthInterceptor.java # JWT 鉴权拦截器
│   └── WebMvcConfig.java       # Web MVC 配置
├── chat/websocket/             # WebSocket 聊天
└── util/                       # 工具类
```

---

## 5.2 关键代码及说明

### 5.2.1 JWT 鉴权拦截器实现

**文件路径**：`uniseek_java/src/main/java/com/uniseek/config/JwtAuthInterceptor.java`

```java
@Component
public class JwtAuthInterceptor implements HandlerInterceptor {

    @Autowired
    private JwtUtil jwtUtil;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response,
                             Object handler) throws Exception {
        // 从请求头提取 Token
        String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new UnauthorizedException("未登录或Token已过期");
        }

        String token = authHeader.substring(7);

        // 校验 Token 签名和有效期
        if (!jwtUtil.validateToken(token)) {
            throw new UnauthorizedException("Token无效或已过期");
        }

        // 解析用户信息
        Long userId = jwtUtil.getUserIdFromToken(token);
        Integer role = jwtUtil.getRoleFromToken(token);

        // 角色权限校验（按 URL 前缀）
        String path = request.getRequestURI();
        if (path.startsWith("/api/admin/") && role < 9) {
            throw new UnauthorizedException("权限不足");
        }
        if (path.startsWith("/api/enterprise/") && role != 1) {
            throw new UnauthorizedException("仅企业HR可操作");
        }

        // 存入 ThreadLocal 供后续使用
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

**实现逻辑说明**：该拦截器实现了全系统的统一鉴权入口。首先从 `Authorization` 请求头提取 Bearer Token，使用 `JwtUtil` 验证 Token 的签名有效性和有效期。验证通过后，从 Token payload 中解析出用户 ID 和角色值，按照请求 URL 的路径前缀执行 RBAC 角色权限匹配——`/api/admin/*` 要求 role ≥ 9，`/api/enterprise/*` 要求 role = 1。校验通过后将用户信息存入 `ThreadLocal` 供 Controller 和 Service 层直接获取，无需从请求参数中重复解析。请求结束后在 `afterCompletion` 中清除 ThreadLocal，避免内存泄漏。

### 5.2.2 投递业务服务实现

**文件路径**：`uniseek_java/src/main/java/com/uniseek/service/impl/ApplicationServiceImpl.java`

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

        // 1. 校验实名认证
        // 省略实名校验逻辑...

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
        application.setStatus(0); // 已投递
        applicationMapper.insert(application);

        // 6. 自动创建聊天会话
        ChatSession session = new ChatSession();
        session.setApplicationId(application.getId());
        session.setEmployerId(task.getPublisherId());
        session.setSeekerId(applicantId);
        session.setStatus(0); // 活跃
        chatSessionMapper.insert(session);

        // 7. 发送通知给HR
        notificationService.send(
            task.getPublisherId(), null,
            "新投递提醒",
            "有求职者投递了职位：" + task.getTitle(),
            0, // 系统通知
            application.getId()
        );

        return ApiResult.success("投递成功");
    }
}
```

**实现逻辑说明**：投递服务是整个平台最核心的业务方法之一，包含完整的业务校验链：实名认证校验（前置条件）、职位状态校验（招聘中/未过期/有名额）、防重复投递校验（利用 `uk_task_applicant` 唯一索引）。校验通过后，读取求职者的最新简历数据序列化为 JSON 字符串作为简历快照（确保投递后简历修改不影响已投递记录），然后以原子操作（`@Transactional`）完成三件事：插入投递记录、创建聊天会话、发送系统通知给 HR。

### 5.2.3 鸿蒙端 HTTP 客户端封装

**文件路径**：`uniseek_arkts/entry/src/main/ets/services/ApiClient.ets`

```typescript
// HTTP 请求客户端封装 - 单例模式
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

  setToken(token: string): void {
    this.token = token;
  }

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

**实现逻辑说明**：该代码使用 HarmonyOS 原生网络请求 SDK（`@ohos.net.http`）封装了统一的 HTTP 客户端。采用单例模式确保全局只有一个 `ApiClient` 实例。提供 `get/post/put` 三个方法，自动从 `UserSession` 获取并注入 JWT Token 到请求头中，统一解析后端返回的标准 `ApiResult` 响应格式，对非 200 状态码统一抛出 `BusinessError` 异常。超时时间统一设置为 10 秒，网络请求完成后在 `finally` 块中销毁 HTTP 连接资源避免泄漏。

---

# 第六章 项目阶段——本人负责模块的测试与功能展示

## 6.1 测试用例

| 测试项目 | 测试步骤 | 预期结果 | 执行结果 | 是否达到预期 |
|---------|---------|---------|---------|:----------:|
| **TC-001：用户注册** | ① 填写手机号 13800138000、邮箱 test@uniseek.com、密码 abc123456、昵称张三 ② 选择"求职者"身份 ③ 点击注册 | 注册成功，返回 JWT Token，跳转至求职者首页 | 注册成功，session 中存储 Token | 是 |
| **TC-002：职位搜索** | ① 在首页搜索框输入"服务员" ② 选择分类为"餐饮服务" ③ 点击搜索 | 展示标题或分类匹配"服务员"的招聘中职位列表 | 正确展示匹配结果 | 是 |
| **TC-003：投递职位** | ① 进入某招聘中职位详情页 ② 点击"投递"按钮 | 投递成功，聊天会话自动创建，HR 收到通知 | 投递记录创建成功，聊天列表出现新会话 | 是 |
| **TC-004：HR 审核投递** | ① HR 进入简历池 ② 查看某投递记录 ③ 选择"邀请面试"并填写面试信息 | 投递状态变更为"待面试"，求职者收到面试通知 | 状态变更成功，通知发送成功 | 是 |
| **TC-005：数据大屏展示** | ① 管理员进入数据大屏页面 ② 切换时间范围为"30d" | KPI 卡片数据更新，各图表按 30 天粒度展示趋势 | 图表正常渲染，数据随参数变化 | 是 |
| **TC-006：实名认证拦截** | ① 未实名认证的求职者点击投递 ② 弹出实名认证弹窗 | 弹窗提示"请先完成实名认证" | 弹窗正常展示，引导用户完成认证 | 是 |

---

## 6.2 功能展示

### 6.2.1 鸿蒙求职者端——首页

求职者进入 App 后的主界面，顶部搜索框支持关键词搜索，下方横向滚动分类芯片（兼职/全职/实习），主力区域为纵向职位 Feed 流卡片列表。支持下拉刷新获取最新职位，上拉加载更多。职位卡片展示标题、薪资范围、公司名称、标签和距离信息，点击进入详情页。

### 6.2.2 鸿蒙求职者端——职位详情页

完整展示职位信息，包含标题、薪资范围与单位、公司名称与行业、工作地址、富文本描述的职位详情、招聘名额与截止时间。底部固定操作栏包含收藏按钮和"投递"按钮。点击投递触发完整投递流程，包含实名认证校验、状态校验、创建投递记录等后端操作。

### 6.2.3 鸿蒙求职者端——聊天页

展示与 HR 的会话列表，按最后消息时间倒序排列，未读消息以红点徽标提示。进入会话后展示历史消息——自己的消息以蓝色气泡居右，对方消息以灰色气泡居左。底部输入栏支持文本和图片发送，上拉可加载更多历史消息。

### 6.2.4 鸿蒙求职者端——简历管理页

求职者编辑在线简历，包含字段：学历（预定义列表选择）、毕业院校、技能标签（JSON 数组）、工作经历（富文本编辑器）。支持 PDF 附件简历上传（≤10MB），可切换简历发布状态（发布到人才市场 / 暂不发布）。

### 6.2.5 鸿蒙求职者端——我的投递页

展示求职者所有投递记录列表，每条记录显示职位标题、企业名称、投递时间和当前状态标签（已投递灰色 / 待面试蓝色 / 已录用绿色 / 已淘汰红色等），点击可查看详情。

### 6.2.6 Vue 数据大屏

运营数据可视化页面，核心功能模块包括：

- **KPI 指标卡**：顶部 4 项核心指标（累计用户、认证企业、招聘中职位、投递总数），带较昨日增减趋势箭头
- **供需趋势折线图**：ECharts 折线图，展示选定时间范围内每日新增用户/职位/投递趋势
- **职位大类占比环形图**：ECharts 环形图，展示各分类岗位数量占比
- **全国岗位流向图**：地域流向可视化，展示各省份岗位需求分布
- **投递转化漏斗进度条**：分段展示已投递→待面试→已录用→已完成各阶段数量
- **企业资质审核进度条**：待审核/已认证/已驳回企业分布
- **实名认证率进度条**：已认证用户占比
- **热门岗位 TOP10 排行榜**：投递量最高的 10 个岗位
- **实时动态时间线**：最新的用户注册、企业认证、职位发布等动态

### 6.2.7 Java 后端 API 接口清单

| 接口地址 | 功能 | 测试状态 |
|---------|------|:--------:|
| `POST /api/auth/register` | 用户注册 | ✅ 通过 |
| `POST /api/auth/login` | 用户登录 | ✅ 通过 |
| `POST /api/auth/real-name` | 实名认证 | ✅ 通过 |
| `PUT /api/resume` | 创建/更新简历 | ✅ 通过 |
| `POST /api/task/publish` | 发布职位 | ✅ 通过 |
| `POST /api/application/deliver` | 投递职位 | ✅ 通过 |
| `PUT /api/application/status` | 更新投递状态 | ✅ 通过 |
| `POST /api/chat/message/send` | 发送聊天消息 | ✅ 通过 |
| `GET /api/admin/statistics/summary` | 大屏 KPI 汇总 | ✅ 通过 |
| `GET /api/admin/statistics/categories` | 职位大类占比 | ✅ 通过 |

---

# 第七章 实训总结

## 项目整体回顾

本次实训历时约 8 周，从需求分析、系统设计、编码实现到测试部署，完整经历了一个企业级 Web + 移动端项目的全生命周期。UniSeek 优寻兼职招聘平台最终交付了包括 Vue 3 前端网站、ArkTS 鸿蒙 App、Java Spring Boot 后端 API 和数据可视化大屏在内的完整产品。

作为项目核心开发成员，我负责了鸿蒙求职者端的前后端、Vue 数据大屏前后端、以及全平台的样式设计系统。这一过程不仅锻炼了我在多端开发中的技术能力，更让我深刻理解了工程化思维在实际项目中的重要性。

## 技术实践收获

### 1. 鸿蒙 ArkTS 开发能力

首次系统性使用 ArkTS 语言开发 HarmonyOS NEXT 应用，深入理解了声明式 UI 开发范式、`@Component` 组件化设计、`@State/@Prop/@Link` 数据流转机制，以及 HarmonyOS 的权限管理、网络请求、WebSocket 等原生 API。掌握了如何将 HMOS 系统 Token（`$r('sys.color.*')`）与业务语义色有机结合，实现自动适配深浅色主题。

### 2. 前后端分离架构实践

通过参与 Java Spring Boot 后端的开发（认证模块、投递模块），深入理解了分层架构（Controller → Service → DAO → Entity）的职责划分、JWT 无状态鉴权的实现原理、乐观锁在并发场景下的应用、以及 AOP 面向切面编程在日志审计中的落地。

### 3. 数据可视化能力

使用 ECharts 实现了数据大屏的多种图表（折线图、环形图、地域流向图等），掌握了 ECharts 的配置项体系、数据驱动的渲染机制、响应式适配和主题定制。同时通过设计"时间范围切换"功能，理解了不同粒度数据聚合的策略。

### 4. 设计系统搭建

从零搭建了一套横跨 Vue 前端、Vue Admin、ArkTS 三端的统一设计系统，定义了品牌色 `#1762FB`、间距、圆角、阴影、动画等视觉 Token。这一实践让我深刻认识到设计系统在保证产品视觉一致性、提升开发效率方面的重要价值。

### 5. 数据库设计与优化

参与了 14 张业务表的数据库设计，理解了唯一索引防重复投递、复合索引加速多条件查询、全文索引支持简历关键词搜索、乐观锁版本号防超录等数据库设计技巧。同时通过 `SET NULL` 外键策略、`ON DELETE RESTRICT` 约束等了解了生产环境下的数据完整性保障。

### 6. 工程化工具使用

熟练使用了 Git 版本控制、Maven 项目构建、Vite 前端构建工具、Hvigor 鸿蒙构建工具，以及 Postman API 测试等工程化工具，提升了开发效率和团队协作能力。

## 个人能力成长

### 工程化思维

从最初"能跑就行"的编码心态，转变为企业级工程化思维——代码要分层、异常要处理、接口要规范、数据要一致。理解了良好的架构设计比炫技的代码更重要。

### 问题解决能力

在开发过程中遇到了诸多实际问题：鸿蒙模拟器网络请求配置、WebSocket 断线重连、前后端联调跨域问题、ECharts 大数据量渲染性能等。通过查阅官方文档、搜索引擎和团队讨论，逐一攻克了这些难题。

### 团队协作

项目采用前后端分离开发模式，前后端通过 API 文档（`api.md`）协同。我作为同时参与前后端的开发者，在接口定义、联调测试中起到了桥梁作用，帮助团队成员快速定位问题，提高了协作效率。

## 未来展望

UniSeek 作为一个实训项目，虽然核心功能已基本完成，但仍有许多可以持续优化的方向：接入支付系统实现薪资在线结算、引入即时通讯的已读回执和消息撤回功能、基于用户行为数据的智能推荐算法、以及更多端（iOS/Android）的覆盖。这些方向也是我后续学习和实践的重点。
