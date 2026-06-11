# WatchConnectivity 真机验证诊断打磨 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 DEBUG WatchConnectivity 诊断面板直接给出真机验证下一步，降低配对设备测试时的排查成本。

**Architecture:** 在 `FitnessRPGCore` 的 `WatchConnectivityDiagnosticsSnapshot.summary` 中追加真机检查 rows。SwiftUI 面板继续纯展示 `summary.rows`，README 补充设备验证流程。

**Tech Stack:** Swift 6、SwiftPM XCTest、SwiftUI、Xcode iOS/watchOS build。

---

## Task 1: Core 红测

- [x] 在 `FitnessRPGCoreTests` 增加 ready 状态真机检查行断言。
- [x] 在 queued 状态测试中断言 `transferUserInfo` 检查提示。
- [x] 增加 inbound 回传清单断言。
- [x] 运行过滤测试确认失败。

## Task 2: Core 实现

- [x] 在 `WatchConnectivityDiagnosticsSnapshot.summary` 追加 `deviceValidationRows`。
- [x] 增加安装、发送、回传三条辅助行。
- [x] 保持原有 headline、detail、tint 和状态行不变。
- [x] 运行过滤测试确认通过。

## Task 3: 文档与验证

- [ ] 更新 README / native README 的真机 WatchConnectivity 验证步骤。
- [ ] 运行 `swift test --package-path native/FitnessRPGCore`。
- [ ] 运行 iOS generic Xcode build。
- [ ] 运行 watchOS generic Xcode build。
- [ ] 运行 `git diff --check`。
