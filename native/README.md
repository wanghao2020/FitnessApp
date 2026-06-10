# Fitness RPG Native App Targets

This folder contains the native iPhone / watchOS app baseline for Fitness RPG.

## Structure

- `FitnessRPGCore/`: compiled Swift Package for shared product logic.
- `FitnessRPG.xcodeproj/`: Xcode project with buildable iOS and watchOS app schemes.
- `AppSources/iOS/`: SwiftUI source files used by the `FitnessRPG` iOS app target.
- `AppSources/watchOS/`: SwiftUI source files used by the `FitnessRPGWatch` watchOS app target.

## Current Pass

The repo now includes `native/FitnessRPG.xcodeproj` with buildable iOS and watchOS schemes. Both app targets use the local `FitnessRPGCore` Swift Package.

The shared core includes deterministic mock health profiles, readiness evaluation, quest selection, Watch execution result handling, and local model harness explanation.

## Xcode Targets

- `FitnessRPG`: iOS app target that launches `FitnessRPGApp`.
- `FitnessRPGWatch`: watchOS app target that launches `FitnessRPGWatchApp`.

Both targets link the local `FitnessRPGCore` package product.

## Future Integration Points

- HealthKit adapter feeds `HealthSummary`.
- WatchConnectivity adapter syncs `DailyQuest` and `ExecutionLog`.
- LiteRT-LM / Gemma adapter drafts coach text before deterministic safety validation.
- Persistence adapter stores memory drafts and completed workouts.

## Verification

Build the app targets:

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
```

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
