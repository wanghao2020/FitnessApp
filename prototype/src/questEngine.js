const questByColor = {
  Green: {
    questTitle: "破障试炼",
    workoutFocus: "推进训练日",
    intensityBoundary: "正常负荷，可选择一个动作小幅进阶",
    storyFraming: "今日共振稳定。用干净的发力推进主线，不靠硬顶，而靠可重复的胜利。",
    safetyNotes: ["只有热身组顺畅时才进阶", "任何肩部尖锐疼痛都立即停止该动作"],
    worldState: {
      label: "共振稳定",
      detail: "主线节点开放，适合推进 Boss 前置关卡。"
    },
    storyNode: {
      chapter: "第一章 · 回声城门",
      node: "破障试炼",
      npc: "铸星教练：记录一次稳定突破，力量属性获得成长。"
    },
    attributeRewards: [
      { label: "力量", code: "STR", delta: "+8" },
      { label: "体质", code: "CON", delta: "+3" },
      { label: "智识", code: "INT", delta: "+1" }
    ],
    exercises: [
      { name: "卧推", target: "4 x 6", rpeCap: 8, restSeconds: 150 },
      { name: "上斜哑铃推", target: "3 x 10", rpeCap: 8, restSeconds: 120 },
      { name: "绳索划船", target: "3 x 12", rpeCap: 7, restSeconds: 90 }
    ]
  },
  Yellow: {
    questTitle: "深厅校准",
    workoutFocus: "技术修炼日",
    intensityBoundary: "负重降低 10-20%，不进行 PR 尝试",
    storyFraming: "今日共振偏移。我们用节奏、控制和动作质量前进，不用蛮力换风险。",
    safetyNotes: ["RPE 控制在 7 或以下", "使用可控离心节奏", "不追训练量"],
    worldState: {
      label: "共振偏移",
      detail: "阴影核心出现排异，主线改为技术校准节点。"
    },
    storyNode: {
      chapter: "第一章 · 深厅回廊",
      node: "校准符文",
      npc: "巡夜导师：今天的胜利来自控制，而不是重量。"
    },
    attributeRewards: [
      { label: "敏捷", code: "AGI", delta: "+5" },
      { label: "智识", code: "INT", delta: "+4" },
      { label: "体质", code: "CON", delta: "+2" }
    ],
    exercises: [
      { name: "高位下拉", target: "3 x 10", rpeCap: 7, restSeconds: 90 },
      { name: "坐姿划船", target: "3 x 10", rpeCap: 7, restSeconds: 90 },
      { name: "面拉", target: "3 x 15", rpeCap: 6, restSeconds: 60 },
      { name: "二区步行", target: "15 分钟", rpeCap: 5, restSeconds: 0 }
    ]
  },
  Red: {
    questTitle: "营火修复",
    workoutFocus: "恢复任务",
    intensityBoundary: "不安排高强度训练",
    storyFraming: "今日场域过载。恢复不是撤退，而是在保护下一章能继续展开。",
    safetyNotes: ["不进行大重量训练", "保持可鼻呼吸的节奏", "症状加重时停止并休息"],
    worldState: {
      label: "营火修复",
      detail: "补给不足，主线进入恢复章节，休息也会结算经验。"
    },
    storyNode: {
      chapter: "第一章 · 北境营地",
      node: "修复护符",
      npc: "营地医师：把今天守住，就是给明天铺路。"
    },
    attributeRewards: [
      { label: "体质", code: "CON", delta: "+6" },
      { label: "耐力", code: "END", delta: "+2" },
      { label: "智识", code: "INT", delta: "+2" }
    ],
    exercises: [
      { name: "灵活性流动", target: "10 分钟", rpeCap: 3, restSeconds: 0 },
      { name: "轻松步行", target: "20 分钟", rpeCap: 4, restSeconds: 0 },
      { name: "呼吸重置", target: "5 分钟", rpeCap: 2, restSeconds: 0 }
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
    quickActions: ["完成", "过重", "跳过", `RPE≤${exercise.rpeCap}`]
  }));

  return {
    questTitle: base.questTitle,
    readinessColor: readiness.color,
    workoutFocus: base.workoutFocus,
    intensityBoundary: base.intensityBoundary,
    storyFraming: base.storyFraming,
    safetyNotes: base.safetyNotes,
    worldState: base.worldState,
    storyNode: base.storyNode,
    attributeRewards: base.attributeRewards,
    exercises: base.exercises,
    watchPayload: {
      questTitle: base.questTitle,
      currentStep: watchSteps[0],
      steps: watchSteps
    }
  };
}
