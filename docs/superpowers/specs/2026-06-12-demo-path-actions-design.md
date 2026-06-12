# 2026-06-12 Demo 路径入口设计

## 目标

把 demo banner 从静态说明升级为演示路径入口。`FitnessRPGDemo` 默认打开 History 后，演示者可以从 banner 快速回到 Today、进入 Memory Review，或明确 Diagnostics 在 Today 页面可见。

## 设计

- Core 增加 `FitnessRPGDemoSeedPresentationAction` 和 `FitnessRPGDemoSeedPresentationDestination`。
- `FitnessRPGDemoSeed.showcase.presentation` 暴露 4 个 action：Today、History、Memory、Diagnostics。
- SwiftUI banner 在 evidence 下方显示 2x2 操作按钮，触控高度不低于 44pt。
- `TodayCommandCenterView` 负责把 action 映射到 `navigationPath`：
  - Today -> 清空路径。
  - History -> `[.history]`。
  - Memory -> `[.memoryReview]`。
  - Diagnostics -> 清空路径，因为 Diagnostics 面板在 Today 页面显示。
- `HistoryView` 接收同一个 action handler，避免在 History 自己维护另一套导航状态。

## 非目标

- 不新增新的 Diagnostics 子页面。
- 不做 ScrollView 精确滚动定位。
- 不改变 release 或普通 `FitnessRPG` scheme 的默认 UI。

## UI 原则

- 使用 SF Symbols 和文字按钮，不使用 emoji。
- 保持 8pt 圆角和现有浅蓝 demo 语义。
- 按钮之间保留 8pt 间距，满足移动端触控间隔。
