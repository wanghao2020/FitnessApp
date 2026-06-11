# History 周回顾润色缓存 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将通过校验的 History 周回顾本地模型润色文案保存为本地缓存，并在后续打开 History 时优先恢复。

**Architecture:** 新增 Core 缓存模型和 upsert helper，JSON store 用独立文件保存 `WeeklySummaryPolishEntry` 集合。`TodayPersistenceModel` 负责加载、匹配和保存缓存，`HistoryView` 先展示缓存，没有缓存时才跑模型并保存 accepted local output。

**Tech Stack:** Swift 6、SwiftPM XCTest、FitnessRPGPersistence JSON store、SwiftUI、Xcode iOS/watchOS build。

---

## Task 1: Core / Persistence 红测

- [x] 在 `FitnessRPGCoreTests` 增加 `testWeeklySummaryPolishCacheUpsertsAcceptedLocalModelDraft`。
- [x] 在 `JSONFitnessRPGStoreTests` 增加 `testSavingWeeklySummaryPolishEntriesCanBeLoadedAgain`。
- [x] 运行过滤测试确认失败。

## Task 2: Core 缓存模型

- [x] 在 `WeeklySummaryModelPolish.swift` 增加 `WeeklySummaryPolishEntry`。
- [x] 增加 `WeeklySummaryPolishCache.fingerprint(for:)`、`entry(for:in:)`、`upserting(response:summary:in:date:)`。
- [x] 只保存 `.localModel` response，fallback response 不改变 entries。
- [x] 运行 Core 过滤测试确认通过。

## Task 3: JSON store

- [x] 在 `JSONFitnessRPGStore` 增加 `loadWeeklySummaryPolishEntries()`。
- [x] 在 `JSONFitnessRPGStore` 增加 `saveWeeklySummaryPolishEntries(_:)`。
- [x] 运行 persistence 过滤测试确认通过。

## Task 4: iOS History 接入

- [x] 在 `TodayPersistenceModel` 发布 `weeklySummaryPolishEntry`。
- [x] `reloadHistory()` 后加载并匹配缓存。
- [x] 增加 `saveWeeklySummaryPolishResponse(_:)`，只保存 accepted local model response。
- [x] 在 `HistoryView.refreshWeeklyPolishResponse()` 中先使用缓存，缺缓存才跑模型。
- [x] 成功 local model response 写回 persistence model。

## Task 5: 文档与验证

- [x] 更新 README / native README。
- [x] 运行 `swift test --package-path native/FitnessRPGCore`。
- [x] 运行 iOS generic Xcode build。
- [x] 运行 watchOS generic Xcode build。
- [x] Simulator ready fixture 截图确认缓存生成和显示。
- [x] Simulator 不带 fixture 重新打开 History，确认缓存恢复显示。
- [x] 运行 `git diff --check`。
