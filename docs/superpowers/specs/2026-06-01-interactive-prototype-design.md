# Interactive Prototype Design

## Purpose

Build the first development slice as an interactive web prototype named **Today Command Center**. The prototype is a product and harness alignment surface for the Fitness RPG iPhone + Apple Watch app. It should let us quickly inspect the daily user experience before committing to native SwiftUI/watchOS implementation details.

The approved first direction is **Approach A: Interactive Web Prototype**. The screen will start as a dashboard-first command center, with the option to evolve toward a conversation-first or data-dashboard-first layout later.

## Scope

The prototype will simulate one daily loop:

1. The app receives a mock Apple Health / Apple Watch summary.
2. A deterministic readiness result is shown as Green, Yellow, or Red.
3. The app presents a daily quest plan constrained by readiness and safety rules.
4. The RPG coach explains the plan in narrative language.
5. The Watch preview shows the execution surface for the current workout step.
6. User interactions update visible state so we can evaluate the product flow.

This prototype does not connect to real HealthKit, LiteRT-LM, Gemma, OpenAI APIs, SwiftData, or WatchConnectivity. Those integrations come after the interaction model and data contracts stabilize.

## First Screen

The first screen is **Today Command Center**.

Primary areas:

- Readiness panel: Green / Yellow / Red state, sleep, HRV, resting heart rate, recent load, and the rule boundary.
- Daily Quest panel: training day type, intensity cap, and RPG quest framing.
- Workout Plan panel: exercises, sets, reps, RPE cap, rest guidance, and optional cardio or mobility.
- Safety Validator panel: visible explanation of why the generated plan is allowed.
- RPG Coach panel: short coach dialogue and 2-3 action choices.
- Apple Watch Preview panel: compact execution view with current exercise, set progress, and quick feedback controls.

The initial example state should use a Yellow day because it exercises the most important safety behavior: reducing load and rewarding recovery-aware training instead of pushing for PRs.

## Interaction Model

The prototype should support these interactions:

- Switch readiness scenario between Green, Yellow, and Red.
- Regenerate the visible daily quest from the selected readiness scenario.
- Choose coach actions such as Start Quest, Lower Intensity, or Rest Camp.
- Preview how the selected quest appears on Apple Watch.
- Record a mock workout result with completion, RPE, and feedback.
- Show a post-workout recap that updates experience, training notes, and story progress.
- Open a settings panel for model mode: Local Only, Local + Remote Enhancement, and Remote Disabled.

Interactions can be deterministic. The goal is not model intelligence yet; the goal is to align states, copy, layout, and schema boundaries.

## Data Contracts

The prototype should make these future schemas visible through realistic mock data:

- `DailyHealthSummary`: date, sleep, HRV trend, resting heart rate trend, recent training load, soreness, injury flags, and activity context.
- `ReadinessState`: color, score, drivers, restrictions, and recommended training mode.
- `DailyQuestPlan`: quest title, readiness color, workout focus, exercise list, intensity boundaries, story framing, safety notes, and watch payload.
- `WatchWorkoutStep`: exercise name, target sets, target reps or duration, rest seconds, RPE cap, and available quick actions.
- `WorkoutResult`: completed steps, skipped steps, average RPE, duration, heart-rate summary, and user feedback.
- `StoryStateDelta`: experience gained, attribute changes, story node update, and recovery-positive narrative outcome.

These contracts are intentionally lightweight so they can later map to SwiftData models and the local LLM harness.

## Visual Direction

The prototype should feel like a quiet operational tool with RPG personality layered into the content. It should avoid a marketing-page style. The layout should prioritize scanning, repeated daily use, and clear safety boundaries.

Design principles:

- Make readiness and safety legible before narrative flourish.
- Keep RPG copy short and actionable.
- Use restrained color coding for Green / Yellow / Red.
- Keep the Watch preview compact and glanceable.
- Make settings practical, especially model mode and privacy choices.

## Non-Goals

- No real HealthKit permissions.
- No native iOS/watchOS project scaffolding.
- No real local or remote model invocation.
- No persistent user accounts.
- No complex world-authoring UI.
- No full long-term memory implementation.

## Acceptance Criteria

- A local web prototype opens in the browser.
- The Today Command Center screen is usable without reading instructions.
- The user can switch readiness scenarios and see the quest, safety text, coach dialogue, and Watch preview change.
- The user can complete a mock workout and see a concise recap plus story update.
- The prototype includes a model settings panel that communicates local-first behavior and optional remote enhancement.
- The visible mock data corresponds to the future schema names listed in this spec.
- The prototype remains clearly scoped as an alignment tool, not the production iOS implementation.

## Spec Review

This design is intentionally limited to the first interactive prototype slice. It does not contradict the project brief: iPhone remains the planning and model surface, Apple Watch remains the execution surface, safety is deterministic before model text, and local-first remains the default model strategy.
