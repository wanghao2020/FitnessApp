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
- `native/FitnessRPGCore/`: Swift Package containing shared deterministic domain models and engines.
- `native/AppSources/`: SwiftUI iPhone and watchOS source scaffolds for future Xcode targets.
- `docs/project-brief.md`: product and architecture brief.
- `docs/superpowers/`: design specs and implementation plans used during development.
- `records/`: migrated conversation archive and raw Codex thread sources.
- `work/`: migration helper scripts kept for traceability.

## Current Verification

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

The native code is currently a Swift Package plus SwiftUI source scaffold. There is no committed `.xcodeproj` or `.xcworkspace` yet.

See `native/README.md` for how the scaffold should connect to future iPhone and watchOS targets.

## Migrated Context

The prior design and migration discussions are preserved under `records/`:

- `records/migration-index.md` lists all migrated sources and files.
- `records/transcripts/` contains readable Markdown transcripts.
- `records/raw/` contains original Codex JSONL sources for full traceability.

These records are context, not runtime app assets.

## Next Major Work

Recommended sequence:

1. Create a real iOS / watchOS Xcode project or equivalent app target structure.
2. Attach `FitnessRPGCore` and `native/AppSources` to the app targets.
3. Add a HealthKit adapter that maps real data into `HealthSummary`.
4. Add WatchConnectivity for quest payload and execution log sync.
5. Add persistence for workout results, memory drafts, and story progression.
6. Integrate local model runtime behind the deterministic harness and validator.
