# Todo 2 变更摘要：全局硬编码颜色收敛到 AppColors / sys.color

## 修改文件

| 文件 | 变更概要 |
| --- | --- |
| `uniseek_arkts/entry/src/main/ets/common/AppStyles.ets` | 新增语义颜色 Token (`PRIMARY_LIGHT`、`PRIMARY_LIGHTER`、`PRIMARY_FAINT`、`PRIMARY_ALPHA_6`、`PRIMARY_ALPHA_8`、`BORDER_LIGHT`、`BORDER_FAINT`、`OVERLAY_DARK`) 与菜单阴影 `AppShadow.MENU`；`PrimaryButton.fontColor` 从 `'#ffffff'` 改为 `AppColors.BG_CARD`；补充 `HEADLINE`、`BOTTOM_ACTION_HEIGHT`、`XS` 等 Token。 |
| `uniseek_arkts/entry/src/main/ets/pages/LoginPage.ets` | 登录按钮文字、渐变背景色统一使用 `AppColors.BG_CARD` / 新增渐变 Token。 |
| `uniseek_arkts/entry/src/main/ets/pages/RegisterPage.ets` | 分段按钮选中文字、注册按钮文字、页面背景色统一使用 `AppColors.BG_CARD`。 |
| `uniseek_arkts/entry/src/main/ets/pages/JobDetailPage.ets` | 头像/首字母/主操作按钮白色文字、职位标签边框、加载更多按压态背景使用 AppColors 常量。 |
| `uniseek_arkts/entry/src/main/ets/pages/ChatDetailPage.ets` | 重发按钮/头像/文本消息白色文字、操作菜单遮罩、菜单阴影、图片预览遮罩与关闭图标、输入框光晕与顶部分隔线使用 `AppColors.*` / `AppShadow.MENU`；补充 `AppShadow` 导入。 |
| `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/HomePage.ets` | 筛选面板中日结/时薪/月结、省/市/区/行业/岗位选中项、底部确定按钮等处的 `'#FFFFFF'` 全部替换为 `AppColors.BG_CARD`。 |
| `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/JobFeedCard.ets` | 未修改，原有颜色已使用 AppColors 常量。 |

## 设计原则

- 优先复用现有 `AppColors.*` 语义常量（如 `BG_CARD` 表示白色前景）。
- 仅在 `AppStyles.ets` 中新增通用语义 Token，不在页面中扩散魔法值。
- 业务语义色（状态色 `SUCCESS`/`WARNING`/`DANGER` 等）保持原常量不变。

## 回退策略

- 新增常量仅追加，不删除旧常量，所有旧引用继续有效。
- 如因 `AppShadow` 常量导致问题，可直接回退为内联 `shadow({...})`。
