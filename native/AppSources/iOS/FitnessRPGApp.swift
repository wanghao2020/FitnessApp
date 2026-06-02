import SwiftUI
import FitnessRPGCore

@main
struct FitnessRPGApp: App {
    var body: some Scene {
        WindowGroup {
            TodayCommandCenterView(
                readiness: ReadinessEngine.evaluate(MockHealthProfiles.green),
                modelMode: .localFirst
            )
        }
    }
}
