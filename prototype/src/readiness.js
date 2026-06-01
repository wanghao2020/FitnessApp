const restrictionsByColor = {
  Green: ["Normal training allowed", "Small progression allowed if form is clean"],
  Yellow: ["Reduce load 10-20%", "No PR attempts", "Keep RPE at or below 7"],
  Red: ["No high-intensity training", "Use recovery, mobility, or rest quest"]
};

export function computeReadiness(summary) {
  let score = 85;
  const drivers = [];

  if (summary.sleepHours < 6) {
    score -= 18;
    drivers.push(`Sleep is short at ${summary.sleepHours}h`);
  } else if (summary.sleepHours >= 7.2) {
    drivers.push(`Sleep supports training at ${summary.sleepHours}h`);
  }

  if (summary.hrvTrend === "down") {
    score -= 14;
    drivers.push("HRV trend is down");
  } else {
    drivers.push("HRV trend is stable or up");
  }

  if (summary.restingHeartRateDelta >= 8) {
    score -= 18;
    drivers.push(`Resting heart rate is +${summary.restingHeartRateDelta}`);
  } else if (summary.restingHeartRateDelta >= 5) {
    score -= 10;
    drivers.push(`Resting heart rate is +${summary.restingHeartRateDelta}`);
  } else {
    drivers.push("Resting heart rate is within normal range");
  }

  if (summary.recentLoad === "very high") {
    score -= 18;
    drivers.push("Recent training load is very high");
  } else if (summary.recentLoad === "high") {
    score -= 10;
    drivers.push("Recent training load is high");
  }

  if (summary.soreness === "high") {
    score -= 12;
    drivers.push("Soreness is high");
  } else if (summary.soreness === "moderate") {
    score -= 6;
    drivers.push("Soreness is moderate");
  }

  const clampedScore = Math.max(0, Math.min(100, score));
  const color = clampedScore >= 70 ? "Green" : clampedScore >= 45 ? "Yellow" : "Red";

  return {
    color,
    score: clampedScore,
    drivers,
    restrictions: restrictionsByColor[color],
    recommendedTrainingMode:
      color === "Green" ? "Progress training" : color === "Yellow" ? "Technique or reduced-load training" : "Recovery or rest"
  };
}
