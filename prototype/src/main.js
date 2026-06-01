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
