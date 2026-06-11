import SwiftUI
import FitnessRPGCore

@main
struct FitnessRPGApp: App {
    @StateObject private var healthViewModel = TodayHealthViewModel()
    @StateObject private var watchSyncModel = WatchQuestSyncModel()
    @StateObject private var persistenceModel = TodayPersistenceModel()

    var body: some Scene {
        WindowGroup {
            TodayCommandCenterView(
                readiness: healthViewModel.readiness,
                modelMode: .localFirst,
                sourceNote: healthViewModel.sourceNote,
                healthDataSourceSnapshot: healthViewModel.healthDataSourceSnapshot,
                watchSyncModel: watchSyncModel,
                persistenceModel: persistenceModel,
                initialDestination: Self.debugInitialDestination,
                showsDiagnostics: Self.debugShowsDiagnostics,
                modelRuntimeFixtureMode: Self.debugModelRuntimeFixtureMode
            )
            .task {
                await healthViewModel.loadHealthSummary()
                persistenceModel.loadOrCreateToday(readiness: healthViewModel.readiness)
                if let record = persistenceModel.todayRecord {
                    watchSyncModel.send(quest: record.quest, readinessColor: record.readiness.color)
                }
            }
        }
    }

    private static var debugInitialDestination: AppLaunchDestination {
        #if DEBUG
        AppLaunchOptions.initialDestination(arguments: ProcessInfo.processInfo.arguments)
        #else
        .today
        #endif
    }

    private static var debugShowsDiagnostics: Bool {
        #if DEBUG
        AppLaunchOptions.showsDiagnostics(arguments: ProcessInfo.processInfo.arguments)
        #else
        false
        #endif
    }

    private static var debugModelRuntimeFixtureMode: ModelRuntimeDebugFixtureMode? {
        #if DEBUG
        AppLaunchOptions.modelRuntimeDebugFixtureMode(arguments: ProcessInfo.processInfo.arguments)
        #else
        nil
        #endif
    }
}
