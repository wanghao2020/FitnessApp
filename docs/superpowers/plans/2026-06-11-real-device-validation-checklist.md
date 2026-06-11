# 实机验证总览清单 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 DEBUG Today 页面增加一张端到端实机验证总览卡片，串联 Watch、HealthKit、Runtime 和 History 周回顾缓存状态。

**Architecture:** `FitnessRPGCore` 新增纯派生 checklist builder，SwiftUI 只渲染 rows。现有 WatchConnectivity、HealthKit、Runtime、History 行为保持不变。

**Tech Stack:** Swift 6, SwiftUI, XCTest, Xcode iOS/watchOS schemes.

---

### Task 1: Core Checklist Builder

**Files:**
- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/RealDeviceValidationChecklist.swift`
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`

- [x] **Step 1: Write failing tests**

Add tests that assert:

- unsupported Watch + HealthKit authorization fallback + Runtime unavailable + no History produces blocking rows and orange headline.
- sent-but-not-returned Watch + loading HealthKit + Runtime ready + History without polish cache produces blue in-progress headline.
- inbound Watch + HealthKit success + Runtime ready + History polish cache produces green passed headline.

- [x] **Step 2: Verify RED**

Run:

```bash
swift test --package-path native/FitnessRPGCore --filter RealDeviceValidationChecklist
```

Expected: build failure because the checklist types do not exist.

- [x] **Step 3: Implement builder**

Create `RealDeviceValidationState`, `RealDeviceValidationRow`, `RealDeviceValidationChecklist`, and `RealDeviceValidationChecklistBuilder.summary(...)`.

- [x] **Step 4: Verify GREEN**

Run the focused test again and expect pass.

### Task 2: Today DEBUG Panel

**Files:**
- Modify: `native/AppSources/iOS/TodayCommandCenterView.swift`

- [x] **Step 1: Build checklist from existing state**

Add a computed `realDeviceValidationChecklist` using `watchSyncModel.diagnosticsSnapshot`, `healthDataSourceSnapshot`, `modelRuntimeDiagnostics`, `persistenceModel.historyDays.count`, and `persistenceModel.weeklySummaryPolishEntry != nil`.

- [x] **Step 2: Render panel above detailed diagnostics**

Add `RealDeviceValidationChecklistPanel` with compact row rendering and 8pt rounded material card styling. Show it only when `showsDiagnostics` is true.

### Task 3: Documentation And Verification

**Files:**
- Modify: `README.md`
- Modify: `native/README.md`

- [x] **Step 1: Update DEBUG diagnostics docs**

Mention the real-device validation overview card and that detailed Runtime / Watch panels remain below it.

- [x] **Step 2: Run verification**

```bash
swift test --package-path native/FitnessRPGCore
git diff --check
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/FitnessRPGRealDeviceChecklistIOS CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' -derivedDataPath /private/tmp/FitnessRPGRealDeviceChecklistWatch CODE_SIGNING_ALLOWED=NO build
```

- [x] **Step 3: Simulator screenshot**

Launch with `--fitnessrpg-show-diagnostics`, capture a screenshot, and check the overview card renders without text overlap.

- [x] **Step 4: Commit and push**

Commit message:

```bash
feat(native): add real device validation overview
```
