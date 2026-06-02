# Visual Asset Enhancement Design

## Goal

Add a low-distraction visual asset layer to the Chinese Fitness RPG prototype so the app feels more distinct and emotionally RPG-like while preserving the current command-center readability.

This pass should enhance first-glance recognition of readiness state and story atmosphere. It should not turn the prototype into a landing page or obscure the health, safety, Watch execution, memory, or model harness panels.

## Chosen Direction

Use Approach D: lightweight visual asset enhancement.

The prototype already has the product logic needed for the current phase:

- Chinese daily command center.
- Apple Watch execution loop.
- Training log and memory draft.
- Local model harness transparency.

The next useful visual step is to add an ambient fantasy-fitness image or image-like asset that supports the RPG world state without competing with the data-heavy interface.

## Asset Strategy

Create one reusable project asset under `prototype/assets/`.

Preferred asset:

- A subtle fantasy-fitness environment image.
- Theme: resonance training hall with a small campfire/restoration motif and Apple Watch-like execution glow.
- No text in the image.
- No visible brand logos.
- No human face close-up.
- Avoid dark, heavy, high-contrast fantasy art.
- Composition should leave room for overlay text and work well as a cropped horizontal banner.

If generated image quality is poor, use a deterministic CSS fallback instead:

- soft line patterns,
- restrained state-color accents,
- no decorative orbs,
- no one-note purple/dark fantasy palette.

## UI Placement

Use the visual asset as a restrained hero/world-state accent:

- Add an `ambient-visual` area inside or adjacent to the hero strip.
- Keep the current `今日任务中枢` heading and summary readable.
- Do not move the scenario switcher far from the top.
- Keep the world-state strip directly below the hero.

The asset should be decorative and contextual. The interface must still work if the asset fails to load.

## State Tokens

Add small state-aware visual tokens:

- Green / `共振稳定`: green or teal accent.
- Yellow / `共振偏移`: amber accent.
- Red / `营火修复`: red / warm recovery accent.

These tokens may affect:

- hero accent border,
- ambient image overlay,
- world strip accent,
- status label styling.

Do not change the underlying readiness logic.

## Responsive Requirements

- Desktop: asset should support the hero without making the page feel like a marketing site.
- Mobile: asset should collapse to a compact band or thumbnail and must not push key controls too far down.
- No horizontal overflow.
- Text must remain readable over or near the image.

## Data / Code Scope

Allowed changes:

- Add `prototype/assets/` image file.
- Add asset references in `render.js`.
- Add visual classes in `styles.css`.
- Add README notes for the visual asset.
- Add a lightweight contract assertion that the hero renders an ambient visual element.

Disallowed changes:

- No new app state machine.
- No real image API integration in app code.
- No model calls.
- No HealthKit integration.
- No unrelated refactors.

## Verification

Before completion:

- Run JavaScript syntax checks and the prototype contract test.
- Verify local server returns HTML.
- Verify the asset file exists under `prototype/assets/`.
- Verify desktop and mobile screenshots show the asset without text overlap or horizontal overflow.
