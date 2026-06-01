export const healthScenarios = {
  green: {
    id: "green",
    date: "2026-06-01",
    sleepHours: 7.6,
    hrvTrend: "up",
    restingHeartRateDelta: -2,
    recentLoad: "moderate",
    soreness: "low",
    injuryFlags: ["right shoulder watch"],
    activityContext: "Normal steps yesterday, no late workout."
  },
  yellow: {
    id: "yellow",
    date: "2026-06-01",
    sleepHours: 5.8,
    hrvTrend: "down",
    restingHeartRateDelta: 6,
    recentLoad: "high",
    soreness: "moderate",
    injuryFlags: ["right shoulder watch"],
    activityContext: "Two high-RPE sessions in the last three days."
  },
  red: {
    id: "red",
    date: "2026-06-01",
    sleepHours: 4.9,
    hrvTrend: "down",
    restingHeartRateDelta: 10,
    recentLoad: "very high",
    soreness: "high",
    injuryFlags: ["right shoulder watch", "knee soreness"],
    activityContext: "Poor sleep plus repeated high-RPE training."
  }
};

export const modelModes = [
  {
    id: "local",
    label: "Local Only",
    description: "Use on-device model output only. No health summary leaves the device."
  },
  {
    id: "hybrid",
    label: "Local + Remote Enhancement",
    description: "Use local model by default, with optional remote weekly or story enhancement."
  },
  {
    id: "disabled",
    label: "Remote Disabled",
    description: "Remote APIs are off. Deterministic templates are used if local generation fails."
  }
];
