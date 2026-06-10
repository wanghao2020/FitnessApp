import Combine
import Foundation
import FitnessRPGCore

@MainActor
final class TodayHealthViewModel: ObservableObject {
    @Published private(set) var healthSummary: HealthSummary
    @Published private(set) var sourceNote: String

    private let provider: HealthKitHealthSummaryProvider

    init(
        provider: HealthKitHealthSummaryProvider = HealthKitHealthSummaryProvider(),
        initialSummary: HealthSummary = MockHealthProfiles.missing
    ) {
        self.provider = provider
        self.healthSummary = initialSummary
        self.sourceNote = "正在读取 HealthKit 数据..."
    }

    var readiness: ReadinessResult {
        ReadinessEngine.evaluate(healthSummary)
    }

    func loadHealthSummary() async {
        sourceNote = "正在读取 HealthKit 数据..."

        let summary = await provider.requestAuthorizationAndLoadSummary()
        healthSummary = summary

        if summary.drivers.contains("HealthKit 数据缺失") {
            sourceNote = "HealthKit 数据缺失，已使用保守黄灯策略。"
        } else {
            sourceNote = "已读取 HealthKit 今日健康摘要。"
        }
    }
}
