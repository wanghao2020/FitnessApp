public struct HealthSignals: Equatable, Sendable {
    public let sleepHours: Double?
    public let hrvSDNN: Double?
    public let restingHeartRate: Double?
    public let restingHeartRateBaseline: Double?
    public let activeEnergyKcal: Double?
    public let exerciseMinutes: Double?
    public let stepCount: Double?
    public let workoutCount: Int?

    public init(
        sleepHours: Double?,
        hrvSDNN: Double?,
        restingHeartRate: Double?,
        restingHeartRateBaseline: Double?,
        activeEnergyKcal: Double?,
        exerciseMinutes: Double?,
        stepCount: Double?,
        workoutCount: Int?
    ) {
        self.sleepHours = sleepHours
        self.hrvSDNN = hrvSDNN
        self.restingHeartRate = restingHeartRate
        self.restingHeartRateBaseline = restingHeartRateBaseline
        self.activeEnergyKcal = activeEnergyKcal
        self.exerciseMinutes = exerciseMinutes
        self.stepCount = stepCount
        self.workoutCount = workoutCount
    }

    public static let missing = HealthSignals(
        sleepHours: nil,
        hrvSDNN: nil,
        restingHeartRate: nil,
        restingHeartRateBaseline: nil,
        activeEnergyKcal: nil,
        exerciseMinutes: nil,
        stepCount: nil,
        workoutCount: nil
    )
}

public enum HealthSummaryMapper {
    public static func summary(from signals: HealthSignals) -> HealthSummary {
        guard hasUsableData(signals) else {
            return MockHealthProfiles.missing
        }

        let sleep = sleepScore(hours: signals.sleepHours)
        let recovery = recoveryScore(
            hrvSDNN: signals.hrvSDNN,
            restingHeartRate: signals.restingHeartRate,
            baseline: signals.restingHeartRateBaseline
        )
        let strain = strainScore(
            activeEnergyKcal: signals.activeEnergyKcal,
            exerciseMinutes: signals.exerciseMinutes,
            stepCount: signals.stepCount,
            workoutCount: signals.workoutCount
        )
        let heartRateTrend = heartRateTrendScore(
            restingHeartRate: signals.restingHeartRate,
            baseline: signals.restingHeartRateBaseline
        )
        let energy = clamp((sleep + recovery + max(0, 100 - strain)) / 3)

        return HealthSummary(
            energy: energy,
            recovery: recovery,
            strain: strain,
            sleep: sleep,
            heartRateTrend: heartRateTrend,
            drivers: drivers(
                sleep: sleep,
                recovery: recovery,
                strain: strain,
                heartRateTrend: heartRateTrend
            )
        )
    }

    private static func hasUsableData(_ signals: HealthSignals) -> Bool {
        let hasSleep = signals.sleepHours != nil
        let hasRecovery = signals.hrvSDNN != nil || signals.restingHeartRate != nil
        let hasStrain = [
            signals.activeEnergyKcal,
            signals.exerciseMinutes,
            signals.stepCount
        ].contains { $0 != nil } || signals.workoutCount != nil

        return hasSleep && hasRecovery && hasStrain
    }

    private static func sleepScore(hours: Double?) -> Int {
        guard let hours else {
            return 55
        }

        if hours < 4.5 {
            return 38
        }

        if hours < 6 {
            return 52
        }

        if hours < 7 {
            return 66
        }

        if hours <= 9 {
            return 88
        }

        return 76
    }

    private static func recoveryScore(
        hrvSDNN: Double?,
        restingHeartRate: Double?,
        baseline: Double?
    ) -> Int {
        var components: [Int] = []

        if let hrvSDNN {
            components.append(clamp(Int((hrvSDNN / 70.0) * 90.0)))
        }

        if let restingHeartRate {
            let trendPenalty = heartRateTrendScore(restingHeartRate: restingHeartRate, baseline: baseline) * 3
            let absolutePenalty = restingHeartRate > 72 ? 18 : 0
            components.append(clamp(86 - trendPenalty - absolutePenalty))
        }

        guard !components.isEmpty else {
            return 55
        }

        return clamp(components.reduce(0, +) / components.count)
    }

    private static func strainScore(
        activeEnergyKcal: Double?,
        exerciseMinutes: Double?,
        stepCount: Double?,
        workoutCount: Int?
    ) -> Int {
        let energyLoad = normalizedLoad(value: activeEnergyKcal, green: 350, red: 900)
        let exerciseLoad = normalizedLoad(value: exerciseMinutes, green: 30, red: 95)
        let stepLoad = normalizedLoad(value: stepCount, green: 8000, red: 17000)
        let workoutLoad = clamp((workoutCount ?? 0) * 18)

        return clamp((energyLoad + exerciseLoad + stepLoad + workoutLoad) / 4)
    }

    private static func normalizedLoad(value: Double?, green: Double, red: Double) -> Int {
        guard let value else {
            return 45
        }

        if value <= green {
            return 45
        }

        if value >= red {
            return 90
        }

        return clamp(45 + Int(((value - green) / (red - green)) * 45.0))
    }

    private static func heartRateTrendScore(restingHeartRate: Double?, baseline: Double?) -> Int {
        guard let restingHeartRate else {
            return 0
        }

        if let baseline {
            return clamp(Int(max(0, restingHeartRate - baseline)), upperBound: 25)
        }

        return clamp(Int(max(0, restingHeartRate - 65) * 1.5), upperBound: 25)
    }

    private static func drivers(
        sleep: Int,
        recovery: Int,
        strain: Int,
        heartRateTrend: Int
    ) -> [String] {
        var result: [String] = []

        result.append(sleep >= 75 ? "睡眠稳定" : "睡眠不足")
        result.append(recovery >= 70 ? "恢复良好" : "恢复偏低")

        if strain > 72 {
            result.append("昨日负荷偏高")
        } else {
            result.append("昨日负荷可控")
        }

        if heartRateTrend >= 12 {
            result.append("心率趋势偏高")
        }

        return result
    }

    private static func clamp(_ value: Int, upperBound: Int = 100) -> Int {
        max(0, min(upperBound, value))
    }
}
