# Resource-backed 本地模型 Provider Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增加一个资源预检驱动的本地模型 provider facade，让未来 LiteRT-LM / Gemma adapter 可以接入同一个 runner 和 fallback 链路。

**Architecture:** `FitnessRPGCore` 新增 `ResourceBackedModelDraftProvider` 和 `ModelRuntimeDraftGenerator`，根据 `ModelRuntimeResourcePreflightResult` 与可选 generator 生成 diagnostics 并实现 `ModelDraftProvider`。iOS `LocalModelResourceBundleObserver` 继续负责 Bundle 文件观察，但 diagnostics 改为经由 Core facade。

**Tech Stack:** Swift 6、Swift Package、XCTest async tests、SwiftUI diagnostics surface、Xcode iOS/watchOS schemes.

---

### Task 1: Core 红测

**Files:**
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`

- [x] **Step 1: Add tests**

Add three tests near the existing model runtime provider tests:

```swift
func testResourceBackedModelDraftProviderFallsBackWhenResourcesMissing() async {
    let readiness = ReadinessEngine.evaluate(MockHealthProfiles.yellow)
    let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.calibrationRune.title)
    let context = ModelRuntimeContextBuilder.context(readiness: readiness, quest: quest, memories: [])
    let resourceStatus = ModelRuntimeResourcePreflight.evaluate(
        providerID: "gemma-e2b",
        displayName: "Gemma E2B Local",
        requirements: gemmaResourceRequirements,
        observations: [
            ModelRuntimeResourceObservation(
                requirementID: "model",
                fileName: "gemma-e2b.task",
                byteSize: 64_000_000
            )
        ]
    )
    let provider = ResourceBackedModelDraftProvider(resourceStatus: resourceStatus)

    let response = await ModelRuntimeRunner.response(context: context, provider: provider)

    XCTAssertTrue(response.usedFallback)
    XCTAssertEqual(response.providerDiagnostics?.state, .unavailable)
    XCTAssertEqual(response.providerDiagnostics?.message, "缺少 Tokenizer：tokenizer.model")
    XCTAssertEqual(response.providerDiagnostics?.resourceStatus, resourceStatus)
    XCTAssertTrue(response.validation.issues.contains(.providerUnavailable))
}

func testResourceBackedModelDraftProviderFallsBackWhenAdapterMissingAfterResourcesReady() async {
    let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
    let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.mainTrial.title)
    let context = ModelRuntimeContextBuilder.context(readiness: readiness, quest: quest, memories: [])
    let resourceStatus = readyGemmaResourceStatus
    let provider = ResourceBackedModelDraftProvider(resourceStatus: resourceStatus)

    let response = await ModelRuntimeRunner.response(context: context, provider: provider)

    XCTAssertTrue(response.usedFallback)
    XCTAssertEqual(response.providerDiagnostics?.state, .unavailable)
    XCTAssertEqual(response.providerDiagnostics?.message, "模型执行 adapter 未接入")
    XCTAssertEqual(response.providerDiagnostics?.resourceStatus?.state, .ready)
    XCTAssertTrue(response.validation.issues.contains(.providerUnavailable))
}

func testResourceBackedModelDraftProviderUsesAdapterDraftWhenResourcesReady() async {
    let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
    let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.mainTrial.title)
    let context = ModelRuntimeContextBuilder.context(readiness: readiness, quest: quest, memories: [])
    let provider = ResourceBackedModelDraftProvider(
        resourceStatus: readyGemmaResourceStatus,
        draftGenerator: { _ in
            ModelRuntimeDraft(
                title: "Gemma 草稿",
                body: "保持稳定节奏，按 Watch 步骤完成今日训练。",
                nextAction: "发送到 Watch"
            )
        }
    )

    let response = await ModelRuntimeRunner.response(context: context, provider: provider)

    XCTAssertFalse(response.usedFallback)
    XCTAssertEqual(response.source, .localModel)
    XCTAssertEqual(response.providerDiagnostics?.state, .ready)
    XCTAssertEqual(response.providerDiagnostics?.message, "模型资源与执行 adapter 已就绪")
    XCTAssertEqual(response.draft.title, "Gemma 草稿")
}
```

Add a helper near `gemmaResourceRequirements`:

```swift
private var readyGemmaResourceStatus: ModelRuntimeResourcePreflightResult {
    ModelRuntimeResourcePreflight.evaluate(
        providerID: "gemma-e2b",
        displayName: "Gemma E2B Local",
        requirements: gemmaResourceRequirements,
        observations: [
            ModelRuntimeResourceObservation(
                requirementID: "model",
                fileName: "gemma-e2b.task",
                byteSize: 64_000_000
            ),
            ModelRuntimeResourceObservation(
                requirementID: "tokenizer",
                fileName: "tokenizer.model",
                byteSize: 16_384
            )
        ]
    )
}
```

- [x] **Step 2: Verify RED**

Run:

```bash
swift test --package-path native/FitnessRPGCore --filter FitnessRPGCoreTests/testResourceBackedModelDraftProvider
```

Expected: build fails because `ResourceBackedModelDraftProvider` does not exist yet.

### Task 2: Core provider facade

**Files:**
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/ModelRuntime.swift`

- [x] **Step 1: Add generator alias**

Add near `ModelDraftProvider`:

```swift
public typealias ModelRuntimeDraftGenerator = @Sendable (ModelRuntimeContext) async throws -> ModelRuntimeDraft
```

- [x] **Step 2: Add provider facade**

Add after `ModelRuntimeRunner`:

```swift
public struct ResourceBackedModelDraftProvider: ModelDraftProvider {
    public let diagnostics: ModelRuntimeProviderDiagnostics
    private let draftGenerator: ModelRuntimeDraftGenerator?

    public init(
        resourceStatus: ModelRuntimeResourcePreflightResult,
        draftGenerator: ModelRuntimeDraftGenerator? = nil
    ) {
        self.draftGenerator = draftGenerator

        guard resourceStatus.state == .ready else {
            diagnostics = ModelRuntimeProviderDiagnostics(
                providerID: resourceStatus.providerID,
                displayName: resourceStatus.displayName,
                resourceStatus: resourceStatus
            )
            return
        }

        guard draftGenerator != nil else {
            diagnostics = ModelRuntimeProviderDiagnostics(
                providerID: resourceStatus.providerID,
                displayName: resourceStatus.displayName,
                state: .unavailable,
                message: "模型执行 adapter 未接入",
                resourceStatus: resourceStatus
            )
            return
        }

        diagnostics = ModelRuntimeProviderDiagnostics(
            providerID: resourceStatus.providerID,
            displayName: resourceStatus.displayName,
            state: .ready,
            message: "模型资源与执行 adapter 已就绪",
            resourceStatus: resourceStatus
        )
    }

    public func draft(for context: ModelRuntimeContext) async throws -> ModelRuntimeDraft {
        guard diagnostics.state == .ready, let draftGenerator else {
            throw ResourceBackedModelProviderError(message: diagnostics.message)
        }

        return try await draftGenerator(context)
    }

    private struct ResourceBackedModelProviderError: Error, LocalizedError, Sendable {
        let message: String

        var errorDescription: String? {
            message
        }
    }
}
```

- [x] **Step 3: Verify GREEN**

Run:

```bash
swift test --package-path native/FitnessRPGCore --filter FitnessRPGCoreTests/testResourceBackedModelDraftProvider
```

Expected: the new provider facade tests pass.

### Task 3: iOS observer wiring

**Files:**
- Modify: `native/AppSources/iOS/ModelRuntime/LocalModelResourceBundleObserver.swift`

- [x] **Step 1: Route diagnostics through the facade**

Change the observer to expose:

```swift
var provider: ResourceBackedModelDraftProvider {
    ResourceBackedModelDraftProvider(resourceStatus: resourceStatus)
}

var diagnostics: ModelRuntimeProviderDiagnostics {
    provider.diagnostics
}

private var resourceStatus: ModelRuntimeResourcePreflightResult {
    ModelRuntimeResourcePreflight.evaluate(
        providerID: profile.providerID,
        displayName: profile.displayName,
        requirements: profile.requirements,
        observations: observations
    )
}
```

- [x] **Step 2: Verify app build**

Run the iOS build command from Task 4.

### Task 4: Docs and verification

**Files:**
- Modify: `README.md`
- Modify: `native/README.md`

- [x] **Step 1: Update docs**

Mention that Core now has a resource-backed provider facade, and iOS DEBUG diagnostics go through it even before the real SDK is linked.

- [x] **Step 2: Run full Core tests**

Run:

```bash
swift test --package-path native/FitnessRPGCore
```

- [x] **Step 3: Build iOS and watchOS targets**

Run:

```bash
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'platform=iOS Simulator,id=9B424038-58BD-41D9-A446-399BCC2265C2' -derivedDataPath /private/tmp/FitnessRPGResourceBackedProviderIOS CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'platform=watchOS Simulator,id=62F2C4FA-A9CA-432C-AE3B-76177C6C6AC7' -derivedDataPath /private/tmp/FitnessRPGResourceBackedProviderWatch CODE_SIGNING_ALLOWED=NO build
```

- [x] **Step 4: Screenshot diagnostics mode**

Install the iOS build, launch with `--fitnessrpg-show-diagnostics`, and save `/private/tmp/fitnessrpg-resource-backed-provider.png`.

- [x] **Step 5: Commit**

Run:

```bash
git add README.md native/README.md native/AppSources/iOS/ModelRuntime/LocalModelResourceBundleObserver.swift native/FitnessRPGCore/Sources/FitnessRPGCore/ModelRuntime.swift native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift docs/superpowers/specs/2026-06-11-resource-backed-model-provider-design.md docs/superpowers/plans/2026-06-11-resource-backed-model-provider.md
git commit -m "feat(core): add resource backed model provider"
git push origin main
```
