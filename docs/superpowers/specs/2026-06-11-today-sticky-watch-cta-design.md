# Today 固定 Watch 主行动设计

## 目标

让 `发送到 Watch` 成为 Today 页面稳定、随时可见的主行动，而不是被任务步骤长度推到页面底部。用户进入 Today 后应先理解今日状态和任务，再能直接触发 Watch 同步。

## 当前问题

当前 `发送到 Watch` 按钮位于今日任务卡内部，任务步骤较长时按钮会被推到首屏底部甚至首屏外。它是 Today 的核心操作，不应该依赖滚动位置才可见。

## 方案

- 将 `发送到 Watch` 从 `TodayQuestActionCard` 内移除。
- 在 `TodayCommandCenterView` 的 `safeAreaInset(edge: .bottom)` 中加入固定主 CTA。
- CTA 使用 `.borderedProminent`、大控件尺寸、圆角容器和轻量材质背景，避免遮挡内容。
- ScrollView 底部增加额外 padding，防止最后一张卡片被固定 CTA 覆盖。
- CTA 文案和 SF Symbol 从 `TodayCommandCenterSummary` 派生，避免 Today SwiftUI 再硬编码主行动文案。

## 数据流

`TodayCommandCenterSummary` 新增：

- `primaryActionLabel`
- `primaryActionSystemImage`

`TodayCommandCenterView` 将 `todaySummary` 传入新的 `TodayStickyWatchCTA`，点击时继续调用：

```swift
watchSyncModel.send(quest: quest, readinessColor: questReadinessColor)
```

## 非目标

- 不改变 WatchConnectivity payload。
- 不改变 Today task、history、story progression 或 persistence 行为。
- 不新增二级确认弹窗。
- 不把 CTA 做成全局 Tab 或 toolbar item。

## 验证

- Core 测试覆盖主行动文案和图标。
- iOS build 通过。
- 默认启动截图确认底部 CTA 可见且不遮挡内容。
- Watch build 通过，确认共享 core 变更不影响 watchOS。
