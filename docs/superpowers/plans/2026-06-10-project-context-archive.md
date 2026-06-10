# Project Context Archive Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Commit the migrated project context as intentional repository context and leave the project in a clean, verifiable baseline state.

**Architecture:** Treat `README.md` and `docs/project-brief.md` as maintained project context, while preserving `records/` as immutable migration evidence and `work/` as migration tooling. Do not change app behavior, native core behavior, prototype behavior, or integration boundaries.

**Tech Stack:** Markdown documentation, Node migration helper script, Git, Swift Package Manager, existing JavaScript prototype contract tests.

---

## File Structure

- Modify `README.md`: make it the repository entry point and link current tracked areas.
- Track `docs/project-brief.md`: keep the current product brief as-is unless a link correction is needed.
- Track `records/migration-index.md`: migration source index.
- Track `records/transcripts/*.md`: readable migrated transcripts.
- Track `records/raw/*.jsonl`: raw migrated Codex thread sources.
- Track `work/extract-codex-messages.mjs`: migration extraction script for traceability.

---

### Task 1: Update Repository Entry Point

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Replace the root README with the project entry point**

Use this content:

```markdown
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
```

- [ ] **Step 2: Check README links and wording**

Run:

```bash
rg -n "prototype/|native/README.md|records/migration-index.md|docs/project-brief.md|swift test|prototypeContract" README.md
```

Expected: output includes all referenced project areas and verification commands.

- [ ] **Step 3: Commit README update**

```bash
git add README.md
git commit -m "docs: update project entry point"
```

---

### Task 2: Track Migration Context Archive

**Files:**
- Track: `docs/project-brief.md`
- Track: `records/migration-index.md`
- Track: `records/transcripts/fitness-rpg-watchos-local-llm-thread.md`
- Track: `records/transcripts/migration-conversation-thread.md`
- Track: `records/transcripts/student-reply-watchos-development-extract.md`
- Track: `records/raw/codex-thread-fitness-rpg-watchos-local-llm-019e829b.jsonl`
- Track: `records/raw/codex-thread-migration-conversation-019e82a1.jsonl`
- Track: `records/raw/codex-thread-student-reply-source-019e7bcd.jsonl`
- Track: `work/extract-codex-messages.mjs`

- [ ] **Step 1: Inspect archive file list**

Run:

```bash
find docs/project-brief.md records work -maxdepth 3 -type f -print | sort
```

Expected output:

```text
docs/project-brief.md
records/migration-index.md
records/raw/codex-thread-fitness-rpg-watchos-local-llm-019e829b.jsonl
records/raw/codex-thread-migration-conversation-019e82a1.jsonl
records/raw/codex-thread-student-reply-source-019e7bcd.jsonl
records/transcripts/fitness-rpg-watchos-local-llm-thread.md
records/transcripts/migration-conversation-thread.md
records/transcripts/student-reply-watchos-development-extract.md
work/extract-codex-messages.mjs
```

- [ ] **Step 2: Verify archive index references migrated files**

Run:

```bash
rg -n "records/transcripts|records/raw|student-reply|fitness-rpg-watchos|migration-conversation" records/migration-index.md
```

Expected: output references the transcript and raw archive paths.

- [ ] **Step 3: Commit archive context**

```bash
git add docs/project-brief.md records work/extract-codex-messages.mjs
git commit -m "docs: track migrated project context"
```

---

### Task 3: Final Verification

**Files:**
- No file edits.

- [ ] **Step 1: Run Swift core tests**

Run:

```bash
cd native/FitnessRPGCore
swift test
```

Expected: PASS with 6 tests and 0 failures.

- [ ] **Step 2: Run browser prototype checks**

Run from the repository root:

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

Expected: PASS with `prototype contract ok`.

- [ ] **Step 3: Confirm clean tracked context**

Run:

```bash
git status --short
```

Expected: no output. If ignored build artifacts exist under `native/FitnessRPGCore/.build/`, they should not appear in status.

- [ ] **Step 4: Confirm current repository entry points**

Run:

```bash
rg -n "Current Repository Areas|Native Status|Migrated Context|Next Major Work" README.md
```

Expected: output contains all four section headings.

---

## Final Verification Checklist

- `README.md` is tracked and points to prototype, native, docs, records, and verification commands.
- `docs/project-brief.md` is tracked.
- `records/` raw and transcript files are tracked without rewriting transcript content.
- `work/extract-codex-messages.mjs` is tracked as migration tooling.
- `cd native/FitnessRPGCore && swift test` passes with 6 tests.
- Browser prototype syntax checks and contract test pass.
- `git status --short` is clean.
- No Xcode project, HealthKit adapter, WatchConnectivity, persistence, model runtime, or app behavior changes were introduced.
