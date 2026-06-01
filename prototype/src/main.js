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
