# 本地模型 Runtime 诊断面板 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 iOS DEBUG 诊断面板显示本地模型 provider 状态、输出来源、安全校验和 fallback 路径。

**Architecture:** Core 派生诊断摘要，SwiftUI 只渲染摘要。Today 使用 deterministic stub provider 的 diagnostics 证明 adapter 边界已接通，不改变普通用户路径。

**Tech Stack:** Swift 6、SwiftUI、XCTest、Xcode iOS/watchOS build。

---

## Task 1: Core 红测

- [x] 新增 ready provider 和 unavailable fallback 的诊断摘要测试。
- [x] 运行过滤测试确认失败。

## Task 2: Core 诊断摘要实现

- [x] 新增 `ModelRuntimeDiagnosticsSummary`。
- [x] 新增 `ModelRuntimeDiagnosticsRow`。
- [x] 新增 `ModelRuntimeDiagnosticsBuilder.summary(providerDiagnostics:response:)`。
- [x] 运行过滤测试。

## Task 3: SwiftUI 接入

- [x] `ModelHarnessPanel` 增加可选 runtime summary 区块。
- [x] 新增第一屏可见的 `ModelRuntimeDiagnosticsPanel`。
- [x] `TodayCommandCenterView` 在 diagnostics 模式下显示 deterministic stub provider diagnostics。
- [x] 保持普通用户路径不显示该区块。

## Task 4: 文档与验证

- [x] 更新 README 和 native README。
- [x] 运行 `swift test`。
- [x] 运行 iOS build。
- [x] 运行 watchOS build。
- [x] 运行 `git diff --check`。
- [x] 模拟器诊断模式截图检查本地模型 Runtime 区块。
