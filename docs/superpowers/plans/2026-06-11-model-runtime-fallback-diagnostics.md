# 模型 Runtime Fallback 诊断 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 Runtime diagnostics 中明确显示本地模型 fallback 是解析失败、adapter 失败还是安全校验失败。

**Architecture:** `FitnessRPGCore` 在 provider diagnostics 中增加可选 failure stage，runner 负责分类错误，diagnostics builder 负责把 parsing stage 转为通用 row。现有 SwiftUI 面板继续渲染 rows，不需要视图改动。

**Tech Stack:** Swift 6、XCTest async tests、Swift Package、Xcode iOS/watchOS schemes.

---

### Task 1: Core 红测

**Files:**
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`

- [x] **Step 1: Add parsing diagnostics test**

Add near existing model runtime diagnostics tests:

```swift
func testModelRuntimeDiagnosticsShowsParsingFailureReason() async {
    let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
    let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.mainTrial.title)
    let context = ModelRuntimeContextBuilder.context(readiness: readiness, quest: quest, memories: [])
    let provider = ResourceBackedModelDraftProvider(
        resourceStatus: readyGemmaResourceStatus,
        textGenerator: { _ in #"{"title":"空输出","body":" ","nextAction":"发送到 Watch"}"# }
    )

    let response = await ModelRuntimeRunner.response(context: context, provider: provider)
    let summary = ModelRuntimeDiagnosticsBuilder.summary(
        providerDiagnostics: response.providerDiagnostics!,
        response: response
    )

    XCTAssertTrue(response.usedFallback)
    XCTAssertEqual(response.providerDiagnostics?.failureStage, .parsing)
    XCTAssertTrue(summary.rows.contains(ModelRuntimeDiagnosticsRow(
        title: "解析",
        value: "模型输出缺少正文",
        systemImageName: "curlybraces.square.fill"
    )))
    XCTAssertTrue(summary.rows.contains(ModelRuntimeDiagnosticsRow(
        title: "校验",
        value: "providerFailed",
        systemImageName: "checkmark.shield.fill"
    )))
}
```

- [x] **Step 2: Add validation diagnostics test**

Add:

```swift
func testModelRuntimeDiagnosticsShowsValidatorFallbackReason() {
    let readiness = ReadinessEngine.evaluate(MockHealthProfiles.red)
    let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.recoveryCharm.title)
    let context = ModelRuntimeContextBuilder.context(readiness: readiness, quest: quest, memories: [])
    let diagnostics = ModelRuntimeProviderDiagnostics(
        providerID: "gemma-e2b",
        displayName: "Gemma E2B Local",
        state: .ready,
        message: "模型资源与执行 adapter 已就绪"
    )
    let response = ModelRuntimeOrchestrator.response(
        context: context,
        modelDraft: ModelRuntimeDraft(
            title: "冲刺 PR",
            body: "今天直接冲刺最大重量，突破 PR。",
            nextAction: "发送到 Watch"
        ),
        providerDiagnostics: diagnostics
    )

    let summary = ModelRuntimeDiagnosticsBuilder.summary(
        providerDiagnostics: diagnostics,
        response: response
    )

    XCTAssertTrue(response.usedFallback)
    XCTAssertTrue(summary.rows.contains(ModelRuntimeDiagnosticsRow(
        title: "校验",
        value: "unsafeIntensityForReadiness",
        systemImageName: "checkmark.shield.fill"
    )))
}
```

- [x] **Step 3: Add adapter diagnostics test**

Add:

```swift
func testModelRuntimeDiagnosticsShowsAdapterFailureReason() async {
    let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
    let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.mainTrial.title)
    let context = ModelRuntimeContextBuilder.context(readiness: readiness, quest: quest, memories: [])
    let provider = ResourceBackedModelDraftProvider(
        resourceStatus: readyGemmaResourceStatus,
        draftGenerator: { _ in throw TestModelRuntimeError(message: "SDK 执行失败") }
    )

    let response = await ModelRuntimeRunner.response(context: context, provider: provider)
    let summary = ModelRuntimeDiagnosticsBuilder.summary(
        providerDiagnostics: response.providerDiagnostics!,
        response: response
    )

    XCTAssertTrue(response.usedFallback)
    XCTAssertEqual(response.providerDiagnostics?.failureStage, .adapter)
    XCTAssertTrue(summary.rows.contains(ModelRuntimeDiagnosticsRow(
        title: "Adapter",
        value: "SDK 执行失败",
        systemImageName: "wrench.and.screwdriver.fill"
    )))
}
```

- [x] **Step 4: Verify RED**

Run:

```bash
swift test --package-path native/FitnessRPGCore --filter FitnessRPGCoreTests/testModelRuntimeDiagnosticsShows
```

Expected: build or tests fail because `failureStage`, parsing diagnostics row, and adapter diagnostics row do not exist yet.

### Task 2: Failure stage implementation

**Files:**
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/ModelRuntime.swift`

- [x] **Step 1: Add failure stage type**

Add near `ModelRuntimeProviderState`:

```swift
public enum ModelRuntimeProviderFailureStage: String, Codable, Equatable, Sendable {
    case adapter
    case parsing
}
```

- [x] **Step 2: Extend provider diagnostics**

Add property and initializer argument:

```swift
public let failureStage: ModelRuntimeProviderFailureStage?
```

Set `failureStage` in the initializer and default it to `nil`.

- [x] **Step 3: Classify runner failures**

In `ModelRuntimeRunner.response`, when constructing `failedDiagnostics`, pass:

```swift
failureStage: failureStage(for: error)
```

Add private helper:

```swift
private static func failureStage(for error: Error) -> ModelRuntimeProviderFailureStage {
    if error is ModelRuntimeDraftParsingError {
        return .parsing
    }

    return .adapter
}
```

- [x] **Step 4: Add parsing row**

In `ModelRuntimeDiagnosticsBuilder.summary(...)`, after resource rows and before output rows, append:

```swift
if providerDiagnostics.failureStage == .parsing {
    rows.append(ModelRuntimeDiagnosticsRow(
        title: "解析",
        value: providerDiagnostics.message,
        systemImageName: "curlybraces.square.fill"
    ))
}
```

- [x] **Step 5: Add adapter row**

In `ModelRuntimeDiagnosticsBuilder.summary(...)`, append:

```swift
if providerDiagnostics.failureStage == .adapter {
    rows.append(ModelRuntimeDiagnosticsRow(
        title: "Adapter",
        value: providerDiagnostics.message,
        systemImageName: "wrench.and.screwdriver.fill"
    ))
}
```

- [x] **Step 6: Verify GREEN**

Run:

```bash
swift test --package-path native/FitnessRPGCore --filter FitnessRPGCoreTests/testModelRuntimeDiagnosticsShows
```

Expected: both diagnostics tests pass.

### Task 3: Docs and verification

**Files:**
- Modify: `README.md`
- Modify: `native/README.md`

- [x] **Step 1: Update docs**

Mention that Runtime diagnostics now distinguishes parser fallback from validator fallback.

- [x] **Step 2: Run full Core tests**

Run:

```bash
swift test --package-path native/FitnessRPGCore
```

- [x] **Step 3: Build app targets**

Run:

```bash
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'platform=iOS Simulator,id=9B424038-58BD-41D9-A446-399BCC2265C2' -derivedDataPath /private/tmp/FitnessRPGFallbackDiagnosticsIOS CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'platform=watchOS Simulator,id=62F2C4FA-A9CA-432C-AE3B-76177C6C6AC7' -derivedDataPath /private/tmp/FitnessRPGFallbackDiagnosticsWatch CODE_SIGNING_ALLOWED=NO build
```

- [x] **Step 4: Commit**

Run:

```bash
git add README.md native/README.md native/FitnessRPGCore/Sources/FitnessRPGCore/ModelRuntime.swift native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift docs/superpowers/specs/2026-06-11-model-runtime-fallback-diagnostics-design.md docs/superpowers/plans/2026-06-11-model-runtime-fallback-diagnostics.md
git commit -m "feat(core): explain model fallback diagnostics"
git push origin main
```
