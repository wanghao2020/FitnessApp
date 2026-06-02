# Native App Skeleton Design

## Goal

Create the first native iPhone / watchOS skeleton for Fitness RPG so the current browser prototype can start moving toward real Apple platforms without losing the product logic that has already been shaped.

This pass should establish native project structure, shared domain models, deterministic mock engines, and SwiftUI source scaffolds. It should not integrate real HealthKit, WatchConnectivity, LiteRT-LM, Gemma, persistence, or background execution yet.

## Chosen Direction

Use Approach E: native app skeleton with a testable shared Swift core.

Because the repository does not currently contain an Xcode project, Swift package, or Swift source files, the safest first native step is:

- Create a Swift Package for shared product logic.
- Add iPhone and watchOS SwiftUI source scaffolds that consume that shared logic.
- Document how these sources will be attached to future Xcode app targets.

This avoids hand-building a fragile `.xcodeproj` while still giving the project real native code, tests, and a stable architecture for the next implementation passes.

## Native Structure

Add a new `native/` area:

- `native/FitnessRPGCore/`: Swift Package containing shared domain models, mock data, and deterministic engines.
- `native/AppSources/iOS/`: SwiftUI source scaffold for the iPhone command center.
- `native/AppSources/watchOS/`: SwiftUI source scaffold for the Apple Watch execution loop.
- `native/README.md`: native architecture notes and setup instructions.

The shared package should be the only compiled target in this pass. The app source folders are intentional scaffolds for future Xcode app targets.

## Shared Core

The Swift Package should include domain concepts that mirror the prototype:

- `ReadinessColor`: green, yellow, red.
- `HealthSummary`: energy, recovery, strain, sleep, heart-rate trend, and driver labels.
- `ReadinessResult`: score, color, title, user-facing explanation, and safety guidance.
- `DailyQuest`: title, objective, difficulty, RPG attribute rewards, story node, and watch steps.
- `WatchStep`: instruction, target, duration, and safety note.
- `ExecutionLog`: watch action, timestamp-like ordering, perceived exertion, and note.
- `WorkoutResult`: completion state, safety feedback, next recommendation, and memory draft.
- `ModelHarnessSnapshot`: input context, skill rules, generation path, fallback policy, and prompt preview.

Engines should stay deterministic:

- `ReadinessEngine`: turns a mock health summary into a readiness result.
- `QuestEngine`: chooses a daily quest from readiness and story context.
- `ExecutionEngine`: turns Watch logs into a result.
- `ModelHarnessBuilder`: explains the local model / skill harness path.

No real model call is made. No Apple framework integration is required inside the package.

## iPhone Scaffold

Add SwiftUI source files that show the intended iPhone surface:

- `FitnessRPGApp.swift`: app entry placeholder for future Xcode target.
- `TodayCommandCenterView.swift`: native command center layout.
- `ReadinessPanel.swift`: readiness and safety summary.
- `QuestPanel.swift`: daily RPG quest and rewards.
- `ModelHarnessPanel.swift`: local model harness transparency.

The iPhone scaffold should use Chinese UI copy and existing Fitness RPG terminology:

- `今日任务中枢`
- `共振稳定`
- `共振偏移`
- `营火修复`
- `本地模型 Harness`
- `Memory 草稿`

These files do not need to compile as an app target during this pass, but they should be syntactically plausible SwiftUI and structured to import `FitnessRPGCore` once attached to Xcode.

## watchOS Scaffold

Add SwiftUI source files that show the intended Watch surface:

- `FitnessRPGWatchApp.swift`: app entry placeholder for future watchOS target.
- `WatchExecutionView.swift`: current step, target, safety note, and quick actions.

The Watch scaffold should prioritize execution clarity:

- current step name,
- compact target and duration,
- safety note,
- quick actions for complete, too heavy, skip, and RPE within target.

It should avoid dense narrative text on the Watch. The iPhone remains the brain; the Watch remains the execution surface.

## Data Flow

For this pass, the native flow is mock-only:

1. Mock health summary enters `ReadinessEngine`.
2. Readiness and story context enter `QuestEngine`.
3. Daily quest and selected model mode enter `ModelHarnessBuilder`.
4. Watch-style logs enter `ExecutionEngine`.
5. Result contains safety feedback, next recommendation, and memory draft.

Future integration points should be named but not implemented:

- HealthKit adapter feeds `HealthSummary`.
- WatchConnectivity adapter syncs quest payloads and execution logs.
- LiteRT-LM / Gemma adapter drafts coach text before deterministic validation.
- Persistence adapter stores memory and completed workouts.

## Error Handling

Because this is a skeleton, errors should be modeled as deterministic guardrails:

- Missing health data uses a conservative yellow readiness result.
- Heavy exertion logs lower the next recommendation.
- Red readiness cannot produce a high-intensity quest.
- Model harness fallback always keeps safety rules active.

These rules should be visible in tests and comments only where helpful.

## Testing

Add Swift package tests for the compiled shared core:

- Green readiness produces an active training quest.
- Yellow readiness produces a reduced-intensity quest.
- Red readiness produces recovery-focused guidance.
- A `tooHeavy` execution log changes the workout result and harness explanation.
- Remote-disabled model mode uses deterministic fallback language.

If the local machine has a Swift toolchain, verification should run `swift test` inside `native/FitnessRPGCore`.

## Non-Goals

This pass does not include:

- creating or editing a full Xcode project,
- real HealthKit authorization or queries,
- WatchConnectivity message transport,
- LiteRT-LM or Gemma runtime setup,
- on-device persistence,
- production visual polish for native screens,
- replacing the browser prototype.

## Verification

Before completion:

- Run Swift package tests if Swift is available.
- Verify the native README explains how the scaffold connects to future Xcode targets.
- Verify no migration transcript files are modified.
- Verify the existing browser prototype tests still pass if prototype files remain untouched.
