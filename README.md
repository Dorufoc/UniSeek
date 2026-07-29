<p align="center">
  <img src="./img/uniseek.png" alt="UniSeek Logo" width="200"/>
</p>
<p align="center">
  <img src="./img/uniseek_text_white_ZH.svg" alt="UniSeek" width="400"/>
</p>
<p align="center">
  <img src="https://img.shields.io/badge/Java-1.8-blue" alt="Java"/>
  <img src="https://img.shields.io/badge/Spring%20Boot-2.2.2-brightgreen" alt="Spring Boot"/>
  <img src="https://img.shields.io/badge/Vue-3-4FC08D" alt="Vue"/>
  <img src="https://img.shields.io/badge/MySQL-8-4479A1" alt="MySQL"/>
  <img src="https://img.shields.io/badge/ArkTS-6.1.1-red" alt="ArkTS"/>
  <img src="https://img.shields.io/badge/license-UNLICENSED-red" alt="License"/>
</p>

<br />

# 优寻（UniSeek）兼职招聘平台

优寻（UniSeek）是一个面向大学生和企业的兼职招聘平台，提供求职信息发布、简历投递、职位管理、即时通讯、数据统计等全方位功能。平台覆盖 **PC 端（Vue 3）**、**鸿蒙端（ArkTS）** 和 **IoT 设备端（LiteOS-M）**，后端采用 **Spring Boot** 微服务架构，多端共用同一套 RESTful API。

***

## 核心功能

### 用户体系与认证

平台采用统一的用户认证体系，支持手机号加密码的注册与登录方式。用户在注册时需填写手机号（11 位数字，1 开头）、邮箱（标准邮箱格式）、密码（6-20 位）和昵称，并选择注册身份——求职者（role=0）或企业 HR（role=1）。注册时密码经过 MD5 + 独立随机盐值加密后存储，保障账户安全。

用户登录后获得 JWT Token（有效期 7 天），后续请求在请求头中携带 `Authorization: Bearer <token>` 完成鉴权。系统内置四级角色体系：求职者（role=0）、企业 HR（role=1）、运营管理员（role=9）和超级管理员（role=99），不同角色拥有差异化的 API 访问权限和前端页面视图。

平台要求求职者在投递职位前、企业 HR 在提交企业资质前完成实名认证。实名认证使用 Hutool 工具类的 `IdcardUtil` 对身份证号进行格式校验和年龄计算（须年满 16 周岁），身份证号在数据库中加密存储，保障用户隐私。

### 职位管理全流程

**职位分类体系**：系统内置 15 个顶级分类（餐饮服务、家教辅导、快递物流、促销导购、话务客服、设计创作、文案写作、技术支持、翻译校对、美容美发、家政保洁、教育培训、活动策划、摄影摄像、其他）和 47 个子级分类，共计 62 条种子数据，支持两级级联选择。

**职位发布与审核**：企业 HR 提交职位后，系统自动进入待审核状态（status=0）。运营管理员审核通过后职位变为招聘中状态（status=1），对求职者可见。审核不通过时填写驳回原因，HR 可修改后重新提交。已上架的职位支持按"未审核 → 招聘中 → 已满员 → 已过期 → 已下架"的完整状态机流转。

**招聘名额管理**：每个职位设定招聘总人数（total\_quota）和剩余名额（remaining\_quota），采用乐观锁机制防止并发超录。名额扣减至零时自动标记为已满员（status=2）。系统定时任务在每日凌晨自动将已过报名截止时间的职位标记为已过期（status=3）。

### 职位搜索与投递

求职者可按关键词、分类、地区（省/市/区三级）、薪资范围、岗位类型（全职/兼职/实习）、标签等维度筛选职位，结果按发布时间或薪资排序，支持多标签并集筛选。后端为按状态 + 时间、分类 + 状态、地区 + 状态等查询模式建立了复合索引，确保搜索性能。

投递时系统自动读取求职者在线简历的完整数据，生成 JSON 快照（resume\_snapshot）与投递记录一同存储。这一机制确保 HR 审核时看到的是投递时刻的简历原始状态，求职者后续修改简历不会影响已投递的审核记录。投递状态支持完整的生命周期流转：已投递（0）→ 待面试（1）/ 面试通过（2）/ 已淘汰（4）→ 已录用（3）→ 已完成（5），每个状态变更均有严格的流转校验和规则约束。

### 简历管理

每位求职者拥有唯一一份在线简历（用户与简历 1:1 绑定），可在 PC 端或鸿蒙端编辑。简历字段包括：性别、出生日期、学历、毕业院校、技能标签（JSON 数组格式）、工作实践经历（富文本 HTML）。同时支持上传附件简历（PDF/Word 格式，最大 10MB）作为补充材料。简历中的经历字段设置了全文索引（FULLTEXT），支持 HR 在人才库中通过关键词搜索简历内容。

### 企业资质认证

企业 HR 注册后需提交企业资质信息（公司全称、统一社会信用代码、营业执照图片、所属行业、公司简介）供运营管理员审核。企业资质状态包括：待审（0）、已认证（1）、已驳回（2）。认证通过后 HR 方能发布职位；认证驳回时 HR 可查看驳回原因并修改后重新提交。信用代码使用唯一索引（uk\_credit\_code）防止重复注册。

### 即时通讯

求职者投递成功后，系统自动为求职者与 HR 创建一个聊天会话（chat\_session，与投递记录 1:1 关联）。会话列表直接读取 chat\_session 表的 last\_message 和 last\_message\_time 字段，无需聚合 chat\_message 表，确保列表加载性能。聊天消息使用 `idx_session_time` 复合索引支持高效的历史消息分页查询。用户进入聊天页面时，系统自动将对方发送的未读消息批量标记为已读。两端均支持发送文本、图片等消息类型。

### 消息通知

系统在关键业务节点自动推送站内信通知，覆盖四类场景：投递成功时通知 HR（类型 0）、HR 邀请面试时通知求职者（类型 1）、录用时通知求职者（类型 2）、淘汰时通知求职者并附原因（类型 3）。通知列表支持分页查询和一键全部已读。

### 职位收藏

求职者可以收藏感兴趣的心仪职位，同一用户对同一职位仅能收藏一次（uk\_user\_task 唯一索引约束）。收藏列表支持分页查询，方便求职者后续集中查看。

### 运营管理后台

运营后台为管理员提供完整的平台管理能力，包括：

- **数据统计看板**：展示累计数据（总用户数、企业数、职位数、投递次数等）和每日趋势（新增用户/企业/职位/投递/面试/入职折线图），数据来源于 daily\_statistics 表，由定时任务每日凌晨自动统计。
- **企业管理**：查看企业资质认证列表，审核或驳回企业的认证申请。
- **职位管理**：查看所有职位（按状态筛选），审核待审职位，下架违规职位。
- **用户管理**：查看平台用户列表，按角色/状态筛选，支持禁用违规用户账号。
- **操作审计日志**：系统自动记录所有关键业务操作（注册、登录、投递、审核、录用、淘汰等），日志以只追加方式存储，不可修改或删除，支持按操作人、操作类型、时间范围等维度筛选追溯。

### 环境温湿度遥测

系统内置传感器数据采集接口（Telemetry API），支持对接 IoT 设备上报温湿度等环境数据。数据存储在 `telemetry_data` 表中，提供最新数据查询接口，可用于办公环境监控等场景。

配套 IoT 固件 `uniseek_liteos_m` 运行在 RK2206 开发板上，使用 LiteOS-M 实时操作系统。固件通过板载 SHT30 温湿度传感器每 10 秒采集一次数据，通过 Wi-Fi 以 HTTP POST 方式上报到后端 `/api/v1/telemetry` 接口。设备配备 LCD 显示屏实时显示 Wi-Fi 状态、IP 地址、温湿度数值和服务端返回结果，RGB LED 指示灯以三色显示设备健康状态：

- **红色**：Wi-Fi 未连接
- **黄色**：Wi-Fi 已连接但传感器或服务器异常
- **绿色**：最近一次上报成功（HTTP 2xx）

### 定时任务

系统内置三个定时任务：每日凌晨 01:00 自动将已过期的职位标记为"已过期"状态（status=3）；每日凌晨 00:05 自动统计前一天的平台运营数据（新增用户数、企业数、职位数、投递数、面试数、入职数）并写入 daily\_statistics 表，统计逻辑包含幂等保护（`uk_stat_date` 唯一索引防止重复统计）；`TaskScheduledService` 负责定时任务调度编排。

***

## 技术栈

| 层级            | 技术                   |       版本      |
| ------------- | -------------------- | :-----------: |
| 后端框架          | Spring Boot          | 2.2.2.RELEASE |
| 后端语言          | Java                 |      1.8      |
| ORM           | MyBatis-Plus         |     3.3.0     |
| 数据库           | MySQL                |      8.0      |
| MySQL JDBC 驱动 | mysql-connector-java |     8.0.19    |
| JWT 鉴权        | jjwt                 |     0.9.1     |
| 工具库           | Hutool               |     5.8.26    |
| 构建工具          | Maven                |      3.6+     |
| PC 前端框架       | Vue                  |     3.5.39    |
| PC 前端 UI      | Element Plus         |     2.14.3    |
| 状态管理          | Pinia                |     3.0.4     |
| 路由            | Vue Router           |     4.6.4     |
| HTTP 客户端      | Axios                |     1.18.1    |
| 图表库           | ECharts              |     6.1.0     |
| PDF 预览        | pdfjs-dist           |    6.1.200    |
| 构建工具          | Vite                 |     8.1.4     |
| 前端语言          | TypeScript           |     6.0.2     |
| 鸿蒙端语言         | ArkTS                |     6.1.1     |
| 鸿蒙端 UI        | ArkUI                |       -       |
| IoT 端操作系统     | LiteOS-M             |       -       |
| IoT 端硬件平台     | RK2206               |       -       |
| IoT 端传感器      | SHT30（温湿度）           |       -       |
| IoT 端显示       | LCD 屏 + RGB LED      |       -       |
| IoT 端语言       | C                    |       -       |
| Mock 数据生成     | Python 3             |       -       |

***

## 系统架构

```
┌──────────────────────────────────────────────────────────┐
│                        客户端层                           │
│  ┌──────────────────┐  ┌──────────────┐  ┌───────────┐  │
│  │  PC (Vue 3)      │  │鸿蒙(ArkTS)   │  │IoT(LiteOS)│  │
│  │  localhost:5173   │  │ 鸿蒙设备原生  │  │RK2206 板  │  │
│  │  求职/招聘/管理    │  │ 求职/招聘/聊天│  │SHT30传感器│  │
│  └────────┬─────────┘  └──────┬───────┘  └─────┬─────┘  │
│           │                   │                  │        │
│           └──────────┬────────┘                  │        │
│                      │ HTTP / WebSocket          │ HTTP   │
├──────────────────────┼───────────────────────────┼───────┤
│                      ▼                           ▼       │
│            接入层 (Controller)                            │
│  ┌──────┬──────┬──────┬──────┬──────┬──────┬──────┬───┐  │
│  │ Auth │ Task │Resume│Applic│ Chat │Notif │Upload│Tel│  │
│  └──┬───┴──┬───┴──┬───┴──┬───┴──┬───┴──┬───┴──┬───┴───┘  │
│     │      │      │      │      │      │                  │
│     ▼      ▼      ▼      ▼      ▼      ▼                  │
│             业务层 (Service)                               │
│  ┌────────────────────────────────────────────────────┐   │
│  │   Auth/User    │    Task      │    Application      │   │
│  │   Resume       │    Chat      │    Notification     │   │
│  │   Enterprise   │    Favorite  │    Category/Region  │   │
│  │   Admin        │   Telemetry  │  DailyStatistics    │   │
│  │   OperationLog │  ApplicationStatusMachine          │   │
│  └────────────────────────────────────────────────────┘   │
│              │            │              │                 │
│              ▼            ▼              ▼                 │
│       数据层 (MyBatis-Plus DAO / Entity)                   │
│  ┌────────────────────────────────────────────────────┐   │
│  │ 15 个 Mapper 接口 + XML 映射文件                    │   │
│  │   user / task / resume / enterprise / category     │   │
│  │   region / application / notification / chat       │   │
│  │   favorite / daily_statistics / telemetry_data     │   │
│  │   operation_log / real_name_auth                   │   │
│  └──────────────────────┬─────────────────────────────┘   │
│                         │                                   │
│                         ▼                                   │
│                  MySQL 8 数据库                             │
│                  ┌──────────────┐                          │
│                  │   uniseek    │                          │
│                  │  (15 张表)   │                          │
│                  └──────────────┘                          │
└──────────────────────────────────────────────────────────┘
```

***

## 快速开始

### 环境要求

- JDK 1.8+
- Maven 3.6+
- MySQL 8.0+
- Node.js 18+
- 鸿蒙 DevEco Studio（可选，仅鸿蒙端开发需要）
- OpenHarmony 编译环境（可选，仅 LiteOS-M 固件开发需要）

### 1. 克隆项目

```bash
git clone <仓库地址>
cd UniSeek
```

### 2. 初始化数据库

```bash
mysql -u root -p < sql/uniseek_schema.sql
mysql -u root -p < sql/uniseek_mock_data_large.sql
```

### 3. 配置后端

编辑 `uniseek_java/src/main/resources/application.yml`，配置数据库连接信息：

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/uniseek?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai
    username: root
    password: 你的密码
```

### 4. 启动后端

```bash
cd uniseek_java
mvn spring-boot:run
```

后端默认启动在 `http://localhost:8080`。

### 5. 启动 PC 前端

```bash
cd uniseek_vue
npm install
npm run dev
```

前端默认启动在 `http://localhost:5173`。

### 6. 启动鸿蒙端（可选）

使用 DevEco Studio 打开 `uniseek_arkts/` 目录，连接鸿蒙设备或模拟器后运行。

### 7. 构建 LiteOS-M 固件（可选）

使用 OpenHarmony 标准构建流程，在 RK2206 开发板上运行：

```bash
# 修改 Wi-Fi 与服务器配置（烧录前）
# 编辑 uniseek_liteos_m/uniseek_app/include/uniseek_config.h
# 设置 UNISEEK_WIFI_SSID / UNISEEK_WIFI_PASSWORD / UNISEEK_SERVER_IP 等

# 使用 OpenHarmony 编译框架构建
hb build -f
```

构建完成后烧录至 RK2206 开发板。设备启动后自动连接 Wi-Fi，每 10 秒采集一次温湿度并上报至后端 `/api/v1/telemetry` 接口。LCD 屏实时显示状态，RGB LED 指示健康状态。

***

## 数据库设计

系统共包含 **15 张数据库表**，全部使用 InnoDB 引擎、utf8mb4 字符集，设计遵循外键约束与索引优化原则。

|  序号 | 表名                 | 说明             | 核心字段                                                                                                                                                                                                                                                                     | <br /> |
| :-: | ------------------ | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | :----- |
|  1  | `user`             | 用户表            | phone, email, password, salt, nickname, role(0/1/9/99), avatar\_url, credit\_score, status, last\_login\_time                                                                                                                                                            | <br /> |
|  2  | `real_name_auth`   | 实名认证表          | user\_id(FK), real\_name, id\_card(加密), status(0/1), auth\_time                                                                                                                                                                                                          | <br /> |
|  3  | `resume`           | 在线简历表          | user\_id(FK), gender, birth\_date, education, school, graduation\_date, skills(JSON), experience(FULLTEXT), attachment\_url, is\_published                                                                                                                               | <br /> |
|  4  | `category`         | 职位分类表（自关联树形）   | parent\_id(FK), name, sort\_order（62 条种子数据）                                                                                                                                                                                                                              | <br /> |
|  5  | `region`           | 行政区划表（省/市/区三级） | parent\_id(FK), name, level(1/2/3), sort\_order                                                                                                                                                                                                                          | <br /> |
|  6  | `enterprise`       | 企业信息表          | user\_id(FK), company\_name, credit\_code, license\_img\_url, industry, sub\_category\_id, region\_id, description, audit\_status(0/1/2), reject\_reason, audit\_time                                                                                                    | <br /> |
|  7  | `task`             | 职位/岗位表（核心业务表）  | enterprise\_id(FK), category\_id(FK), region\_id, title, description, salary\_min/max, salary\_unit(日结/时薪/月结), job\_type(全职/兼职/实习), total\_quota, remaining\_quota, tag, address, longitude, latitude, status(0\~5), version(乐观锁), reject\_reason, deadline, audit\_time | <br /> |
|  8  | `task_application` | 投递报名表          | task\_id(FK), applicant\_id(FK), resume\_snapshot(JSON), attachment\_url, status(0\~5), hr\_id, interview\_time/location, reject\_reason, hr\_note, version(乐观锁)                                                                                                         | <br /> |
|  9  | `notification`     | 消息通知表          | receiver\_id(FK), sender\_id(FK), title, content, type(0\~3), is\_read, biz\_id                                                                                                                                                                                          | <br /> |
|  10 | `chat_session`     | 聊天会话表          | task\_application\_id(uk), employer\_id(FK), seeker\_id(FK), last\_message, last\_message\_time, status(活跃/已关闭)                                                                                                                                                          | <br /> |
|  11 | `chat_message`     | 聊天消息表          | session\_id(FK), sender\_id(FK), message\_type(文本/图片), content, is\_read, send\_time                                                                                                                                                                                     | <br /> |
|  12 | `daily_statistics` | 运营日报统计表        | stat\_date(uk), new\_user/enterprise/task/resume/delivery/interview/entry\_count                                                                                                                                                                                         | <br /> |
|  13 | `telemetry_data`   | 传感器遥测数据表       | temperature, humidity, device\_id, report\_time                                                                                                                                                                                                                          | <br /> |
|  14 | `operation_log`    | 操作日志审计表        | operator\_id(FK), operation\_type, target\_type, target\_id, detail(JSON), ip\_address                                                                                                                                                                                   | <br /> |
|  15 | `favorite`         | 职位收藏表          | user\_id(FK), task\_id(FK), uk\_user\_task（唯一约束）                                                                                                                                                                                                                         | <br /> |

***

## 角色权限矩阵

| 角色值 | 角色名称  | 浏览职位 | 投递简历 | 发布职位 | 企业认证 | 聊天通讯 | 收藏职位 | 用户管理 | 职位审核 | 企业审核 | 统计看板 | 操作审计 | 修改角色 |
| :-: | ----- | :--: | :--: | :--: | :--: | :--: | :--: | :--: | :--: | :--: | :--: | :--: | :--: |
|  0  | 求职者   |   ✅  |   ✅  |   ❌  |   ❌  |   ✅  |   ✅  |   ❌  |   ❌  |   ❌  |   ❌  |   ❌  |   ❌  |
|  1  | 企业 HR |   ✅  |   ❌  |   ✅  |   ✅  |   ✅  |   ❌  |   ❌  |   ❌  |   ❌  |   ❌  |   ❌  |   ❌  |
|  9  | 管理员   |   ✅  |   ❌  |   ❌  |   ❌  |   ❌  |   ❌  |   ✅  |   ✅  |   ✅  |   ✅  |   ✅  |   ❌  |
|  99 | 超级管理员 |   ✅  |   ❌  |   ❌  |   ❌  |   ❌  |   ❌  |   ✅  |   ✅  |   ✅  |   ✅  |   ✅  |   ✅  |

***

## 目录结构

```
UniSeek/
├── img/                               # 项目 Logo 与品牌素材（13 个文件）
├── sql/                               # 数据库脚本
│   ├── uniseek_schema.sql             #   建表脚本（15 张表 + 种子数据 + 索引外键）
│   ├── uniseek_mock_data_large.sql    #   大规模 Mock 测试数据
├── uniseek_mock_generator/            # Mock 数据生成器（Python 3）
│   ├── generators/                    #   各表数据生成器（enterprise / task / user 等 8 个）
│   ├── config.py / crypto.py          #   配置 & 加密工具
│   ├── datapool.py / generate.py      #   数据池 & 主生成入口
│   ├── sql_output.py / validate.py    #   SQL 输出 & 数据校验
│   └── requirements.txt               #   Python 依赖
├── uniseek_java/                      # 后端模块（Spring Boot 2.2.2 + MyBatis-Plus）
│   └── src/main/
│       ├── java/com/uniseek/
│       │   ├── UniSeekApplication.java    # 应用入口（@EnableScheduling）
│       │   ├── admin/                     # 运营管理后台
│       │   │   ├── controller/            #   5 个控制器（企业/日志/统计/职位/用户）
│       │   │   └── service/               #   管理后台业务逻辑
│       │   ├── auth/                      # 认证模块（登录/注册/实名/改密）
│       │   ├── chat/                      # 聊天模块（WebSocket 处理器 + 配置）
│       │   ├── common/                    # 通用组件（ApiResult/异常/MyBatisPlus 配置）
│       │   ├── config/                    # 全局配置（JWT 拦截器 / WebMVC）
│       │   ├── constant/                  # 常量定义（角色 / 操作类型）
│       │   ├── controller/                # 业务控制器（11 个 REST 接口入口）
│       │   ├── dao/                       # MyBatis-Plus Mapper 接口（15 个）
│       │   ├── dto/                       # 数据传输对象（16 个）
│       │   ├── entity/                    # 实体类（15 张表映射）
│       │   ├── operationlog/              # 操作日志（注解 + AOP 切面）
│       │   ├── service/                   # 业务服务层（14 个接口 + 实现）
│       │   ├── task/                      # 定时任务调度
│       │   ├── upload/                    # 文件上传（controller / service）
│       │   ├── user/                      # 用户模块（controller / service）
│       │   └── util/                      # 工具类（JWT / 密码加密）
│       └── resources/
│           ├── mapper/                    # MyBatis XML 映射文件（9 个）
│           ├── application.yml            # 应用配置（数据源 / JWT / 上传）
│           └── banner.txt                 # 启动 banner
├── uniseek_vue/                       # PC 前端模块（Vue 3 + TypeScript + Element Plus）
│   ├── src/
│   │   ├── api/                       #   API 请求封装（13 个模块）
│   │   ├── assets/                    #   静态资源（Logo / 图片 / SVG）
│   │   ├── components/                #   通用组件
│   │   ├── composables/               #   组合式函数（WebSocket）
│   │   ├── layouts/                   #   布局组件（DefaultLayout / AdminLayout）
│   │   ├── pages/                     #   页面组件
│   │   │   ├── admin/                 #     管理后台（Dashboard / 用户管理 / 职位审核 / 企业审核 / 日志）
│   │   │   ├── Login.vue / Home.vue / Jobs.vue / Resume.vue / Chat.vue / ...
│   │   │   └── 30+ 求职端/企业端页面
│   │   ├── router/                    #   路由配置
│   │   ├── stores/                    #   Pinia 状态管理（user / chat / app）
│   │   └── styles/                    #   全局样式
│   ├── dist/                          #   构建产物
│   └── 配置文件：index.html / vite.config.ts / tsconfig.json / package.json
├── uniseek_arkts/                     # 鸿蒙前端模块（ArkTS 6.1.1 + ArkUI）
│   └── entry/src/main/
│       ├── ets/
│       │   ├── common/                    # 11 个公共策略/组件
│       │   ├── components/                # 业务组件（application / chat / enterprise / filter）
│       │   ├── entryability/              # Ability 入口
│       │   ├── entrybackupability/        # 备份恢复 Ability
│       │   ├── pages/                     # 30+ 页面（tab / 详情 / 表单 / 设置）
│       │   ├── services/                  # 20 个服务文件（API / WebSocket / 业务服务）
│       │   └── utils/                     # 工具类
│       ├── resources/                     # 资源文件（颜色 / 字符串 / 图片 / 页面配置）
│       └── module.json5                   # 模块配置
│   ├── test/ / ohosTest/              # 15+ 单元测试文件
│   └── 配置文件：build-profile.json5 / oh-package.json5 / hvigorfile.ts
├── uniseek_liteos_m/                  # IoT 设备端固件（LiteOS-M + RK2206 + SHT30）
│   └── uniseek_app/
│       ├── include/                   #   8 个头文件（config / display / http / logic / rgb / sensor / state / wifi）
│       ├── src/                       #   8 个源文件（app / display / http / logic / rgb / sensor / state / wifi）
│       ├── tests/                     #   单元测试
│       ├── BUILD.gn                   #   构建配置
│       └── README_zh.md               #   固件说明文档
├── design.xd                          # UI 设计源文件（Adobe XD）
└── .gitignore
```

***

## 安全特性

- **密码加密**：使用 MD5 + 随机盐值加密存储，防止彩虹表攻击
- **JWT 鉴权**：Token 有效期 **7 天**，支持用户 ID、角色、脱敏手机号等声明
- **乐观锁**：`task` 表和 `task_application` 表使用 version 字段防止并发操作数据不一致
- **手机号脱敏**：JWT Token 中手机号自动脱敏（138\*\*\*\*1234），防止敏感信息泄露
- **身份证加密**：实名认证身份证号加密存储
- **操作日志审计**：基于 AOP 切面 + 自定义注解，自动记录关键操作日志
- **全局异常处理**：统一异常拦截，避免敏感信息泄露到客户端

***

## 开发规范

- 所有注释及文档使用中文书写，UI 文本内容使用中文
- 前后端严格分离，不跨模块编写代码
- 后端采用分层架构（Controller / Service / DAO / Entity），各层职责清晰
- 命名规范统一，遵循各语言官方最佳实践
- Git 操作前需说明变更内容并经确认后方可执行
- ArkTS 修改需先加载 hmos 相关技能了解鸿蒙原生能力

***

## 贡献指南

1. Fork 本仓库
2. 创建功能分支（`git checkout -b feature/xxx`）
3. 提交代码（`git commit -m 'feat: 添加某某功能'`）
4. 推送到分支（`git push origin feature/xxx`）
5. 创建 Pull Request

***

## 许可证

当前项目并未使用任何公开的开源协议，保留所有权利。如有任何问题，请直接与开发者联系。

***

## 联系方式

- 项目主页：<https://github.com/Dorufoc/UniSeek>
- 问题反馈：[Issues](https://github.com/Dorufoc/UniSeek/issues)

