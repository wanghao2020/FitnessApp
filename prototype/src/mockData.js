export const healthScenarios = {
  green: {
    id: "green",
    label: "绿",
    statusLabel: "共振稳定",
    date: "2026-06-01",
    sleepHours: 7.6,
    hrvTrend: "up",
    restingHeartRateDelta: -2,
    recentLoad: "moderate",
    soreness: "low",
    injuryFlags: ["右肩持续观察"],
    activityContext: "昨日步数正常，没有夜间高强度训练。"
  },
  yellow: {
    id: "yellow",
    label: "黄",
    statusLabel: "共振偏移",
    date: "2026-06-01",
    sleepHours: 5.8,
    hrvTrend: "down",
    restingHeartRateDelta: 6,
    recentLoad: "high",
    soreness: "moderate",
    injuryFlags: ["右肩持续观察"],
    activityContext: "过去三天内有两次高 RPE 训练。"
  },
  red: {
    id: "red",
    label: "红",
    statusLabel: "营火修复",
    date: "2026-06-01",
    sleepHours: 4.9,
    hrvTrend: "down",
    restingHeartRateDelta: 10,
    recentLoad: "very high",
    soreness: "high",
    injuryFlags: ["右肩持续观察", "膝部酸痛"],
    activityContext: "睡眠不足叠加连续高 RPE 训练。"
  }
};

export const modelModes = [
  {
    id: "local",
    label: "本地优先",
    description: "仅使用设备端模型与确定性模板，健康摘要不离开设备。"
  },
  {
    id: "hybrid",
    label: "本地 + 远程增强",
    description: "日常判断以本地模型为主，周报或剧情润色可按需使用远程增强。"
  },
  {
    id: "disabled",
    label: "禁用远程",
    description: "关闭远程 API。本地生成失败时，回退到固定规则与模板。"
  }
];
