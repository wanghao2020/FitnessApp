# 本地模型资源打包入口 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 Gemma E2B 本地模型文件预留稳定的 iOS Bundle 资源目录，并让 Core catalog 指向该目录。

**Architecture:** Core catalog 使用 `ModelResources/...` 相对路径；iOS target 通过 Xcode folder reference 将 `native/AppSources/iOS/ModelRuntime/ModelResources` 复制到 app bundle。目录内只提交说明文件，不提交真实模型资源。

**Tech Stack:** Swift 6、Xcode project resources、XCTest、iOS/watchOS simulator builds。

---

## Task 1: Core 红测

- [x] 更新 `ModelRuntimeResourceCatalog.gemmaE2B` 测试，要求资源路径带 `ModelResources/` 前缀。
- [x] 运行过滤测试确认失败。

## Task 2: Core Catalog 路径更新

- [x] 将 Gemma E2B model 路径改为 `ModelResources/gemma-e2b.task`。
- [x] 将 tokenizer 路径改为 `ModelResources/tokenizer.model`。
- [x] 运行过滤测试。

## Task 3: iOS 资源目录与 Xcode 引用

- [x] 新增 `native/AppSources/iOS/ModelRuntime/ModelResources/README.md`。
- [x] 在 Xcode project 中新增 `ModelResources` folder reference。
- [x] 将 `ModelResources` 加入 iOS Resources build phase。

## Task 4: 文档与验证

- [x] 更新 README 和 native README。
- [x] 运行 `swift test`。
- [x] 运行 iOS build。
- [x] 检查构建产物包含 `FitnessRPG.app/ModelResources/README.md`。
- [x] 运行 watchOS build。
- [x] 运行 `git diff --check`。
- [x] 提交并推送。
