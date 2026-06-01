import assert from "node:assert/strict";
import { healthScenarios, modelModes } from "../src/mockData.js";
import { computeReadiness } from "../src/readiness.js";
import { buildDailyQuest } from "../src/questEngine.js";

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

console.log("prototype contract ok");
