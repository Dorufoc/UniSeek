# arkts-job-detail-refactor

## Status
- Intent: **CLEAR**
- review_required: true (用户在审批阶段要求高精度审查)
- Status: plan-ready (Momus 高精度审查已通过，计划已修复3项阻塞问题)
- Started: 2026-07-20
- Momus review: PASS (all 3 blocking issues fixed)

## 需求摘要
完全重构 ArkTS 职位详情页面，实现：
1. 列表卡片点击后一镜到底展开动效
2. 卡片拉伸覆盖全屏，内容位移缩放至目标位置
3. 与 Vue 端功能完全一致的内容和交互
4. 移动端优先布局设计

## 关键决策记录
- **架构方案**：采用同页叠加层 + geometryTransition 实现卡片到详情的流畅过渡，而非页面跳转
- **动效实现**：使用 HMOS geometryTransition API 实现卡片容器补间动画 + 自定义animateTo实现内容元素位移/缩放
- **功能来源**：通过 API 获取完整 TaskVO 数据，与 Vue 端 JobDetail.vue 功能一一对应
- **布局策略**：移动端竖屏单列布局，无侧边栏（与 Vue 的桌面端双栏布局不同）

## 待探索问题
- [x] 现有 JobData 字段是否完整覆盖 TaskVO 所需字段？
- [x] ApiClient 是否有 getTaskById 方法？
- [x] 现有 JobFeedCard 点击行为是 pushUrl 到新页面

## 探索结果
- JobData 缺少 enterpriseName, totalQuota, address, deadline, applicationCount, hasFavorited 等字段
- ApiClient 没有 getTaskById 方法，需要添加
- JobFeedCard 当前使用 router.pushUrl 跳转
- HMOS 支持 geometryTransition 和 sharedTransition 两种共享元素转场方式
