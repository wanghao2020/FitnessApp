# LiteRT-LM Swift 接入桥 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让本地模型 runtime 具备可接 LiteRT-LM Swift SDK 的 prompt、资源和 adapter 边界，同时默认保持可编译 fallback。

**Architecture:** Core 新增 SDK 无关 prompt formatter，并把 Gemma profile 迁移到 `.litertlm` 单文件容器。iOS adapter 使用 conditional compile 包裹真实 LiteRT-LM 调用；默认未链接 SDK 时继续报告不可用并走现有 fallback。

**Tech Stack:** Swift 6, Swift Package, SwiftUI diagnostics, conditional compilation, guarded LiteRT-LM Swift package entry.

---

### Task 1: Core Prompt Contract

**Files:**
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/ModelRuntime.swift`
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`

- [ ] **Step 1: Write failing prompt formatter test**

Add a test that creates a `ModelRuntimeContext` and expects `ModelRuntimePromptFormatter.prompt(for:)` to include safety rules, watch steps, memory lines, Chinese output, and JSON keys `title`, `body`, `nextAction`.

- [ ] **Step 2: Verify RED**

Run:

```bash
swift test --package-path native/FitnessRPGCore --filter ModelRuntimePromptFormatter
```

Expected: build failure because `ModelRuntimePromptFormatter` does not exist.

- [ ] **Step 3: Implement prompt formatter**

Add `ModelRuntimePrompt` and `ModelRuntimePromptFormatter` to Core. Keep it pure Swift and SDK independent.

- [ ] **Step 4: Verify GREEN**

Run the same focused test and expect pass.

### Task 2: LiteRT-LM Resource Catalog

**Files:**
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/ModelRuntimeResources.swift`
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`
- Modify: `native/AppSources/iOS/ModelRuntime/ModelResources/README.md`

- [ ] **Step 1: Update tests for `.litertlm` container**

Update catalog and resource-preflight tests to expect `ModelResources/gemma-4-E2B-it.litertlm` as the single required resource.

- [ ] **Step 2: Verify RED**

Run:

```bash
swift test --package-path native/FitnessRPGCore --filter ModelRuntimeResource
```

Expected: failures because catalog still points to `.task` and tokenizer files.

- [ ] **Step 3: Update catalog and helper fixtures**

Change `ModelRuntimeResourceCatalog.gemmaE2B` and test helper resources to the `.litertlm` container.

- [ ] **Step 4: Update model resource README**

Document the expected `.litertlm` package and keep the no-large-model-files rule.

- [ ] **Step 5: Verify GREEN**

Run focused resource tests and expect pass.

### Task 3: iOS Conditional Adapter Bridge

**Files:**
- Modify: `native/AppSources/iOS/ModelRuntime/GemmaLocalModelAdapter.swift`
- Modify: `native/AppSources/iOS/ModelRuntime/LocalModelResourceBundleObserver.swift`
- Modify: `README.md`
- Modify: `native/README.md`

- [ ] **Step 1: Make adapter resource-aware**

Give `GemmaLocalModelAdapter` bundle/profile/fileManager configuration and resolve the catalog model resource URL.

- [ ] **Step 2: Add conditional LiteRT-LM bridge**

Add `#if canImport(LiteRTLM) && FITNESSRPG_ENABLE_LITERTLM` code that imports `LiteRTLM`, creates an engine from the `.litertlm` model path, sends `ModelRuntimePromptFormatter.prompt(for:).rawText`, and returns raw text.

- [ ] **Step 3: Keep default fallback**

When the package or compile flag is absent, `isAvailable` remains false and `generateText` throws `sdkNotLinked`.

- [ ] **Step 4: Update docs**

Document that real SDK integration requires adding the LiteRT-LM Swift package, placing the `.litertlm` file in `ModelResources`, and enabling `FITNESSRPG_ENABLE_LITERTLM`.

### Task 4: Verification And Commit

- [ ] **Step 1: Run full tests**

```bash
swift test --package-path native/FitnessRPGCore
```

- [ ] **Step 2: Run whitespace check**

```bash
git diff --check
```

- [ ] **Step 3: Build iOS and watchOS**

```bash
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/FitnessRPGLiteRTLMBridgeIOS CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' -derivedDataPath /private/tmp/FitnessRPGLiteRTLMBridgeWatch CODE_SIGNING_ALLOWED=NO build
```

- [ ] **Step 4: Commit and push**

Commit message:

```bash
feat(native): prepare litertlm swift bridge
```
