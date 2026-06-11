# History 周训练总结卡片 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 iOS History 列表顶部展示确定性周训练总结和下周计划。

**Architecture:** 复用 `FitnessRPGCore.WeeklyTrainingSummaryBuilder`。`TodayPersistenceModel` 提供 `weeklyTrainingSummary` 只读属性，`HistoryView` 只消费发布后的历史派生数据。SwiftUI 负责布局，不重新拼接聚合规则。

**Tech Stack:** SwiftUI、FitnessRPGCore、Xcode iOS/watchOS build、SwiftPM XCTest。

---

## Task 1: 数据门面

- [x] 在 `TodayPersistenceModel` 增加 `weeklyTrainingSummary`。
- [x] 从当前发布的 `historyDays` 派生 Core 周总结。
- [x] 不改变 JSON 持久化格式。

## Task 2: History UI

- [x] 在 `HistoryView` 列表顶端加入 `WeeklyTrainingSummaryCard`。
- [x] 展示周范围、摘要、完成分布、readiness 分布、安全提示和下周行动。
- [x] 只在历史非空时进入列表，因此空状态保持原有体验。
- [x] 使用系统字体、SF Symbols、8px 圆角和可换行文案。

## Task 3: 文档与验证

- [x] 更新 README / native README 当前状态和下一步路线。
- [x] 运行 Core 测试。
- [x] 运行 iOS Xcode build。
- [x] 运行 watchOS Xcode build。
- [x] 使用模拟器截图验证 `--fitnessrpg-open-history`。
- [x] 运行 `git diff --check`。
