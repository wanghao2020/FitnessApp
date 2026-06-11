public enum AppLaunchDestination: Hashable, Sendable {
    case today
    case history
    case latestHistoryDetail
    case memoryReview
}

public enum AppLaunchOptions {
    public static func initialDestination(arguments: [String]) -> AppLaunchDestination {
        if arguments.contains("--fitnessrpg-open-memory-review") {
            return .memoryReview
        }

        if arguments.contains("--fitnessrpg-open-latest-history-detail") {
            return .latestHistoryDetail
        }

        return arguments.contains("--fitnessrpg-open-history")
            ? AppLaunchDestination.history
            : AppLaunchDestination.today
    }

    public static func showsDiagnostics(arguments: [String]) -> Bool {
        arguments.contains("--fitnessrpg-show-diagnostics")
    }
}
