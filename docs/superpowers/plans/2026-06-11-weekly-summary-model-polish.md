# History 周回顾本地模型润色 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 iOS History 周回顾在本地模型输出安全可用时显示润色文案，不可用时保持确定性 summary。

**Architecture:** 在 Core 中新增周回顾到 `ModelRuntimeContext` 的适配器和 polish runner，复用现有 provider / parser / validator / diagnostics。iOS History 只接收 `ModelRuntimeResponse?`，仅在 `.localModel` 时展示润色区块。

**Tech Stack:** Swift 6、SwiftPM XCTest、SwiftUI、Xcode iOS/watchOS build。

---

## Task 1: Core 红测

- [x] 在 `FitnessRPGCoreTests` 增加 `testWeeklySummaryModelContextPreservesDeterministicBoundaries`。
- [x] 在 `FitnessRPGCoreTests` 增加 `testWeeklySummaryPolishRunnerAcceptsSafeProviderDraft`。
- [x] 在 `FitnessRPGCoreTests` 增加 `testWeeklySummaryPolishRunnerFallsBackToDeterministicSummary`。
- [x] 运行过滤测试确认失败。

## Task 2: Core 实现

- [x] 新增 `native/FitnessRPGCore/Sources/FitnessRPGCore/WeeklySummaryModelPolish.swift`。
- [x] 实现 `WeeklySummaryModelContextBuilder.context(summary:)`。
- [x] 实现 `WeeklySummaryPolishRunner.response(summary:provider:)` 和 `fallbackDraft(for:)`。
- [x] 运行过滤测试确认通过。

## Task 3: iOS History 接入

- [x] 修改 `HistoryView`，增加 `modelRuntimeFixtureMode` 参数、state 和 async refresh。
- [x] 修改 `WeeklyTrainingSummaryCard`，在 `.localModel` 输出时显示“本地模型润色”区块。
- [x] 修改 `TodayCommandCenterView`，把 fixture mode 传给 History。
- [x] 修改 `DebugGemmaLocalModelAdapter`，当 context 是 `周训练总结` 时返回周回顾 fixture 文案。

## Task 4: 文档与验证

- [x] 更新 README / native README。
- [x] 运行 `swift test --package-path native/FitnessRPGCore`。
- [x] 运行 iOS generic Xcode build。
- [x] 运行 watchOS generic Xcode build。
- [x] Simulator 使用 `--fitnessrpg-open-history --fitnessrpg-model-fixture-ready` 截图验证。
- [x] 运行 `git diff --check`。
