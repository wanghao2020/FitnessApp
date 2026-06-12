# 实机验证报告归档 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 DEBUG Today 诊断区域增加本地保存实机验证报告快照的能力。

**Architecture:** Core 定义 report entry 和 bounded archive helper；Persistence 用独立 `validation-reports.json` 存储；TodayPersistenceModel 负责加载/保存；SwiftUI DEBUG 总览卡只触发复制/保存动作并显示已保存数量。

**Tech Stack:** Swift 6, SwiftUI, XCTest, JSON persistence, Xcode iOS/watchOS schemes.

---

### Task 1: Core Report Archive

**Files:**
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/RealDeviceValidationChecklist.swift`
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`

- [x] **Step 1: Write failing archive tests**

Add tests after the report builder tests:

```swift
func testRealDeviceValidationReportArchivePrependsAndLimitsEntries() {
    let existing = (0..<3).map { index in
        RealDeviceValidationReportEntry(
            headline: "旧报告 \(index)",
            body: "body-\(index)",
            createdAt: Date(timeIntervalSince1970: Double(index))
        )
    }
    let updated = RealDeviceValidationReportArchive.upserting(
        report: RealDeviceValidationReport(body: "new-body"),
        headline: "新报告",
        in: existing,
        createdAt: Date(timeIntervalSince1970: 10),
        maxCount: 3
    )

    XCTAssertEqual(updated.map(\.headline), ["新报告", "旧报告 2", "旧报告 1"])
    XCTAssertEqual(updated.first?.body, "new-body")
    XCTAssertEqual(updated.first?.id, "validation-report-10")
}

func testRealDeviceValidationReportArchiveReplacesSameTimestamp() {
    let existing = [
        RealDeviceValidationReportEntry(
            headline: "旧报告",
            body: "old",
            createdAt: Date(timeIntervalSince1970: 10)
        )
    ]

    let updated = RealDeviceValidationReportArchive.upserting(
        report: RealDeviceValidationReport(body: "new"),
        headline: "新报告",
        in: existing,
        createdAt: Date(timeIntervalSince1970: 10),
        maxCount: 20
    )

    XCTAssertEqual(updated.count, 1)
    XCTAssertEqual(updated[0].headline, "新报告")
    XCTAssertEqual(updated[0].body, "new")
}
```

- [x] **Step 2: Verify RED**

Run:

```bash
swift test --package-path native/FitnessRPGCore --filter RealDeviceValidationReportArchive
```

Expected: build failure because archive types do not exist.

- [x] **Step 3: Implement archive model**

Add `RealDeviceValidationReportEntry` and `RealDeviceValidationReportArchive.upserting(...)` near the existing report builder.

- [x] **Step 4: Verify GREEN**

Run the focused test again and expect pass.

### Task 2: JSON Persistence

**Files:**
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGPersistence/JSONFitnessRPGStore.swift`
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGPersistenceTests/JSONFitnessRPGStoreTests.swift`

- [x] **Step 1: Write failing persistence test**

Add:

```swift
func testSavingValidationReportEntriesCanBeLoadedAgain() throws {
    let store = try temporaryStore()
    let entry = RealDeviceValidationReportEntry(
        headline: "实机验证还有阻塞项",
        body: "Fitness RPG 实机验证报告",
        createdAt: Date(timeIntervalSince1970: 10)
    )

    try store.saveValidationReportEntries([entry])
    let loaded = store.loadValidationReportEntries()

    XCTAssertEqual(loaded.value, [entry])
    XCTAssertNil(loaded.warning)
}
```

- [x] **Step 2: Verify RED**

Run:

```bash
swift test --package-path native/FitnessRPGCore --filter ValidationReportEntries
```

Expected: build failure because store methods do not exist.

- [x] **Step 3: Implement store methods**

Add:

```swift
public func loadValidationReportEntries() -> PersistenceLoadResult<[RealDeviceValidationReportEntry]> {
    readCollection(filename: "validation-reports.json", defaultValue: [])
}

public func saveValidationReportEntries(_ entries: [RealDeviceValidationReportEntry]) throws {
    try write(entries, filename: "validation-reports.json")
}
```

- [x] **Step 4: Verify GREEN**

Run the focused persistence test and expect pass.

### Task 3: Today Save Action

**Files:**
- Modify: `native/AppSources/iOS/Persistence/TodayPersistenceModel.swift`
- Modify: `native/AppSources/iOS/TodayCommandCenterView.swift`

- [x] **Step 1: Load and save reports in persistence model**

Add a published `validationReportEntries`, call `reloadValidationReports()` during init, and add `saveValidationReport(_:)` that uses `RealDeviceValidationReportArchive.upserting(...)`.

- [x] **Step 2: Add save button to DEBUG panel**

Pass `savedReportCount` and `saveReportAction` into `RealDeviceValidationChecklistPanel`. Add a second small bordered button with `tray.and.arrow.down.fill`, and show `已保存 N 份验证报告。` below the card detail when `N > 0`.

### Task 4: Documentation And Verification

**Files:**
- Modify: `README.md`
- Modify: `native/README.md`

- [x] **Step 1: Update docs**

Mention that DEBUG diagnostics can copy and locally save validation reports.

- [x] **Step 2: Run verification**

```bash
swift test --package-path native/FitnessRPGCore
git diff --check
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/FitnessRPGValidationReportArchiveIOS CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' -derivedDataPath /private/tmp/FitnessRPGValidationReportArchiveWatch CODE_SIGNING_ALLOWED=NO build
```

- [x] **Step 3: Simulator screenshot**

Launch with `--fitnessrpg-show-diagnostics`, screenshot `/private/tmp/fitnessrpg-validation-report-archive.png`, and confirm the two buttons do not overlap.

- [x] **Step 4: Commit and push**

Commit message:

```bash
feat(native): archive validation reports
```
