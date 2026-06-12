# Fitness RPG

Fitness RPG is an iPhone + Apple Watch AI fitness coach RPG app concept.

The project is local-first:

- iPhone reads Apple Health / Apple Watch data through HealthKit.
- iPhone owns planning, safety validation, memory, and local model orchestration.
- Apple Watch acts as the workout execution and quick feedback surface.
- Gemma / LiteRT-LM style local models are intended for bounded coach text, summaries, and narrative drafts.
- Remote APIs are optional enhancement paths, not the default safety authority.
- Fitness Coach RPG skill content becomes app rules, templates, and narrative knowledge, not one giant prompt.

## Current Repository Areas

- `prototype/`: browser Today Command Center prototype with Chinese Fitness RPG UI, readiness scenarios, Watch execution loop, local model harness, memory draft, and visual asset layer.
- `native/FitnessRPG.xcodeproj/`: Xcode project with buildable iOS and watchOS app schemes.
- `native/FitnessRPGCore/`: Swift Package containing shared deterministic domain models and engines.
- `native/AppSources/`: SwiftUI iPhone and watchOS source files used by the native app targets.
- `docs/project-brief.md`: product and architecture brief.
- `docs/superpowers/`: design specs and implementation plans used during development.
- `records/`: migrated conversation archive and raw Codex thread sources.
- `work/`: migration helper scripts kept for traceability.

## Current Verification

Build native iOS and watchOS app targets:

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
```

Run native shared core tests:

```bash
cd native/FitnessRPGCore
swift test
```

Run browser prototype checks from the repository root:

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

## Native Status

The native code now includes `native/FitnessRPG.xcodeproj` with buildable iOS and watchOS app schemes, plus the shared `native/FitnessRPGCore` Swift Package.

The iOS target includes a read-only HealthKit MVP that maps available Apple Health sleep, heart-rate, activity, and workout data into `HealthSummary`. Missing, denied, unavailable, or incomplete HealthKit data falls back to the conservative yellow readiness path, with a structured source-status notice explaining the reason and showing concrete next-action rows for permissions, device support, or missing signal coverage.

The native app now includes a first-pass WatchConnectivity sync layer. The iOS app can package the current `DailyQuest` into a versioned Core payload and send it to the watchOS app; the watchOS app records `ExecutionLog` feedback and returns it to iPhone for deterministic `ExecutionEngine` resolution. When WatchConnectivity is unavailable, both app surfaces keep safe fallback behavior.

DEBUG builds can show a real-device validation overview plus WatchConnectivity and local model Runtime diagnostics from `--fitnessrpg-show-diagnostics`. The overview summarizes Watch sync, HealthKit, Runtime, and History weekly polish cache readiness, and can copy, locally save, and browse plain-text validation reports for issue notes or real-device test logs. Use `--fitnessrpg-open-validation-report-archive` to enable diagnostics and open the saved-report archive sheet directly during simulator or real-device smoke tests. The detailed panels separate Watch session support, activation, pairing, reachability, model provider status, Bundle model resource preflight, `.litertlm` resource rows, validator state, and fallback paths.
After a Runtime response executes, the panel also shows the generated draft title and next action for quick output inspection.
The WatchConnectivity diagnostics panel also includes device-validation checklist rows for installation, sending, and inbound return so paired-device testing can move from setup to Today send to Watch return without reading console logs first.

DEBUG demo builds can use `--fitnessrpg-demo-seed` to write deterministic Today, History, Memory Review, weekly polish cache, and validation archive data. This gives the native app a concrete showcase path before real HealthKit, WatchConnectivity, or LiteRT-LM resources are available.
For one-click simulator demos, use the shared `FitnessRPGDemo` Xcode scheme or run `bash native/scripts/demo-seed-simulator-smoke.sh`; pass `--screenshot /private/tmp/fitnessrpg-demo-smoke.png` for one UI capture or `--screenshots-dir /private/tmp/fitnessrpg-demo-gallery` for the full History/Today/Memory/archive gallery. See `docs/validation/demo-seed-runbook.md`.

DEBUG model Runtime fixture launch arguments can also simulate ready output, parsing failure, adapter failure, and validator fallback without real model files. Use them together with `--fitnessrpg-show-diagnostics` when validating the Runtime panel, or with `--fitnessrpg-open-history` when validating the History weekly polish path.

The native iOS app now has a JSON-backed persistence MVP. iPhone restores the same local-day quest after relaunch, saves Watch-returned execution logs and deterministic workout results, stores memory drafts, and advances lightweight RPG chapter/node progression locally. History and Memory Review surfaces expose persisted training days and memory drafts for review. History shows a deterministic weekly summary and next-week plan built from persisted training records, caches accepted local-model-polished weekly copy after provider output passes the existing safety pipeline, and lets the user clear or regenerate the current weekly polish cache. The watchOS target remains an execution surface and does not write durable history.

The shared core now includes a local model runtime scaffold, adapter boundary, SDK-independent resource preflight layer, resource-backed provider facade, raw text output parser, prompt formatter, and a Gemma 4 E2B LiteRT-LM resource catalog. It builds bounded context from Today readiness, the current quest, and recent Memory Review entries, checks provider resource requirements from platform observations, lets SDK adapters return raw text or structured drafts, then validates draft coach text before it can be accepted. The iOS target now has a resource-aware `GemmaLocalModelAdapting` bridge that can call LiteRT-LM behind `FITNESSRPG_ENABLE_LITERTLM` when the Swift package is linked; default builds still report unavailable and route through deterministic fallback. The iOS DEBUG diagnostics path uses the Core catalog to scan `Bundle.main/ModelResources/gemma-4-E2B-it.litertlm`; the Runtime panel shows both the provider-level resource summary and each required file row. If local output falls back, diagnostics now distinguish resource, adapter, parsing, and validator reasons before deterministic safety copy is used.

See `native/README.md` for native build commands and target structure.

## Migrated Context

The prior design and migration discussions are preserved under `records/`:

- `records/migration-index.md` lists all migrated sources and files.
- `records/transcripts/` contains readable Markdown transcripts.
- `records/raw/` contains original Codex JSONL sources for full traceability.

These records are context, not runtime app assets.

## Next Major Work

Recommended sequence:

1. Run paired-device WatchConnectivity validation on real hardware: first run `bash native/scripts/watchconnectivity-real-device-preflight.sh`, then follow `docs/validation/watchconnectivity-real-device-runbook.md` to install both targets, launch iOS with `--fitnessrpg-show-diagnostics`, send Today to Watch, complete Watch steps, confirm inbound return, and save baseline/final validation reports.
2. Validate the HealthKit permission and data-coverage action rows on real devices: first run `bash native/scripts/healthkit-real-device-preflight.sh`, then follow `docs/validation/healthkit-real-device-runbook.md`; add deeper onboarding only if those fallback notices are not enough.
3. Prepare LiteRT-LM / Gemma real-device model execution: run `bash native/scripts/model-artifact-git-guard.sh`, `bash native/scripts/litertlm-integration-checklist.sh`, then `bash native/scripts/litertlm-real-device-preflight.sh`, and follow `docs/validation/litertlm-real-device-runbook.md` before adding the Swift package, local ignored licensed `gemma-4-E2B-it.litertlm` resource, and `FITNESSRPG_ENABLE_LITERTLM` flag.
4. Run the end-to-end real-device pass: first run `bash native/scripts/end-to-end-real-device-preflight.sh`, then follow `docs/validation/end-to-end-real-device-runbook.md` across WatchConnectivity, HealthKit fallback/action rows, Runtime diagnostics, History weekly polish cache controls, and validation report archive evidence.
