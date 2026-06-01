# Watch Execution Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a deterministic Apple Watch workout execution loop to the Chinese Fitness RPG prototype.

**Architecture:** Add a small `execution.js` module for execution state, step logging, result summaries, and memory draft generation. Keep `state.js` as the store coordinator and `render.js` as the UI layer.

**Tech Stack:** Vanilla JavaScript ES modules, Node built-in `assert`, CSS, local static HTTP server.

---

## File Structure

- Create: `prototype/src/execution.js`
  - Builds initial step logs and derives execution progress, result summaries, and memory drafts.
- Modify: `prototype/src/state.js`
  - Adds active step navigation, watch action recording, reset-on-scenario-change behavior, and completion generation.
- Modify: `prototype/src/render.js`
  - Renders Apple Watch progress/navigation, training log draft, richer result summary, and memory draft.
- Modify: `prototype/styles.css`
  - Adds compact execution, status, result, and memory draft styles with mobile wrapping.
- Modify: `prototype/tests/prototypeContract.test.mjs`
  - Extends contract coverage for execution loop behaviors.
- Modify: `prototype/README.md`
  - Documents the execution-loop test flow.

## Task 1: Add Failing Execution Contract

**Files:**
- Modify: `prototype/tests/prototypeContract.test.mjs`

- [ ] **Step 1: Add execution assertions**

Append assertions that verify:

```js
const executionStore = createStore();
assert.equal(executionStore.getState().activeStepIndex, 0);
assert.equal(executionStore.getState().activeStep.id, "step-1");
assert.equal(executionStore.getState().executionSummary.completedCount, 0);

executionStore.recordWatchAction("完成");
assert.equal(executionStore.getState().stepLogs["step-1"].status, "completed");
assert.match(executionStore.getState().stepLogs["step-1"].note, /完成/);

executionStore.nextStep();
assert.equal(executionStore.getState().activeStep.id, "step-2");

executionStore.recordWatchAction("过重");
assert.equal(executionStore.getState().stepLogs["step-2"].status, "tooHeavy");
assert.equal(executionStore.getState().executionSummary.hasLoadIssue, true);

executionStore.nextStep();
executionStore.recordWatchAction("跳过");
assert.equal(executionStore.getState().stepLogs["step-3"].status, "skipped");

executionStore.previousStep();
assert.equal(executionStore.getState().activeStep.id, "step-2");

executionStore.completeWorkout();
assert.equal(executionStore.getState().workoutResult.status, "任务完成");
assert.match(executionStore.getState().workoutResult.safetyFeedback, /降低|保守|安全/);
assert.match(executionStore.getState().memoryDraft, /深厅校准/);

executionStore.setScenario("green");
assert.equal(executionStore.getState().activeStepIndex, 0);
assert.equal(executionStore.getState().workoutResult, null);
assert.equal(executionStore.getState().executionSummary.completedCount, 0);
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node prototype/tests/prototypeContract.test.mjs`

Expected: FAIL because `activeStep`, `executionSummary`, `recordWatchAction`, `nextStep`, `previousStep`, generated completion, and `memoryDraft` are not implemented.

- [ ] **Step 3: Commit red test**

Commit message: `test: add watch execution contract`

## Task 2: Implement Execution State

**Files:**
- Create: `prototype/src/execution.js`
- Modify: `prototype/src/state.js`

- [ ] **Step 1: Create `execution.js`**

Implement pure helpers:

- `createInitialStepLogs(steps)`
- `deriveExecutionState(baseState)`
- `recordStepAction(stepLogs, step, action)`
- `buildWorkoutResult(state)`
- `buildMemoryDraft(state)`

- [ ] **Step 2: Update store**

Add store methods:

- `nextStep()`
- `previousStep()`
- `recordWatchAction(action)`
- `completeWorkout(result)`

When `completeWorkout()` is called without an explicit result, generate one from `buildWorkoutResult`.

- [ ] **Step 3: Run contract test**

Run: `node prototype/tests/prototypeContract.test.mjs`

Expected: PASS and print `prototype contract ok`.

- [ ] **Step 4: Commit**

Commit message: `feat: add watch execution state`

## Task 3: Render Execution Loop

**Files:**
- Modify: `prototype/src/render.js`

- [ ] **Step 1: Update Apple Watch panel**

Show:

- step progress such as `2 / 4`,
- active exercise,
- target,
- RPE cap,
- rest guidance,
- `上一项` and `下一项` buttons,
- quick action buttons connected to `recordWatchAction`.

- [ ] **Step 2: Add training log draft panel**

Render every step from `quest.watchPayload.steps`, with status and note from `state.stepLogs`.

- [ ] **Step 3: Add richer result and memory UI**

Render:

- `workoutResult.summary`,
- `workoutResult.safetyFeedback`,
- `workoutResult.nextRecommendation`,
- `memoryDraft`.

- [ ] **Step 4: Run syntax and contract checks**

Run:

```bash
node --check prototype/src/main.js
node --check prototype/src/mockData.js
node --check prototype/src/questEngine.js
node --check prototype/src/readiness.js
node --check prototype/src/render.js
node --check prototype/src/state.js
node --check prototype/src/execution.js
node prototype/tests/prototypeContract.test.mjs
```

Expected: all checks exit 0 and test prints `prototype contract ok`.

- [ ] **Step 5: Commit**

Commit message: `feat: render watch execution loop`

## Task 4: Polish Layout and Docs

**Files:**
- Modify: `prototype/styles.css`
- Modify: `prototype/README.md`

- [ ] **Step 1: Add CSS**

Add styles for execution progress, status pills, log rows, result blocks, disabled buttons, and memory draft text.

- [ ] **Step 2: Update README**

Document the execution-loop flow:

- switch scenario,
- record watch actions,
- move between steps,
- complete workout,
- inspect result and memory draft.

- [ ] **Step 3: Final verification**

Run syntax checks, contract test, local HTTP `curl`, and desktop/mobile screenshot verification.

- [ ] **Step 4: Commit**

Commit message: `style: polish watch execution loop`
