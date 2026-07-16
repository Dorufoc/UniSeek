# readme-hotfix - 修复 README.md 阻塞性问题

## TL;DR (For humans)

**What you'll get:** 修复 README.md 中高精度审查发现的 3 个阻塞性错误：JWT Token 有效期（30分钟→7天）、通知 API 路径（/api/notifications→/api/messages）、删除无法执行的 Docker 部署章节。

**Why this approach:** 审查代理逐行对比了 README 与实际代码，确认这 3 个问题会导致开发者按文档操作时产生严重误导（API 调不通、Token 意外过期、Docker 构建失败），必须在文档发布前修正。

**What it will NOT do:** 本次不涉及补充 30+ 遗漏 API 端点、前端路由页面、目录结构等非阻塞性优化项——这些可放入后续计划。

**Effort:** Short
**Risk:** Low - 3 处精确字符串替换，不涉及代码修改

Your next move: 批准本计划后，执行角色将依次完成 3 项修复。

---

## Scope
### Must have
1. JWT Token 有效期：`30 分钟` → `7 天`
2. 通知 API 路径：`/api/notifications` → `/api/messages`（共 3 处）
3. Docker 部署章节：整段删除

### Must NOT have
- ❌ 不修改任何代码文件
- ❌ 不创建 Dockerfile
- ❌ 不补充非阻塞性的遗漏 API/路由

## Verification strategy
- 修复后使用 `grep` 验证 "30 分钟" 和 "/api/notifications" 在 README 中不再出现
- 使用 `grep` 验证 "Docker 部署（推荐）" 已删除
- 使用 `grep` 验证 "7 天" 和 "/api/messages" 已出现

## Todos
- [ ] 1. 修复 JWT Token 有效期
  文件: `README.md`
  操作: 将 `Token 有效期：30 分钟` 替换为 `Token 有效期：7 天`
  验证: grep "30 分钟" 无结果，grep "7 天" 有结果

- [ ] 2. 修复通知 API 路径
  文件: `README.md`
  操作: 将所有 `/api/notifications` 替换为 `/api/messages`（共 3 处）
  验证: grep "/api/notifications" 无结果，grep "/api/messages" 出现 3 次

- [ ] 3. 删除 Docker 部署章节
  文件: `README.md`
  操作: 从 "### Docker 部署（推荐）" 到代码块结束的行删除
  验证: grep "Docker 部署" 无结果

## Final verification
- [ ] F1. 确认 README.md 中无 "30 分钟" 残留
- [ ] F2. 确认 README.md 中无 "/api/notifications" 残留
- [ ] F3. 确认 README.md 中无 "Docker 部署" 残留
- [ ] F4. 确认文件仍可正常打开，前后内容连贯

## Commit strategy
等待用户确认后提交。
