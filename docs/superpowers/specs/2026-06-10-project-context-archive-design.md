# Project Context Archive Design

## Goal

Turn the migrated project context into tracked, intentional repository context so future native app, HealthKit, WatchConnectivity, persistence, and local model work starts from a clean baseline.

This pass should preserve the migration records and project brief without changing product behavior or implementing new app features.

## Chosen Direction

Use F0: project archive and context stabilization.

The current repository has working tracked prototype and native scaffold code, while the original migration context is still untracked:

- `README.md`
- `docs/project-brief.md`
- `records/`
- `work/`

These files are valuable project history and should be committed intentionally instead of left as loose local files.

## Repository Context

Track the root `README.md` as the main project entry point.

It should explain:

- the Fitness RPG iPhone + Apple Watch direction,
- the local-first model strategy,
- where the browser prototype lives,
- where the native scaffold lives,
- where migration records live,
- how to run current verification commands.

Track `docs/project-brief.md` as the product brief.

It should remain the higher-level product and architecture summary for:

- iPhone role,
- Apple Watch role,
- HealthKit / readiness,
- local model harness,
- memory strategy,
- safety rules,
- MVP scope.

## Migration Records

Track `records/` as an immutable migration archive.

Allowed changes:

- add or keep an index file,
- keep transcripts and raw JSONL files in place,
- fix broken relative links if discovered.

Disallowed changes:

- rewrite transcript content,
- summarize away raw records,
- delete migration sources,
- move records into implementation folders.

The records are context, not runtime app assets.

## Work Script

Track `work/extract-codex-messages.mjs` for traceability if it is already part of the migration archive workflow.

It should remain clearly separate from production app code. Do not move it into `native/` or `prototype/`.

If future work turns it into a maintained tool, it can be moved to `tools/` in a later pass.

## Non-Goals

This pass does not include:

- creating an Xcode project,
- changing Swift core behavior,
- changing browser prototype behavior,
- adding HealthKit integration,
- adding WatchConnectivity,
- adding persistence,
- adding model runtime code,
- rewriting migration transcripts.

## Verification

Before completion:

- Run `cd native/FitnessRPGCore && swift test`.
- Run the browser prototype syntax checks and contract test.
- Confirm `git status --short` has no untracked project context files left after commit.
- Confirm `README.md` points to the current tracked project areas.
