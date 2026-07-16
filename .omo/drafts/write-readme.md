---
slug: write-readme
status: awaiting-approval
intent: clear
pending-action: write .omo/plans/write-readme.md
approach: 基于对项目全量文件（后端Java、前端Vue/ArkTS、数据库SQL、业务逻辑设计文档、API文档、配置文件）的深入探索，编写一份符合一线大厂开源项目标准的完整中文README.md
---

# Draft: write-readme

## Components (topology ledger)
<!-- Lock the SHAPE before depth. One row per top-level component that can succeed or fail independently. -->
| id | outcome | status |
|----|---------|--------|
| README.md | 一份涵盖项目概述、核心功能、技术栈、架构图、环境配置、安装部署、API文档、数据库设计、贡献指南、许可证等完整模块的README文档 | completed |

## Open assumptions (announced defaults)
| assumption | adopted default | rationale | reversible? |
|-------------|----------------|-----------|-------------|
| README语言 | 中文（全篇）| AGENTS.md 规定所有文档使用中文 | 否 |
| Markdown格式 | 标准GFM Markdown | 通用可读、GitHub友好 | 是 |
| 架构图格式 | ASCII Art 文本图 | 无需外部工具、内联展示 | 是 |
| 许可证 | MIT | 开源项目通用标准 | 是 |
| 图标/徽章 | shields.io | 开源项目规范 | 是 |

## Findings (cited - path:lines)
- **项目定位**: 优寻（UniSeek）兼职招聘平台，面向大学生和企业（README.md:1-4）
- **技术栈**: Java 1.8 / Spring Boot 2.2.2 / MyBatis-Plus 3.3.0 / MySQL 8 / Vue 3 + Element Plus + Pinia / ArkTS 6.1.1 (AGENTS.md:18-20; pom.xml:10-12)
- **架构模式**: 前后端分离，后端四层架构 Controller/Service/DAO/Entity (AGENTS.md:28-33, 36-37)
- **数据库**: 15张业务表，含独立盐值MD5加密、乐观锁、简历JSON快照、全文索引等设计亮点 (uniseek_schema.sql:1-8)
- **API设计**: 40+ RESTful接口，统一响应格式 code/message/data (api.md:25-64)
- **角色体系**: 4级角色 0=求职者 / 1=HR / 9=管理员 / 99=超级管理员 (AGENTS.md:87-92)
- **核心功能**: 职位CRUD、投递状态机（6状态流转）、简历快照、即时通讯、实名认证、运营统计看板、操作审计日志 (UniSeek全平台业务逻辑设计V2.md)
- **前端路由**: 20+页面，含路由守卫（auth/recruiter/admin三级权限）(router/index.ts:174-212)
- **Mock账号**: 超级管理员 18688886666/admin (README.md:76-82)

## Decisions (with rationale)
1. **采用成品级README结构**: 参考Vue/React/Apache等顶级开源项目标准，包含项目概览→技术栈→架构图→快速开始→API→数据库→贡献指南全链路
2. **架构图使用ASCII Art**: 无需Mermaid依赖，纯文本内联展示，跨平台兼容
3. **API文档链接引用**: 不复制全部API细节到README，引用已有 api.md 文件（3080行），保持README可读性
4. **保留原始README内容**: 兼容升级，覆盖已有README.md但保留其核心信息（Mock账号、角色说明、快速开始）

## Scope IN
- 项目概述与定位描述
- 核心功能矩阵（求职者/HR/管理员三端）
- 完整技术栈表格（含版本号）
- ASCII Art 架构图（分层展示）
- 环境配置与安装部署步骤
- API 文档概要（含表格列表），引用 api.md
- 数据库设计概览（15表+设计亮点）
- Mock测试账号与角色权限矩阵
- 贡献指南与开发规范
- 项目目录结构完整展示
- Docker部署建议
- 许可证与联系方式

## Scope OUT (Must NOT have)
- 不复制 api.md 的完整API细节（引用方式）
- 不复制 uniseek_schema.sql 的完整建表SQL
- 不包含实际业务的截图（除非用户要求）
- 不修改任何代码文件
- 不创建新文件，仅替换 README.md

## Open questions
无 - 所有信息已从代码库探索中获取

## Approval gate
status: awaiting-approval
