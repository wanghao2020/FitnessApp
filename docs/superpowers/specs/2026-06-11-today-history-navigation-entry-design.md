# Today / History 导航入口统一设计

## 目标

统一 Today 到 History 的入口文案和图标，让右上角入口从英文 `History` 变成清晰的中文“历史”，并让 History 列表页标题改为“训练历史”。

## 当前问题

- Today 右上角 toolbar 入口使用英文 `History`。
- History 列表页标题也使用英文 `History`。
- 图标和文案直接写在 SwiftUI 视图里，后续如果增加 Tab 或更多入口，容易出现命名不一致。

## 方案

新增 `AppNavigationDisplay`，集中存放跨页面导航显示文案：

- `todayTitle = "Fitness RPG"`
- `historyTitle = "训练历史"`
- `historyEntryLabel = "历史"`
- `historyEntrySystemImage = "clock.arrow.circlepath"`

Today 右上角入口使用 `Label("历史", systemImage: "clock.arrow.circlepath")`，并设置 accessibility label 为“训练历史”。History 列表页标题使用“训练历史”，详情页仍使用“训练详情”。

## UI/UX Pro Max 约束

- 图标按钮必须有可访问名称。
- 移动导航必须保留可预测 back 行为，不重置 NavigationStack。
- 不新增固定导航条或 Tab，避免遮挡当前底部 Watch CTA。

## 非目标

- 不引入底部 Tab。
- 不改变 `AppLaunchDestination` 和 DEBUG deep link 行为。
- 不改变 History 列表/详情数据结构。
- 不改变 Watch、HealthKit、持久化或训练结算逻辑。

## 验证

- Core 测试覆盖导航显示文案和图标。
- iOS build 通过。
- Watch build 通过。
- 默认启动截图确认右上角历史入口仍可见。
- DEBUG history deep link 继续可启动。
