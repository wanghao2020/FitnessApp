# 2026-06-12 Demo Presentation Banner Design

## 目标

`FitnessRPGDemo` 已能一键打开确定性数据。下一步是在首屏加入清晰但不喧宾夺主的演示说明，让截图和现场演示一眼看出这是可重复的 demo 数据，并提示可验证的路径：Today、History、Memory、Diagnostics。

## 设计

- Core 新增 `FitnessRPGDemoSeedPresentation`，保存演示标题、说明、系统图标和证据行。
- `FitnessRPGDemoSeed.showcase` 携带 presentation，避免 SwiftUI 硬编码演示文案。
- `TodayPersistenceModel.applyDemoSeed(_:)` 发布 presentation；正式 `loadOrCreateToday` 清空该状态。
- `HistoryView` 在 weekly summary 前展示紧凑 banner，因为 `FitnessRPGDemo` 默认打开 History。
- `TodayCommandCenterView` 在 hero 前展示同一 banner，方便从 History 返回 Today 后仍可确认演示模式。

## UI 原则

- 使用 SF Symbols，不使用 emoji。
- 使用圆角 8 的卡片，与现有 History 卡片一致。
- 信息密度紧凑：标题、说明、2x2 证据行。
- 颜色使用蓝色主色和橙色强调点，呼应 ui-ux-pro-max 对运动/游戏 demo 的建议。
- banner 不增加新的按钮，避免占用触控复杂度；导航仍用现有 toolbar。

## 验证

- Core 测试验证 presentation 文案和证据行。
- Swift Package 全量测试通过。
- iOS/watchOS 构建通过。
- Demo smoke 脚本通过并截图确认 banner 显示。
