const modeLabels = {
  local: "本地优先",
  hybrid: "本地 + 远程增强",
  disabled: "禁用远程"
};

function generationPathForMode(modelMode) {
  if (modelMode === "hybrid") {
    return ["规则过滤", "本地模型草稿", "安全校验", "Watch Payload", "远程增强候选"];
  }

  if (modelMode === "disabled") {
    return ["规则过滤", "确定性模板", "安全校验", "Watch Payload"];
  }

  return ["规则过滤", "本地模型草稿", "安全校验", "Watch Payload"];
}

function fallbackPolicyForMode(modelMode) {
  if (modelMode === "hybrid") {
    return "本地生成失败时回退到确定性模板；远程只用于周报或剧情润色，不参与安全关键决策。";
  }

  if (modelMode === "disabled") {
    return "不请求远程。若本地模型不可用，直接使用确定性模板，并保留所有安全边界。";
  }

  return "本地模型不可用时使用确定性模板，确保训练强度、恢复建议和 Watch Payload 仍可生成。";
}

function logLineForExecution(summary) {
  const flags = [];
  if (summary.hasLoadIssue) flags.push("过重");
  if (summary.hasSkippedStep) flags.push("跳过");
  return `训练日志：已记录 ${summary.recordedCount}/${summary.totalCount} 项${flags.length ? `，包含 ${flags.join("、")} 信号` : ""}`;
}

function skillRulesForState(state) {
  const rules = [
    "安全优先：任何降负、跳过或恢复选择都被视为有效进展。",
    `世界状态映射：${state.quest.worldState.label} → ${state.quest.storyNode.node}`,
    "Watch Payload 只输出当前训练可执行动作、RPE 上限和快速反馈。"
  ];

  if (state.readiness.color === "Yellow") {
    rules.push("黄色状态：保持降负和技术质量，不追 PR。");
  }

  if (state.readiness.color === "Red") {
    rules.push("红色状态：恢复保护优先，不生成高强度补偿建议。");
  }

  if (state.executionSummary.hasLoadIssue) {
    rules.push("过重反馈：下一次建议降负或减少组数。");
  }

  return rules;
}

export function buildModelHarness(state, modelMode) {
  const modeLabel = modeLabels[modelMode] ?? modeLabels.local;
  const generationPath = generationPathForMode(modelMode);
  const fallbackPolicy = fallbackPolicyForMode(modelMode);
  const inputContext = [
    `HealthKit：${state.readiness.color} ${state.readiness.score}，${state.readiness.recommendedTrainingMode}`,
    `身体信号：${state.readiness.drivers.join("；")}`,
    `剧情节点：${state.quest.storyNode.chapter} / ${state.quest.storyNode.node}`,
    `今日任务：${state.quest.questTitle}，${state.quest.workoutFocus}`,
    logLineForExecution(state.executionSummary)
  ];
  const skillRules = skillRulesForState(state);
  const promptPreview = [
    "SYSTEM: 你是本地优先 Fitness RPG Coach，训练安全高于剧情表现。",
    `HEALTHKIT_CONTEXT: ${inputContext[0]}`,
    `STORY_CONTEXT: ${state.quest.worldState.label}，${state.quest.storyNode.node}`,
    `SAFETY_CONSTRAINTS: ${state.readiness.restrictions.join("；")}`,
    `EXECUTION_LOG: ${logLineForExecution(state.executionSummary)}`,
    "OUTPUT_REQUIREMENTS: 生成今日任务说明、安全边界、Apple Watch payload、memory 草稿。"
  ].join("\n");

  return {
    modeLabel,
    inputContext,
    skillRules,
    generationPath,
    fallbackPolicy,
    promptPreview
  };
}
