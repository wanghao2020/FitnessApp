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

See `native/README.md` for native build commands and target structure.

## Migrated Context

The prior design and migration discussions are preserved under `records/`:

- `records/migration-index.md` lists all migrated sources and files.
- `records/transcripts/` contains readable Markdown transcripts.
- `records/raw/` contains original Codex JSONL sources for full traceability.

These records are context, not runtime app assets.

## Next Major Work

Recommended sequence:

1. Add a HealthKit adapter that maps real data into `HealthSummary`.
2. Add WatchConnectivity for quest payload and execution log sync.
3. Add persistence for workout results, memory drafts, and story progression.
4. Integrate local model runtime behind the deterministic harness and validator.
