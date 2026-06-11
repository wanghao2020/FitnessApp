# iOS Gemma Adapter 占位层 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 iOS target 增加可替换的 Gemma 本地模型 adapter 占位层，并保持 Core provider/fallback 语义不变。

**Architecture:** Core 增加 optional raw text generator 初始化入口；iOS 新增 `GemmaLocalModelAdapting` 和默认不可用 adapter；`LocalModelResourceBundleObserver` 将 Bundle 资源状态与 adapter 可用性组合成 `ResourceBackedModelDraftProvider`。

**Tech Stack:** Swift 6、SwiftPM XCTest、SwiftUI iOS target、Xcode iOS/watchOS build。

---

### Task 1: Core optional adapter 入口

- [x] 写 `ResourceBackedModelDraftProvider` optional text-generator 红测。
- [x] 运行过滤测试，确认缺少接口导致失败。
- [x] 新增 `init(resourceStatus:optionalTextGenerator:)`。
- [x] 运行过滤测试，确认 nil adapter 走 unavailable，可用 adapter 走 local model。

### Task 2: iOS Gemma adapter 占位层

- [x] 新增 `GemmaLocalModelAdapting` 协议。
- [x] 新增默认不可用 `GemmaLocalModelAdapter`。
- [x] 将 adapter 注入 `LocalModelResourceBundleObserver`。
- [x] 将 `GemmaLocalModelAdapter.swift` 加入 iOS target Sources。

### Task 3: 文档与验证

- [x] 更新 README / native README 的当前状态说明。
- [x] 运行 SwiftPM 全量测试。
- [x] 运行 iOS Xcode build。
- [x] 运行 watchOS Xcode build。
- [x] 运行 DEBUG 诊断启动截图检查。
- [x] 运行 `git diff --check`。
