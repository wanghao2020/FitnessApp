# Today Next Focus Design

## Goal

让 Today Hero 在 readiness 分数和 Watch 进度之外，直接告诉用户“下一步该做什么”。这能降低首屏阅读成本，特别是在任务未发送、Watch 执行进行中、今日步骤已回传完成这三种状态之间切换时。

## UX Direction

结合 `ui-ux-pro-max` 对移动健康/游戏化产品的建议，本轮保留活力和 RPG 感，但优先做移动端清晰度：

- 首屏显示一个可读的 next-focus 行，避免用户只看到数字后还要自己判断。
- 使用 SF Symbols，不引入额外字体资源。
- 保持系统 Dynamic Type、短句、两行以内文案。
- 使用 readiness tint 做轻强调，不新增大面积装饰色块。

## Core Contract

`TodayCommandCenterSummary` 新增：

- `nextFocusHeadline`
- `nextFocusDetail`
- `nextFocusSystemImage`

派生规则：

1. `executionLogCount == 0`
   - headline: `下一步：发送到 Watch`
   - detail: `把 3 个步骤同步到手表。`
   - symbol: `applewatch`

2. `executionLogCount` 大于 0 但小于总步骤数
   - headline: `下一步：继续 Watch 执行`
   - detail: `已回传 1/3 步，完成剩余步骤后回到 iPhone。`
   - symbol: `figure.run`

3. `executionLogCount` 大于或等于总步骤数
   - headline: `下一步：查看 History`
   - detail: `今日 Watch 记录已收齐，查看结果与故事进度。`
   - symbol: `clock.arrow.circlepath`

## SwiftUI Integration

`TodayHeroCard` 在状态行和 inline metrics 之间加入一个紧凑 focus row：

- 左侧为 `nextFocusSystemImage`。
- 右侧显示 headline 和 detail。
- 图标和 headline 使用 readiness tint。
- 作为 hero 内容的一部分，不作为嵌套卡片。

## Non-goals

- 不改变 WatchConnectivity 发送/回传逻辑。
- 不改变 History 导航行为。
- 不新增全局设计系统文件。
- 不改变 HealthKit、Runtime 或持久化行为。

## Verification

- Core 测试覆盖 0/部分/全部 Watch 回传状态的 next focus 派生。
- iOS/watchOS generic build 继续通过。
- UI 文案在 SwiftUI 中只读取 Core summary 字段。
