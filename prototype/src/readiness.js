const restrictionsByColor = {
  Green: ["允许正常训练", "热身组顺畅时可小幅进阶"],
  Yellow: ["负重降低 10-20%", "不进行 PR 尝试", "RPE 控制在 7 或以下"],
  Red: ["不安排高强度训练", "使用恢复、灵活性或休息任务推进剧情"]
};

export function computeReadiness(summary) {
  let score = 100;
  const drivers = [];

  if (summary.sleepHours < 6) {
    score -= 18;
    drivers.push(`睡眠偏短：${summary.sleepHours} 小时`);
  } else if (summary.sleepHours >= 7.2) {
    drivers.push(`睡眠支持训练：${summary.sleepHours} 小时`);
  }

  if (summary.hrvTrend === "down") {
    score -= 14;
    drivers.push("HRV 趋势下降");
  } else {
    drivers.push("HRV 稳定或上升");
  }

  if (summary.restingHeartRateDelta >= 8) {
    score -= 18;
    drivers.push(`静息心率升高 +${summary.restingHeartRateDelta}`);
  } else if (summary.restingHeartRateDelta >= 5) {
    score -= 10;
    drivers.push(`静息心率升高 +${summary.restingHeartRateDelta}`);
  } else {
    drivers.push("静息心率在正常范围");
  }

  if (summary.recentLoad === "very high") {
    score -= 18;
    drivers.push("近期训练负荷很高");
  } else if (summary.recentLoad === "high") {
    score -= 10;
    drivers.push("近期训练负荷偏高");
  }

  if (summary.soreness === "high") {
    score -= 12;
    drivers.push("酸痛程度较高");
  } else if (summary.soreness === "moderate") {
    score -= 6;
    drivers.push("酸痛程度中等");
  }

  const clampedScore = Math.max(0, Math.min(100, score));
  const color = clampedScore >= 70 ? "Green" : clampedScore >= 35 ? "Yellow" : "Red";

  return {
    color,
    score: clampedScore,
    drivers,
    restrictions: restrictionsByColor[color],
    recommendedTrainingMode:
      color === "Green" ? "推进训练" : color === "Yellow" ? "技术或降负荷训练" : "恢复或休息"
  };
}
