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

console.log("prototype contract ok");
