# 本地模型资源预检 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增加 Core 模型资源清单和预检结果，让未来 LiteRT-LM / Gemma provider 可以明确报告模型资源是否就绪。

**Architecture:** `FitnessRPGCore` 只处理平台无关的数据结构：requirements、observations、preflight result。iOS/真实 provider 以后负责把 Bundle 或文件系统状态映射成 observations。`ModelRuntimeProviderDiagnostics` 通过可选 `resourceStatus` 暴露预检结果，诊断摘要只渲染摘要文本。

**Tech Stack:** Swift 6、Foundation、XCTest、Swift Package、Xcode iOS/watchOS build。

---

## Task 1: Core 红测

- [x] 新增资源全部就绪的预检测试。
- [x] 新增缺 tokenizer 的预检测试。
- [x] 新增 model 文件过小的预检测试。
- [x] 新增 diagnostics summary 资源行测试。
- [x] 运行过滤测试确认失败。

## Task 2: Core 资源预检实现

- [x] 新增 `ModelRuntimeResources.swift` 拆分资源预检类型。
- [x] 新增 `ModelRuntimeResourceKind`。
- [x] 新增 `ModelRuntimeResourceRequirement`。
- [x] 新增 `ModelRuntimeResourceObservation`。
- [x] 新增 `ModelRuntimeResourceStatus`。
- [x] 新增 `ModelRuntimeResourcePreflightResult`。
- [x] 新增 `ModelRuntimeResourcePreflight.evaluate(...)`。
- [x] 扩展 `ModelRuntimeProviderDiagnostics` 支持可选 `resourceStatus`。
- [x] 扩展 `ModelRuntimeDiagnosticsBuilder` 在有资源预检时显示“资源”行。
- [x] 运行过滤测试。

## Task 3: 文档与验证

- [x] 更新 README 和 native README。
- [x] 运行 `swift test`。
- [x] 运行 iOS build。
- [x] 运行 watchOS build。
- [x] 运行 `git diff --check`。
- [x] 提交并推送。
