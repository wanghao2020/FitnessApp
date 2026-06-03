# Native Scaffold Review Polish Design

## Goal

Address the two non-blocking final review findings from the native iPhone / watchOS skeleton work so the scaffold better preserves the product language and covers the conservative missing-HealthKit path.

This is a small follow-up to the native skeleton. It should not introduce a new Xcode project, real HealthKit integration, WatchConnectivity, LiteRT-LM / Gemma runtime, persistence, or changes to the browser prototype behavior.

## Chosen Direction

Use Approach A: targeted review polish.

The final review raised two P3 items:

- The iPhone scaffold does not visibly show the `Memory 草稿` product term.
- The conservative yellow result for missing HealthKit data is implemented but not directly tested.

Both are narrow enough to fix without changing the shared core architecture.

## iPhone Scaffold Change

Add a compact `Memory 草稿` section to `native/AppSources/iOS/ModelHarnessPanel.swift`.

The section should:

- appear inside the existing `本地模型 Harness` panel,
- use Chinese UI copy,
- explain that completed Watch execution will become a memory draft,
- stay scaffold-only and not require a new model field,
- avoid changing `ModelHarnessSnapshot` unless implementation discovers the existing type cannot support the display cleanly.

Preferred copy:

- title: `Memory 草稿`
- body: `完成后记录训练反馈、降阶信号和下一次建议。`

This keeps the visible native vocabulary aligned with the browser prototype and previous product language while avoiding fake persistence.

## Missing HealthKit Test

Add one Swift test to `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`.

The test should verify that:

- `ReadinessEngine.evaluate(MockHealthProfiles.missing)` returns `.yellow`,
- title is `共振偏移`,
- explanation mentions `HealthKit 数据缺失`,
- safety guidance remains conservative.

No core logic changes are expected unless the test exposes a mismatch.

## Scope

Allowed changes:

- `native/AppSources/iOS/ModelHarnessPanel.swift`
- `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`

Optional only if needed:

- Small README note in `native/README.md` explaining that `Memory 草稿` is currently a scaffold label, not persistence.

Disallowed changes:

- No Xcode project creation.
- No HealthKit adapter or authorization code.
- No WatchConnectivity code.
- No model runtime setup.
- No persistence layer.
- No changes to browser prototype files.
- No broad refactor of shared core models.

## Verification

Before completion:

- Run `cd native/FitnessRPGCore && swift test`.
- Run existing prototype syntax checks and contract test to ensure browser prototype behavior remains unchanged.
- Confirm only the known migration-context files remain untracked outside the new committed changes.
