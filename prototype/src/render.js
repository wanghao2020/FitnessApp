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
