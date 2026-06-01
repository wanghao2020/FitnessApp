# Interactive Prototype Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a dependency-free local web prototype for the Fitness RPG **Today Command Center** interaction loop.

**Architecture:** The prototype is a static browser app under `prototype/`. It uses modular JavaScript for mock health data, readiness rules, quest generation, state transitions, and rendering. It is intentionally separate from future SwiftUI/watchOS code and serves as an alignment artifact for UX and harness contracts.

**Tech Stack:** HTML, CSS, vanilla JavaScript ES modules, browser local runtime, optional `python3 -m http.server` for local preview.

---

## File Structure

- Create: `prototype/index.html`
  - Loads the app shell and ES modules.
- Create: `prototype/styles.css`
  - Defines responsive layout, readiness color tokens, panels, buttons, and Watch preview styling.
- Create: `prototype/src/mockData.js`
  - Stores mock health scenarios and model settings options.
- Create: `prototype/src/readiness.js`
  - Computes deterministic `ReadinessState` objects from mock `DailyHealthSummary` data.
- Create: `prototype/src/questEngine.js`
  - Converts readiness state into deterministic `DailyQuestPlan`, `WatchWorkoutStep`, and coach copy.
- Create: `prototype/src/state.js`
  - Owns UI state, transitions, workout completion, settings changes, and subscribers.
- Create: `prototype/src/render.js`
  - Renders Today Command Center panels and binds interactions.
- Create: `prototype/src/main.js`
  - Wires store, renderer, initial state, and browser boot.
- Create: `prototype/README.md`
  - Explains how to open and use the prototype.

## Task 1: Static App Shell

**Files:**
- Create: `prototype/index.html`
- Create: `prototype/styles.css`
- Create: `prototype/src/main.js`
- Create: `prototype/README.md`

- [ ] **Step 1: Create the app shell**

Create `prototype/index.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Fitness RPG Today Command Center</title>
    <link rel="stylesheet" href="./styles.css">
  </head>
  <body>
    <div id="app" class="app-shell">
      <main class="loading-panel">
        <p>Loading Today Command Center...</p>
      </main>
    </div>
    <script type="module" src="./src/main.js"></script>
  </body>
</html>
```

Create `prototype/src/main.js`:

```js
const app = document.querySelector("#app");

app.innerHTML = `
  <main class="page">
    <section class="hero-strip">
      <div>
        <p class="eyebrow">Fitness RPG Prototype</p>
        <h1>Today Command Center</h1>
        <p class="summary">A local-first daily quest loop for HealthKit readiness, RPG coaching, and Apple Watch execution.</p>
      </div>
    </section>
  </main>
`;
```

Create `prototype/styles.css`:

```css
:root {
  color-scheme: light;
  --bg: #f5f7f3;
  --surface: #ffffff;
  --surface-2: #edf2ef;
  --ink: #17211c;
  --muted: #607067;
  --line: #d8e0da;
  --green: #27845f;
  --yellow: #b7791f;
  --red: #b7413e;
  --blue: #2f6f9f;
  --radius: 8px;
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  background: var(--bg);
  color: var(--ink);
}

button,
input,
select,
textarea {
  font: inherit;
}

button {
  border: 1px solid var(--line);
  border-radius: 8px;
  background: var(--surface);
  color: var(--ink);
  cursor: pointer;
}

button:hover {
  border-color: var(--blue);
}

.app-shell {
  min-height: 100vh;
}

.page {
  width: min(1180px, calc(100vw - 32px));
  margin: 0 auto;
  padding: 24px 0 40px;
}

.loading-panel,
.hero-strip {
  background: var(--surface);
  border: 1px solid var(--line);
  border-radius: var(--radius);
  padding: 24px;
}

.eyebrow {
  margin: 0 0 8px;
  color: var(--blue);
  font-size: 0.78rem;
  font-weight: 700;
  text-transform: uppercase;
}

h1 {
  margin: 0;
  font-size: clamp(2rem, 5vw, 3.5rem);
  line-height: 1;
  letter-spacing: 0;
}

.summary {
  max-width: 680px;
  color: var(--muted);
  line-height: 1.55;
}
```

Create `prototype/README.md`:

```markdown
# Fitness RPG Interactive Prototype

This is a dependency-free browser prototype for aligning the Today Command Center experience before native iPhone/watchOS development.

Open directly:

```text
prototype/index.html
```

Or serve locally:

```bash
cd prototype
python3 -m http.server 5173
```

Then open `http://localhost:5173`.
```

- [ ] **Step 2: Preview the shell**

Run:

```bash
python3 -m http.server 5173
```

Expected: the server starts from `prototype/` and the page shows `Today Command Center`.

- [ ] **Step 3: Commit**

```bash
git add prototype/index.html prototype/styles.css prototype/src/main.js prototype/README.md
git commit -m "feat: scaffold interactive prototype shell"
```

## Task 2: Mock Data And Readiness Rules

**Files:**
- Create: `prototype/src/mockData.js`
- Create: `prototype/src/readiness.js`
- Modify: `prototype/src/main.js`

- [ ] **Step 1: Add mock health scenarios**

Create `prototype/src/mockData.js`:

```js
export const healthScenarios = {
  green: {
    id: "green",
    date: "2026-06-01",
    sleepHours: 7.6,
    hrvTrend: "up",
    restingHeartRateDelta: -2,
    recentLoad: "moderate",
    soreness: "low",
    injuryFlags: ["right shoulder watch"],
    activityContext: "Normal steps yesterday, no late workout."
  },
  yellow: {
    id: "yellow",
    date: "2026-06-01",
    sleepHours: 5.8,
    hrvTrend: "down",
    restingHeartRateDelta: 6,
    recentLoad: "high",
    soreness: "moderate",
    injuryFlags: ["right shoulder watch"],
    activityContext: "Two high-RPE sessions in the last three days."
  },
  red: {
    id: "red",
    date: "2026-06-01",
    sleepHours: 4.9,
    hrvTrend: "down",
    restingHeartRateDelta: 10,
    recentLoad: "very high",
    soreness: "high",
    injuryFlags: ["right shoulder watch", "knee soreness"],
    activityContext: "Poor sleep plus repeated high-RPE training."
  }
};

export const modelModes = [
  {
    id: "local",
    label: "Local Only",
    description: "Use on-device model output only. No health summary leaves the device."
  },
  {
    id: "hybrid",
    label: "Local + Remote Enhancement",
    description: "Use local model by default, with optional remote weekly or story enhancement."
  },
  {
    id: "disabled",
    label: "Remote Disabled",
    description: "Remote APIs are off. Deterministic templates are used if local generation fails."
  }
];
```

- [ ] **Step 2: Implement readiness calculation**

Create `prototype/src/readiness.js`:

```js
const restrictionsByColor = {
  Green: ["Normal training allowed", "Small progression allowed if form is clean"],
  Yellow: ["Reduce load 10-20%", "No PR attempts", "Keep RPE at or below 7"],
  Red: ["No high-intensity training", "Use recovery, mobility, or rest quest"]
};

export function computeReadiness(summary) {
  let score = 85;
  const drivers = [];

  if (summary.sleepHours < 6) {
    score -= 18;
    drivers.push(`Sleep is short at ${summary.sleepHours}h`);
  } else if (summary.sleepHours >= 7.2) {
    drivers.push(`Sleep supports training at ${summary.sleepHours}h`);
  }

  if (summary.hrvTrend === "down") {
    score -= 14;
    drivers.push("HRV trend is down");
  } else {
    drivers.push("HRV trend is stable or up");
  }

  if (summary.restingHeartRateDelta >= 8) {
    score -= 18;
    drivers.push(`Resting heart rate is +${summary.restingHeartRateDelta}`);
  } else if (summary.restingHeartRateDelta >= 5) {
    score -= 10;
    drivers.push(`Resting heart rate is +${summary.restingHeartRateDelta}`);
  } else {
    drivers.push("Resting heart rate is within normal range");
  }

  if (summary.recentLoad === "very high") {
    score -= 18;
    drivers.push("Recent training load is very high");
  } else if (summary.recentLoad === "high") {
    score -= 10;
    drivers.push("Recent training load is high");
  }

  if (summary.soreness === "high") {
    score -= 12;
    drivers.push("Soreness is high");
  } else if (summary.soreness === "moderate") {
    score -= 6;
    drivers.push("Soreness is moderate");
  }

  const clampedScore = Math.max(0, Math.min(100, score));
  const color = clampedScore >= 70 ? "Green" : clampedScore >= 45 ? "Yellow" : "Red";

  return {
    color,
    score: clampedScore,
    drivers,
    restrictions: restrictionsByColor[color],
    recommendedTrainingMode:
      color === "Green" ? "Progress training" : color === "Yellow" ? "Technique or reduced-load training" : "Recovery or rest"
  };
}
```

- [ ] **Step 3: Show readiness output in the shell**

Replace `prototype/src/main.js` with:

```js
import { healthScenarios } from "./mockData.js";
import { computeReadiness } from "./readiness.js";

const app = document.querySelector("#app");
const summary = healthScenarios.yellow;
const readiness = computeReadiness(summary);

app.innerHTML = `
  <main class="page">
    <section class="hero-strip">
      <div>
        <p class="eyebrow">Fitness RPG Prototype</p>
        <h1>Today Command Center</h1>
        <p class="summary">A local-first daily quest loop for HealthKit readiness, RPG coaching, and Apple Watch execution.</p>
      </div>
    </section>

    <section class="panel-grid">
      <article class="panel readiness-${readiness.color.toLowerCase()}">
        <p class="eyebrow">Readiness</p>
        <h2>${readiness.color} · ${readiness.score}</h2>
        <p>${readiness.recommendedTrainingMode}</p>
        <ul>${readiness.drivers.map((driver) => `<li>${driver}</li>`).join("")}</ul>
      </article>
    </section>
  </main>
`;
```

Append to `prototype/styles.css`:

```css
.panel-grid {
  display: grid;
  grid-template-columns: repeat(12, 1fr);
  gap: 16px;
  margin-top: 16px;
}

.panel {
  grid-column: span 6;
  background: var(--surface);
  border: 1px solid var(--line);
  border-radius: var(--radius);
  padding: 18px;
}

.panel h2 {
  margin: 0 0 8px;
  font-size: 1.6rem;
  letter-spacing: 0;
}

.readiness-green {
  border-left: 6px solid var(--green);
}

.readiness-yellow {
  border-left: 6px solid var(--yellow);
}

.readiness-red {
  border-left: 6px solid var(--red);
}

@media (max-width: 760px) {
  .panel {
    grid-column: 1 / -1;
  }
}
```

- [ ] **Step 4: Preview readiness shell**

Run:

```bash
python3 -m http.server 5173
```

Expected: page shows `Yellow · 51` or similar readiness output with drivers.

- [ ] **Step 5: Commit**

```bash
git add prototype/src/mockData.js prototype/src/readiness.js prototype/src/main.js prototype/styles.css
git commit -m "feat: add mock readiness scenarios"
```

## Task 3: Quest Engine And Watch Payload

**Files:**
- Create: `prototype/src/questEngine.js`
- Modify: `prototype/src/main.js`

- [ ] **Step 1: Implement deterministic quest generation**

Create `prototype/src/questEngine.js`:

```js
const questByColor = {
  Green: {
    questTitle: "Resonance Breakthrough",
    workoutFocus: "Progressive Push Day",
    intensityBoundary: "Normal load with one optional small progression",
    storyFraming: "The signal is stable. Advance the main path with clean force.",
    safetyNotes: ["Progress only if warm-up sets feel smooth", "Stop shoulder movements that create sharp pain"],
    exercises: [
      { name: "Bench Press", target: "4 x 6", rpeCap: 8, restSeconds: 150 },
      { name: "Incline Dumbbell Press", target: "3 x 10", rpeCap: 8, restSeconds: 120 },
      { name: "Cable Row", target: "3 x 12", rpeCap: 7, restSeconds: 90 }
    ]
  },
  Yellow: {
    questTitle: "Deep Hall Calibration",
    workoutFocus: "Technique Pull Day",
    intensityBoundary: "Reduce load 10-20%, no PR attempts",
    storyFraming: "The resonance is unstable today. We advance through precision, not force.",
    safetyNotes: ["Keep RPE at or below 7", "Use controlled tempo", "Do not chase volume"],
    exercises: [
      { name: "Lat Pulldown", target: "3 x 10", rpeCap: 7, restSeconds: 90 },
      { name: "Seated Row", target: "3 x 10", rpeCap: 7, restSeconds: 90 },
      { name: "Face Pull", target: "3 x 15", rpeCap: 6, restSeconds: 60 },
      { name: "Zone 2 Walk", target: "15 min", rpeCap: 5, restSeconds: 0 }
    ]
  },
  Red: {
    questTitle: "Campfire Restoration",
    workoutFocus: "Recovery Quest",
    intensityBoundary: "No high-intensity training",
    storyFraming: "The field is overcharged. Recovery protects the next chapter.",
    safetyNotes: ["No heavy lifting", "Use nasal-breathing pace", "Stop if symptoms worsen"],
    exercises: [
      { name: "Mobility Flow", target: "10 min", rpeCap: 3, restSeconds: 0 },
      { name: "Easy Walk", target: "20 min", rpeCap: 4, restSeconds: 0 },
      { name: "Breathing Reset", target: "5 min", rpeCap: 2, restSeconds: 0 }
    ]
  }
};

export function buildDailyQuest(readiness) {
  const base = questByColor[readiness.color];
  const watchSteps = base.exercises.map((exercise, index) => ({
    id: `step-${index + 1}`,
    exerciseName: exercise.name,
    target: exercise.target,
    restSeconds: exercise.restSeconds,
    rpeCap: exercise.rpeCap,
    quickActions: ["Done", "Too Heavy", "Skip", `RPE <= ${exercise.rpeCap}`]
  }));

  return {
    questTitle: base.questTitle,
    readinessColor: readiness.color,
    workoutFocus: base.workoutFocus,
    intensityBoundary: base.intensityBoundary,
    storyFraming: base.storyFraming,
    safetyNotes: base.safetyNotes,
    exercises: base.exercises,
    watchPayload: {
      questTitle: base.questTitle,
      currentStep: watchSteps[0],
      steps: watchSteps
    }
  };
}
```

- [ ] **Step 2: Render quest and Watch payload**

Replace `prototype/src/main.js` with:

```js
import { healthScenarios } from "./mockData.js";
import { computeReadiness } from "./readiness.js";
import { buildDailyQuest } from "./questEngine.js";

const app = document.querySelector("#app");
const summary = healthScenarios.yellow;
const readiness = computeReadiness(summary);
const quest = buildDailyQuest(readiness);

app.innerHTML = `
  <main class="page">
    <section class="hero-strip">
      <div>
        <p class="eyebrow">Fitness RPG Prototype</p>
        <h1>Today Command Center</h1>
        <p class="summary">A local-first daily quest loop for HealthKit readiness, RPG coaching, and Apple Watch execution.</p>
      </div>
    </section>

    <section class="panel-grid">
      <article class="panel readiness-${readiness.color.toLowerCase()}">
        <p class="eyebrow">Readiness</p>
        <h2>${readiness.color} · ${readiness.score}</h2>
        <p>${readiness.recommendedTrainingMode}</p>
        <ul>${readiness.drivers.map((driver) => `<li>${driver}</li>`).join("")}</ul>
      </article>

      <article class="panel">
        <p class="eyebrow">Daily Quest</p>
        <h2>${quest.questTitle}</h2>
        <p>${quest.workoutFocus}</p>
        <p>${quest.intensityBoundary}</p>
      </article>

      <article class="panel wide">
        <p class="eyebrow">Workout Plan</p>
        <div class="exercise-list">
          ${quest.exercises.map((exercise) => `
            <div class="exercise-row">
              <strong>${exercise.name}</strong>
              <span>${exercise.target}</span>
              <span>RPE cap ${exercise.rpeCap}</span>
            </div>
          `).join("")}
        </div>
      </article>

      <article class="panel">
        <p class="eyebrow">RPG Coach</p>
        <blockquote>${quest.storyFraming}</blockquote>
        <div class="button-row">
          <button>Start Quest</button>
          <button>Lower Intensity</button>
          <button>Rest Camp</button>
        </div>
      </article>

      <article class="panel watch-panel">
        <p class="eyebrow">Apple Watch</p>
        <h2>${quest.watchPayload.questTitle}</h2>
        <p>${quest.watchPayload.currentStep.exerciseName} · ${quest.watchPayload.currentStep.target}</p>
        <div class="button-row">
          ${quest.watchPayload.currentStep.quickActions.map((action) => `<button>${action}</button>`).join("")}
        </div>
      </article>
    </section>
  </main>
`;
```

Append to `prototype/styles.css`:

```css
.wide {
  grid-column: 1 / -1;
}

.exercise-list {
  display: grid;
  gap: 8px;
}

.exercise-row {
  display: grid;
  grid-template-columns: 1.4fr .7fr .7fr;
  gap: 12px;
  padding: 10px;
  background: var(--surface-2);
  border-radius: 8px;
}

blockquote {
  margin: 0 0 16px;
  padding-left: 14px;
  border-left: 4px solid var(--blue);
  color: var(--muted);
  line-height: 1.5;
}

.button-row {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.button-row button {
  padding: 9px 12px;
}

.watch-panel {
  background: #101615;
  color: #f5fbf7;
  border-color: #2a3934;
}

.watch-panel .eyebrow,
.watch-panel p {
  color: #b8c8c0;
}
```

- [ ] **Step 3: Preview quest screen**

Run:

```bash
python3 -m http.server 5173
```

Expected: page shows readiness, daily quest, workout plan, coach copy, and Watch preview.

- [ ] **Step 4: Commit**

```bash
git add prototype/src/questEngine.js prototype/src/main.js prototype/styles.css
git commit -m "feat: render quest and watch preview"
```

## Task 4: App State And Scenario Switching

**Files:**
- Create: `prototype/src/state.js`
- Create: `prototype/src/render.js`
- Modify: `prototype/src/main.js`
- Modify: `prototype/styles.css`

- [ ] **Step 1: Add state store**

Create `prototype/src/state.js`:

```js
import { healthScenarios } from "./mockData.js";
import { computeReadiness } from "./readiness.js";
import { buildDailyQuest } from "./questEngine.js";

function deriveState(base) {
  const summary = healthScenarios[base.scenarioId];
  const readiness = computeReadiness(summary);
  const quest = buildDailyQuest(readiness);
  return { ...base, summary, readiness, quest };
}

export function createStore() {
  let state = deriveState({
    scenarioId: "yellow",
    selectedAction: "Start Quest",
    workoutResult: null,
    modelMode: "local"
  });
  const listeners = new Set();

  function notify() {
    for (const listener of listeners) {
      listener(state);
    }
  }

  return {
    getState() {
      return state;
    },
    subscribe(listener) {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },
    setScenario(scenarioId) {
      state = deriveState({ ...state, scenarioId, workoutResult: null });
      notify();
    },
    chooseAction(action) {
      state = { ...state, selectedAction: action };
      notify();
    },
    completeWorkout(result) {
      state = { ...state, workoutResult: result };
      notify();
    },
    setModelMode(modelMode) {
      state = { ...state, modelMode };
      notify();
    }
  };
}
```

- [ ] **Step 2: Add renderer**

Create `prototype/src/render.js`:

```js
import { healthScenarios, modelModes } from "./mockData.js";

function list(items) {
  return items.map((item) => `<li>${item}</li>`).join("");
}

function activeClass(value, current) {
  return value === current ? "active" : "";
}

export function renderApp(app, store) {
  const state = store.getState();
  const { summary, readiness, quest } = state;
  const modelMode = modelModes.find((mode) => mode.id === state.modelMode);

  app.innerHTML = `
    <main class="page">
      <section class="hero-strip">
        <div>
          <p class="eyebrow">Fitness RPG Prototype</p>
          <h1>Today Command Center</h1>
          <p class="summary">A local-first daily quest loop for HealthKit readiness, RPG coaching, and Apple Watch execution.</p>
        </div>
        <div class="scenario-switcher" aria-label="Readiness scenarios">
          ${Object.keys(healthScenarios).map((id) => `
            <button class="${activeClass(id, state.scenarioId)}" data-scenario="${id}">${id}</button>
          `).join("")}
        </div>
      </section>

      <section class="panel-grid">
        <article class="panel readiness-${readiness.color.toLowerCase()}">
          <p class="eyebrow">Readiness</p>
          <h2>${readiness.color} · ${readiness.score}</h2>
          <p>${readiness.recommendedTrainingMode}</p>
          <ul>${list(readiness.drivers)}</ul>
        </article>

        <article class="panel">
          <p class="eyebrow">Daily Health Summary</p>
          <dl class="metric-list">
            <div><dt>Sleep</dt><dd>${summary.sleepHours}h</dd></div>
            <div><dt>HRV</dt><dd>${summary.hrvTrend}</dd></div>
            <div><dt>RHR</dt><dd>${summary.restingHeartRateDelta > 0 ? "+" : ""}${summary.restingHeartRateDelta}</dd></div>
            <div><dt>Load</dt><dd>${summary.recentLoad}</dd></div>
          </dl>
        </article>

        <article class="panel">
          <p class="eyebrow">Daily Quest</p>
          <h2>${quest.questTitle}</h2>
          <p>${quest.workoutFocus}</p>
          <p>${quest.intensityBoundary}</p>
        </article>

        <article class="panel">
          <p class="eyebrow">Safety Validator</p>
          <ul>${list([...readiness.restrictions, ...quest.safetyNotes])}</ul>
        </article>

        <article class="panel wide">
          <p class="eyebrow">Workout Plan</p>
          <div class="exercise-list">
            ${quest.exercises.map((exercise) => `
              <div class="exercise-row">
                <strong>${exercise.name}</strong>
                <span>${exercise.target}</span>
                <span>RPE cap ${exercise.rpeCap}</span>
              </div>
            `).join("")}
          </div>
        </article>

        <article class="panel">
          <p class="eyebrow">RPG Coach</p>
          <blockquote>${quest.storyFraming}</blockquote>
          <div class="button-row">
            ${["Start Quest", "Lower Intensity", "Rest Camp"].map((action) => `
              <button class="${activeClass(action, state.selectedAction)}" data-action="${action}">${action}</button>
            `).join("")}
          </div>
        </article>

        <article class="panel watch-panel">
          <p class="eyebrow">Apple Watch</p>
          <h2>${quest.watchPayload.questTitle}</h2>
          <p>${quest.watchPayload.currentStep.exerciseName} · ${quest.watchPayload.currentStep.target}</p>
          <div class="button-row">
            ${quest.watchPayload.currentStep.quickActions.map((action) => `<button data-watch-action="${action}">${action}</button>`).join("")}
          </div>
        </article>

        <article class="panel">
          <p class="eyebrow">Model Mode</p>
          <h2>${modelMode.label}</h2>
          <p>${modelMode.description}</p>
          <div class="button-row">
            ${modelModes.map((mode) => `<button class="${activeClass(mode.id, state.modelMode)}" data-model-mode="${mode.id}">${mode.label}</button>`).join("")}
          </div>
        </article>

        <article class="panel">
          <p class="eyebrow">Workout Result</p>
          ${state.workoutResult ? `
            <h2>${state.workoutResult.status}</h2>
            <p>${state.workoutResult.summary}</p>
          ` : `
            <p>No workout completed yet.</p>
            <button class="primary" data-complete-workout="true">Complete Mock Workout</button>
          `}
        </article>
      </section>
    </main>
  `;

  app.querySelectorAll("[data-scenario]").forEach((button) => {
    button.addEventListener("click", () => store.setScenario(button.dataset.scenario));
  });

  app.querySelectorAll("[data-action]").forEach((button) => {
    button.addEventListener("click", () => store.chooseAction(button.dataset.action));
  });

  app.querySelectorAll("[data-model-mode]").forEach((button) => {
    button.addEventListener("click", () => store.setModelMode(button.dataset.modelMode));
  });

  const completeButton = app.querySelector("[data-complete-workout]");
  if (completeButton) {
    completeButton.addEventListener("click", () => {
      store.completeWorkout({
        status: "Quest Complete",
        summary: `${quest.questTitle} completed with average RPE ${readiness.color === "Green" ? 8 : readiness.color === "Yellow" ? 7 : 4}. Story state updated with recovery-positive progress.`
      });
    });
  }
}
```

- [ ] **Step 3: Wire renderer**

Replace `prototype/src/main.js` with:

```js
import { createStore } from "./state.js";
import { renderApp } from "./render.js";

const app = document.querySelector("#app");
const store = createStore();

function render() {
  renderApp(app, store);
}

store.subscribe(render);
render();
```

Append to `prototype/styles.css`:

```css
.hero-strip {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 16px;
}

.scenario-switcher {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.scenario-switcher button,
.button-row button {
  min-height: 40px;
}

button.active,
button.primary {
  background: var(--ink);
  border-color: var(--ink);
  color: #ffffff;
}

.metric-list {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
  margin: 0;
}

.metric-list div {
  padding: 10px;
  background: var(--surface-2);
  border-radius: 8px;
}

.metric-list dt {
  color: var(--muted);
  font-size: 0.82rem;
}

.metric-list dd {
  margin: 2px 0 0;
  font-weight: 800;
}

@media (max-width: 760px) {
  .hero-strip {
    align-items: stretch;
    flex-direction: column;
  }

  .exercise-row {
    grid-template-columns: 1fr;
  }
}
```

- [ ] **Step 4: Preview interactions**

Run:

```bash
python3 -m http.server 5173
```

Expected: scenario buttons switch Green / Yellow / Red; quest panels and Watch preview update; model mode and mock completion controls update visible state.

- [ ] **Step 5: Commit**

```bash
git add prototype/src/state.js prototype/src/render.js prototype/src/main.js prototype/styles.css
git commit -m "feat: add prototype interaction state"
```

## Task 5: Visual Polish And Responsive QA

**Files:**
- Modify: `prototype/styles.css`
- Modify: `prototype/README.md`

- [ ] **Step 1: Improve app polish**

Append to `prototype/styles.css`:

```css
.panel p,
.panel li {
  line-height: 1.5;
}

.panel ul {
  padding-left: 20px;
}

.readiness-green h2 {
  color: var(--green);
}

.readiness-yellow h2 {
  color: var(--yellow);
}

.readiness-red h2 {
  color: var(--red);
}

.watch-panel button {
  background: #182522;
  border-color: #31443e;
  color: #f5fbf7;
}

.watch-panel button:hover {
  border-color: #8bc7b0;
}

@media (max-width: 520px) {
  .page {
    width: min(100vw - 20px, 1180px);
    padding-top: 10px;
  }

  .hero-strip,
  .panel {
    padding: 14px;
  }

  h1 {
    font-size: 2.1rem;
  }

  .panel h2 {
    font-size: 1.35rem;
  }

  .button-row button,
  .scenario-switcher button {
    flex: 1 1 auto;
  }
}
```

- [ ] **Step 2: Update usage documentation**

Replace `prototype/README.md` with:

```markdown
# Fitness RPG Interactive Prototype

This dependency-free browser prototype aligns the Fitness RPG Today Command Center before native iPhone/watchOS development.

## Open

Open directly:

```text
prototype/index.html
```

Or serve locally:

```bash
cd prototype
python3 -m http.server 5173
```

Then open `http://localhost:5173`.

## What To Test

- Switch Green / Yellow / Red readiness scenarios.
- Confirm quest intensity changes with readiness.
- Confirm Safety Validator blocks unsafe framing on Yellow and Red days.
- Preview the Apple Watch execution payload.
- Switch model mode between Local Only, Local + Remote Enhancement, and Remote Disabled.
- Complete a mock workout and inspect the recap.
```

- [ ] **Step 3: Run final local preview**

Run:

```bash
python3 -m http.server 5173
```

Expected: prototype remains usable on desktop width and narrow mobile width. No text overlaps panels or buttons.

- [ ] **Step 4: Commit**

```bash
git add prototype/styles.css prototype/README.md
git commit -m "style: polish interactive prototype"
```

## Self-Review

- Spec coverage: The plan implements the Today Command Center, Green / Yellow / Red readiness switching, deterministic quest generation, Watch preview, model settings, mock workout completion, and documentation. It intentionally excludes real HealthKit and model runtime.
- Placeholder scan: No implementation steps rely on placeholder tasks or undefined future work.
- Type consistency: `DailyHealthSummary`, `ReadinessState`, `DailyQuestPlan`, `WatchWorkoutStep`, `WorkoutResult`, and model settings are represented by the mock data and state fields named in the design spec.
