# 验证报告归档浏览 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 DEBUG Today 增加已保存实机验证报告的本地浏览、再次复制入口，以及可复现截图的 DEBUG 自动打开参数。

**Architecture:** Core 为 report entry 暴露稳定展示属性；Today DEBUG 卡片打开 sheet；sheet 用 SwiftUI `NavigationStack` + `List` 展示归档，详情页负责完整正文和复制；`AppLaunchOptions` 提供 `--fitnessrpg-open-validation-report-archive` 作为 smoke test 入口。

**Tech Stack:** Swift 6, SwiftUI, XCTest, Xcode iOS/watchOS schemes.

---

### Task 1: Core Entry Display Helpers

**Files:**
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/RealDeviceValidationChecklist.swift`
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`

- [x] **Step 1: Write failing display tests**

Add:

```swift
func testRealDeviceValidationReportEntryProvidesArchiveDisplayText() {
    let entry = RealDeviceValidationReportEntry(
        headline: "实机验证还有阻塞项",
        body: "Fitness RPG 实机验证报告\n生成时间：1970-01-01T00:00:00Z",
        createdAt: Date(timeIntervalSince1970: 0)
    )

    XCTAssertEqual(entry.createdAtLabel, "1970-01-01T00:00:00Z")
    XCTAssertEqual(entry.bodyPreview, "Fitness RPG 实机验证报告")
}

func testRealDeviceValidationReportEntryUsesFallbackPreviewForBlankBody() {
    let entry = RealDeviceValidationReportEntry(
        headline: "空报告",
        body: "\n  \n",
        createdAt: Date(timeIntervalSince1970: 0)
    )

    XCTAssertEqual(entry.bodyPreview, "无报告正文")
}
```

- [x] **Step 2: Verify RED**

Run:

```bash
swift test --package-path native/FitnessRPGCore --filter RealDeviceValidationReportEntry
```

Expected: build failure because `createdAtLabel` and `bodyPreview` do not exist.

- [x] **Step 3: Implement helpers**

Add public computed properties to `RealDeviceValidationReportEntry`.

- [x] **Step 4: Verify GREEN**

Run the focused test again and expect pass.

### Task 2: SwiftUI Archive Sheet

**Files:**
- Modify: `native/AppSources/iOS/TodayCommandCenterView.swift`
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/RealDeviceValidationChecklist.swift`
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`

- [x] **Step 1: Pass entries into panel**

Pass `persistenceModel.validationReportEntries` instead of only the count.

- [x] **Step 2: Add archive button and sheet**

In `RealDeviceValidationChecklistPanel`, add `@State private var showsReportArchive = false`, show `查看归档` when entries are not empty, and present `ValidationReportArchiveSheet(entries:)`.

- [x] **Step 3: Add sheet, row, detail views**

Add private SwiftUI views:

- `ValidationReportArchiveSheet`
- `ValidationReportArchiveRow`
- `ValidationReportArchiveDetailView`

Use `UIPasteboard.general.string = entry.body` for detail copy.

- [x] **Step 4: Add DEBUG launch option**

Add `AppLaunchOptions.opensValidationReportArchive(arguments:)`, make it imply diagnostics, and pass it through `FitnessRPGApp` to auto-open the archive sheet for screenshot automation.

- [x] **Step 5: Add empty archive state**

Add tested Core empty-state copy and render it in the archive sheet when no reports are saved yet.

### Task 3: Documentation And Verification

**Files:**
- Modify: `README.md`
- Modify: `native/README.md`

- [x] **Step 1: Update docs**

Mention that DEBUG diagnostics can browse locally saved validation reports.

- [x] **Step 2: Run verification**

```bash
swift test --package-path native/FitnessRPGCore
git diff --check
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/FitnessRPGValidationReportViewerIOS CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' -derivedDataPath /private/tmp/FitnessRPGValidationReportViewerWatch CODE_SIGNING_ALLOWED=NO build
```

- [x] **Step 3: Simulator screenshot**

Launch with `--fitnessrpg-open-validation-report-archive` and screenshot `/private/tmp/fitnessrpg-validation-report-viewer.png`.

- [ ] **Step 4: Commit and push**

Commit message:

```bash
feat(native): browse validation report archive
```
