const pptxgen = require('pptxgenjs');
const {
  safeOuterShadow,
  warnIfSlideHasOverlaps,
  warnIfSlideElementsOutOfBounds,
} = require('./pptxgenjs_helpers');

const pptx = new pptxgen();
pptx.layout = 'LAYOUT_WIDE';
pptx.author = 'UniSeek Team';
pptx.company = 'UniSeek';
pptx.subject = 'UniSeek 团队成员核心工作汇总';
pptx.title = 'UniSeek（优寻）兼职招聘平台｜团队成员核心工作汇总';
pptx.lang = 'zh-CN';
pptx.theme = {
  headFontFace: 'Microsoft YaHei',
  bodyFontFace: 'Microsoft YaHei',
  lang: 'zh-CN',
};
pptx.defineLayout({ name: 'WIDE', width: 13.333, height: 7.5 });

const C = {
  navy: '08182F', blue: '1762FB', cyan: '2BC8FF', mint: '2ED8A3',
  orange: 'FF9F43', purple: '8A6CFF', ink: '13213A', text: '30405D',
  muted: '71809A', pale: 'F3F7FF', line: 'DCE6F6', white: 'FFFFFF',
  darkCard: '10284A', red: 'F05B6E', sky: 'EAF3FF', green: 'E9FBF4',
};
const W = 13.333; const H = 7.5;
const shadow = safeOuterShadow('000000', 0.14, 45, 2, 1);

function addBg(slide, dark = false) {
  slide.background = { color: dark ? C.navy : C.white };
  if (dark) {
    slide.addShape(pptx.ShapeType.rect, { x: 0, y: 0, w: W, h: H, fill: { color: C.navy }, line: { color: C.navy } });
    // 仅保留画布内的装饰线，避免影响幻灯片边界检查。
    slide.addShape(pptx.ShapeType.line, { x: 9.5, y: 0.62, w: 2.6, h: 0, line: { color: '17467D', transparency: 35, width: 1.2 } });
    slide.addShape(pptx.ShapeType.line, { x: 10.3, y: 0.9, w: 1.8, h: 0, line: { color: '17467D', transparency: 55, width: 0.8 } });
  } else {
    slide.addShape(pptx.ShapeType.rect, { x: 0, y: 0, w: W, h: 0.09, fill: { color: C.blue }, line: { color: C.blue } });
  }
}

function addHeader(slide, title, kicker, page) {
  slide.addText(kicker.toUpperCase(), { x: 0.62, y: 0.38, w: 5.8, h: 0.24, fontFace: 'Microsoft YaHei', fontSize: 8.5, bold: true, color: C.blue, charSpacing: 1.7, margin: 0 });
  slide.addText(title, { x: 0.62, y: 0.7, w: 9.6, h: 0.5, fontFace: 'Microsoft YaHei', fontSize: 25, bold: true, color: C.ink, margin: 0 });
  slide.addText(`0${page}`, { x: 11.95, y: 0.4, w: 0.72, h: 0.32, fontSize: 11, bold: true, align: 'right', color: C.blue, margin: 0 });
  slide.addShape(pptx.ShapeType.line, { x: 0.62, y: 1.34, w: 12.08, h: 0, line: { color: C.line, width: 0.7 } });
}

function addFooter(slide, dark = false) {
  slide.addText('UniSeek（优寻）兼职招聘平台  ·  团队成员核心工作汇总', { x: 0.62, y: 7.15, w: 8.8, h: 0.14, fontSize: 7.5, color: dark ? 'A7BEDD' : '8A9AB3', margin: 0 });
}

function pill(slide, text, x, y, w, color = C.blue) {
  slide.addShape(pptx.ShapeType.roundRect, { x, y, w, h: 0.32, rectRadius: 0.06, fill: { color, transparency: 86 }, line: { color, transparency: 100 } });
  slide.addText(text, { x, y: y + 0.05, w, h: 0.16, fontSize: 7.2, bold: true, color, align: 'center', margin: 0 });
}

function metric(slide, value, label, x, y, color = C.blue) {
  slide.addText(value, { x, y, w: 1.7, h: 0.42, fontSize: 25, bold: true, color, margin: 0, align: 'center' });
  slide.addText(label, { x, y: y + 0.48, w: 1.7, h: 0.23, fontSize: 8.6, color: C.muted, margin: 0, align: 'center' });
}

function card(slide, x, y, w, h, opt = {}) {
  slide.addShape(pptx.ShapeType.roundRect, { x, y, w, h, rectRadius: 0.07, fill: { color: opt.fill || C.white }, line: { color: opt.line || C.line, width: 0.6 }, shadow: opt.shadow === false ? undefined : shadow });
}

function memberCard(slide, cfg) {
  const { x, y, w, h, name, role, color, pages, focus, tech } = cfg;
  card(slide, x, y, w, h, { fill: C.white });
  slide.addShape(pptx.ShapeType.roundRect, { x: x + 0.18, y: y + 0.18, w: 0.7, h: 0.7, rectRadius: 0.1, fill: { color }, line: { color } });
  slide.addText(name.substring(0, 1), { x: x + 0.18, y: y + 0.33, w: 0.7, h: 0.22, fontSize: 17, bold: true, color: C.white, align: 'center', margin: 0 });
  slide.addText(name, { x: x + 1.02, y: y + 0.2, w: w - 1.2, h: 0.28, fontSize: 14, bold: true, color: C.ink, margin: 0 });
  slide.addText(role, { x: x + 1.02, y: y + 0.54, w: w - 1.2, h: 0.23, fontSize: 7.6, color: C.muted, margin: 0 });
  pill(slide, pages, x + 0.18, y + 1.02, 0.98, color);
  slide.addText(focus, { x: x + 0.18, y: y + 1.48, w: w - 0.36, h: 0.48, fontSize: 8.6, bold: true, color: C.text, breakLine: false, margin: 0 });
  slide.addText(tech, { x: x + 0.18, y: y + 2.14, w: w - 0.36, h: 0.46, fontSize: 7.3, color: C.muted, breakLine: false, margin: 0 });
}

function memberSlide(slide, d, page) {
  addBg(slide, false); addHeader(slide, d.name + '｜' + d.title, d.kicker, page);
  slide.addShape(pptx.ShapeType.roundRect, { x: 0.62, y: 1.68, w: 3.08, h: 4.98, rectRadius: 0.08, fill: { color: d.color }, line: { color: d.color } });
  slide.addText(d.name.substring(0, 1), { x: 0.94, y: 2.02, w: 1.1, h: 0.7, fontSize: 46, bold: true, color: C.white, margin: 0 });
  slide.addText(d.name, { x: 0.94, y: 2.82, w: 2.3, h: 0.32, fontSize: 22, bold: true, color: C.white, margin: 0 });
  slide.addText(d.role, { x: 0.94, y: 3.26, w: 2.3, h: 0.52, fontSize: 9, color: 'D8EAFF', breakLine: false, margin: 0 });
  slide.addShape(pptx.ShapeType.line, { x: 0.94, y: 4.02, w: 1.94, h: 0, line: { color: C.white, transparency: 55, width: 0.8 } });
  slide.addText(d.tagline, { x: 0.94, y: 4.28, w: 2.16, h: 0.9, fontSize: 11.2, bold: true, color: C.white, breakLine: false, margin: 0 });
  slide.addText(d.foot, { x: 0.94, y: 5.76, w: 2.15, h: 0.35, fontSize: 7.6, color: 'D8EAFF', margin: 0 });

  slide.addText('核心交付', { x: 4.08, y: 1.72, w: 2.2, h: 0.26, fontSize: 12, bold: true, color: C.ink, margin: 0 });
  d.deliveries.forEach((item, i) => {
    const yy = 2.15 + i * 0.76;
    slide.addShape(pptx.ShapeType.ellipse, { x: 4.08, y: yy + 0.03, w: 0.24, h: 0.24, fill: { color: d.color }, line: { color: d.color } });
    slide.addText(String(i + 1), { x: 4.08, y: yy + 0.075, w: 0.24, h: 0.1, fontSize: 6.5, bold: true, color: C.white, align: 'center', margin: 0 });
    slide.addText(item, { x: 4.46, y: yy, w: 4.15, h: 0.38, fontSize: 10.2, color: C.text, breakLine: false, margin: 0 });
  });
  card(slide, 8.92, 1.68, 3.76, 2.36, { fill: C.pale, line: 'D7E7FE', shadow: false });
  slide.addText('技术亮点', { x: 9.2, y: 1.96, w: 2.2, h: 0.24, fontSize: 12, bold: true, color: d.color, margin: 0 });
  slide.addText(d.tech, { x: 9.2, y: 2.36, w: 3.18, h: 1.3, fontSize: 8.8, color: C.text, breakLine: false, valign: 'top', margin: 0.02 });
  card(slide, 8.92, 4.28, 3.76, 2.38, { fill: 'F8FAFE', line: C.line, shadow: false });
  slide.addText('工程价值', { x: 9.2, y: 4.56, w: 2.2, h: 0.24, fontSize: 12, bold: true, color: d.color, margin: 0 });
  slide.addText(d.value, { x: 9.2, y: 4.95, w: 3.18, h: 1.15, fontSize: 9.2, color: C.text, breakLine: false, valign: 'top', margin: 0.02 });
  addFooter(slide);
}

// 1 封面
{
  const s = pptx.addSlide(); addBg(s, true);
  s.addShape(pptx.ShapeType.line, { x: 0.72, y: 1.26, w: 1.28, h: 0, line: { color: C.cyan, width: 2.6 } });
  s.addText('UNISEEK  /  TEAM REVIEW', { x: 0.72, y: 1.54, w: 4.2, h: 0.25, fontSize: 9, bold: true, color: C.cyan, charSpacing: 1.6, margin: 0 });
  s.addText('优寻兼职招聘平台', { x: 0.72, y: 2.04, w: 7.3, h: 0.64, fontSize: 39, bold: true, color: C.white, margin: 0 });
  s.addText('团队成员核心工作汇总', { x: 0.72, y: 2.86, w: 5.3, h: 0.42, fontSize: 22, color: 'BFD4F3', margin: 0 });
  s.addText('一个面向大学生与企业的多端协同兼职招聘平台', { x: 0.72, y: 3.55, w: 5.9, h: 0.25, fontSize: 11, color: 'A7BEDD', margin: 0 });
  ['PC 端 Vue 3', '鸿蒙 ArkTS', 'Spring Boot', 'MySQL 8'].forEach((t, i) => pill(s, t, 0.72 + i * 1.5, 4.17, 1.28, [C.cyan, C.mint, C.orange, C.purple][i]));
  s.addShape(pptx.ShapeType.roundRect, { x: 8.38, y: 1.15, w: 3.93, h: 4.73, rectRadius: 0.12, fill: { color: '0F2C53' }, line: { color: '235890', width: 0.8 } });
  s.addText('多端协同', { x: 8.8, y: 1.7, w: 2.7, h: 0.35, fontSize: 16, bold: true, color: C.white, align: 'center', margin: 0 });
  [['求职者', C.cyan], ['企业 HR', C.mint], ['管理员', C.orange]].forEach((a, i) => { s.addShape(pptx.ShapeType.roundRect, { x: 9.0, y: 2.38 + i * 0.74, w: 2.7, h: 0.45, rectRadius: 0.06, fill: { color: a[1], transparency: 78 }, line: { color: a[1], transparency: 25 } }); s.addText(a[0], { x: 9.0, y: 2.51 + i * 0.74, w: 2.7, h: 0.12, fontSize: 10, bold: true, color: C.white, align: 'center', margin: 0 }); });
  s.addText('统一 RESTful API  ·  实时 WebSocket 通信  ·  角色权限闭环', { x: 8.72, y: 4.95, w: 3.23, h: 0.35, fontSize: 8, color: 'A7BEDD', align: 'center', breakLine: false, margin: 0 });
  s.addText('TEAM SUMMARY  |  2026', { x: 0.72, y: 6.72, w: 3.5, h: 0.2, fontSize: 8, color: '89A8CF', charSpacing: 1.2, margin: 0 });
  addFooter(s, true);
}

// 2 项目全景
{
  const s = pptx.addSlide(); addBg(s); addHeader(s, '产品全景与协同架构', 'PROJECT OVERVIEW', 2);
  const cols = [
    ['PC 端 / Vue 3', '求职者端 · 企业 HR 端 · 管理后台', C.blue],
    ['鸿蒙端 / ArkTS', '求职者端 · 企业 HR 端 · 原生交互', C.mint],
    ['服务端 / Java', '认证 · 职位 · 投递 · 聊天 · 统计', C.orange],
  ];
  cols.forEach((c, i) => { const x = 0.66 + i * 4.22; card(s, x, 1.77, 3.8, 1.5, { fill: C.white }); s.addShape(pptx.ShapeType.rect, { x, y: 1.77, w: 3.8, h: 0.12, fill: { color: c[2] }, line: { color: c[2] } }); s.addText(c[0], { x: x + 0.26, y: 2.12, w: 3.2, h: 0.3, fontSize: 15, bold: true, color: C.ink, margin: 0 }); s.addText(c[1], { x: x + 0.26, y: 2.58, w: 3.2, h: 0.3, fontSize: 8.5, color: C.muted, margin: 0 }); });
  s.addShape(pptx.ShapeType.downArrow, { x: 6.29, y: 3.42, w: 0.7, h: 0.45, fill: { color: C.blue }, line: { color: C.blue } });
  card(s, 1.42, 4.02, 10.48, 1.42, { fill: C.pale, line: 'C9DCF8', shadow: false });
  s.addText('统一业务中台', { x: 1.75, y: 4.35, w: 2.1, h: 0.3, fontSize: 15, bold: true, color: C.blue, margin: 0 });
  ['认证与权限', '企业与职位', '投递状态机', '即时聊天', '通知与统计'].forEach((t, i) => pill(s, t, 3.85 + i * 1.52, 4.48, 1.28, [C.blue, C.mint, C.orange, C.purple, C.red][i]));
  s.addText('RESTful API + JWT  ·  MyBatis-Plus 数据访问  ·  MySQL 8 数据存储  ·  WebSocket 实时通信', { x: 1.75, y: 5.0, w: 9.6, h: 0.2, fontSize: 8.5, color: C.muted, margin: 0 });
  metric(s, '3', '前端形态', 2.2, 5.88, C.blue); metric(s, '5', '核心角色域', 4.75, 5.88, C.mint); metric(s, '15+', '核心业务能力', 7.3, 5.88, C.orange); metric(s, '1', '统一服务中台', 9.85, 5.88, C.purple);
  addFooter(s);
}

// 3 团队分工
{
  const s = pptx.addSlide(); addBg(s); addHeader(s, '团队分工：围绕角色与业务域协同建设', 'TEAM RESPONSIBILITIES', 3);
  memberCard(s, { x: 0.62, y: 1.65, w: 2.28, h: 3.05, name: '吕宇昕', role: '企业 HR 端 Vue 前端', color: C.blue, pages: '6 页面', focus: '企业认证 · 职位管理 · 简历池 · 人才库 · 聊天', tech: 'Vue 3 / TS / Pinia / WebSocket' });
  memberCard(s, { x: 3.03, y: 1.65, w: 2.28, h: 3.05, name: '宋展鹏', role: '管理员后台全栈', color: C.orange, pages: '5 模块', focus: '审核 · 用户管理 · 统计看板 · 审计日志', tech: 'Spring Boot / AOP / RBAC' });
  memberCard(s, { x: 5.44, y: 1.65, w: 2.28, h: 3.05, name: '孙怀霜', role: '企业 HR 端全栈', color: C.mint, pages: '全链路', focus: '鸿蒙招聘端 · 投递处理 · 通知 · 数据统计', tech: 'ArkTS / Java / WebSocket' });
  memberCard(s, { x: 7.85, y: 1.65, w: 2.28, h: 3.05, name: '郑少轩', role: '认证后端 + 求职 Vue', color: C.purple, pages: '求职端', focus: '登录注册 · 职位搜索 · 简历与个人中心', tech: 'JWT / Vue 3 / 乐观锁' });
  memberCard(s, { x: 10.26, y: 1.65, w: 2.28, h: 3.05, name: '张翰扬', role: '多端 + 数据大屏 + 设计系统', color: C.red, pages: '28 页面', focus: '鸿蒙求职端 · 数据大屏 · 认证投递统计', tech: 'ArkTS / ECharts / 设计 Token' });
  card(s, 0.62, 5.15, 12.02, 1.28, { fill: C.navy, line: C.navy, shadow: false });
  s.addText('协同主线', { x: 0.95, y: 5.5, w: 1.1, h: 0.25, fontSize: 12, bold: true, color: C.white, margin: 0 });
  ['身份认证', '浏览与发布', '投递与筛选', '即时沟通', '审核与运营'].forEach((t, i) => { const x = 2.25 + i * 1.9; s.addShape(pptx.ShapeType.roundRect, { x, y: 5.42, w: 1.52, h: 0.4, rectRadius: 0.06, fill: { color: [C.cyan, C.mint, C.orange, C.purple, C.red][i] }, line: { color: [C.cyan, C.mint, C.orange, C.purple, C.red][i] } }); s.addText(t, { x, y: 5.54, w: 1.52, h: 0.12, fontSize: 8.2, bold: true, color: C.white, align: 'center', margin: 0 }); if (i < 4) s.addShape(pptx.ShapeType.rightArrow, { x: x + 1.58, y: 5.5, w: 0.22, h: 0.2, fill: { color: '6984A7' }, line: { color: '6984A7' } }); });
  addFooter(s);
}

memberSlide(pptx.addSlide(), {
  name: '吕宇昕', title: '企业 HR 端 Vue 前端', kicker: 'RECRUITER WEB', color: C.blue,
  role: '负责招聘者端企业 HR 前端体验与实时交互', tagline: '让企业从认证、发布到沟通形成顺畅的招聘工作台。', foot: 'Vue 3 · TypeScript · Element Plus',
  deliveries: ['完成企业资质认证、职位发布管理、简历池、人才库、即时聊天五大模块', '实现企业认证、发布职位、职位管理、简历池、人才库、消息聊天 6 个页面组件', '封装 5 个 API 模块、2 个 Pinia Store、WebSocket 实时聊天与路由权限守卫', '编写 20 条测试用例，验证核心功能闭环'],
  tech: '级联选择器递归路径回填；投递状态机流转；简历快照 JSON 解析；前端分页与筛选；WebSocket 断线重连与心跳保活。',
  value: '把复杂招聘流程沉淀为清晰的企业操作界面，并保障实时沟通在网络波动下持续可用。'
}, 4);

memberSlide(pptx.addSlide(), {
  name: '宋展鹏', title: '管理员后台全栈', kicker: 'ADMIN CONSOLE', color: C.orange,
  role: '负责平台治理、风控审核与运营数据能力', tagline: '用审核、权限与审计机制，为平台运营建立可追溯的管理闭环。', foot: 'Spring Boot · MyBatis-Plus · Vue 3',
  deliveries: ['完成企业资质审核、职位内容审核、用户管理、数据统计看板、操作日志审计五大功能', '后端实现 5 个 Controller、AdminService、JWT 鉴权拦截器与每日统计任务', '通过 AOP 注解与 Service 手动记录，构建双模式操作日志审计能力', '前端完成 5 个管理页面、AdminLayout、API 封装及路由守卫'],
  tech: 'Spring MVC 无状态鉴权（role≥9）；AOP 自动审计；RBAC 权限控制；乐观锁防并发超录；日报统计幂等生成。',
  value: '提供平台内容审核、操作留痕和可视化运营数据，为规模化运营提供治理基础。'
}, 5);

memberSlide(pptx.addSlide(), {
  name: '孙怀霜', title: '企业 HR 端全栈', kicker: 'RECRUITER FULL STACK', color: C.mint,
  role: '负责鸿蒙招聘者端与招聘业务服务全生命周期', tagline: '将企业招聘业务完整落地到鸿蒙原生体验和服务端业务规则中。', foot: 'ArkTS 6.1.1 · ArkUI · Spring Boot',
  deliveries: ['覆盖实名认证、企业认证、职位发布管理、投递处理、聊天、人才搜索、通知、数据统计', '完成首页三 Tab、聊天会话/详情、职位表单、简历池、人才搜索等 ArkTS 页面', '实现企业、职位、投递、聊天、认证、通知等 RESTful Controller + Service', '构建 WebSocket 连接管理、PING 保活、断线重连与消息分发'],
  tech: 'ArkUI 声明式组件；投递状态机 0→1/2/4 → 1→2/3/4 → 3→5；乐观锁名额控制；Preferences 缓存；消息游标分页。',
  value: '从移动端交互到后端规则保持同一业务语义，确保企业招聘流程在鸿蒙端完整闭环。'
}, 6);

memberSlide(pptx.addSlide(), {
  name: '郑少轩', title: '认证后端 + 求职者端 Vue', kicker: 'AUTH & SEEKER WEB', color: C.purple,
  role: '负责账号体系、身份鉴权与 PC 求职者核心流程', tagline: '构建安全账号入口，并让求职者高效完成“搜—投—管”。', foot: 'Spring Boot · JWT · Vue 3 SPA',
  deliveries: ['实现手机号/邮箱注册、账号登录、JWT Token 签发鉴权、密码加密存储', '完成职位搜索与详情、我的求职、简历编辑、个人中心、账号安全、实名认证页面', '后端建设 AuthController、UserService、JWT 拦截器、职位搜索 API', '前端实现路由守卫、Pinia 状态管理与多条件搜索筛选'],
  tech: 'HandlerInterceptor + ThreadLocal；MD5 + 32 位随机盐；requiresAuth + role 校验；el-cascader 级联筛选；骨架屏、分页与乐观锁并发投递。',
  value: '同时保障账号安全与求职体验，让用户从注册登录到完成投递的路径稳定、清晰、可控。'
}, 7);

// 8 张翰扬 + 总结
{
  const s = pptx.addSlide(); addBg(s); addHeader(s, '张翰扬｜多端建设、数据可视化与设计系统', 'MULTI-PLATFORM DELIVERY', 8);
  s.addShape(pptx.ShapeType.roundRect, { x: 0.62, y: 1.65, w: 3.08, h: 4.96, rectRadius: 0.08, fill: { color: C.red }, line: { color: C.red } });
  s.addText('张', { x: 0.94, y: 2.02, w: 1.1, h: 0.7, fontSize: 46, bold: true, color: C.white, margin: 0 });
  s.addText('张翰扬', { x: 0.94, y: 2.82, w: 2.3, h: 0.32, fontSize: 22, bold: true, color: C.white, margin: 0 });
  s.addText('鸿蒙求职端 · 数据大屏 · 后端认证/投递/统计 · 设计系统', { x: 0.94, y: 3.26, w: 2.18, h: 0.65, fontSize: 8.7, color: 'FFE1E5', breakLine: false, margin: 0 });
  s.addShape(pptx.ShapeType.line, { x: 0.94, y: 4.15, w: 1.94, h: 0, line: { color: C.white, transparency: 55, width: 0.8 } });
  s.addText('从用户体验、数据洞察到统一视觉，贯通产品呈现的关键层。', { x: 0.94, y: 4.4, w: 2.18, h: 0.88, fontSize: 11, bold: true, color: C.white, breakLine: false, margin: 0 });
  s.addText('ArkTS · ECharts · Java · Design Tokens', { x: 0.94, y: 5.82, w: 2.2, h: 0.26, fontSize: 7.4, color: 'FFE1E5', margin: 0 });
  const blocks = [
    ['鸿蒙求职者端', '28 个页面 · 28 个可复用组件 · 20 个 Service，覆盖浏览、搜索、投递、聊天、简历、收藏、个人中心。', C.blue],
    ['Vue 数据大屏', 'KPI、供需趋势、岗位占比、全国流向、转化漏斗、资质审核、认证率、热门岗位、实时动态。', C.mint],
    ['后端与数据设计', '认证、投递六步校验链、统计定时任务；14 张业务表、唯一/复合/全文索引与乐观锁。', C.orange],
    ['跨端设计系统', '统一品牌色 #1762FB 与间距、圆角、阴影、动效 Token，覆盖 Vue、Admin、ArkTS 三端。', C.purple],
  ];
  blocks.forEach((b, i) => { const x = 4.08 + (i % 2) * 4.35; const y = 1.72 + Math.floor(i / 2) * 2.28; card(s, x, y, 3.98, 1.88, { fill: 'F9FBFF', line: C.line, shadow: false }); s.addShape(pptx.ShapeType.rect, { x, y, w: 0.09, h: 1.88, fill: { color: b[2] }, line: { color: b[2] } }); s.addText(b[0], { x: x + 0.28, y: y + 0.3, w: 3.25, h: 0.25, fontSize: 12.5, bold: true, color: C.ink, margin: 0 }); s.addText(b[1], { x: x + 0.28, y: y + 0.72, w: 3.38, h: 0.76, fontSize: 8.6, color: C.text, breakLine: false, margin: 0 }); });
  card(s, 4.08, 6.1, 8.33, 0.5, { fill: C.navy, line: C.navy, shadow: false });
  s.addText('最终沉淀：一套能跨端复用、支持可视化运营、由统一设计语言串联的产品能力体系。', { x: 4.35, y: 6.27, w: 7.75, h: 0.14, fontSize: 9.4, bold: true, color: C.white, align: 'center', margin: 0 });
  addFooter(s);
}

// 所有幻灯片统一执行布局诊断。
for (const slide of pptx._slides) {
  warnIfSlideHasOverlaps(slide, pptx);
  warnIfSlideElementsOutOfBounds(slide, pptx);
}

pptx.writeFile({ fileName: 'UniSeek_团队成员核心工作汇总.pptx' });
