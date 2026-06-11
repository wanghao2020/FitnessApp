# HealthKit 权限与数据覆盖 UX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 HealthKit fallback notice 展示明确的下一步操作，方便用户授权、补齐数据并进行真机验证。

**Architecture:** `FitnessRPGCore` 为 `HealthDataSourceSnapshot` 暴露纯 Swift action rows；iOS Today 只负责按行渲染，不判断 HealthKit 状态。HealthKit provider、readiness 评分、WatchConnectivity 和持久化保持不变。

**Tech Stack:** Swift 6, SwiftUI, XCTest, SF Symbols.

---

### Task 1: Core Action Rows

**Files:**
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/HealthDataSourceSnapshot.swift`
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`

- [ ] **Step 1: Write failing tests**

Add assertions that authorization, unavailable, and insufficient-data snapshots expose action rows with user-facing next steps.

- [ ] **Step 2: Run focused tests and verify RED**

Run:

```bash
swift test --package-path native/FitnessRPGCore --filter HealthDataSourceSnapshot
```

Expected: build or test failure because `actionRows` does not exist.

- [ ] **Step 3: Add `HealthDataSourceActionRow` and `actionRows`**

Add a `Codable`, `Equatable`, `Identifiable`, `Sendable` row type containing `title`, `value`, and `systemImageName`. Add computed rows on `HealthDataSourceSnapshot`.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run:

```bash
swift test --package-path native/FitnessRPGCore --filter HealthDataSourceSnapshot
```

Expected: all focused tests pass.

### Task 2: Today Notice Rendering

**Files:**
- Modify: `native/AppSources/iOS/TodayCommandCenterView.swift`

- [ ] **Step 1: Render action rows below the detail copy**

Use a compact vertical stack inside `TodayHealthSourceNoticeCard`. Each row uses an SF Symbol, a short semibold title, and secondary detail text.

- [ ] **Step 2: Keep responsive text safe**

Rows must allow multi-line Chinese, use system fonts, keep the existing 8pt rounded card treatment, and avoid nested decorative cards.

### Task 3: Documentation And Verification

**Files:**
- Modify: `README.md`
- Modify: `native/README.md`

- [ ] **Step 1: Update HealthKit MVP docs**

Mention that fallback notices now include concrete action rows for permission, data coverage, and unsupported device states.

- [ ] **Step 2: Update next-work roadmap**

Move the next HealthKit work from UI copy to real-device validation and deeper onboarding only if the action rows are insufficient.

- [ ] **Step 3: Run full verification**

Run:

```bash
swift test --package-path native/FitnessRPGCore
git diff --check
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/FitnessRPGHealthKitUXIOS CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' -derivedDataPath /private/tmp/FitnessRPGHealthKitUXWatch CODE_SIGNING_ALLOWED=NO build
```

Expected: all tests and builds pass.
