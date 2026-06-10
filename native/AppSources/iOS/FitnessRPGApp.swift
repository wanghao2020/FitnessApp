import SwiftUI
import FitnessRPGCore

@main
struct FitnessRPGApp: App {
    @StateObject private var healthViewModel = TodayHealthViewModel()

    var body: some Scene {
        WindowGroup {
            TodayCommandCenterView(
                readiness: healthViewModel.readiness,
                modelMode: .localFirst,
                sourceNote: healthViewModel.sourceNote
            )
            .task {
                await healthViewModel.loadHealthSummary()
            }
        }
    }
}
