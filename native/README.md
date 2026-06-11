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

DEBUG diagnostics can also show WatchConnectivity support, activation, pairing, Watch App installation, reachability, recent send/receive path, local model Runtime provider status, Bundle resource preflight, per-file model/tokenizer resource rows, validator state, and fallback paths from the Today surface.

The iOS target now owns local durable state through a JSON persistence store. It restores the same daily quest for the local day, persists Watch execution logs and resolved workout results, stores memory drafts, and advances deterministic RPG story progression. History and Memory Review expose those persisted records in the app. The watchOS target stays non-persistent in this pass.

The shared core also includes a local model runtime scaffold, adapter boundary, SDK-independent resource preflight layer, and a Gemma E2B resource catalog. It turns current readiness, the active quest, and recent Memory Review entries into bounded prompt context, checks provider resource requirements from platform observations, calls an interchangeable draft provider, validates draft coach text for safety, and returns deterministic fallback copy when model output is missing, unavailable, or unsafe. The iOS DEBUG diagnostics path uses the Core catalog to scan `Bundle.main/ModelResources` for `gemma-e2b.task` and `tokenizer.model`, then shows both a resource summary row and each required file row in the Runtime panel. No LiteRT-LM / Gemma SDK or model file is linked in this pass.

## HealthKit MVP

The iOS target requests read-only HealthKit access for sleep, heart-rate, activity, and workout signals. The app maps available samples into `HealthSummary` and falls back to conservative yellow readiness when HealthKit is unavailable, denied, or incomplete. Fallback states now publish a structured source-status notice so Today can distinguish unsupported devices, unfinished authorization, and missing signal coverage.

The watchOS target does not read HealthKit in this pass.

## Xcode Targets

- `FitnessRPG`: iOS app target that launches `FitnessRPGApp`.
- `FitnessRPGWatch`: watchOS app target that launches `FitnessRPGWatchApp`.

Both targets link the local `FitnessRPGCore` package product; the iOS target also links `FitnessRPGPersistence` for JSON-backed durable state.

## DEBUG Launch Arguments

- `--fitnessrpg-open-history`: launch directly into History.
- `--fitnessrpg-open-latest-history-detail`: launch History and open the latest day detail.
- `--fitnessrpg-open-memory-review`: launch directly into Memory Review.
- `--fitnessrpg-show-diagnostics`: show the Today WatchConnectivity and model Runtime/resource diagnostics panels in DEBUG builds.

## Future Integration Points

- Real-device WatchConnectivity validation can harden diagnostics copy after paired-device testing.
- HealthKit permission and data-coverage copy can be validated on real devices before adding deeper onboarding.
- LiteRT-LM / Gemma SDK, model resource packaging, and model execution can plug into the Core adapter boundary behind deterministic safety validation.

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
