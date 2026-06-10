public enum ReadinessEngine {
    public static func evaluate(_ health: HealthSummary) -> ReadinessResult {
        if health.drivers.contains("HealthKit 数据缺失") {
            return ReadinessResult(
                score: 55,
                color: .yellow,
                title: "共振偏移",
                explanation: "HealthKit 数据缺失，使用保守黄灯策略。",
                safetyGuidance: "降低强度，优先确认身体状态。"
            )
        }

        let score = max(
            0,
            min(
                100,
                (health.energy + health.recovery + health.sleep + (100 - health.strain) + (100 - health.heartRateTrend * 4)) / 5
            )
        )

        if health.recovery < 45 || health.sleep < 50 || health.heartRateTrend >= 12 {
            return ReadinessResult(
                score: score,
                color: .red,
                title: "营火修复",
                explanation: "恢复或睡眠信号不足，今日训练应转为修复。",
                safetyGuidance: "避免高强度训练，恢复也计入成长。"
            )
        }

        if health.energy < 68 || health.recovery < 66 || health.strain > 72 {
            return ReadinessResult(
                score: score,
                color: .yellow,
                title: "共振偏移",
                explanation: "身体可训练但负荷需要下调。",
                safetyGuidance: "降低强度，保持动作质量和可持续完成。"
            )
        }

        return ReadinessResult(
            score: score,
            color: .green,
            title: "共振稳定",
            explanation: "恢复、能量与负荷处在可推进区间。",
            safetyGuidance: "可以执行标准训练，但保留热身和RPE监控。"
        )
    }
}
