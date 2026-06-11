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

The iOS target includes a read-only HealthKit MVP that maps available Apple Health sleep, heart-rate, activity, and workout data into `HealthSummary`. Missing, denied, unavailable, or incomplete HealthKit data falls back to the conservative yellow readiness path, with a structured source-status notice explaining the reason.

The native app now includes a first-pass WatchConnectivity sync layer. The iOS app can package the current `DailyQuest` into a versioned Core payload and send it to the watchOS app; the watchOS app records `ExecutionLog` feedback and returns it to iPhone for deterministic `ExecutionEngine` resolution. When WatchConnectivity is unavailable, both app surfaces keep safe fallback behavior.

DEBUG builds can show WatchConnectivity and local model Runtime diagnostics from `--fitnessrpg-show-diagnostics`. These panels separate Watch session support, activation, pairing, reachability, model provider status, Bundle model resource preflight, per-file model/tokenizer resource rows, validator state, and fallback paths so device testing has a clear checklist.
After a Runtime response executes, the panel also shows the generated draft title and next action for quick output inspection.

DEBUG model Runtime fixture launch arguments can also simulate ready output, parsing failure, adapter failure, and validator fallback without real model files. Use them together with `--fitnessrpg-show-diagnostics` when validating the Runtime panel.

The native iOS app now has a JSON-backed persistence MVP. iPhone restores the same local-day quest after relaunch, saves Watch-returned execution logs and deterministic workout results, stores memory drafts, and advances lightweight RPG chapter/node progression locally. History and Memory Review surfaces expose persisted training days and memory drafts for review. History also shows a deterministic weekly summary and next-week plan built from persisted training records, ready for later model-polished weekly copy. The watchOS target remains an execution surface and does not write durable history.

The shared core now includes a local model runtime scaffold, adapter boundary, SDK-independent resource preflight layer, resource-backed provider facade, raw text output parser, and a Gemma E2B resource catalog. It builds bounded context from Today readiness, the current quest, and recent Memory Review entries, checks provider resource requirements from platform observations, lets SDK adapters return raw text or structured drafts, then validates draft coach text before it can be accepted. The iOS target now has a `GemmaLocalModelAdapting` placeholder that combines Bundle resource status with future SDK availability before routing through the Core provider facade. The iOS DEBUG diagnostics path uses the Core catalog to scan `Bundle.main/ModelResources` for `gemma-e2b.task` and `tokenizer.model`; the Runtime panel shows both the provider-level resource summary and each required file row. If local output falls back, diagnostics now distinguish resource, adapter, parsing, and validator reasons before deterministic safety copy is used.

See `native/README.md` for native build commands and target structure.

## Migrated Context

The prior design and migration discussions are preserved under `records/`:

- `records/migration-index.md` lists all migrated sources and files.
- `records/transcripts/` contains readable Markdown transcripts.
- `records/raw/` contains original Codex JSONL sources for full traceability.

These records are context, not runtime app assets.

## Next Major Work

Recommended sequence:

1. Run paired-device WatchConnectivity validation and tune diagnostics copy from real activation/reachability states.
2. Validate HealthKit permission and data-coverage copy on real devices, then add onboarding if the fallback notice is not enough.
3. Replace the iOS `GemmaLocalModelAdapting` placeholder with concrete LiteRT-LM / Gemma SDK execution and packaged model resources.
4. Let the local model polish weekly History copy behind the deterministic summary and safety rules.
