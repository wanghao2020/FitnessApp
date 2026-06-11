# 模型资源诊断明细 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 Runtime diagnostics 在资源汇总行之外展示每个模型资源的 ready/missing/invalid 明细。

**Architecture:** `FitnessRPGCore` 已经拥有 `ModelRuntimeResourcePreflightResult.statuses`。本次只扩展 `ModelRuntimeDiagnosticsBuilder`，把 statuses 转换成通用 `ModelRuntimeDiagnosticsRow`；SwiftUI 现有面板继续按 rows 渲染。

**Tech Stack:** Swift Package, XCTest, SwiftUI diagnostics renderer, Xcode iOS/watchOS schemes.

---

### Task 1: Core 失败测试

**Files:**
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`

- [x] **Step 1: Write the failing test**

Add this test near the existing model runtime diagnostics tests:

```swift
func testModelRuntimeDiagnosticsIncludesEachResourceStatusRow() {
    let resourceStatus = ModelRuntimeResourcePreflight.evaluate(
        providerID: "gemma-e2b",
        displayName: "Gemma E2B Local",
        requirements: ModelRuntimeResourceCatalog.gemmaE2B.requirements,
        observations: [
            ModelRuntimeResourceObservation(
                requirementID: "model",
                fileName: "ModelResources/gemma-e2b.task",
                byteSize: 512
            )
        ]
    )
    let diagnostics = ModelRuntimeProviderDiagnostics(
        providerID: "gemma-e2b",
        displayName: "Gemma E2B Local",
        resourceStatus: resourceStatus
    )

    let summary = ModelRuntimeDiagnosticsBuilder.summary(
        providerDiagnostics: diagnostics,
        response: nil
    )

    XCTAssertTrue(summary.rows.contains(ModelRuntimeDiagnosticsRow(
        title: "资源 · Model 文件",
        value: "Model 文件过小：512 / 1024 bytes",
        systemImageName: "exclamationmark.triangle.fill"
    )))
    XCTAssertTrue(summary.rows.contains(ModelRuntimeDiagnosticsRow(
        title: "资源 · Tokenizer 文件",
        value: "缺少 Tokenizer 文件：ModelResources/tokenizer.model",
        systemImageName: "xmark.circle.fill"
    )))
}
```

- [x] **Step 2: Run test to verify it fails**

Run:

```bash
swift test --package-path native/FitnessRPGCore --filter FitnessRPGCoreTests/testModelRuntimeDiagnosticsIncludesEachResourceStatusRow
```

Expected: test fails because the resource detail rows are not generated yet.

### Task 2: Diagnostics builder implementation

**Files:**
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/ModelRuntime.swift`
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/ModelRuntimeResources.swift`

- [x] **Step 1: Append resource detail rows**

Inside `ModelRuntimeDiagnosticsBuilder.summary(providerDiagnostics:response:)`, after appending the existing `"资源"` row, append:

```swift
rows.append(contentsOf: resourceStatus.statuses.map { status in
    ModelRuntimeDiagnosticsRow(
        title: "资源 · \(status.displayName)",
        value: status.detail,
        systemImageName: resourceSystemImageName(for: status.state)
    )
})
```

- [x] **Step 2: Add icon mapping helper**

Add this private helper in `ModelRuntimeDiagnosticsBuilder`:

```swift
private static func resourceSystemImageName(for state: ModelRuntimeResourceState) -> String {
    switch state {
    case .ready:
        return "checkmark.circle.fill"
    case .missing:
        return "xmark.circle.fill"
    case .invalid:
        return "exclamationmark.triangle.fill"
    }
}
```

- [x] **Step 3: Normalize undersized resource copy**

In `ModelRuntimeResourcePreflight`, build the undersized detail prefix with:

```swift
private static func undersizedDetailName(for requirement: ModelRuntimeResourceRequirement) -> String {
    if requirement.displayName.hasSuffix("文件") {
        return requirement.displayName
    }

    return "\(requirement.displayName) 文件"
}
```

Use it for invalid resources so `Model` becomes `Model 文件过小` and `Model 文件` stays `Model 文件过小`.

- [x] **Step 4: Run Core tests**

Run:

```bash
swift test --package-path native/FitnessRPGCore
```

Expected: all Core tests pass.

### Task 3: Docs and app verification

**Files:**
- Modify: `README.md`
- Modify: `native/README.md`

- [x] **Step 1: Update README copy**

Mention that DEBUG model resource diagnostics show per-file rows for model/tokenizer resources.

- [x] **Step 2: Build app targets**

Run:

```bash
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'platform=iOS Simulator,id=9B424038-58BD-41D9-A446-399BCC2265C2' -derivedDataPath /private/tmp/FitnessRPGModelResourceDiagnosticsDetailIOS CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'platform=watchOS Simulator,id=62F2C4FA-A9CA-432C-AE3B-76177C6C6AC7' -derivedDataPath /private/tmp/FitnessRPGModelResourceDiagnosticsDetailWatch CODE_SIGNING_ALLOWED=NO build
```

Expected: both targets build.

- [x] **Step 3: Screenshot diagnostics mode**

Install the iOS build on the simulator, launch with `--fitnessrpg-show-diagnostics`, and save a screenshot to `/private/tmp/fitnessrpg-model-resource-diagnostics-detail.png`.

- [x] **Step 4: Commit**

Run:

```bash
git add README.md native/README.md native/FitnessRPGCore/Sources/FitnessRPGCore/ModelRuntime.swift native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift docs/superpowers/specs/2026-06-11-model-resource-diagnostics-detail-design.md docs/superpowers/plans/2026-06-11-model-resource-diagnostics-detail.md
git commit -m "feat(core): detail model resource diagnostics"
git push origin main
```
