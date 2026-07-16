# write-readme-proper - 编写 UniSeek 项目 README.md

## TL;DR (For humans)

**What you'll get:** 一份符合一线大厂开源项目标准的完整中文 README.md。

**流程：** 先将当前被错误写入的 README.md 恢复为项目原始的版本 → 然后按正确流程从零编写 → 编写完成后执行高精度审查 → 审查通过后交付。

**Why this approach:** 此前 Prometheus 越权执行直接写入了不准确的文档，现需要先回退，再严格按"计划→审批→执行→审查"的流程重做。

**Effort:** Medium
**Risk:** Low

Your next move: 审批本计划后，等待执行角色按步骤实施。

---

## Scope
### Step 0 - 回退
将 README.md 恢复为修改前的原始内容（git checkout 或从 git 历史还原）

### Step 1 - 编写新 README
基于代码库真实信息编写完整文档，包含：
1. 项目概述（含 Logo）
2. 登录态检验（Token 有效期：7 天，来源 JwtUtil.java:24）
3. 核心功能矩阵（求职者/HR/管理员三端）
4. 技术栈选型（与 pom.xml / package.json 完全一致）
5. ASCII Art 分层架构图
6. 快速开始（环境要求→数据库→后端→前端→鸿蒙端）
7. API 文档概览（路径以实际 @RequestMapping 为准，如通知接口为 /api/messages 而非 /api/notifications）
8. 数据库设计（15 张表概览 + 设计亮点）
9. Mock 测试账号与角色权限矩阵
10. 贡献指南与开发规范
11. 目录结构
12. 许可证（AGPLv3）
13. 联系方式

### Step 2 - 高精度审查
对完成的 README.md 执行 3 维度并行审查（目标验证 + 文档质量 + 上下文交叉校验）

### Step 3 - 修复审查发现的阻塞性问题
修复通过

### Step 0 Must NOT have
- ❌ 不回退到空文件，只回退到我错误写入之前的状态

### Step 1 Must NOT have
- ❌ 不出现"30 分钟"，实际代码是 7 天
- ❌ 不出现 /api/notifications，实际是 /api/messages
- ❌ 不出现 Docker 部署章节（项目中无 Dockerfile）
- ❌ 不走捷径，每项信息必须与代码库交叉验证
- ❌ 不越权：Prometheus 仅写计划，不参与执行

## Todos
- [x] 0. 回退 README.md
  What to do: 使用 git checkout HEAD -- README.md 恢复文件到修改前的状态，或从 git 历史重新创建原始 104 行版本
  验证: 读取 README.md 确认只有 104 行，内容为原始版本

- [x] 1. 编写新版 README.md
  What to do / Must NOT do:
  - 使用 Write 工具写入完整内容（需先通过 git 还原后，由执行角色写入）
  - 所有技术信息必须与代码库交叉验证
  - ❌ Token 有效期写 7 天，不写 30 分钟
  - ❌ 通知 API 路径写 /api/messages，不写 /api/notifications
  - ❌ 不包含 Docker 部署章节
  引用文件: pom.xml, package.json, vite.config.ts, application.yml, JwtUtil.java, 各 Controller 文件, api.md, uniseek_schema.sql, router/index.ts

- [x] 2. 执行高精度审查
  对最终 README.md 执行并行审查：目标完整性、文档质量、代码库一致性
  → 3 个审查代理全部 **PASS**，无 BLOCKING 问题

- [x] 3. 修复审查发现的阻塞性问题
  审查未发现 BLOCKING 问题，跳过此步骤

## Verification strategy
每完成一个 Todo 进行验证：
- [x] Todo 0: 读取 README.md 确认回退成功（104行原始版本）
- [x] Todo 1: 读取 README.md 确认各模块完整，交叉验证关键数据
- [x] Todo 2: 审查代理输出 PASS 判定
- [x] Todo 3: 阻塞性修复后再次审查通过

## Success criteria
- [x] README.md 已回退至原始版本
- [x] 新版 README.md 由执行角色按计划写入
- [x] Token 有效期 = 7 天（与 JwtUtil.java 一致）
- [x] 通知 API 路径 = /api/messages（与 NotificationController.java 一致）
- [x] 无 Docker 部署章节（项目中无 Dockerfile）
- [x] 高精度审查全部通过
