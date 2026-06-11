# 模型 Runtime 输出摘要 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Runtime diagnostics 在执行过模型或 fallback 后显示草稿标题和下一步动作，提升 DEBUG fixture 和未来真实模型排障效率。

**Architecture:** 仅扩展 `FitnessRPGCore` 的 diagnostics summary builder。SwiftUI 面板继续按现有 rows 渲染，不新增 iOS 专用视图逻辑。

**Tech Stack:** Swift 6、SwiftPM XCTest、SwiftUI diagnostics panel、Xcode iOS/watchOS build。

---

### Task 1: Core 红测

- [x] 写 `testModelRuntimeDiagnosticsIncludesRunDraftSummaryRows`。
- [x] 运行过滤测试确认缺少 `草稿` / `下一步` 行导致失败。

### Task 2: Core 实现

- [x] 在 `ModelRuntimeDiagnosticsBuilder.summary` 中仅当 `response != nil` 时追加 `草稿` 行。
- [x] 在 `ModelRuntimeDiagnosticsBuilder.summary` 中仅当 `response != nil` 时追加 `下一步` 行。
- [x] 运行过滤测试确认通过。

### Task 3: 文档与验证

- [x] 更新 README / native README 的诊断说明。
- [x] 运行 SwiftPM 全量测试。
- [x] 运行 iOS Xcode build。
- [x] 运行 watchOS Xcode build。
- [x] 运行 iOS Simulator ready fixture 截图检查面板渲染；新增输出行由 Core 测试验证。
- [x] 运行 `git diff --check`。
