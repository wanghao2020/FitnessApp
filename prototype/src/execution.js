const statusLabels = {
  pending: "待执行",
  completed: "已完成",
  tooHeavy: "过重",
  skipped: "已跳过"
};

export function createInitialStepLogs(steps) {
  return Object.fromEntries(
    steps.map((step) => [
      step.id,
      {
        status: "pending",
        note: "等待 Apple Watch 反馈",
        rpe: null
      }
    ])
  );
}

export function deriveExecutionState(baseState) {
  const steps = baseState.quest.watchPayload.steps;
  const activeStepIndex = Math.max(0, Math.min(baseState.activeStepIndex ?? 0, steps.length - 1));
  const stepLogs = baseState.stepLogs ?? createInitialStepLogs(steps);
  const activeStep = steps[activeStepIndex];
  const logValues = steps.map((step) => stepLogs[step.id]);
  const completedCount = logValues.filter((log) => log.status === "completed").length;
  const tooHeavyCount = logValues.filter((log) => log.status === "tooHeavy").length;
  const skippedCount = logValues.filter((log) => log.status === "skipped").length;
  const recordedCount = completedCount + tooHeavyCount + skippedCount;
  const rpeValues = logValues.map((log) => log.rpe).filter((rpe) => typeof rpe === "number");
  const averageRpe = rpeValues.length
    ? Math.round((rpeValues.reduce((sum, rpe) => sum + rpe, 0) / rpeValues.length) * 10) / 10
    : null;

  return {
    ...baseState,
    activeStepIndex,
    activeStep,
    stepLogs,
    executionSummary: {
      totalCount: steps.length,
      completedCount,
      tooHeavyCount,
      skippedCount,
      recordedCount,
      averageRpe,
      hasLoadIssue: tooHeavyCount > 0,
      hasSkippedStep: skippedCount > 0
    },
    memoryDraft: buildMemoryDraft({ ...baseState, activeStepIndex, activeStep, stepLogs })
  };
}

export function recordStepAction(stepLogs, step, action) {
  const nextLogs = { ...stepLogs };
  const status =
    action === "完成" || action.startsWith("RPE")
      ? "completed"
      : action === "过重"
        ? "tooHeavy"
        : action === "跳过"
          ? "skipped"
          : "pending";

  const notes = {
    completed: `${step.exerciseName} 已完成，按目标 RPE 控制。`,
    tooHeavy: `${step.exerciseName} 标记过重，下次建议降负或减量。`,
    skipped: `${step.exerciseName} 已跳过，作为安全保护选择记录。`,
    pending: "等待 Apple Watch 反馈"
  };

  nextLogs[step.id] = {
    status,
    note: notes[status],
    rpe: status === "completed" ? step.rpeCap : null
  };

  return nextLogs;
}

export function buildWorkoutResult(state) {
  const execution = deriveExecutionState(state);
  const { quest, readiness } = execution;
  const summary = execution.executionSummary;
  const averageRpeText = summary.averageRpe ? `平均 RPE ${summary.averageRpe}` : "尚无完成动作的 RPE";
  const safetyFeedback = summary.hasLoadIssue
    ? "已记录过重信号，下次训练建议降低负荷或减少组数，优先保证动作质量与安全。"
    : readiness.color === "Red"
      ? "今天保持保守恢复节奏，避免用高强度补偿疲劳。"
      : summary.hasSkippedStep
        ? "跳过动作被记录为安全选择，训练结算仍保留。"
        : "本次记录未出现明显安全警报。";
  const nextRecommendation = summary.hasLoadIssue
    ? "下一次从更低重量开始，先完成稳定动作再考虑进阶。"
    : readiness.color === "Green"
      ? "若明日恢复仍稳定，可保留一个小幅进阶点。"
      : readiness.color === "Yellow"
        ? "下一次继续观察 HRV 与静息心率，优先技术质量。"
        : "下一次先确认睡眠和酸痛恢复，再决定是否回到训练主线。";
  const storyOutcome =
    readiness.color === "Green" ? "主线推进" : readiness.color === "Yellow" ? "章节校准" : "营地恢复";

  return {
    status: "任务完成",
    summary: `${quest.questTitle} 已记录 ${summary.recordedCount}/${summary.totalCount} 项，${averageRpeText}。${quest.storyNode.node} 进入${storyOutcome}结算。`,
    safetyFeedback,
    nextRecommendation
  };
}

export function buildMemoryDraft(state) {
  const steps = state.quest.watchPayload.steps;
  const logs = state.stepLogs ?? createInitialStepLogs(steps);
  const completed = steps
    .filter((step) => logs[step.id]?.status === "completed")
    .map((step) => step.exerciseName);
  const tooHeavy = steps
    .filter((step) => logs[step.id]?.status === "tooHeavy")
    .map((step) => step.exerciseName);
  const skipped = steps
    .filter((step) => logs[step.id]?.status === "skipped")
    .map((step) => step.exerciseName);

  return [
    `日期：${state.summary.date}`,
    `任务：${state.quest.questTitle} / ${state.quest.workoutFocus}`,
    `状态：${state.readiness.color} ${state.readiness.score}，${state.readiness.recommendedTrainingMode}`,
    `完成：${completed.length ? completed.join("、") : "暂无"}`,
    `过重：${tooHeavy.length ? tooHeavy.join("、") : "无"}`,
    `跳过：${skipped.length ? skipped.join("、") : "无"}`,
    `建议：${tooHeavy.length ? "下次降低负荷或减少组数" : "继续按恢复状态调整任务"}`
  ].join("\n");
}

export function getStatusLabel(status) {
  return statusLabels[status] ?? status;
}
