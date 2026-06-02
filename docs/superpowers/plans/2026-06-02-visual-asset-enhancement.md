# Visual Asset Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a restrained ambient RPG visual asset and readiness-state visual tokens to the Chinese Fitness RPG prototype.

**Architecture:** Create one project-local asset under `prototype/assets/`, reference it from the hero area, and add CSS state tokens that respond to the existing readiness color. Keep the prototype logic unchanged except for a contract assertion that the ambient visual renders.

**Tech Stack:** Vanilla JavaScript ES modules, CSS, project-local raster asset or deterministic SVG/CSS fallback, Node built-in assertions, local static server.

---

## File Structure

- Create: `prototype/assets/resonance-hall.svg` or `prototype/assets/resonance-hall.png`
  - Reusable ambient visual asset for the hero/world-state area.
- Modify: `prototype/src/render.js`
  - Render an `ambient-visual` element in the hero strip.
- Modify: `prototype/styles.css`
  - Add ambient visual layout, image handling, overlay, and readiness state tokens.
- Modify: `prototype/tests/prototypeContract.test.mjs`
  - Assert rendered markup contains the ambient visual element.
- Modify: `prototype/README.md`
  - Document the visual asset and fallback behavior.

## Task 1: Add Failing Ambient Visual Contract

**Files:**
- Modify: `prototype/tests/prototypeContract.test.mjs`

- [ ] **Step 1: Add render contract assertion**

Import `renderApp`, render into a fake DOM root, and assert:

```js
const renderRoot = { innerHTML: "", querySelectorAll: () => [], querySelector: () => null };
renderApp(renderRoot, createStore());
assert.match(renderRoot.innerHTML, /ambient-visual/);
assert.match(renderRoot.innerHTML, /prototype\/assets\/resonance-hall/);
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node prototype/tests/prototypeContract.test.mjs`

Expected: FAIL because `ambient-visual` is not rendered yet.

- [ ] **Step 3: Commit red test**

Commit message: `test: add ambient visual contract`

## Task 2: Create Project Asset

**Files:**
- Create: `prototype/assets/resonance-hall.svg`

- [ ] **Step 1: Create deterministic SVG fallback asset**

Create a horizontal ambient SVG with:

- no text,
- no logos,
- light background,
- restrained resonance hall lines,
- small campfire/restoration accent,
- Apple Watch-like execution glow.

- [ ] **Step 2: Verify asset exists**

Run: `test -f prototype/assets/resonance-hall.svg`

Expected: exit 0.

- [ ] **Step 3: Commit asset**

Commit message: `feat: add resonance hall visual asset`

## Task 3: Render and Style Ambient Visual

**Files:**
- Modify: `prototype/src/render.js`
- Modify: `prototype/styles.css`

- [ ] **Step 1: Render ambient visual**

Add an `ambient-visual` block inside the hero strip with:

- image reference,
- readiness state class,
- accessible decorative `alt=""`.

- [ ] **Step 2: Add CSS**

Style the visual so:

- desktop keeps it compact and adjacent to the scenario switcher,
- mobile collapses to a short band,
- text never overlays the image,
- readiness state accents change through existing color classes.

- [ ] **Step 3: Run checks**

Run:

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

Expected: all checks exit 0 and test prints `prototype contract ok`.

- [ ] **Step 4: Commit**

Commit message: `feat: render ambient visual state tokens`

## Task 4: Docs and Visual Verification

**Files:**
- Modify: `prototype/README.md`

- [ ] **Step 1: Update README**

Mention the visual asset and readiness token check.

- [ ] **Step 2: Final verification**

Run:

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
curl -s http://localhost:5174
test -f prototype/assets/resonance-hall.svg
```

Then run desktop and mobile headless screenshots and inspect that the asset appears without text overlap or horizontal overflow.

- [ ] **Step 3: Commit**

Commit message: `docs: update visual asset verification`
