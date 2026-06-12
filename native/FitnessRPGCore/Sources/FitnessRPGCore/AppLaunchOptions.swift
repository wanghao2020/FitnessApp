public enum AppLaunchDestination: Hashable, Sendable {
    case today
    case history
    case latestHistoryDetail
    case memoryReview
}

public enum ModelRuntimeDebugFixtureMode: String, Codable, Equatable, Hashable, Sendable {
    case ready
    case parsingFailure
    case adapterFailure
    case validatorFailure
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
            || opensValidationReportArchive(arguments: arguments)
    }

    public static func opensValidationReportArchive(arguments: [String]) -> Bool {
        arguments.contains("--fitnessrpg-open-validation-report-archive")
    }

    public static func modelRuntimeDebugFixtureMode(arguments: [String]) -> ModelRuntimeDebugFixtureMode? {
        if arguments.contains("--fitnessrpg-model-fixture-adapter-failure") {
            return .adapterFailure
        }

        if arguments.contains("--fitnessrpg-model-fixture-parsing-failure") {
            return .parsingFailure
        }

        if arguments.contains("--fitnessrpg-model-fixture-validator-failure") {
            return .validatorFailure
        }

        return arguments.contains("--fitnessrpg-model-fixture-ready") ? .ready : nil
    }
}
