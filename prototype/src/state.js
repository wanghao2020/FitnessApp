import { healthScenarios } from "./mockData.js";
import { computeReadiness } from "./readiness.js";
import { buildDailyQuest } from "./questEngine.js";
import {
  buildWorkoutResult,
  createInitialStepLogs,
  deriveExecutionState,
  recordStepAction
} from "./execution.js";

function deriveState(base) {
  const summary = healthScenarios[base.scenarioId];
  const readiness = computeReadiness(summary);
  const quest = buildDailyQuest(readiness);
  const nextBase = { ...base, summary, readiness, quest };
  return deriveExecutionState(nextBase);
}

export function createStore() {
  let state = deriveState({
    scenarioId: "yellow",
    selectedAction: "开始任务",
    workoutResult: null,
    modelMode: "local",
    activeStepIndex: 0
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
      state = deriveState({
        ...state,
        scenarioId,
        workoutResult: null,
        activeStepIndex: 0,
        stepLogs: null
      });
      notify();
    },
    chooseAction(action) {
      state = { ...state, selectedAction: action };
      notify();
    },
    nextStep() {
      state = deriveExecutionState({
        ...state,
        activeStepIndex: Math.min(state.activeStepIndex + 1, state.quest.watchPayload.steps.length - 1)
      });
      notify();
    },
    previousStep() {
      state = deriveExecutionState({
        ...state,
        activeStepIndex: Math.max(state.activeStepIndex - 1, 0)
      });
      notify();
    },
    recordWatchAction(action) {
      state = deriveExecutionState({
        ...state,
        stepLogs: recordStepAction(
          state.stepLogs ?? createInitialStepLogs(state.quest.watchPayload.steps),
          state.activeStep,
          action
        )
      });
      notify();
    },
    completeWorkout(result) {
      const workoutResult = result ?? buildWorkoutResult(state);
      state = deriveExecutionState({ ...state, workoutResult });
      notify();
    },
    setModelMode(modelMode) {
      state = { ...state, modelMode };
      notify();
    }
  };
}
