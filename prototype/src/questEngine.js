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
