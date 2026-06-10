import SwiftUI
import FitnessRPGCore

@main
struct FitnessRPGWatchApp: App {
    @StateObject private var syncModel = WatchQuestSyncModel()

    var body: some Scene {
        WindowGroup {
            WatchExecutionView(syncModel: syncModel)
        }
    }
}
