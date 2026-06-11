# 本地模型 Bundle 资源观察器 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 Core 模型资源预检接到 iOS Bundle/文件扫描，让 DEBUG Runtime 诊断卡显示模型资源缺失或就绪状态。

**Architecture:** Core 只新增可测试的 file snapshot -> observation 转换；iOS 新增 `LocalModelResourceBundleObserver` 负责从 `Bundle.main` 和 `FileManager` 读取文件大小。Today diagnostics 使用该 observer 的 provider diagnostics，普通用户路径不变。

**Tech Stack:** Swift 6、Foundation、SwiftUI、XCTest、Xcode iOS/watchOS build。

---

## Task 1: Core 红测

- [x] 新增 file snapshot 匹配 requirement 生成 observation 的测试。
- [x] 新增未匹配 file snapshot 不生成 observation 的测试。
- [x] 运行过滤测试确认失败。

## Task 2: Core 转换实现

- [x] 新增 `ModelRuntimeResourceFileSnapshot`。
- [x] 新增 `ModelRuntimeResourceObservationBuilder.observations(requirements:files:)`。
- [x] 运行过滤测试。

## Task 3: iOS Bundle observer 接入

- [x] 新增 `native/AppSources/iOS/ModelRuntime/LocalModelResourceBundleObserver.swift`。
- [x] 在 Xcode project 中新增 ModelRuntime 分组、file reference 和 iOS Sources build phase 引用。
- [x] `TodayCommandCenterView.modelRuntimeDiagnostics` 使用 `LocalModelResourceBundleObserver().diagnostics`。

## Task 4: 文档与验证

- [x] 更新 README 和 native README。
- [x] 运行 `swift test`。
- [x] 运行 iOS build。
- [x] 运行 watchOS build。
- [x] 运行 `git diff --check`。
- [x] 模拟器诊断模式截图确认 Runtime 卡显示资源缺失原因。
- [x] 提交并推送。
