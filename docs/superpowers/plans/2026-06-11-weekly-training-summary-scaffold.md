# 周训练总结脚手架 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增加确定性周训练总结 Core builder，为后续 History UI 和本地模型润色周报提供稳定输入。

**Architecture:** 新增 `WeeklyTrainingSummary.swift`，只依赖 `TrainingDayRecord`、`WorkoutResult` 和 `ReadinessColor`。SwiftUI 不在本轮接入，避免 UI 与聚合规则同时变化。

**Tech Stack:** Swift 6、SwiftPM XCTest、Xcode iOS/watchOS build。

---

### Task 1: Core 红测

- [x] 写混合训练周测试，覆盖 completed/downgraded/skipped/pending 和 readiness 分布。
- [x] 写空状态测试，覆盖无记录时的建立基线计划。
- [x] 运行过滤测试确认 `WeeklyTrainingSummaryBuilder` 不存在导致失败。

### Task 2: Core 实现

- [x] 新增 `WeeklyTrainingSummary`。
- [x] 新增 `WeeklyTrainingSummaryBuilder.summary(from:)`。
- [x] 实现周范围、完成标签、readiness 标签、安全标签和下周动作。
- [x] 运行过滤测试确认通过。

### Task 3: 文档与验证

- [x] 更新 README / native README 的当前状态。
- [x] 运行 SwiftPM 全量测试。
- [x] 运行 iOS Xcode build。
- [x] 运行 watchOS Xcode build。
- [x] 运行 `git diff --check`。
