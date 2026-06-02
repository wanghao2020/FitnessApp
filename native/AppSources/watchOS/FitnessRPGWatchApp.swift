import SwiftUI
import FitnessRPGCore

@main
struct FitnessRPGWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchExecutionView(
                quest: QuestEngine.quest(
                    for: ReadinessEngine.evaluate(MockHealthProfiles.green),
                    storyNode: "回声训练厅"
                )
            )
        }
    }
}
