# Chinese RPG Visual Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the interactive prototype into a Chinese-first Fitness RPG command center with improved layout, color, RPG world-state affordances, and responsive polish.

**Architecture:** Keep the existing static prototype architecture. Add a small Node contract test for data and quest output, then update mock data, quest generation, rendering, and CSS in focused passes.

**Tech Stack:** Vanilla HTML/CSS/JavaScript ES modules, Node built-in `assert`, local `python3 -m http.server`, in-app browser verification.

---

## File Structure

- Create: `prototype/tests/prototypeContract.test.mjs`
  - Verifies Chinese scenario labels, quest metadata, watch payload actions, and model mode labels.
- Modify: `prototype/src/mockData.js`
  - Localizes scenarios and model modes, adds display labels and RPG world metadata.
- Modify: `prototype/src/questEngine.js`
  - Localizes quest output and adds story node plus attribute reward metadata.
- Modify: `prototype/src/render.js`
  - Localizes UI copy and adds world state / character growth sections.
- Modify: `prototype/styles.css`
  - Refines palette, hierarchy, grid behavior, Chinese text wrapping, and mobile layout.
- Modify: `prototype/README.md`
  - Updates prototype description and verification notes in Chinese.

## Task 1: Add Contract Test

**Files:**
- Create: `prototype/tests/prototypeContract.test.mjs`

- [ ] **Step 1: Write the failing test**

```js
import assert from "node:assert/strict";
import { healthScenarios, modelModes } from "../src/mockData.js";
import { calculateReadiness } from "../src/readiness.js";
import { buildDailyQuest } from "../src/questEngine.js";

const expectedScenarioLabels = {
  green: "绿",
  yellow: "黄",
  red: "红"
};

for (const [id, expectedLabel] of Object.entries(expectedScenarioLabels)) {
  const scenario = healthScenarios[id];
  assert.equal(scenario.label, expectedLabel);

  const readiness = calculateReadiness(scenario);
  const quest = buildDailyQuest(readiness);

  assert.match(readiness.recommendedTrainingMode, /训练|恢复|技术/);
  assert.ok(quest.questTitle.length > 0);
  assert.ok(quest.worldState.label.length > 0);
  assert.ok(quest.storyNode.chapter.length > 0);
  assert.ok(quest.attributeRewards.length >= 2);
  assert.ok(quest.watchPayload.currentStep.quickActions.includes("完成"));
}

assert.deepEqual(
  modelModes.map((mode) => mode.label),
  ["本地优先", "本地 + 远程增强", "禁用远程"]
);

console.log("prototype contract ok");
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node prototype/tests/prototypeContract.test.mjs`

Expected: FAIL because `scenario.label`, `quest.worldState`, `quest.storyNode`, and Chinese model labels do not exist yet.

- [ ] **Step 3: Commit after the test is red**

Do not commit if the test passes before implementation.

## Task 2: Localize Data and Quest Output

**Files:**
- Modify: `prototype/src/mockData.js`
- Modify: `prototype/src/questEngine.js`

- [ ] **Step 1: Update `mockData.js`**

Add Chinese labels and RPG world metadata to each scenario. Localize model mode labels and descriptions.

- [ ] **Step 2: Update `questEngine.js`**

Replace English quest content with Chinese quest titles, focus, boundaries, story framing, safety notes, exercise names, watch quick actions, story node metadata, and attribute rewards.

- [ ] **Step 3: Run contract test**

Run: `node prototype/tests/prototypeContract.test.mjs`

Expected: PASS and print `prototype contract ok`.

- [ ] **Step 4: Commit**

Commit message: `feat: localize rpg prototype data`

## Task 3: Refresh Rendering

**Files:**
- Modify: `prototype/src/render.js`

- [ ] **Step 1: Update visible copy**

Translate all headings, buttons, empty states, result copy, and metric labels into Chinese while keeping `Apple Watch`, `RPE`, and `HRV` where useful.

- [ ] **Step 2: Add RPG sections**

Render `世界状态`, `章节节点`, and `角色成长` using the new quest metadata. Keep these as top-level panels or strips, not nested cards.

- [ ] **Step 3: Run syntax and contract checks**

Run:

```bash
node --check prototype/src/main.js
node --check prototype/src/mockData.js
node --check prototype/src/questEngine.js
node --check prototype/src/readiness.js
node --check prototype/src/render.js
node --check prototype/src/state.js
node prototype/tests/prototypeContract.test.mjs
```

Expected: all syntax checks exit 0 and the contract test prints `prototype contract ok`.

- [ ] **Step 4: Commit**

Commit message: `feat: render chinese rpg command center`

## Task 4: Refresh Visual System

**Files:**
- Modify: `prototype/styles.css`

- [ ] **Step 1: Update palette and layout primitives**

Use a light base, dark readable text, green/amber/red readiness colors, blue/teal system accents, and a dark Watch panel. Keep border radius at 8px or less.

- [ ] **Step 2: Add layout styles**

Add styles for world-state strip, story node details, attribute reward grid, compact labels, and responsive button wrapping.

- [ ] **Step 3: Check mobile resilience**

Ensure hero text, scenario buttons, exercise rows, and model buttons wrap without horizontal overflow at narrow widths.

- [ ] **Step 4: Commit**

Commit message: `style: polish chinese rpg prototype`

## Task 5: Update Docs and Verify

**Files:**
- Modify: `prototype/README.md`

- [ ] **Step 1: Update README**

Describe the Chinese RPG command center, the three readiness scenarios, and the verification commands.

- [ ] **Step 2: Run final verification**

Run:

```bash
node --check prototype/src/main.js
node --check prototype/src/mockData.js
node --check prototype/src/questEngine.js
node --check prototype/src/readiness.js
node --check prototype/src/render.js
node --check prototype/src/state.js
node prototype/tests/prototypeContract.test.mjs
curl -s http://localhost:5173
```

Expected: syntax checks exit 0, contract test prints `prototype contract ok`, and curl returns the prototype HTML.

- [ ] **Step 3: Browser verification**

Open or refresh `http://localhost:5173` and verify:

- Scenario buttons `绿 / 黄 / 红` update readiness, quest, world state, watch payload, and safety notes.
- Model mode buttons update the model explanation.
- `完成模拟训练` updates the result panel in Chinese.
- Desktop and narrow/mobile widths do not show obvious overlap or horizontal overflow.

- [ ] **Step 4: Commit**

Commit message: `docs: update chinese prototype readme`
