# 本地模型 Adapter 边界 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增加可替换的本地模型 provider 协议和 runner，让未来 LiteRT-LM / Gemma adapter 接入时保持安全校验不变。

**Architecture:** 在 `FitnessRPGCore` 的 `ModelRuntime.swift` 中扩展 provider 边界。测试仍在 `FitnessRPGCoreTests` 中覆盖，不引入真实模型 SDK。

**Tech Stack:** Swift 6、async XCTest、Swift Package、Xcode iOS/watchOS build。

---

## Task 1: Core 红测

- [x] 写 ready provider、unavailable provider、deterministic stub provider 的失败测试。
- [x] 运行过滤测试确认失败。

## Task 2: Provider 边界实现

- [x] 新增 provider diagnostics 类型。
- [x] 新增 `ModelDraftProvider` 协议。
- [x] 新增 `ModelRuntimeRunner.response(context:provider:)`。
- [x] 新增 `DeterministicModelDraftProvider` 和 `UnavailableModelDraftProvider`。
- [x] 扩展 `ModelRuntimeResponse` 保留 provider diagnostics。
- [x] 运行过滤测试。

## Task 3: 文档与验证

- [x] 更新 README 和 native README。
- [x] 运行 `swift test`。
- [x] 运行 iOS build。
- [x] 运行 watchOS build。
- [x] 运行 `git diff --check`。
