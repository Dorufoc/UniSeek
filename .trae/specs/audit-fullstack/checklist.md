# 审计验收清单

## 范围类
- [x] 已覆盖 `uniseek_java/src/main/java/com/uniseek/**` 全部 .java 源文件
- [x] 已覆盖 `uniseek_vue/src/**` 全部 .vue/.ts/.js 源文件
- [x] 已覆盖 `uniseek_java/src/main/resources/mapper/*.xml` 全部 SQL
- [x] 未审计 `uniseek_arkts/`（按用户要求）
- [x] 未审计 `dist/`、`node_modules/`、`.idea/`、Mock 生成器、`.md`/`.sql`/`.json`/构建脚本

## 维度类
- [x] A. 安全漏洞维度已输出至少 1 条具体问题（共 8 条）
- [x] B. 健壮性与 Bug 维度已输出至少 1 条具体问题（共 4 条）
- [x] C. 架构与分层维度已输出至少 1 条具体问题（共 3 条）
- [x] D. 性能与数据库维度已输出至少 1 条具体问题（共 4 条）

## 质量类
- [x] 每条问题包含：标题、维度标签（A/B/C/D）、严重程度（critical/major/minor）、文件:行号
- [x] 每条问题包含证据代码片段（≤10 行）
- [x] 每条问题包含具体修复建议（可执行的代码或步骤）
- [x] 跨子代理交叉验证已执行（6 子代理并行 + 主代理 self-review），置信度已标注
- [x] 低置信度（0/2 验证通过）问题已剔除，9 条误报已记录于 findings.md 「已剔除的误报」表格

## 可视化类
- [x] 至少 1 个 Mermaid 图已生成（findings.md 含 2 个：审计问题分布 + 核心调用链）
- [x] Mermaid 节点 `style` 同时设置 `fill` + `color`，确保深/浅主题均可读

## 交付物类
- [x] `findings.md` 已落盘（共 19 条问题，含优先级表与误报说明）
- [x] `spec.md`、`tasks.md`、`checklist.md` 已落盘（本目录）
- [x] 所有交付物使用中文撰写（与项目语言规范一致）
- [x] 报告中引用的文件路径全部使用 `file:///` 协议，可点击跳转

## 误报控制
- [x] 未对纯 UI 样式/CSS 数值/视觉设计发评论
- [x] 未对构建脚本、配置文件、`.md` 发评论（`application.yml` 中的硬编码密钥/密码除外，属安全维度）
- [x] 未对被识别为「用户刻意为之」的删除/重构发评论
- [x] 静态类型语言（Java）默认构建通过，未对未证明的类型/接口缺失发评论
- [x] Vue `dist/` 产物虽含大体积 JS，已明确不审计
