# 本地模型资源 Catalog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 Gemma E2B 本地模型的 provider 元数据和资源要求集中到 Core catalog，供 iOS Bundle observer 和未来真实 provider 复用。

**Architecture:** `FitnessRPGCore` 新增平台无关的 `ModelRuntimeResourceProfile` 和 `ModelRuntimeResourceCatalog.gemmaE2B`。iOS `LocalModelResourceBundleObserver` 只持有 profile 并做 Bundle/FileManager 扫描，不再定义资源文件名。

**Tech Stack:** Swift 6、Foundation、XCTest、Xcode iOS/watchOS build。

---

## Task 1: Core 红测

- [x] 新增 `ModelRuntimeResourceCatalog.gemmaE2B` 测试。
- [x] 运行过滤测试确认失败。

## Task 2: Core Catalog 实现

- [x] 新增 `ModelRuntimeResourceProfile`。
- [x] 新增 `ModelRuntimeResourceCatalog.gemmaE2B`。
- [x] 运行过滤测试。

## Task 3: iOS Observer 复用 Catalog

- [x] `LocalModelResourceBundleObserver` 改为接收 `profile`。
- [x] 默认 profile 使用 `ModelRuntimeResourceCatalog.gemmaE2B`。
- [x] 移除 iOS 层重复的 provider ID、显示名和 requirements 常量。

## Task 4: 文档与验证

- [x] 更新 README 和 native README。
- [x] 运行 `swift test`。
- [x] 运行 iOS build。
- [x] 运行 watchOS build。
- [x] 运行 `git diff --check`。
- [x] 提交并推送。
