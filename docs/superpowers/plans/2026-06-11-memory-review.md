# Memory Review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增加只读 Memory Review 页面，让已持久化的 memory drafts 能被用户从 Today 进入、列表查看并打开详情。

**Architecture:** `FitnessRPGCore` 负责把 `MemoryEntry` 和 `TrainingDayRecord` 派生成展示模型；`TodayPersistenceModel` 负责读取 JSON store 并发布 memory review 状态；SwiftUI 负责列表、详情、空状态和导航入口。首版不改变持久化 schema。

**Tech Stack:** Swift 6, SwiftUI, XCTest, JSONFitnessRPGStore, Xcode project file, Markdown docs.

---

### Task 1: Core Memory Review Model

**Files:**
- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/MemoryReview.swift`
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`

- [ ] **Step 1: 写 failing tests**

Add tests for:
- sorted memory review entries,
- matched training record enrichment,
- unmatched memory fallback.

Run:
```bash
swift test --package-path native/FitnessRPGCore --filter FitnessRPGCoreTests/testMemoryReview
```

Expected: build fails because `MemoryReviewBuilder` is not defined.

- [ ] **Step 2: 实现 core 展示模型**

Create `MemoryReviewEntry` and `MemoryReviewBuilder.entries(from:records:)`.

- [ ] **Step 3: 验证 core 测试**

Run:
```bash
swift test --package-path native/FitnessRPGCore --filter FitnessRPGCoreTests/testMemoryReview
```

Expected: memory review tests pass.

### Task 2: Navigation Constants

**Files:**
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/AppLaunchOptions.swift`
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/AppNavigationDisplay.swift`
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`

- [ ] **Step 1: 写 failing tests**

Extend existing app launch/navigation tests to expect:
- `.memoryReview`
- `--fitnessrpg-open-memory-review`
- `记忆回顾`
- `记忆`
- `book.closed`

- [ ] **Step 2: 实现 constants**

Add the memory destination and display labels.

- [ ] **Step 3: 验证 core 测试**

Run:
```bash
swift test --package-path native/FitnessRPGCore
```

Expected: all core tests pass.

### Task 3: iOS Memory Review State And UI

**Files:**
- Modify: `native/AppSources/iOS/Persistence/TodayPersistenceModel.swift`
- Create: `native/AppSources/iOS/Memory/MemoryReviewView.swift`
- Modify: `native/AppSources/iOS/TodayCommandCenterView.swift`
- Modify: `native/FitnessRPG.xcodeproj/project.pbxproj`

- [ ] **Step 1: Expose memory review state**

Add:
- `memoryReviewEntries`
- `memoryReviewLoadErrorText`
- `memoryReviewEmptyStateText`
- `reloadMemoryReview()`

- [ ] **Step 2: Build SwiftUI view**

Create list, empty state, error state, row and detail view.

- [ ] **Step 3: Wire navigation**

Add `.memoryReview` route and Today toolbar entry.

- [ ] **Step 4: Add file to Xcode project**

Register `MemoryReviewView.swift` in iOS sources and group tree.

### Task 4: Docs And Verification

**Files:**
- Modify: `README.md`
- Modify: `native/README.md`
- Add: `docs/superpowers/specs/2026-06-11-memory-review-design.md`
- Add: `docs/superpowers/plans/2026-06-11-memory-review.md`

- [ ] **Step 1: Update README roadmap**

Replace completed History wording with Memory Review, diagnostics, HealthKit UX, local model runtime, and weekly summary.

- [ ] **Step 2: Run final verification**

Run:
```bash
swift test --package-path native/FitnessRPGCore
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'platform=iOS Simulator,id=9B424038-58BD-41D9-A446-399BCC2265C2' -derivedDataPath /private/tmp/FitnessRPGMemoryReviewIOS CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'platform=watchOS Simulator,id=62F2C4FA-A9CA-432C-AE3B-76177C6C6AC7' -derivedDataPath /private/tmp/FitnessRPGMemoryReviewWatch CODE_SIGNING_ALLOWED=NO build
git diff --check
```

Expected: all commands exit with code 0.

- [ ] **Step 3: Commit and push**

Run:
```bash
git add README.md native/README.md docs/superpowers/specs/2026-06-11-memory-review-design.md docs/superpowers/plans/2026-06-11-memory-review.md native
git commit -m "feat(native): add memory review surface"
git push origin main
```
