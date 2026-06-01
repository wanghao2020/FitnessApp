import assert from "node:assert/strict";
import { healthScenarios, modelModes } from "../src/mockData.js";
import { computeReadiness } from "../src/readiness.js";
import { buildDailyQuest } from "../src/questEngine.js";
import { createStore } from "../src/state.js";

const expectedScenarioLabels = {
  green: "绿",
  yellow: "黄",
  red: "红"
};

for (const [id, expectedLabel] of Object.entries(expectedScenarioLabels)) {
  const scenario = healthScenarios[id];
  assert.equal(scenario.label, expectedLabel);

  const readiness = computeReadiness(scenario);
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

const store = createStore();
assert.equal(store.getState().scenarioId, "yellow");
assert.equal(store.getState().quest.questTitle, "深厅校准");

store.setScenario("green");
assert.equal(store.getState().readiness.color, "Green");
assert.equal(store.getState().quest.worldState.label, "共振稳定");
assert.equal(store.getState().quest.watchPayload.currentStep.quickActions[0], "完成");

store.setScenario("red");
assert.equal(store.getState().readiness.color, "Red");
assert.equal(store.getState().quest.questTitle, "营火修复");
assert.match(store.getState().quest.worldState.detail, /恢复章节/);

store.setModelMode("hybrid");
assert.equal(store.getState().modelMode, "hybrid");

store.completeWorkout({
  status: "任务完成",
  summary: "测试结算"
});
assert.equal(store.getState().workoutResult.status, "任务完成");

console.log("prototype contract ok");
