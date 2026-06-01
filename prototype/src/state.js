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
