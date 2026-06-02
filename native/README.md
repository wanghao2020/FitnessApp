# Fitness RPG Native Scaffold

This folder contains the first native iPhone / watchOS scaffold for Fitness RPG.

## Structure

- `FitnessRPGCore/`: compiled Swift Package for shared product logic.
- `AppSources/iOS/`: SwiftUI source files for a future iPhone app target.
- `AppSources/watchOS/`: SwiftUI source files for a future watchOS app target.

## Current Pass

The shared core is the only compiled native target in this repository pass. It includes deterministic mock health profiles, readiness evaluation, quest selection, Watch execution result handling, and local model harness explanation.

The app source folders are intentionally not wired into an Xcode project yet. They are source scaffolds that should be copied or referenced by future Xcode app targets after the project file is created.

## Future Xcode Target Setup

1. Create an iOS app target named `FitnessRPG`.
2. Add `FitnessRPGCore` as a local Swift Package dependency from `native/FitnessRPGCore`.
3. Add `AppSources/iOS/*.swift` to the iOS target.
4. Create a watchOS app target named `FitnessRPGWatch`.
5. Add the same `FitnessRPGCore` package dependency to the watchOS target.
6. Add `AppSources/watchOS/*.swift` to the watchOS target.

## Future Integration Points

- HealthKit adapter feeds `HealthSummary`.
- WatchConnectivity adapter syncs `DailyQuest` and `ExecutionLog`.
- LiteRT-LM / Gemma adapter drafts coach text before deterministic safety validation.
- Persistence adapter stores memory drafts and completed workouts.

## Verification

Run the shared core tests:

```bash
cd native/FitnessRPGCore
swift test
```

Run the existing browser prototype contract test from the repository root:

```bash
node --check prototype/src/main.js
node --check prototype/src/mockData.js
node --check prototype/src/questEngine.js
node --check prototype/src/readiness.js
node --check prototype/src/render.js
node --check prototype/src/state.js
node --check prototype/src/execution.js
node --check prototype/src/modelHarness.js
node prototype/tests/prototypeContract.test.mjs
```
