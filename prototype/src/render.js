import { healthScenarios, modelModes } from "./mockData.js";

function list(items) {
  return [...new Set(items)].map((item) => `<li>${item}</li>`).join("");
}

function activeClass(value, current) {
  return value === current ? "active" : "";
}

const colorLabels = {
  Green: "绿",
  Yellow: "黄",
  Red: "红"
};

const trendLabels = {
  up: "上升",
  down: "下降"
};

const loadLabels = {
  moderate: "中等",
  high: "偏高",
  "very high": "很高"
};

const sorenessLabels = {
  low: "低",
  moderate: "中等",
  high: "高"
};

export function renderApp(app, store) {
  const state = store.getState();
  const { summary, readiness, quest } = state;
  const modelMode = modelModes.find((mode) => mode.id === state.modelMode);

  app.innerHTML = `
    <main class="page">
      <section class="hero-strip">
        <div>
          <p class="eyebrow">Fitness RPG 原型</p>
          <h1>今日任务中枢</h1>
          <p class="summary">本地优先的每日任务循环：读取 HealthKit 恢复状态，生成安全训练边界，把剧情 RPG 任务同步到 Apple Watch 执行。</p>
        </div>
        <div class="scenario-switcher" aria-label="状态场景">
          ${Object.keys(healthScenarios).map((id) => `
            <button class="${activeClass(id, state.scenarioId)}" data-scenario="${id}">
              <span>${healthScenarios[id].label}</span>
              <small>${healthScenarios[id].statusLabel}</small>
            </button>
          `).join("")}
        </div>
      </section>

      <section class="world-strip readiness-${readiness.color.toLowerCase()}">
        <div>
          <p class="eyebrow">世界状态</p>
          <strong>${quest.worldState.label}</strong>
          <span>${quest.worldState.detail}</span>
        </div>
        <div>
          <p class="eyebrow">章节节点</p>
          <strong>${quest.storyNode.chapter}</strong>
          <span>${quest.storyNode.node}</span>
        </div>
      </section>

      <section class="panel-grid">
        <article class="panel readiness-${readiness.color.toLowerCase()}">
          <p class="eyebrow">今日状态</p>
          <h2>${colorLabels[readiness.color]} · ${readiness.score}</h2>
          <p>${readiness.recommendedTrainingMode}</p>
          <ul>${list(readiness.drivers)}</ul>
        </article>

        <article class="panel">
          <p class="eyebrow">健康摘要</p>
          <dl class="metric-list">
            <div><dt>睡眠</dt><dd>${summary.sleepHours} 小时</dd></div>
            <div><dt>HRV</dt><dd>${trendLabels[summary.hrvTrend] ?? summary.hrvTrend}</dd></div>
            <div><dt>静息心率</dt><dd>${summary.restingHeartRateDelta > 0 ? "+" : ""}${summary.restingHeartRateDelta}</dd></div>
            <div><dt>负荷</dt><dd>${loadLabels[summary.recentLoad] ?? summary.recentLoad}</dd></div>
            <div><dt>酸痛</dt><dd>${sorenessLabels[summary.soreness] ?? summary.soreness}</dd></div>
            <div><dt>观察项</dt><dd>${summary.injuryFlags.join("、")}</dd></div>
          </dl>
        </article>

        <article class="panel">
          <p class="eyebrow">今日任务</p>
          <h2>${quest.questTitle}</h2>
          <p>${quest.workoutFocus}</p>
          <p>${quest.intensityBoundary}</p>
        </article>

        <article class="panel">
          <p class="eyebrow">安全边界</p>
          <ul>${list([...readiness.restrictions, ...quest.safetyNotes])}</ul>
        </article>

        <article class="panel wide">
          <p class="eyebrow">训练计划</p>
          <div class="exercise-list">
            ${quest.exercises.map((exercise) => `
              <div class="exercise-row">
                <strong>${exercise.name}</strong>
                <span>${exercise.target}</span>
                <span>RPE 上限 ${exercise.rpeCap}</span>
                <span>${exercise.restSeconds > 0 ? `休息 ${exercise.restSeconds} 秒` : "连续执行"}</span>
              </div>
            `).join("")}
          </div>
        </article>

        <article class="panel">
          <p class="eyebrow">剧情教练</p>
          <blockquote>${quest.storyFraming}</blockquote>
          <p class="coach-note">${quest.storyNode.npc}</p>
          <div class="button-row">
            ${["开始任务", "降低强度", "进入恢复营地"].map((action) => `
              <button class="${activeClass(action, state.selectedAction)}" data-action="${action}">${action}</button>
            `).join("")}
          </div>
        </article>

        <article class="panel">
          <p class="eyebrow">角色成长</p>
          <div class="attribute-grid">
            ${quest.attributeRewards.map((reward) => `
              <div class="attribute-pill">
                <span>${reward.code}</span>
                <strong>${reward.label}</strong>
                <em>${reward.delta}</em>
              </div>
            `).join("")}
          </div>
          <p class="muted-copy">恢复任务同样结算经验，避免把休息误读成失败。</p>
        </article>

        <article class="panel watch-panel">
          <p class="eyebrow">Apple Watch 执行</p>
          <h2>${quest.watchPayload.questTitle}</h2>
          <p>${quest.watchPayload.currentStep.exerciseName} · ${quest.watchPayload.currentStep.target}</p>
          <div class="button-row">
            ${quest.watchPayload.currentStep.quickActions.map((action) => `<button data-watch-action="${action}">${action}</button>`).join("")}
          </div>
        </article>

        <article class="panel">
          <p class="eyebrow">模型模式</p>
          <h2>${modelMode.label}</h2>
          <p>${modelMode.description}</p>
          <div class="button-row">
            ${modelModes.map((mode) => `<button class="${activeClass(mode.id, state.modelMode)}" data-model-mode="${mode.id}">${mode.label}</button>`).join("")}
          </div>
        </article>

        <article class="panel">
          <p class="eyebrow">训练结果</p>
          ${state.workoutResult ? `
            <h2>${state.workoutResult.status}</h2>
            <p>${state.workoutResult.summary}</p>
          ` : `
            <p>尚未完成今日任务。</p>
            <button class="primary" data-complete-workout="true">完成模拟训练</button>
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
        status: "任务完成",
        summary: `${quest.questTitle} 已结算，平均 RPE ${readiness.color === "Green" ? 8 : readiness.color === "Yellow" ? 7 : 4}。剧情状态已更新，恢复型进展也计入成长。`
      });
    });
  }
}
