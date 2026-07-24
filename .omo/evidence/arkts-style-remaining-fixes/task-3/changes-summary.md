# Task 3 — 变更摘要

## 修改文件

| 文件 | 变更内容 |
|------|----------|
| `entry/src/main/ets/common/AppStyles.ets` | 新增字号/间距/圆角 Token；将 `StandardInput`、`PrimaryButton` 的硬编码 `height`、`borderRadius` 收口为 Token。 |
| `entry/src/main/ets/pages/ChatDetailPage.ets` | 收敛导航栏、消息气泡、附件消息、菜单、Lightbox、输入区等大量字号/尺寸/圆角。 |
| `entry/src/main/ets/pages/JobDetailPage.ets` | 收敛加载、HR 信息、公司信息、底部操作栏等字号/尺寸。 |
| `entry/src/main/ets/pages/tab/seeker/HomePage.ets` | 收敛筛选 Sheet、列表、Tab 标签、标题栏字号/尺寸。 |
| `entry/src/main/ets/pages/tab/seeker/JobFeedCard.ets` | 收敛卡片标题、薪资、标签、企业信息字号/圆角，补充 `AppFontSize` 导入。 |
| `entry/src/main/ets/pages/tab/seeker/JobFeedList.ets` | 收敛加载/空状态/错误状态字号与按钮尺寸，补充 `AppFontSize` 导入。 |
| `entry/src/main/ets/pages/MainPage.ets` | 收敛 Tab 图标/标签字号与 Tab 栏高度，补充 `AppFontSize`/`AppSpacing` 导入。 |
| `entry/src/main/ets/pages/RecruiterHomePage.ets` | 收敛 Tab 图标/标签字号与 Tab 栏高度，补充 `AppFontSize`/`AppSpacing` 导入。 |
| `entry/src/main/ets/pages/tab/seeker/ProfilePage.ets` | 收敛头像、头部高度、菜单项字号/高度。 |

## AppStyles.ets 新增 Token

### AppFontSize

- `XXS = 10`
- `TINY = 11`
- `CAPTION = 12.5`
- `META = 13`
- `LABEL = 13.5`
- `BODY = 14.5`
- `SUBHEAD = 15`
- `TITLE = 17`
- `ICON_LG = 22`

### AppSpacing

- `ICON_XS = 20`
- `ICON_SM = 24`
- `ICON_MD = 28`
- `ICON_LG = 40`
- `ICON_XL = 44`
- `ICON_XXL = 48`
- `AVATAR_XL = 72`
- `BUTTON_HEIGHT_MINI = 32`
- `BUTTON_HEIGHT_SM = 36`
- `BUTTON_HEIGHT = 40`
- `BUTTON_HEIGHT_MD = 44`
- `BUTTON_HEIGHT_LG = 52`
- `INPUT_HEIGHT = 48`
- `INPUT_HEIGHT_STANDARD = 50`
- `LIST_ITEM_HEIGHT = 56`
- `FOOTER_SPACER = 88`
- `HEADER_HEIGHT = 104`
- `FILTER_LIST_HEIGHT = 200`
- `FILTER_OCCUPATION_LIST_HEIGHT = 180`
- `MENU_PANEL_WIDTH = 180`
- `CARD_PADDING = 14`
- `PAGE_PADDING_VERTICAL = 28`
- `DIVIDER_THICKNESS = 0.5`
- `DIVIDER_THICKNESS_BOLD = 1`

### AppRadius

- `PANEL = 10`
- `SOFT = 14`
- `BUBBLE = 18`
- `PILL = 20`

## 典型替换映射

| 原魔法数字 | Token |
|------------|-------|
| `fontSize(10)` → `AppFontSize.XXS` |
| `fontSize(12.5)` → `AppFontSize.CAPTION` |
| `fontSize(14.5)` → `AppFontSize.BODY` |
| `fontSize(15)` → `AppFontSize.SUBHEAD` |
| `fontSize(17)` → `AppFontSize.TITLE` |
| `fontSize(22)` → `AppFontSize.ICON_LG` |
| `borderRadius(14)` → `AppRadius.SOFT` |
| `borderRadius(18)` → `AppRadius.BUBBLE` |
| `borderRadius(20)` → `AppRadius.PILL` |
| `height(48)` → `AppSpacing.INPUT_HEIGHT` |
| `height(52)` → `AppSpacing.BUTTON_HEIGHT_LG` |
| `width(180)` → `AppSpacing.MENU_PANEL_WIDTH` |

所有替换均保持数值不变，UI 视觉与交互行为不受影响。
