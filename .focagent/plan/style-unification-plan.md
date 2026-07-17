# UniSeek Vue 前端样式统一与优化执行计划

## 1. 项目概述

### 1.1 项目背景
UniSeek 是一个招聘平台的前端项目，采用 Vue 3 框架开发。项目包含多个页面模块，包括求职者端、企业端和管理后台。为了提升用户体验和品牌一致性，需要对整个应用进行样式统一和优化。

### 1.2 核心目标
- **统一控件风格**：确保所有页面的按钮、输入框、卡片等控件风格一致
- **统一页面样式**：使整个应用界面更加协调、现代化
- **移除不必要的动画**：删除 hover 位移动画（transform: translateY, translateX），提升性能
- **统一颜色系统**：使用 `#1762FB` 作为主色调，替换所有旧的主色调

### 1.3 设计规范
- **主色调**：`#1762FB`（蓝色）
- **主色调悬停**：`#0052e6`
- **主色调背景**：`rgba(23, 98, 251, 0.08)`
- **主色调边框**：`rgba(23, 98, 251, 0.15)`
- **圆角系统**：
  - 小圆角：`6px`
  - 中圆角：`8px`
  - 大圆角：`12px`
- **阴影系统**：
  - 小阴影：`0 1px 3px rgba(0, 0, 0, 0.04)`
  - 中阴影：`0 4px 12px rgba(0, 0, 0, 0.06)`
  - 大阴影：`0 8px 24px rgba(0, 0, 0, 0.08)`

---

## 2. 当前进度

### 2.1 已完成页面
以下页面已完成样式统一：
- [x] `Home.vue` - 首页
- [x] `Login.vue` - 登录页
- [x] `Jobs.vue` - 职位列表页
- [x] `Profile.vue` - 个人中心
- [x] `Resume.vue` - 简历管理
- [x] `Company.vue` - 企业详情
- [x] `PostJob.vue` - 发布职位
- [x] `JobDetail.vue` - 职位详情
- [x] `PrivacyPolicy.vue` - 隐私政策
- [x] `UserAgreement.vue` - 用户协议

### 2.2 已完成颜色替换
- [x] 全局样式文件 `style.css` 已更新
- [x] 管理后台主题 `admin-theme.css` 已更新
- [x] 已完成 `rgba(0, 122, 255)` → `rgba(23, 98, 251)` 的替换

### 2.3 待完成任务
- [ ] 检查并更新其他页面样式
- [ ] 移除所有页面中的 hover 位移动画
- [ ] 验证所有修改后页面的视觉效果
- [ ] 确保样式系统的一致性

---

## 3. 详细执行步骤

### 阶段一：颜色系统统一

#### 任务 1.1：替换旧主色调 rgba(0, 122, 255)

**核心需求**：将所有页面中的 `rgba(0, 122, 255)` 替换为 `rgba(23, 98, 251)`

**核心边界**：
- 范围内：所有 Vue 组件文件中的 CSS 样式
- 范围外：JavaScript 逻辑代码、第三方库样式

**具体操作**：
1. 在以下文件中搜索并替换：
   - `AccountSecurity.vue`：第 434 行
     ```css
     /* 替换前 */
     background: rgba(0, 122, 255, 0.08);
     border: 1px solid rgba(0, 122, 255, 0.2);
     
     /* 替换后 */
     background: rgba(23, 98, 251, 0.08);
     border: 1px solid rgba(23, 98, 251, 0.15);
     ```
   
   - `EnterpriseCertification.vue`：第 423, 424, 426 行
     ```css
     /* 替换前 */
     background: rgba(0,122,255,0.06);
     border: 1px solid rgba(0,122,255,0.2);
     
     /* 替换后 */
     background: rgba(23, 98, 251, 0.08);
     border: 1px solid rgba(23, 98, 251, 0.15);
     ```
   
   - `MyApplications.vue`：第 42, 355, 360, 527, 528, 534, 652 行
     ```css
     /* 替换前 */
     background: rgba(0,122,255,0.08);
     background: rgba(0,122,255,0.05);
     background: rgba(0,122,255,0.06);
     border: 1px solid rgba(0,122,255,0.2);
     
     /* 替换后 */
     background: rgba(23, 98, 251, 0.08);
     background: rgba(23, 98, 251, 0.05);
     background: rgba(23, 98, 251, 0.06);
     border: 1px solid rgba(23, 98, 251, 0.15);
     ```

2. 使用全局搜索替换工具，确保不遗漏任何实例

**验证方法**：
- 使用 IDE 的全局搜索功能，搜索 `rgba(0, 122, 255)` 和 `rgba(0,122,255)`，确认无结果
- 启动开发服务器，访问相关页面，检查颜色是否正确

**依赖关系**：可独立执行

---

#### 任务 1.2：替换旧主色调 #409eff

**核心需求**：将所有页面中的 `#409eff` 替换为 `#1762FB`

**核心边界**：
- 范围内：所有 Vue 组件文件中的 CSS 样式
- 范围外：JavaScript 逻辑代码

**具体操作**：
1. 在以下文件中搜索并替换：
   - `Talents.vue`：第 336, 375 行
     ```css
     /* 替换前 */
     background: #409eff;
     
     /* 替换后 */
     background: #1762FB;
     ```
   
   - `ResumePool.vue`：第 550, 619, 688, 722 行
     ```css
     /* 替换前 */
     background: #409eff;
     border-left: 3px solid #409eff;
     
     /* 替换后 */
     background: #1762FB;
     border-left: 3px solid #1762FB;
     ```

2. 使用全局搜索替换工具，确保不遗漏任何实例

**验证方法**：
- 使用 IDE 的全局搜索功能，搜索 `#409eff`，确认无结果
- 启动开发服务器，访问人才库和简历池页面，检查颜色是否正确

**依赖关系**：可独立执行

---

### 阶段二：移除 hover 位移动画

#### 任务 2.1：移除 Messages.vue 中的位移动画

**核心需求**：移除 `transform: translateY` 和 `transform: translateX` 动画

**核心边界**：
- 范围内：`Messages.vue` 文件中的 CSS 动画
- 范围外：其他动画效果（如淡入淡出）

**具体操作**：
1. 打开 `Messages.vue` 文件
2. 定位到第 1082-1090 行，找到以下代码：
   ```css
   .action-fade-enter-active,
   .action-fade-leave-active {
     transition: opacity 0.2s, transform 0.2s;
   }

   .action-fade-enter-from,
   .action-fade-leave-to {
     opacity: 0;
     transform: translateY(4px);
   }
   ```
3. 修改为仅保留透明度动画：
   ```css
   .action-fade-enter-active,
   .action-fade-leave-active {
     transition: opacity 0.2s;
   }

   .action-fade-enter-from,
   .action-fade-leave-to {
     opacity: 0;
   }
   ```

4. 定位到第 1192-1215 行，找到简历操作按钮的滑入动画：
   ```css
   .resume-actions {
     transform: translateX(100%);
     transition: transform 0.25s ease;
   }
   .resume-bubble:hover .resume-actions {
     transform: translateX(0);
   }
   ```
5. 修改为直接显示，移除位移动画：
   ```css
   .resume-actions {
     opacity: 0;
     transition: opacity 0.25s ease;
   }
   .resume-bubble:hover .resume-actions {
     opacity: 1;
   }
   ```

**验证方法**：
- 启动开发服务器，访问消息页面
- 点击加号按钮，检查菜单是否仅有淡入淡出效果，无上下移动
- 悬停在简历消息上，检查操作按钮是否直接显示，无左右滑动

**依赖关系**：可独立执行

---

#### 任务 2.2：移除 Chat.vue 中的位移动画

**核心需求**：移除 `transform: translateY` 动画

**核心边界**：
- 范围内：`Chat.vue` 文件中的 CSS 动画
- 范围外：其他动画效果

**具体操作**：
1. 打开 `Chat.vue` 文件
2. 定位到第 761-769 行，找到以下代码：
   ```css
   .action-fade-enter-active,
   .action-fade-leave-active {
     transition: opacity 0.2s, transform 0.2s;
   }

   .action-fade-enter-from,
   .action-fade-leave-to {
     opacity: 0;
     transform: translateY(4px);
   }
   ```
3. 修改为仅保留透明度动画：
   ```css
   .action-fade-enter-active,
   .action-fade-leave-active {
     transition: opacity 0.2s;
   }

   .action-fade-enter-from,
   .action-fade-leave-to {
     opacity: 0;
   }
   ```

**验证方法**：
- 启动开发服务器，访问聊天页面
- 点击加号按钮，检查菜单是否仅有淡入淡出效果，无上下移动

**依赖关系**：可独立执行

---

#### 任务 2.3：移除 Talents.vue 中的位移动画

**核心需求**：移除卡片 hover 时的 `transform: translateY` 动画

**核心边界**：
- 范围内：`Talents.vue` 文件中的卡片 hover 动画
- 范围外：其他动画效果

**具体操作**：
1. 打开 `Talents.vue` 文件
2. 定位到第 353-362 行，找到以下代码：
   ```css
   .talent-card {
     transition: transform 0.15s;
     position: relative;
   }

   .talent-card:hover {
     transform: translateY(-2px);
   }
   ```
3. 修改为仅保留阴影变化：
   ```css
   .talent-card {
     transition: box-shadow 0.15s;
     position: relative;
   }

   .talent-card:hover {
     box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
   }
   ```

**验证方法**：
- 启动开发服务器，访问人才库页面
- 悬停在人才卡片上，检查是否仅有阴影变化，无上下移动

**依赖关系**：可独立执行

---

#### 任务 2.4：检查并移除其他页面中的位移动画

**核心需求**：全面检查所有页面，移除不必要的位移动画

**核心边界**：
- 范围内：所有 Vue 组件文件中的位移动画
- 范围外：必要的功能动画（如页面切换）

**具体操作**：
1. 使用全局搜索功能，搜索以下关键词：
   - `transform: translateY`
   - `transform: translateX`
   - `translateY(`
   - `translateX(`

2. 对每个搜索结果进行评估：
   - 如果是 hover 效果中的位移动画，则移除
   - 如果是功能性动画（如页面加载、模态框出现），则保留

3. 需要检查的文件列表：
   - `ErrorPage.vue`
   - `ScreenPreview.vue`
   - `admin/Dashboard.vue`
   - `admin/UserManagement.vue`
   - `admin/OperationLogs.vue`
   - `admin/TaskAudit.vue`
   - `admin/EnterpriseAudit.vue`

**验证方法**：
- 全局搜索确认无不必要的位移动画
- 启动开发服务器，访问所有页面，检查交互效果

**依赖关系**：依赖任务 2.1、2.2、2.3 完成

---

### 阶段三：控件风格统一

#### 任务 3.1：统一按钮样式

**核心需求**：确保所有页面的按钮风格一致

**核心边界**：
- 范围内：所有自定义按钮样式
- 范围外：Element Plus 原生按钮（已通过主题统一）

**具体操作**：
1. 检查以下文件中的自定义按钮样式：
   - `Talents.vue`：`.search-btn`、`.filter-tab`、`.contact-btn`
   - `MyApplications.vue`：`.action-btn`、`.empty-action`
   - `EnterpriseCertification.vue`：`.submit-btn`、`.cancel-btn`
   - `AccountSecurity.vue`：`.save-btn`
   - `JobManagement.vue`：`.jm-btn` 系列

2. 确保所有按钮遵循以下规范：
   ```css
   /* 主按钮 */
   .btn-primary {
     background: #1762FB;
     color: #fff;
     border: none;
     border-radius: 6px;
     padding: 8px 16px;
     font-weight: 500;
     transition: background 0.2s;
   }
   .btn-primary:hover {
     background: #0052e6;
   }

   /* 次级按钮 */
   .btn-secondary {
     background: rgba(23, 98, 251, 0.08);
     color: #1762FB;
     border: 1px solid rgba(23, 98, 251, 0.15);
     border-radius: 6px;
     padding: 8px 16px;
     font-weight: 500;
     transition: all 0.2s;
   }
   .btn-secondary:hover {
     background: rgba(23, 98, 251, 0.12);
   }
   ```

3. 对比各页面按钮样式，确保一致性

**验证方法**：
- 启动开发服务器，访问所有包含自定义按钮的页面
- 检查按钮的颜色、圆角、悬停效果是否一致

**依赖关系**：依赖阶段一完成

---

#### 任务 3.2：统一卡片样式

**核心需求**：确保所有页面的卡片风格一致

**核心边界**：
- 范围内：所有自定义卡片样式
- 范围外：Element Plus 原生卡片（已通过主题统一）

**具体操作**：
1. 检查以下文件中的卡片样式：
   - `Talents.vue`：`.talent-card`
   - `MyApplications.vue`：`.app-card`、`.interview-card`、`.favorite-card`
   - `ResumePool.vue`：`.application-card`、`.interview-card`
   - `JobManagement.vue`：`.job-card`

2. 确保所有卡片遵循以下规范：
   ```css
   .card {
     background: #fff;
     border-radius: 8px;
     padding: 16px;
     box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
     transition: box-shadow 0.2s;
   }
   .card:hover {
     box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
   }
   ```

3. 对比各页面卡片样式，确保一致性

**验证方法**：
- 启动开发服务器，访问所有包含卡片的页面
- 检查卡片的背景色、圆角、阴影是否一致

**依赖关系**：依赖阶段一完成

---

#### 任务 3.3：统一输入框样式

**核心需求**：确保所有页面的输入框风格一致

**核心边界**：
- 范围内：所有自定义输入框样式
- 范围外：Element Plus 原生输入框（已通过主题统一）

**具体操作**：
1. 检查以下文件中的输入框样式：
   - `Talents.vue`：`.search-input`
   - `Messages.vue`：输入区域样式
   - `Chat.vue`：输入区域样式

2. 确保所有输入框遵循以下规范：
   ```css
   .input {
     border: 1px solid #e2e8f0;
     border-radius: 6px;
     padding: 8px 12px;
     transition: all 0.2s;
   }
   .input:hover {
     border-color: #1762FB;
   }
   .input:focus {
     border-color: #1762FB;
     box-shadow: 0 0 0 3px rgba(23, 98, 251, 0.1);
   }
   ```

3. 对比各页面输入框样式，确保一致性

**验证方法**：
- 启动开发服务器，访问所有包含输入框的页面
- 检查输入框的边框、圆角、焦点效果是否一致

**依赖关系**：依赖阶段一完成

---

### 阶段四：验证与测试

#### 任务 4.1：视觉验证

**核心需求**：验证所有修改后页面的视觉效果

**核心边界**：
- 范围内：所有已修改的页面
- 范围外：未修改的页面

**具体操作**：
1. 启动开发服务器：
   ```bash
   cd uniseek_vue
   npm run dev
   ```

2. 依次访问以下页面，检查视觉效果：
   - 首页 (`/`)
   - 职位列表 (`/jobs`)
   - 人才库 (`/talents`)
   - 消息页面 (`/messages`)
   - 个人中心 (`/profile`)
   - 账号管理 (`/account-security`)
   - 企业认证 (`/enterprise-cert`)
   - 我的求职 (`/my-applications`)
   - 简历池 (`/resume-pool`)
   - 职位管理 (`/job-management`)
   - 管理后台 (`/admin/dashboard`)

3. 检查要点：
   - 主色调是否统一为 `#1762FB`
   - 按钮样式是否一致
   - 卡片样式是否一致
   - 输入框样式是否一致
   - 是否还有不必要的位移动画

4. 使用浏览器开发者工具，检查 CSS 样式是否符合规范

**验证方法**：
- 截图记录每个页面的视觉效果
- 对比不同页面的控件风格，确保一致性

**依赖关系**：依赖阶段一、二、三完成

---

#### 任务 4.2：交互测试

**核心需求**：测试所有页面的交互效果

**核心边界**：
- 范围内：所有已修改的页面
- 范围外：未修改的页面

**具体操作**：
1. 测试以下交互场景：
   - 按钮点击、悬停效果
   - 卡片悬停效果
   - 输入框焦点效果
   - 菜单展开、收起动画
   - 页面切换动画

2. 检查要点：
   - 所有交互是否流畅
   - 是否还有不必要的位移动画
   - 颜色变化是否符合预期

3. 在不同浏览器中测试：
   - Chrome
   - Firefox
   - Safari
   - Edge

**验证方法**：
- 记录测试结果，确保所有交互正常
- 检查浏览器控制台是否有错误

**依赖关系**：依赖任务 4.1 完成

---

#### 任务 4.3：响应式测试

**核心需求**：测试所有页面在不同屏幕尺寸下的表现

**核心边界**：
- 范围内：所有已修改的页面
- 范围外：未修改的页面

**具体操作**：
1. 使用浏览器开发者工具的响应式模式，测试以下尺寸：
   - 桌面端：1920x1080、1440x900、1366x768
   - 平板端：1024x768、768x1024
   - 移动端：375x667、414x896

2. 检查要点：
   - 布局是否正确适配
   - 控件是否正确显示
   - 交互是否正常

3. 特别关注：
   - 导航菜单在移动端的显示
   - 卡片列表在不同屏幕下的布局
   - 按钮和输入框在移动端的尺寸

**验证方法**：
- 记录测试结果，确保所有页面在响应式模式下正常
- 截图记录关键页面的响应式效果

**依赖关系**：依赖任务 4.1 完成

---

## 4. 颜色映射表

### 4.1 主色调映射
| 旧颜色值 | 新颜色值 | 使用场景 |
|---------|---------|---------|
| `rgba(0, 122, 255, 1)` | `#1762FB` | 主色调 |
| `rgba(0, 122, 255, 0.08)` | `rgba(23, 98, 251, 0.08)` | 主色调背景 |
| `rgba(0, 122, 255, 0.06)` | `rgba(23, 98, 251, 0.06)` | 主色调浅背景 |
| `rgba(0, 122, 255, 0.05)` | `rgba(23, 98, 251, 0.05)` | 主色调极浅背景 |
| `rgba(0, 122, 255, 0.2)` | `rgba(23, 98, 251, 0.15)` | 主色调边框 |
| `#409eff` | `#1762FB` | Element Plus 默认主色调 |

### 4.2 功能色映射
| 颜色值 | 使用场景 |
|-------|---------|
| `#10b981` | 成功色 |
| `#f59e0b` | 警告色 |
| `#ef4444` | 危险色 |
| `#6366f1` | 信息色 |

### 4.3 中性色映射
| 颜色值 | 使用场景 |
|-------|---------|
| `#1a1a2e` | 主要文本 |
| `#64748b` | 次要文本 |
| `#94a3b8` | 辅助文本 |
| `#e2e8f0` | 边框色 |
| `#f8fafc` | 页面背景 |
| `#ffffff` | 卡片背景 |

---

## 5. 动画移除清单

### 5.1 已确认需要移除的动画
| 文件 | 行号 | 动画类型 | 说明 |
|-----|------|---------|------|
| `Messages.vue` | 1082-1090 | `translateY(4px)` | 菜单淡入淡出动画 |
| `Messages.vue` | 1192-1215 | `translateX(100%)` | 简历操作按钮滑入动画 |
| `Chat.vue` | 761-769 | `translateY(4px)` | 菜单淡入淡出动画 |
| `Talents.vue` | 353-362 | `translateY(-2px)` | 卡片 hover 位移动画 |

### 5.2 需要检查的动画
| 文件 | 动画类型 | 说明 |
|-----|---------|------|
| `ErrorPage.vue` | 待检查 | 检查是否有不必要的位移动画 |
| `ScreenPreview.vue` | 待检查 | 检查是否有不必要的位移动画 |
| `admin/*.vue` | 待检查 | 检查管理后台页面是否有不必要的位移动画 |

### 5.3 保留的动画
以下动画应保留，因为是功能性动画：
- 页面加载动画（如 `admin-fade-in`）
- 模态框出现动画
- 页面切换动画

---

## 6. 验证方法

### 6.1 代码验证
1. **全局搜索验证**：
   ```bash
   # 搜索旧颜色值
   grep -r "rgba(0, 122, 255)" uniseek_vue/src/
   grep -r "rgba(0,122,255)" uniseek_vue/src/
   grep -r "#409eff" uniseek_vue/src/
   
   # 搜索位移动画
   grep -r "transform: translateY" uniseek_vue/src/
   grep -r "transform: translateX" uniseek_vue/src/
   ```

2. **CSS 规范验证**：
   - 使用 Stylelint 检查 CSS 代码规范
   - 确保所有颜色值使用统一格式

### 6.2 视觉验证
1. **页面截图对比**：
   - 对每个页面截图
   - 对比不同页面的控件风格

2. **颜色拾取验证**：
   - 使用浏览器开发者工具的颜色拾取器
   - 验证主色调是否为 `#1762FB`

### 6.3 交互验证
1. **手动测试**：
   - 测试所有按钮的点击、悬停效果
   - 测试所有卡片的悬停效果
   - 测试所有输入框的焦点效果

2. **自动化测试**：
   - 使用 Cypress 或 Playwright 进行端到端测试
   - 验证关键交互流程

---

## 7. 注意事项和最佳实践

### 7.1 注意事项
1. **备份原始文件**：
   - 在修改前，确保代码已提交到版本控制系统
   - 如需回滚，可使用 `git checkout` 恢复

2. **逐步修改**：
   - 按阶段逐步修改，不要一次性修改所有文件
   - 每完成一个阶段，进行验证和测试

3. **保持一致性**：
   - 确保所有页面使用相同的设计规范
   - 避免在不同页面使用不同的样式

4. **性能优化**：
   - 移除不必要的动画可提升性能
   - 避免使用过多的 `box-shadow` 和 `transform`

### 7.2 最佳实践
1. **使用 CSS 变量**：
   ```css
   :root {
     --primary-color: #1762FB;
     --primary-hover: #0052e6;
     --primary-bg: rgba(23, 98, 251, 0.08);
   }
   
   .button {
     background: var(--primary-color);
   }
   ```

2. **使用 scoped 样式**：
   ```vue
   <style scoped>
   .component {
     /* 样式仅作用于当前组件 */
   }
   </style>
   ```

3. **遵循 BEM 命名规范**：
   ```css
   .block {}
   .block__element {}
   .block--modifier {}
   ```

4. **使用 Flexbox 和 Grid 布局**：
   - 避免使用浮动布局
   - 使用 Flexbox 和 Grid 实现响应式布局

5. **移动端优先**：
   - 先设计移动端样式
   - 使用媒体查询适配桌面端

---

## 8. 任务依赖关系图

```
阶段一：颜色系统统一
├─ 任务 1.1：替换旧主色调 rgba(0, 122, 255) [可独立执行]
└─ 任务 1.2：替换旧主色调 #409eff [可独立执行]

阶段二：移除 hover 位移动画
├─ 任务 2.1：移除 Messages.vue 中的位移动画 [可独立执行]
├─ 任务 2.2：移除 Chat.vue 中的位移动画 [可独立执行]
├─ 任务 2.3：移除 Talents.vue 中的位移动画 [可独立执行]
└─ 任务 2.4：检查并移除其他页面中的位移动画 [依赖 2.1, 2.2, 2.3]

阶段三：控件风格统一
├─ 任务 3.1：统一按钮样式 [依赖阶段一]
├─ 任务 3.2：统一卡片样式 [依赖阶段一]
└─ 任务 3.3：统一输入框样式 [依赖阶段一]

阶段四：验证与测试
├─ 任务 4.1：视觉验证 [依赖阶段一、二、三]
├─ 任务 4.2：交互测试 [依赖 4.1]
└─ 任务 4.3：响应式测试 [依赖 4.1]
```

---

## 9. 时间估算

| 阶段 | 任务 | 预计时间 |
|-----|------|---------|
| 阶段一 | 任务 1.1 | 30 分钟 |
| 阶段一 | 任务 1.2 | 20 分钟 |
| 阶段二 | 任务 2.1 | 20 分钟 |
| 阶段二 | 任务 2.2 | 15 分钟 |
| 阶段二 | 任务 2.3 | 15 分钟 |
| 阶段二 | 任务 2.4 | 40 分钟 |
| 阶段三 | 任务 3.1 | 1 小时 |
| 阶段三 | 任务 3.2 | 1 小时 |
| 阶段三 | 任务 3.3 | 45 分钟 |
| 阶段四 | 任务 4.1 | 1 小时 |
| 阶段四 | 任务 4.2 | 1 小时 |
| 阶段四 | 任务 4.3 | 1 小时 |
| **总计** | | **约 9 小时** |

---

## 10. 附录

### 10.1 相关文件清单
- `uniseek_vue/src/style.css` - 全局样式文件
- `uniseek_vue/src/styles/admin-theme.css` - 管理后台主题
- `uniseek_vue/src/pages/Messages.vue` - 消息页面
- `uniseek_vue/src/pages/Chat.vue` - 聊天页面
- `uniseek_vue/src/pages/Talents.vue` - 人才库页面
- `uniseek_vue/src/pages/MyApplications.vue` - 我的求职页面
- `uniseek_vue/src/pages/EnterpriseCertification.vue` - 企业认证页面
- `uniseek_vue/src/pages/AccountSecurity.vue` - 账号管理页面
- `uniseek_vue/src/pages/ResumePool.vue` - 简历池页面
- `uniseek_vue/src/pages/JobManagement.vue` - 职位管理页面
- `uniseek_vue/src/pages/ErrorPage.vue` - 错误页面
- `uniseek_vue/src/pages/ScreenPreview.vue` - 数据大屏
- `uniseek_vue/src/pages/admin/Dashboard.vue` - 管理后台工作台
- `uniseek_vue/src/pages/admin/UserManagement.vue` - 用户管理
- `uniseek_vue/src/pages/admin/OperationLogs.vue` - 操作日志
- `uniseek_vue/src/pages/admin/TaskAudit.vue` - 职位审核
- `uniseek_vue/src/pages/admin/EnterpriseAudit.vue` - 企业审核

### 10.2 参考资源
- [Vue 3 官方文档](https://cn.vuejs.org/)
- [Element Plus 官方文档](https://element-plus.org/zh-CN/)
- [CSS 变量使用指南](https://developer.mozilla.org/zh-CN/docs/Web/CSS/Using_CSS_custom_properties)
- [Flexbox 布局指南](https://css-tricks.com/snippets/css/a-guide-to-flexbox/)
- [Grid 布局指南](https://css-tricks.com/snippets/css/complete-guide-grid/)

---

**文档版本**：1.0  
**创建日期**：2026-07-17  
**最后更新**：2026-07-17  
**维护者**：UniSeek 开发团队
