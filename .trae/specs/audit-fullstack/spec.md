# 全栈代码审计 Spec

## Why
UniSeek 项目采用前后端分离架构（Java 1.8 + Vue 3），随着功能迭代积累了较多代码，但缺少系统性安全/质量审计。当前需要对该项目的 Java 后端与 Vue 前端进行全量代码审计，识别安全漏洞、健壮性缺陷、架构问题与性能瓶颈，为后续修复提供依据。

## What Changes
- **审计范围**：仅 `uniseek_java/` 与 `uniseek_vue/` 两个模块；不涉及 `uniseek_arkts/`
- **审计维度**：安全漏洞、健壮性与 Bug、架构与分层、性能与数据库
- **交付物**：
  - 本 spec 文档（含审计发现）
  - `findings.md`（按维度归类的问题清单，附文件:行号 + 修复建议）
  - `tasks.md`（每个发现项对应一个修复任务，可被后续迭代复用）
  - `checklist.md`（审计完成度验收清单）

## Impact
- **Affected specs**：本审计为 `audit-fullstack` 唯一 change-id，不影响其他 spec
- **Affected code**：覆盖
  - `uniseek_java/src/main/java/com/uniseek/**` 全部 ~120 个 .java 文件
  - `uniseek_vue/src/**` 下全部 .vue/.ts/.js 源文件（不含 `dist/` 产物）
  - `uniseek_java/src/main/resources/mapper/*.xml` 中的 SQL（性能/安全维度）
  - **不审计**：`pom.xml`、`vite.config.ts`、`application.yml`、`*.md`、Mock 生成器、ArkTS 全部

## ADDED Requirements

### Requirement: 审计报告完整覆盖四大维度
系统 SHALL 在 `findings.md` 中按以下四类归类每个发现项，并提供 文件:行号 + 严重程度 + 修复建议：
- **A. 安全漏洞**：SQL 注入、XSS、未授权访问、JWT/Session 漏洞、敏感信息泄露、文件上传/下载越权、CORS、CSRF、硬编码密钥
- **B. 健壮性与 Bug**：空指针、数组越界、并发竞态、事务一致性、异常吞咽、资源未关闭、边界条件、IO 失败
- **C. 架构与分层**：Service 越权调用 Mapper 与 Controller、循环依赖、重复代码、类过大、命名/分包违规、前后端契约不一致
- **D. 性能与数据库**：N+1 查询、缺少索引/分页、慢 SQL、全表扫描、连接池/线程池配置、批量插入、大字段返回

#### Scenario: 审计交付完成
- **WHEN** 审计流程结束
- **THEN** `findings.md` 至少包含 4 个分类小节，每个小节至少 1 条具体问题
- **AND** 每条问题必须包含：标题、维度标签、文件:行号、证据代码片段、修复建议

### Requirement: 跨子代理交叉验证
系统 SHALL 对每个候选问题由 2 个独立子代理验证存在性与严重程度，输出高/中/低置信度。**仅 ≥1 个子代理确认的问题进入最终报告**。

#### Scenario: 高置信问题
- **WHEN** 两个子代理均确认某问题存在
- **THEN** 该问题在报告中标记为「高置信度」

#### Scenario: 误报排除
- **WHEN** 两个子代理均判定为误报
- **THEN** 该问题不得进入最终报告

### Requirement: 输出可视化总结
系统 SHALL 至少提供 1 个 Mermaid 流程图总结本次审计的关键发现分布或核心调用链，并在报告中使用规范的颜色对比（`fill` + `color` 同时设置）。

## MODIFIED Requirements
无（本次仅为审计，不修改业务代码）

## REMOVED Requirements
无

## Out of Scope
- 不进行任何代码修改（仅审计与报告）
- 不审计 ArkTS 模块
- 不审计配置文件、构建脚本、Mock 数据生成器
- 不评估 UI 视觉设计、不审计 CSS 数值（除非影响交互正确性）
- 不审计 .vue 中的样式代码块
