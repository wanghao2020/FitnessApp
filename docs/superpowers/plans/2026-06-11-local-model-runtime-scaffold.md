# 本地模型 Runtime Scaffold Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增加可测试的本地模型上下文、输出校验器和确定性 fallback，为后续 LiteRT-LM / Gemma adapter 做准备。

**Architecture:** 只在 `FitnessRPGCore` 新增纯 Swift 类型，不接真实模型 SDK。iOS 和 watchOS 继续通过现有 Core package 编译；产品行为不改变。

**Tech Stack:** Swift 6、XCTest、Swift Package、Xcode iOS/watchOS build。

---

## 文件结构

- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/ModelRuntime.swift`
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`
- Modify: `README.md`
- Modify: `native/README.md`

## Task 1: Core 红测

- [x] 写 context builder、validator、orchestrator 的失败测试。
- [x] 运行过滤测试确认失败。

## Task 2: Runtime Scaffold 实现

- [x] 新增 `ModelRuntimeContext`、`ModelRuntimeMemorySummary`、`ModelRuntimeDraft`。
- [x] 新增 `ModelRuntimeContextBuilder.context(...)`。
- [x] 新增 `ModelOutputValidator.validate(...)`。
- [x] 新增 `ModelRuntimeOrchestrator.response(...)` 和确定性 fallback。
- [x] 运行 Core 过滤测试。

## Task 3: 文档与验证

- [x] 更新 README 和 native README。
- [x] 运行 `swift test`。
- [x] 运行 iOS build。
- [x] 运行 watchOS build。
- [x] 运行 `git diff --check`。
