import Combine
import Foundation
import FitnessRPGCore

@MainActor
final class TodayHealthViewModel: ObservableObject {
    @Published private(set) var healthSummary: HealthSummary
    @Published private(set) var sourceNote: String
    @Published private(set) var healthDataSourceSnapshot: HealthDataSourceSnapshot

    private let provider: HealthKitHealthSummaryProvider

    init(
        provider: HealthKitHealthSummaryProvider = HealthKitHealthSummaryProvider(),
        initialSummary: HealthSummary = MockHealthProfiles.missing,
        initialSourceSnapshot: HealthDataSourceSnapshot = .loading
    ) {
        self.provider = provider
        self.healthSummary = initialSummary
        self.healthDataSourceSnapshot = initialSourceSnapshot
        self.sourceNote = initialSourceSnapshot.sourceNote
    }

    var readiness: ReadinessResult {
        ReadinessEngine.evaluate(healthSummary)
    }

    func loadHealthSummary() async {
        healthDataSourceSnapshot = .loading
        sourceNote = healthDataSourceSnapshot.sourceNote

        let result = await provider.requestAuthorizationAndLoadResult()
        healthSummary = result.summary
        healthDataSourceSnapshot = result.sourceSnapshot
        sourceNote = result.sourceSnapshot.sourceNote
    }
}
