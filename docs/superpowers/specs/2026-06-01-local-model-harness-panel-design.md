# Local Model Harness Panel Design

## Goal

Add a product-facing local model harness panel to the Chinese Fitness RPG prototype. The panel should explain how the daily quest is produced from HealthKit readiness, recent workout execution, RPG story state, safety rules, and the selected model mode.

This is a deterministic browser prototype. It should not call a real model, persist data, or integrate with HealthKit. The goal is to make the intended Gemma / LiteRT-LM product flow visible and testable.

## Chosen Direction

Use Approach C: local model / skill harness transparency.

The current prototype can already show a daily quest and simulate Apple Watch execution. The next useful increment is to expose the generation pipeline so the product feels explainable:

- what context enters the coach,
- which rules constrain it,
- where a local model would draft,
- where deterministic safety validation happens,
- what happens when local generation fails.

## User Experience

Add a new `本地模型 Harness` panel near `模型模式` and `Memory 草稿`.

The panel should show four compact sections:

- `输入上下文`: readiness score, HealthKit drivers, current story node, active quest, and recorded training log count.
- `Skill 规则`: safety-first, recovery-positive framing, world-state mapping, and Watch payload constraints.
- `生成路径`: selected model mode and a step-by-step path such as `规则过滤 → 本地模型草稿 → 安全校验 → Watch Payload`.
- `Fallback`: deterministic template behavior when local generation is unavailable or remote enhancement is disabled.

The panel should update when:

- readiness scenario changes,
- model mode changes,
- Watch execution logs change,
- workout result is generated.

## Model Mode Behavior

The existing model mode buttons should influence the harness explanation:

- `本地优先`: shows local Gemma / LiteRT-LM draft as the primary path and deterministic fallback as backup.
- `本地 + 远程增强`: shows local generation for daily safety-critical content, with remote enhancement limited to weekly summary or story polish.
- `禁用远程`: shows deterministic templates and local-only rules; no remote enhancement is available.

No actual model call is made in this pass.

## Data Shape

Add a deterministic derived harness object:

- `inputContext`: summary lines for readiness, HealthKit signals, story node, quest, and execution log.
- `skillRules`: short Chinese rule lines based on the current readiness color and quest.
- `generationPath`: ordered Chinese steps based on model mode.
- `fallbackPolicy`: Chinese fallback explanation based on model mode.
- `promptPreview`: a compact prompt-like preview that combines health, story, safety, and output requirements.

This can live in a new `modelHarness.js` module so render code stays small.

## UI Structure

Render a single top-level panel:

- title: `本地模型 Harness`
- model badge: current model mode
- four subsections: `输入上下文`, `Skill 规则`, `生成路径`, `Fallback`
- a compact `Prompt 预览` block using pre-wrapped text

Avoid nested cards. Use rows, chips, and bordered blocks consistent with the current visual system.

## Safety Requirements

The harness must make safety boundaries explicit:

- Yellow and red modes should mention intensity reduction or recovery protection.
- Remote enhancement must not be described as making safety decisions.
- Fallback templates must preserve safety constraints.
- Recovery should remain framed as progress.

## Responsive Requirements

- The harness panel must fit mobile width without horizontal scrolling.
- Prompt preview must wrap.
- Generation path chips must wrap into multiple lines.

## Verification

Before completion:

- Add deterministic contract tests for harness output in local, hybrid, and remote-disabled modes.
- Verify harness output updates when Watch logs record `过重`.
- Run syntax checks for all prototype modules.
- Verify browser rendering and mobile layout via local server and screenshot or DOM inspection.
