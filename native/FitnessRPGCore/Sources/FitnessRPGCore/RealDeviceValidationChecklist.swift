public enum RealDeviceValidationState: String, Codable, Equatable, Sendable {
    case passed
    case pending
    case needsAction
}

public struct RealDeviceValidationRow: Codable, Equatable, Identifiable, Sendable {
    public let title: String
    public let value: String
    public let state: RealDeviceValidationState
    public let systemImageName: String

    public init(
        title: String,
        value: String,
        state: RealDeviceValidationState,
        systemImageName: String
    ) {
        self.title = title
        self.value = value
        self.state = state
        self.systemImageName = systemImageName
    }

    public var id: String {
        title
    }
}

public struct RealDeviceValidationChecklist: Codable, Equatable, Sendable {
    public let headline: String
    public let detail: String
    public let systemImageName: String
    public let tintName: String
    public let rows: [RealDeviceValidationRow]

    public init(
        headline: String,
        detail: String,
        systemImageName: String,
        tintName: String,
        rows: [RealDeviceValidationRow]
    ) {
        self.headline = headline
        self.detail = detail
        self.systemImageName = systemImageName
        self.tintName = tintName
        self.rows = rows
    }
}

public enum RealDeviceValidationChecklistBuilder {
    public static func summary(
        watch: WatchConnectivityDiagnosticsSnapshot,
        health: HealthDataSourceSnapshot,
        runtime: ModelRuntimeDiagnosticsSummary,
        historyRecordCount: Int,
        hasWeeklyPolishCache: Bool
    ) -> RealDeviceValidationChecklist {
        let rows = [
            watchRow(from: watch),
            healthRow(from: health),
            runtimeRow(from: runtime),
            historyRow(recordCount: historyRecordCount, hasWeeklyPolishCache: hasWeeklyPolishCache)
        ]
        let passedCount = rows.filter { $0.state == .passed }.count
        let presentation = presentation(for: rows, passedCount: passedCount)

        return RealDeviceValidationChecklist(
            headline: presentation.headline,
            detail: "\(passedCount)/\(rows.count) 项已通过。\(presentation.detail)",
            systemImageName: presentation.systemImageName,
            tintName: presentation.tintName,
            rows: rows
        )
    }

    private static func watchRow(from snapshot: WatchConnectivityDiagnosticsSnapshot) -> RealDeviceValidationRow {
        if let lastInbound = snapshot.lastInbound {
            return RealDeviceValidationRow(
                title: "Watch 同步",
                value: "已收到 Watch 回传：\(lastInbound.summaryLabel)。确认 History 已写入。",
                state: .passed,
                systemImageName: "applewatch"
            )
        }

        if let lastOutbound = snapshot.lastOutbound {
            return RealDeviceValidationRow(
                title: "Watch 同步",
                value: "已发送 \(lastOutbound.summaryLabel)，下一步在 Watch 完成步骤并回到 iPhone 查看 History。",
                state: .pending,
                systemImageName: "arrow.down.doc.fill"
            )
        }

        if snapshot.isSupported, snapshot.isPaired, snapshot.isWatchAppInstalled {
            return RealDeviceValidationRow(
                title: "Watch 同步",
                value: "Watch App 已安装，下一步点击 Today 底部发送按钮。",
                state: .pending,
                systemImageName: "paperplane.fill"
            )
        }

        return RealDeviceValidationRow(
            title: "Watch 同步",
            value: "先用真实 iPhone 和已配对 Apple Watch 完成安装检查。",
            state: .needsAction,
            systemImageName: "iphone.and.arrow.forward"
        )
    }

    private static func healthRow(from snapshot: HealthDataSourceSnapshot) -> RealDeviceValidationRow {
        switch snapshot.status {
        case .healthKit:
            return RealDeviceValidationRow(
                title: "HealthKit",
                value: snapshot.sourceNote,
                state: .passed,
                systemImageName: snapshot.systemImageName
            )
        case .loading:
            return RealDeviceValidationRow(
                title: "HealthKit",
                value: "正在读取 HealthKit，等待权限和数据覆盖结果。",
                state: .pending,
                systemImageName: snapshot.systemImageName
            )
        case .unavailable, .authorizationDenied, .insufficientData:
            let action = snapshot.actionRows.first.map { "\($0.title)：\($0.value)" } ?? snapshot.detail
            return RealDeviceValidationRow(
                title: "HealthKit",
                value: action,
                state: .needsAction,
                systemImageName: snapshot.systemImageName
            )
        }
    }

    private static func runtimeRow(from summary: ModelRuntimeDiagnosticsSummary) -> RealDeviceValidationRow {
        if summary.tintName == "green" {
            return RealDeviceValidationRow(
                title: "Runtime",
                value: summary.detail,
                state: .passed,
                systemImageName: summary.systemImageName
            )
        }

        return RealDeviceValidationRow(
            title: "Runtime",
            value: summary.detail,
            state: .needsAction,
            systemImageName: summary.systemImageName
        )
    }

    private static func historyRow(recordCount: Int, hasWeeklyPolishCache: Bool) -> RealDeviceValidationRow {
        guard recordCount > 0 else {
            return RealDeviceValidationRow(
                title: "History 周回顾",
                value: "先完成 Watch 回传生成 History 记录。",
                state: .needsAction,
                systemImageName: "clock.arrow.circlepath"
            )
        }

        guard hasWeeklyPolishCache else {
            return RealDeviceValidationRow(
                title: "History 周回顾",
                value: "已有 \(recordCount) 条 History 记录，下一步生成周回顾润色并验证清除/重新生成。",
                state: .pending,
                systemImageName: "sparkles"
            )
        }

        return RealDeviceValidationRow(
            title: "History 周回顾",
            value: "已有 \(recordCount) 条 History 记录，当前周润色缓存可清除或重新生成。",
            state: .passed,
            systemImageName: "checkmark.circle.fill"
        )
    }

    private static func presentation(
        for rows: [RealDeviceValidationRow],
        passedCount: Int
    ) -> (
        headline: String,
        detail: String,
        systemImageName: String,
        tintName: String
    ) {
        if rows.contains(where: { $0.state == .needsAction }) {
            return (
                "实机验证还有阻塞项",
                "先处理标记为需要操作的检查项。",
                "exclamationmark.triangle.fill",
                "orange"
            )
        }

        if passedCount == rows.count {
            return (
                "实机验证清单已通过",
                "可以继续记录真实设备结果。",
                "checkmark.seal.fill",
                "green"
            )
        }

        return (
            "实机验证正在推进",
            "继续完成待验证检查项。",
            "arrow.triangle.2.circlepath.circle.fill",
            "blue"
        )
    }
}
