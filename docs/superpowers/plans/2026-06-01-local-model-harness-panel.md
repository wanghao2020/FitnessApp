# Local Model Harness Panel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a deterministic local model / skill harness transparency panel to the Chinese Fitness RPG prototype.

**Architecture:** Create a pure `modelHarness.js` module that derives harness copy from current app state and model mode. Attach the derived harness to store state, then render it as a top-level panel with compact rows, chips, fallback text, and a wrapped prompt preview.

**Tech Stack:** Vanilla JavaScript ES modules, Node built-in `assert`, CSS, static browser prototype.

---

## File Structure

- Create: `prototype/src/modelHarness.js`
  - Derives input context, skill rules, generation path, fallback policy, and prompt preview.
- Modify: `prototype/src/state.js`
  - Adds `modelHarness` to derived state and updates it when scenario, model mode, or execution logs change.
- Modify: `prototype/src/render.js`
  - Renders the `本地模型 Harness` panel near model mode / memory draft.
- Modify: `prototype/styles.css`
  - Adds harness rows, path chips, model badge, and prompt preview styling.
- Modify: `prototype/tests/prototypeContract.test.mjs`
  - Adds deterministic tests for local, hybrid, disabled, and load-issue harness output.
- Modify: `prototype/README.md`
  - Documents the harness panel and verification flow.

## Task 1: Add Failing Harness Contract

**Files:**
- Modify: `prototype/tests/prototypeContract.test.mjs`

- [ ] **Step 1: Add harness assertions**

Append assertions that verify:

```js
const harnessStore = createStore();
assert.equal(harnessStore.getState().modelHarness.modeLabel, "本地优先");
assert.match(harnessStore.getState().modelHarness.inputContext.join("\n"), /深厅校准/);
assert.match(harnessStore.getState().modelHarness.skillRules.join("\n"), /安全优先/);
assert.match(harnessStore.getState().modelHarness.generationPath.join(" → "), /本地模型草稿/);
assert.match(harnessStore.getState().modelHarness.fallbackPolicy, /确定性模板/);
assert.match(harnessStore.getState().modelHarness.promptPreview, /HealthKit/);

harnessStore.setModelMode("hybrid");
assert.equal(harnessStore.getState().modelHarness.modeLabel, "本地 + 远程增强");
assert.match(harnessStore.getState().modelHarness.fallbackPolicy, /远程只用于周报或剧情润色/);

harnessStore.setModelMode("disabled");
assert.equal(harnessStore.getState().modelHarness.modeLabel, "禁用远程");
assert.doesNotMatch(harnessStore.getState().modelHarness.generationPath.join(" "), /远程增强/);
assert.match(harnessStore.getState().modelHarness.fallbackPolicy, /不请求远程/);

harnessStore.recordWatchAction("过重");
assert.match(harnessStore.getState().modelHarness.inputContext.join("\n"), /过重/);
assert.match(harnessStore.getState().modelHarness.skillRules.join("\n"), /降负/);
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node prototype/tests/prototypeContract.test.mjs`

Expected: FAIL because `modelHarness` does not exist.

- [ ] **Step 3: Commit red test**

Commit message: `test: add local model harness contract`

## Task 2: Implement Harness Derivation

**Files:**
- Create: `prototype/src/modelHarness.js`
- Modify: `prototype/src/state.js`

- [ ] **Step 1: Create `modelHarness.js`**

Implement:

- `buildModelHarness(state, modelMode)`
- internal helpers for mode-specific generation path and fallback policy

Harness output must include:

- `modeLabel`
- `inputContext`
- `skillRules`
- `generationPath`
- `fallbackPolicy`
- `promptPreview`

- [ ] **Step 2: Attach harness to state**

Import `buildModelHarness` in `state.js` and include `modelHarness` in every derived state.

- [ ] **Step 3: Run contract test**

Run: `node prototype/tests/prototypeContract.test.mjs`

Expected: PASS and print `prototype contract ok`.

- [ ] **Step 4: Commit**

Commit message: `feat: derive local model harness`

## Task 3: Render Harness Panel

**Files:**
- Modify: `prototype/src/render.js`

- [ ] **Step 1: Add panel markup**

Render a top-level `本地模型 Harness` panel with:

- current model badge,
- `输入上下文`,
- `Skill 规则`,
- `生成路径`,
- `Fallback`,
- `Prompt 预览`.

- [ ] **Step 2: Wire to derived state**

Read from `state.modelHarness`; do not duplicate derivation in render code.

- [ ] **Step 3: Run syntax and contract checks**

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

Commit message: `feat: render local model harness panel`

## Task 4: Polish Styles, Docs, and Verify

**Files:**
- Modify: `prototype/styles.css`
- Modify: `prototype/README.md`

- [ ] **Step 1: Add CSS**

Add styles for:

- `.harness-panel`
- `.model-badge`
- `.harness-grid`
- `.harness-list`
- `.path-chips`
- `.prompt-preview`

- [ ] **Step 2: Update README**

Document how to inspect the harness:

- switch model modes,
- switch readiness scenario,
- record `过重`,
- inspect prompt preview and fallback policy.

- [ ] **Step 3: Final verification**

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
```

Then run desktop and mobile headless screenshots for visual verification.

- [ ] **Step 4: Commit**

Commit message: `style: polish local model harness panel`
