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

The current native pass also includes first-pass WatchConnectivity source adapters. iOS sends versioned quest payloads derived from `ReadinessEngine` and `QuestEngine`; watchOS receives those payloads, records step feedback as `ExecutionLog` values, and sends logs back for `ExecutionEngine` resolution on iPhone. The iOS target embeds the watchOS app in `FitnessRPG.app/Watch`, and the watchOS target declares `com.hao.fitnessrpg` as its companion bundle identifier.

The iOS target now owns local durable state through a JSON persistence store. It restores the same daily quest for the local day, persists Watch execution logs and resolved workout results, stores memory drafts, and advances deterministic RPG story progression. History and Memory Review expose those persisted records in the app. The watchOS target stays non-persistent in this pass.

## HealthKit MVP

The iOS target requests read-only HealthKit access for sleep, heart-rate, activity, and workout signals. The app maps available samples into `HealthSummary` and falls back to conservative yellow readiness when HealthKit is unavailable, denied, or incomplete.

The watchOS target does not read HealthKit in this pass.

## Xcode Targets

- `FitnessRPG`: iOS app target that launches `FitnessRPGApp`.
- `FitnessRPGWatch`: watchOS app target that launches `FitnessRPGWatchApp`.

Both targets link the local `FitnessRPGCore` package product; the iOS target also links `FitnessRPGPersistence` for JSON-backed durable state.

## DEBUG Launch Arguments

- `--fitnessrpg-open-history`: launch directly into History.
- `--fitnessrpg-open-latest-history-detail`: launch History and open the latest day detail.
- `--fitnessrpg-open-memory-review`: launch directly into Memory Review.
- `--fitnessrpg-show-diagnostics`: show the Today model harness diagnostics panel in DEBUG builds.

## Future Integration Points

- Real-device WatchConnectivity diagnostics can be hardened after device testing.
- HealthKit permission UX, diagnostics, and onboarding copy can be hardened after device testing.
- LiteRT-LM / Gemma adapter can use persisted Memory Review entries before deterministic safety validation.

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
