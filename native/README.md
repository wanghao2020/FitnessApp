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

DEBUG diagnostics can also show a real-device validation overview plus WatchConnectivity support, activation, pairing, Watch App installation, reachability, recent send/receive path, local model Runtime provider status, Bundle resource preflight, `.litertlm` resource rows, validator state, and fallback paths from the Today surface. The overview can copy, locally save, and browse plain-text validation reports for real-device test notes. Use `--fitnessrpg-open-validation-report-archive` to enable diagnostics and open the saved-report archive sheet directly for smoke-test screenshots.
When a Runtime response has executed, the panel also shows the resulting draft title and next action so model, fixture, and fallback runs can be inspected without opening logs.
The WatchConnectivity panel includes three real-device checklist rows: installation readiness, send path, and inbound return. Use them with `--fitnessrpg-show-diagnostics` when validating paired hardware.

DEBUG demo builds can seed a complete deterministic showcase with `--fitnessrpg-demo-seed`. It writes Today, History, Memory Review, weekly polish cache, and validation archive data so the app can be demonstrated before real HealthKit, WatchConnectivity, or LiteRT-LM files are available.
For one-click simulator demos, use the shared `FitnessRPGDemo` Xcode scheme or run `bash native/scripts/demo-seed-simulator-smoke.sh`; pass `--screenshot /private/tmp/fitnessrpg-demo-smoke.png` for one UI capture or `--screenshots-dir /private/tmp/fitnessrpg-demo-gallery` for the full History/Today/Memory/archive gallery. See `docs/validation/demo-seed-runbook.md`.

DEBUG builds also support local model Runtime fixture launch arguments. These simulate ready resources and deterministic adapter output without linking LiteRT/Gemma or packaging model files, so the Runtime panel and History weekly polish path can exercise ready, parsing failure, adapter failure, and validator fallback paths.

The iOS target now owns local durable state through a JSON persistence store. It restores the same daily quest for the local day, persists Watch execution logs and resolved workout results, stores memory drafts, and advances deterministic RPG story progression. History and Memory Review expose those persisted records in the app. History now includes a deterministic weekly summary and next-week plan built from persisted training records, plus a cached local model polish section when provider output passes validation. The cached weekly polish section can be regenerated or cleared from History. The watchOS target stays non-persistent in this pass.

The shared core also includes a local model runtime scaffold, adapter boundary, SDK-independent resource preflight layer, resource-backed provider facade, raw text output parser, prompt formatter, and a Gemma 4 E2B LiteRT-LM resource catalog. It turns current readiness, the active quest, and recent Memory Review entries into bounded prompt context, checks provider resource requirements from platform observations, lets future SDK adapters return raw text or structured drafts, validates draft coach text for safety, and returns deterministic fallback copy when model output is missing, unavailable, or unsafe. The iOS DEBUG diagnostics path uses the Core catalog to scan `Bundle.main/ModelResources/gemma-4-E2B-it.litertlm`, combines that result with the iOS `GemmaLocalModelAdapting` bridge, routes the result through the Core provider facade, then shows resource, adapter, parsing, validator, and fallback signals in the Runtime panel. Real LiteRT-LM execution remains guarded by the `FITNESSRPG_ENABLE_LITERTLM` compile flag and requires adding the Swift package plus a licensed `.litertlm` model package.

## HealthKit MVP

The iOS target requests read-only HealthKit access for sleep, heart-rate, activity, and workout signals. The app maps available samples into `HealthSummary` and falls back to conservative yellow readiness when HealthKit is unavailable, denied, or incomplete. Fallback states now publish a structured source-status notice with next-action rows so Today can distinguish unsupported devices, unfinished authorization, and missing signal coverage.
Use `bash native/scripts/healthkit-real-device-preflight.sh`, then follow `docs/validation/healthkit-real-device-runbook.md` when validating permissions and data coverage on real iPhone hardware.

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
- `--fitnessrpg-open-validation-report-archive`: enable diagnostics and open the saved validation report archive sheet for screenshots.
- `--fitnessrpg-demo-seed`: seed deterministic Today, History, Memory Review, weekly polish, and validation archive demo data in DEBUG builds.
- `--fitnessrpg-model-fixture-ready`: in DEBUG diagnostics, run a successful local model fixture response.
- `--fitnessrpg-model-fixture-parsing-failure`: in DEBUG diagnostics, run a fixture response that fails raw text parsing.
- `--fitnessrpg-model-fixture-adapter-failure`: in DEBUG diagnostics, run a fixture response that fails at the adapter layer.
- `--fitnessrpg-model-fixture-validator-failure`: in DEBUG diagnostics, run a fixture response rejected by the safety validator.

## Demo Seed Smoke

Run the deterministic simulator demo from the repository root:

```bash
bash native/scripts/demo-seed-simulator-smoke.sh
```

The script builds `FitnessRPGDemo`, installs it on a booted iPhone simulator, launches History with diagnostics, and checks the seeded JSON persistence files. Add `--screenshot /private/tmp/fitnessrpg-demo-smoke.png` to save one rendered History screen, or `--screenshots-dir /private/tmp/fitnessrpg-demo-gallery` to capture History, Today, Memory Review, and validation archive screens during the same pass.

## Future Integration Points

- Real-device WatchConnectivity validation can now start with `bash native/scripts/watchconnectivity-real-device-preflight.sh`, then follow `docs/validation/watchconnectivity-real-device-runbook.md`: confirm iPhone support/pairing/Watch App installation, send Today to Watch, complete Watch steps, then verify inbound return and History persistence.
- HealthKit permission and data-coverage action rows can be validated with `bash native/scripts/healthkit-real-device-preflight.sh` and `docs/validation/healthkit-real-device-runbook.md` before adding deeper onboarding.
- LiteRT-LM / Gemma SDK execution can now start with `bash native/scripts/model-artifact-git-guard.sh`, `bash native/scripts/litertlm-integration-checklist.sh`, then `bash native/scripts/litertlm-real-device-preflight.sh`, and follow `docs/validation/litertlm-real-device-runbook.md` before linking the Swift package, placing the local ignored `ModelResources/gemma-4-E2B-it.litertlm`, and setting `FITNESSRPG_ENABLE_LITERTLM`.
- End-to-end real-device validation can now start with `bash native/scripts/end-to-end-real-device-preflight.sh`, then follow `docs/validation/end-to-end-real-device-runbook.md` to capture baseline, HealthKit, Watch return, Runtime, History weekly polish, and final validation report archive evidence in one pass.

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
