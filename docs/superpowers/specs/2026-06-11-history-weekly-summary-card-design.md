# History 周训练总结卡片设计

## 背景

`FitnessRPGCore` 已经提供确定性的 `WeeklyTrainingSummaryBuilder`，可以从本地训练记录生成周范围、完成分布、readiness 分布、安全提示和下周行动。README 的下一步是把这个稳定结果先显示到 History，再接入本地模型润色周报文案。

## 目标

- 在 iOS `History` 列表首屏显示一张“本周回顾”卡片。
- 继续让 `TodayPersistenceModel` 作为 History 的只读数据门面，SwiftUI 不直接读取 JSON store。
- 保持 Native Pro + 轻 RPG 风格：系统字体、SF Symbols、8px 圆角、清晰信息层级。
- 不改变持久化格式、WatchConnectivity、训练结算或 Core 聚合规则。

## 方案

采用 History 列表顶端卡片，而不是新增独立周报页面。

理由：

- 周总结是回顾中心的概览，适合放在历史列表之前。
- 用户仍能向下查看每日记录，不增加新导航层级。
- 空历史时继续显示原有空状态，不展示重复的“暂无训练周”卡片。

## UI 内容

卡片展示：

- 标题：`本周回顾` + `calendar.badge.clock`
- 周范围：`dateRangeLabel`
- 摘要标题：`headline`
- 周详情：`detail`
- 完成分布：`completionLabel`
- readiness 分布：`readinessLabel`
- 安全提示：`safetyLabel`
- 下周计划标题和行动列表：`nextWeekPlanTitle` / `nextWeekActions`

## 设计约束

- 不使用大面积渐变、装饰图形或落地页式 hero。
- 不新增自定义字体，继续使用 SwiftUI 系统字体和 Dynamic Type。
- 卡片圆角保持 8px，与现有 History 详情卡片一致。
- 文案允许多行换行，避免在小屏或大字号下截断核心信息。
- 使用 `accessibilityElement(children: .combine)` 让 VoiceOver 将周回顾作为完整摘要读取。

## 验证

- `swift test --package-path native/FitnessRPGCore`
- iOS generic Xcode build
- watchOS generic Xcode build
- iOS Simulator 使用 `--fitnessrpg-open-history` 截图确认卡片出现在历史列表顶部
- `git diff --check`
