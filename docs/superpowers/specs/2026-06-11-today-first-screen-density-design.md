# Today 首屏信息密度微调设计

## 目标

在默认 iPhone 视口里让 Today 页面露出更多“今日任务”和第一步动作，同时保持当前 Native Pro + 轻 RPG 视觉语言、Dynamic Type 和主行动触控尺寸。

## 当前问题

Today 首屏中，大号 navigation title、hero 标题、两行状态说明和纵向指标块共同占据较多高度。用户能看到任务标题，但第一步动作和固定底部 CTA 之间略显拥挤，任务信息的“行动感”不够靠前。

## 方案

- 将 navigation title 改为 inline，减少顶部大标题占用。
- Hero 标题从 large title 降为 title 级别，保留圆角粗体风格。
- 将 Watch 状态和 HealthKit/source note 合并为一个 footnote 文本组，最多两行。
- 将 Readiness / Watch 指标改为横向 compact metric，减少纵向高度。
- 任务卡标题从 title2 调整为 title3，保留粗体和最多三行。
- 任务卡内边距和组间距小幅收紧，但正文继续使用 footnote/subheadline，避免压到不可读。
- 底部固定 CTA 保持 `.controlSize(.large)` 和安全区 inset，不缩小主按钮。

## UI/UX Pro Max 约束

- 主触控目标保持 44pt 以上。
- 正文不低于 footnote/subheadline，继续跟随系统 Dynamic Type。
- 不只靠颜色表达 readiness，继续保留 icon 和文本。
- 不为了首屏露出更多内容而隐藏核心状态或安全说明。

## 非目标

- 不改变 WatchConnectivity、HealthKit、持久化或训练结算逻辑。
- 不移除底部固定 CTA。
- 不新增图片、动画或自定义字体。
- 不新增设置项或导航层级。

## 验证

- iOS build 通过。
- Watch build 通过。
- SwiftPM tests 通过。
- 默认启动截图确认首屏更紧凑、底部 CTA 正常显示、中文不乱码。
