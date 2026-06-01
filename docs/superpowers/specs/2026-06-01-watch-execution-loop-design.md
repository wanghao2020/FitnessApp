# Watch Execution Loop Design

## Goal

Extend the Chinese Fitness RPG prototype from a static daily command center into a simulated workout execution loop. The user should be able to step through the Apple Watch workout payload, record quick feedback, and see the iPhone side produce a training log draft, safety-aware result, attribute growth, and memory draft.

This remains a browser prototype. It should demonstrate product behavior and information flow before native iPhone/watchOS implementation.

## Chosen Direction

Use Approach B: training execution loop.

The current prototype already shows readiness, RPG world state, and the first Apple Watch action. The next useful increment is to make that action surface interactive enough to simulate one workout from start to finish.

## User Experience

The page keeps the current command center layout and adds execution state:

- Apple Watch panel shows the active step number, current exercise, target, RPE cap, and rest guidance.
- Watch controls include `上一项`, `下一项`, `完成`, `过重`, `跳过`, and the current `RPE≤目标` action.
- The iPhone side shows a `训练日志草稿` panel with each exercise row and its current status.
- Selecting `完成`, `过重`, or `跳过` updates the active step's status and appends a short note.
- `下一项` advances through the workout without losing previous step feedback.
- `完成模拟训练` generates a result based on the recorded log rather than only the readiness color.

## Safety Behavior

Safety remains product-critical:

- `过重` marks the step as a load issue and should surface a safety note in the result.
- `跳过` is treated as a valid safety-preserving choice, not a failure.
- Yellow and red days should keep conservative language in the summary.
- If any step is marked `过重`, the next-session suggestion should recommend lowering load or reducing volume.
- Red recovery days should never produce language that encourages high-intensity compensation.

## RPG Behavior

The execution loop should keep RPG feedback lightweight:

- Completing safe work grants the existing attribute rewards.
- Skipped or too-heavy steps still produce progress if the choice protected the body.
- Result copy should mention the current story node and whether the chapter advanced, calibrated, or recovered.
- A memory draft should summarize health state, quest, completed steps, flags, and next recommendation.

## Data Model

Add execution state in the client store:

- `activeStepIndex`: current Apple Watch step.
- `stepLogs`: keyed by watch step id, storing:
  - `status`: `pending`, `completed`, `tooHeavy`, or `skipped`.
  - `note`: short Chinese note.
  - `rpe`: numeric cap-derived value for completed steps, or null.
- Derived helpers should compute:
  - active step,
  - completed count,
  - safety flags,
  - result summary,
  - memory draft.

Keep the model small and deterministic. Do not introduce persistence, HealthKit integration, or model calls in this pass.

## UI Structure

Add or update these sections:

- `Apple Watch 执行`: current step, progress count, step navigation, and quick feedback.
- `训练日志草稿`: compact iPhone-side rows showing exercise name, target, status, and note.
- `训练结果`: after completion, show:
  - result status,
  - average/estimated RPE,
  - safety feedback,
  - next recommendation.
- `Memory 草稿`: appears after completion or in a compact always-visible form showing the record that would be saved to local memory.

The new panels should not create nested cards. They should use compact rows, status pills, and the existing palette.

## Interaction Rules

- Scenario switching resets execution state and workout result.
- `上一项` is disabled on the first step.
- `下一项` is disabled on the final step.
- Quick actions update the current step and keep the current step selected.
- `完成模拟训练` is always available but should summarize whatever has been recorded so far.
- Model mode switching does not reset workout logs.

## Responsive Requirements

- Watch controls must wrap cleanly on mobile.
- Log rows collapse to one column on narrow widths.
- The progress indicator must not overflow.
- Chinese status labels must fit without clipping.

## Verification

Before completion:

- Add or update a deterministic Node contract test for:
  - initial active step,
  - recording completed / too-heavy / skipped actions,
  - next / previous step navigation,
  - scenario reset behavior,
  - result and memory draft generation.
- Run syntax checks for all prototype modules.
- Verify the local prototype server returns HTML.
- Use browser or headless screenshot verification for desktop and mobile layout.
