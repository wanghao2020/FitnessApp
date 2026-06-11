# 模型 Runtime DEBUG Fixture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增加 DEBUG-only 本地模型 fixture 启动参数，让诊断面板能在无真实 SDK/模型文件时验证 ready、parser、adapter 和 validator 路径。

**Architecture:** Core 负责解析 fixture launch args；iOS DEBUG adapter 返回确定性 raw text 或错误；`LocalModelResourceBundleObserver` 支持资源状态 override；Today 仅在 fixture mode 下执行一次 Runtime response 并显示结果。

**Tech Stack:** Swift 6、SwiftPM XCTest、SwiftUI、Xcode iOS/watchOS build、iOS Simulator screenshot。

---

### Task 1: Core launch args

- [x] 写 `AppLaunchOptions.modelRuntimeDebugFixtureMode` 红测。
- [x] 运行过滤测试确认缺少 API 失败。
- [x] 新增 `ModelRuntimeDebugFixtureMode`。
- [x] 实现四个 fixture launch args 解析。
- [x] 运行过滤测试确认通过。

### Task 2: iOS DEBUG fixture adapter

- [x] 新增 `DebugGemmaLocalModelAdapter`。
- [x] 为 `LocalModelResourceBundleObserver` 增加 resource status override。
- [x] 新增 `.debugFixture(mode:)` 工厂，注入模拟 ready 资源状态。
- [x] 保持普通路径继续扫描 Bundle 资源。

### Task 3: Today 诊断执行

- [x] App 从 DEBUG launch args 读取 fixture mode。
- [x] Today 接收 fixture mode。
- [x] fixture mode 下执行一次 `ModelRuntimeRunner.response`。
- [x] 诊断 summary 优先展示 response provider diagnostics。

### Task 4: 文档与验证

- [x] 更新 README / native README 的 DEBUG launch args。
- [x] 运行 SwiftPM 全量测试。
- [x] 运行 iOS Xcode build。
- [x] 运行 watchOS Xcode build。
- [x] 运行 iOS Simulator fixture 截图检查。
- [x] 运行 `git diff --check`。
