# History 周回顾润色缓存操作 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 History 的本地模型润色区块中增加重新生成和清除缓存操作。

**Architecture:** Core 增加 fingerprint-based remove helper；`TodayPersistenceModel` 执行 JSON store 读写；`HistoryView` 只触发清除和重新运行现有 polish runner，不直接操作 store。

**Tech Stack:** Swift 6, SwiftUI, XCTest, JSON persistence.

---

### Task 1: Core Cache Removal

**Files:**
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/WeeklySummaryModelPolish.swift`
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`

- [ ] **Step 1: Write failing test**

Add `testWeeklySummaryPolishCacheRemovesOnlyMatchingSummaryEntry`, with two entries and an assertion that only the matching summary entry is removed.

- [ ] **Step 2: Verify RED**

Run:

```bash
swift test --package-path native/FitnessRPGCore --filter WeeklySummaryPolishCacheRemoves
```

Expected: build failure because `WeeklySummaryPolishCache.removing` does not exist.

- [ ] **Step 3: Implement removal helper**

Add:

```swift
public static func removing(
    summary: WeeklyTrainingSummary,
    from entries: [WeeklySummaryPolishEntry]
) -> [WeeklySummaryPolishEntry]
```

It should remove entries whose `summaryFingerprint` matches `fingerprint(for: summary)`.

- [ ] **Step 4: Verify GREEN**

Run the focused test and expect pass.

### Task 2: Persistence Model Clear Action

**Files:**
- Modify: `native/AppSources/iOS/Persistence/TodayPersistenceModel.swift`

- [ ] **Step 1: Add clear method**

Add `clearWeeklySummaryPolishEntry()` that loads entries, removes the current summary entry, saves the updated collection, clears `weeklySummaryPolishEntry`, and updates `storageStatusText`.

- [ ] **Step 2: Keep error handling local**

If loading or saving fails, keep current history in memory and set a readable `storageStatusText` error.

### Task 3: History UI Actions

**Files:**
- Modify: `native/AppSources/iOS/History/HistoryView.swift`

- [ ] **Step 1: Add action state and methods**

Add `@State private var weeklyPolishRegenerationToken = 0`, a `regenerateWeeklyPolish()` async method, and a `clearWeeklyPolishCache()` method.

- [ ] **Step 2: Allow refresh to ignore cache**

Change `refreshWeeklyPolishResponse()` to accept `ignoringCache: Bool = false`. Normal `.task` keeps using cache; regeneration bypasses cache after clearing.

- [ ] **Step 3: Add card buttons**

Pass `regenerateAction` and `clearAction` into `WeeklyTrainingSummaryCard`. Show compact bordered `Label` buttons under the local model polish text.

### Task 4: Docs And Verification

**Files:**
- Modify: `README.md`
- Modify: `native/README.md`

- [ ] **Step 1: Update docs**

Mention that History weekly polish cache now has clear/regenerate actions.

- [ ] **Step 2: Run verification**

```bash
swift test --package-path native/FitnessRPGCore
git diff --check
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/FitnessRPGHistoryCacheActionsIOS CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' -derivedDataPath /private/tmp/FitnessRPGHistoryCacheActionsWatch CODE_SIGNING_ALLOWED=NO build
```

- [ ] **Step 3: Commit and push**

Commit message:

```bash
feat(native): add weekly polish cache actions
```
