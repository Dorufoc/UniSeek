# Todo 2 修复方案：全局硬编码颜色收敛到 AppColors / HMOS sys.color

## 目标文件

1. `uniseek_arkts/entry/src/main/ets/pages/LoginPage.ets`
2. `uniseek_arkts/entry/src/main/ets/pages/RegisterPage.ets`
3. `uniseek_arkts/entry/src/main/ets/pages/JobDetailPage.ets`
4. `uniseek_arkts/entry/src/main/ets/pages/ChatDetailPage.ets`
5. `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/HomePage.ets`
6. `uniseek_arkts/entry/src/main/ets/pages/tab/seeker/JobFeedCard.ets`
7. `uniseek_arkts/entry/src/main/ets/common/AppStyles.ets`

## 修复思路

- 优先复用 `AppColors` 中已存在的语义常量（`BG_CARD`、`BORDER`、`OVERLAY` 等）。
- 对于设计系统中尚未覆盖的语义色（登录渐变中间色、遮罩暗色、主色透明按压态、浅色边框等），在 `AppColors` 中补充新的语义 Token，并在相关页面引用，避免在组件中直接写死 `rgba(...)`。
- `AppStyles.ets` 内部 `PrimaryButton` 的 `fontColor('#ffffff')` 替换为 `AppColors.BG_CARD`。
- 本次不替代表达业务语义的常量（如 `SUCCESS`/`WARNING`/`DANGER`、薪资 `DANGER`）和已使用 `AppColors.*` 的定义行。
- `JobFeedCard.ets` 当前已无硬编码颜色，保持不动。

## 新增 Token（写入 `AppStyles.ets` 的 `AppColors`）

| 常量名 | 色值 | 使用场景 |
|---|---|---|
| `PRIMARY_LIGHT` | `'#5A8CFF'` | 登录页渐变 0.15 位置 |
| `PRIMARY_LIGHTER` | `'#A8C4FF'` | 登录页渐变 0.3 位置 |
| `PRIMARY_FAINT` | `'#E4EEFF'` | 登录页渐变 0.5 位置 |
| `PRIMARY_ALPHA_6` | `'rgba(23, 98, 251, 0.06)'` | 聊天页/职位页主色半透明按压背景 |
| `PRIMARY_ALPHA_8` | `'rgba(23, 98, 251, 0.08)'` | 聊天输入框聚焦阴影 |
| `BORDER_LIGHT` | `'rgba(0, 0, 0, 0.06)'` | 职位标签边框 |
| `BORDER_FAINT` | `'rgba(0, 0, 0, 0.04)'` | 聊天输入区顶部分割线 |
| `OVERLAY_DARK` | `'rgba(0, 0, 0, 0.9)'` | 图片预览 Lightbox 遮罩 |

## 新增 Token（写入 `AppStyles.ets` 的 `AppShadow`）

| 常量名 | 值 | 使用场景 |
|---|---|---|
| `MENU` | `{ radius: 16, color: 'rgba(0, 0, 0, 0.12)', offsetX: 0, offsetY: 4 }` | 聊天页操作菜单阴影 |

## 逐文件逐行替换映射

### LoginPage.ets

| 行号 | 当前颜色/代码 | 替换为 | 说明 |
|---|---|---|---|
| 112 | `.fontColor('#FFFFFF')` | `.fontColor(AppColors.BG_CARD)` | 登录按钮文字 |
| 175 | `['#5A8CFF', 0.15]` | `[AppColors.PRIMARY_LIGHT, 0.15]` | 渐变中间色 |
| 176 | `['#A8C4FF', 0.3]` | `[AppColors.PRIMARY_LIGHTER, 0.3]` | 渐变中间色 |
| 177 | `['#E4EEFF', 0.5]` | `[AppColors.PRIMARY_FAINT, 0.5]` | 渐变中间色 |
| 178-179 | `['#FFFFFF', 0.7]` / `['#FFFFFF', 1.0]` | `AppColors.BG_CARD` | 渐变终点白色 |

### RegisterPage.ets

| 行号 | 当前颜色 | 替换为 | 说明 |
|---|---|---|---|
| 25 | `selectedFontColor: '#FFFFFF'` | `selectedFontColor: AppColors.BG_CARD` | 分段按钮选中文字 |
| 225 | `.fontColor('#FFFFFF')` | `.fontColor(AppColors.BG_CARD)` | 注册按钮文字 |
| 274 | `.backgroundColor('#FFFFFF')` | `.backgroundColor(AppColors.BG_CARD)` | 页面背景 |

### JobDetailPage.ets

| 行号 | 当前颜色 | 替换为 | 说明 |
|---|---|---|---|
| 274 | `.fontColor('#FFFFFF')` | `.fontColor(AppColors.BG_CARD)` | HR 头像占位文字 |
| 306 | `.fontColor('#FFFFFF')` | `.fontColor(AppColors.BG_CARD)` | 企业首字母 |
| 348 | `.fontColor('#FFFFFF')` | `.fontColor(AppColors.BG_CARD)` | 主操作按钮文字 |
| 383 | `.border({ width: 1, color: 'rgba(0, 0, 0, 0.06)' })` | 颜色改为 `AppColors.BORDER_LIGHT` | 职位标签边框 |
| 672 | `.backgroundColor('rgba(23,98,251,0.06)')` | `.backgroundColor(AppColors.PRIMARY_ALPHA_6)` | 加载更多按压背景 |

### ChatDetailPage.ets

| 行号 | 当前颜色 | 替换为 | 说明 |
|---|---|---|---|
| 327 | `.fontColor('#FFFFFF')` | `.fontColor(AppColors.BG_CARD)` | 重新加载按钮文字 |
| 432 | `.fontColor('#FFFFFF')` | `.fontColor(AppColors.BG_CARD)` | 头像组件首文字 |
| 467 | `.fontColor('#FFFFFF')` | `.fontColor(AppColors.BG_CARD)` | 己方文本消息 |
| 685 | `.backgroundColor('rgba(0,0,0,0.3)')` | `.backgroundColor(AppColors.OVERLAY)` | 操作菜单遮罩（复用现有 `OVERLAY`，0.4 足够表达遮罩） |
| 742 | `.shadow({ radius: 16, color: 'rgba(0,0,0,0.12)', offsetX: 0, offsetY: 4 })` | `.shadow(AppShadow.MENU)` | 菜单阴影 |
| 761 | `.backgroundColor('rgba(0,0,0,0.9)')` | `.backgroundColor(AppColors.OVERLAY_DARK)` | 图片预览遮罩 |
| 780 | `.fontColor(['#FFFFFF'])` | `.fontColor([AppColors.BG_CARD])` | Lightbox 关闭按钮图标 |
| 845 | `.shadow({ radius: 4, color: 'rgba(23,98,251,0.08)', offsetX: 0, offsetY: 0 })` | 颜色改为 `AppColors.PRIMARY_ALPHA_8` | 输入框聚焦光晕 |
| 874 | `.borderColor({ top: 'rgba(0,0,0,0.04)' })` | 颜色改为 `AppColors.BORDER_FAINT` | 输入区顶部细线 |

**说明**：`ChatDetailPage.ets` 当前未导入 `AppShadow`，需要在 `import { AppColors, AppSpacing, AppRadius, AppFontSize }` 中追加 `AppShadow`。

### HomePage.ets

| 行号 | 当前颜色 | 替换为 | 说明 |
|---|---|---|---|
| 520 | `.fontColor(this.filterSalaryUnit === 0 ? '#FFFFFF' : AppColors.TEXT_SECONDARY)` | `'#FFFFFF'` 改为 `AppColors.BG_CARD` | 薪资单位选中文字（共 3 处，日结/时薪/月结） |
| 529 | 同上（时薪） | `AppColors.BG_CARD` | |
| 538 | 同上（月结） | `AppColors.BG_CARD` | |
| 584 | `.fontColor(... ? '#FFFFFF' : AppColors.TEXT_PRIMARY)`（省选中） | `AppColors.BG_CARD` | |
| 611 | `.fontColor(... ? '#FFFFFF' : AppColors.TEXT_PRIMARY)`（市全部选中） | `AppColors.BG_CARD` | |
| 655 | `.fontColor(... ? '#FFFFFF' : AppColors.TEXT_PRIMARY)`（直辖市区全部选中） | `AppColors.BG_CARD` | |
| 696 | `.fontColor(... ? '#FFFFFF' : AppColors.TEXT_PRIMARY)`（区全部选中） | `AppColors.BG_CARD` | |
| 754 | `.fontColor(... ? '#FFFFFF' : AppColors.TEXT_PRIMARY)`（行业选中） | `AppColors.BG_CARD` | |
| 784 | `.fontColor(... ? '#FFFFFF' : AppColors.TEXT_PRIMARY)`（岗位全部选中） | `AppColors.BG_CARD` | |
| 832 | `.fontColor('#FFFFFF')` | `AppColors.BG_CARD` | 筛选确定按钮文字 |

### JobFeedCard.ets

- 当前文件所有颜色均已使用 `AppColors.*` 常量，无需替换。

### AppStyles.ets

| 行号 | 当前颜色 | 替换为 | 说明 |
|---|---|---|---|
| 204 | `.fontColor('#ffffff')` | `.fontColor(AppColors.BG_CARD)` | `PrimaryButton` 文字 |

## 可能影响的调用方与回退策略

- 新增常量全部写入 `AppStyles.ets`，不会破坏已有引用。
- `ChatDetailPage.ets` 新增 `AppShadow` 导入，若后续 `AppShadow.MENU` 定义被删除会导致编译失败；回退时只需恢复为内联 `shadow({...})` 即可。
- 本次未修改任何 `services/`、`api/`、`models/`、Java/Vue 模块，改动面仅限 UI 颜色常量替换。
