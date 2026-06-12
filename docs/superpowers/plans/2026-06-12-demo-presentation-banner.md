# Demo Presentation Banner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a compact demo-mode banner to Today and History when deterministic demo seed data is active.

**Architecture:** Core owns presentation copy through `FitnessRPGDemoSeedPresentation`. iOS persistence publishes the active presentation after `applyDemoSeed(_:)`, and SwiftUI renders a reusable local banner component in Today and History.

**Tech Stack:** Swift Package domain models, SwiftUI, existing JSON demo seed path, Xcode simulator smoke.

**Execution status:** Implemented in `35c4db5 feat(native): show demo presentation banner`.

---

## Files

- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/FitnessRPGDemoSeed.swift`
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`
- Modify: `native/AppSources/iOS/Persistence/TodayPersistenceModel.swift`
- Modify: `native/AppSources/iOS/History/HistoryView.swift`
- Modify: `native/AppSources/iOS/TodayCommandCenterView.swift`
- Modify: `docs/superpowers/plans/2026-06-12-demo-presentation-banner.md`

## Tasks

- [x] **Step 1: Add failing Core test**

Add a test that asserts `FitnessRPGDemoSeed.showcase.presentation` has title `演示模式`, system image `sparkles.rectangle.stack`, and evidence rows for Today, History, Memory, and Diagnostics.

- [x] **Step 2: Verify RED**

Run: `swift test --package-path native/FitnessRPGCore --filter FitnessRPGCoreTests/testFitnessRPGDemoSeedProvidesPresentationBanner`

Expected: compile failure because `presentation` does not exist.

- [x] **Step 3: Implement presentation model**

Add `FitnessRPGDemoSeedPresentation` and `FitnessRPGDemoSeedPresentationEvidence`, then attach a `presentation` value to `FitnessRPGDemoSeed.showcase`.

- [x] **Step 4: Publish demo presentation in iOS persistence**

Add `@Published private(set) var demoSeedPresentation: FitnessRPGDemoSeedPresentation?`, set it in `applyDemoSeed(_:)`, and clear it in `loadOrCreateToday(readiness:date:)`.

- [x] **Step 5: Render reusable banner in History and Today**

Add `DemoSeedPresentationBanner` to `HistoryView.swift`. Show it before the weekly summary and before Today hero when `persistenceModel.demoSeedPresentation` is non-nil.

- [x] **Step 6: Verify**

Run:

```bash
swift test --package-path native/FitnessRPGCore
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
bash native/scripts/demo-seed-simulator-smoke.sh
git diff --check
```

- [x] **Step 7: Commit and push**

Commit message: `feat(native): show demo presentation banner`
