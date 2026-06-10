# Project Brief

## Goal

Build an iPhone + Apple Watch app that combines Apple Health / Apple Watch data, a local-first LLM runtime, and Fitness Coach RPG-style training plus narrative progression.

The app should generate daily and weekly training quests, adapt intensity from recovery data, and keep the user engaged through RPG progression and story interactions without encouraging unsafe overtraining.

## Core Product Shape

### iPhone App

- Main planning and analysis surface.
- Reads HealthKit data: workouts, sleep, HRV, resting heart rate, heart rate, steps, active energy, exercise time, and related recovery metrics.
- Stores user settings: goals, equipment, injury constraints, preferred coaching style, model settings, privacy settings, and story mode.
- Runs the local LLM harness and optional remote API model router.
- Maintains structured memory, training state, weekly plans, daily quests, and story state.

### Apple Watch App

- Lightweight execution surface.
- Shows today's quest and workout.
- Records sets, reps, RPE, completion, quick feedback, and heart-rate context.
- Offers short story interaction choices, such as continue, rest, lower intensity, or push within allowed limits.
- Syncs results back to iPhone.

## Model Strategy

Default runtime should be local-first.

- Local model: Gemma 4 E2B / LiteRT-LM class model for daily tasks, short recaps, JSON generation, and light narrative.
- Optional local larger model: Gemma 4 E4B or equivalent for supported high-end devices.
- Optional remote API: OpenAI, Gemini, or OpenAI-compatible endpoint for deep weekly/monthly analysis, worldbuilding, long story compaction, or fallback.

The model must not be the safety authority. Health and training safety decisions should be handled by deterministic rules first, then the model writes within those boundaries.

## Harness Principles

The project needs a local model harness, not a long-prompt chat app.

Core modules:

1. Intent Router
   - Classifies events: morning sync, pre-workout adjustment, workout execution, post-workout recap, story interaction, weekly planning.

2. Health Data Adapter
   - Reads HealthKit and converts raw data into app-level summaries.

3. Readiness Engine
   - Computes Green / Yellow / Red training readiness from sleep, HRV, resting heart rate, recent load, RPE, soreness, and injury flags.

4. Memory Store
   - Stores structured facts, not unlimited chat transcripts.
   - Suggested layers: hot memory, warm memory, cold summaries, and narrative state.

5. Retrieval Engine
   - Selects only task-relevant context for each model call.

6. Prompt Builder
   - Builds short prompts from rules, selected memory, health summary, current plan, and required output schema.

7. Model Runtime
   - Wraps local Gemma / LiteRT-LM and optional remote APIs.
   - Manages timeouts, token limits, JSON generation, retries, and fallback.

8. Validator + Committer
   - Validates output schema, safety constraints, recovery boundaries, story consistency, and training progression before saving state.

## Memory Strategy

Avoid prompt growth over time.

- Raw data: HealthKit remains source of truth; raw data does not go directly into prompts.
- Fact memory: structured training and health facts.
- Summary memory: daily, weekly, monthly summaries.
- Narrative state: current chapter, quest, NPC relations, active hooks, unlocked story facts.

Daily prompts should usually contain only:

- Today's health summary.
- Last 3-5 relevant workouts.
- Current weekly plan.
- Injury or safety constraints.
- Current story node.
- A few relevant world rules or narrative templates.

## Safety Rules

Training decisions should be constrained before any model generation.

- Green: normal training or modest progression.
- Yellow: reduce load, focus on technique, lower volume, or choose lower-intensity cardio.
- Red: recovery, mobility, rest, or narrative-only camp/rest quest.

The story system must reward rest and recovery when recovery data is poor. It must not frame unsafe overreaching as heroic.

## Candidate External Skills

Useful external Swift/iOS Skills from `dpearson2699/swift-ios-skills`:

- `healthkit`
- `core-motion`
- `activitykit`
- `widgetkit`
- `app-intents`
- `background-processing`
- `push-notifications`
- `permissionkit`
- `swiftdata`
- `cloudkit`
- `swift-security`
- `swift-concurrency`
- `swift-testing`
- `metrickit`
- `coreml`
- `apple-on-device-ai`
- `swiftui-patterns`
- `swiftui-performance`
- `swiftui-navigation`

Likely project-specific skills to create later:

- `apple-health-rpg-coach`
- `local-llm-harness-ios`
- `fitness-rpg-product-spec`

## MVP Scope

First usable version:

- iPhone reads HealthKit summaries.
- Local storage uses structured models for health summaries, workouts, readiness, daily quests, weekly plans, and story state.
- Local LLM generates a daily quest plan and post-workout recap from bounded context.
- Watch app displays today's quest and records completion plus RPE.
- Validator blocks unsafe plans and invalid JSON.
- Weekly summary and next-week plan can be generated locally, with optional remote enhancement.

Out of MVP:

- Fully autonomous open-ended agent behavior.
- Running the LLM on Apple Watch.
- Complex social systems.
- Full custom world authoring UI.
- Advanced app-store monetization.

## Next Step

Create a design spec for the MVP harness and app architecture before implementation.
