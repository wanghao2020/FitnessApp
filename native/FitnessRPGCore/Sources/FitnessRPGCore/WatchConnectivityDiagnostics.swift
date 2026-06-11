import Foundation

public enum WatchConnectivityActivationState: String, Codable, Equatable, Sendable {
    case notActivated
    case inactive
    case activated
    case unknown

    public var displayLabel: String {
        switch self {
        case .notActivated:
            return "未激活"
        case .inactive:
            return "inactive"
        case .activated:
            return "已激活"
        case .unknown:
            return "未知"
        }
    }
}

public enum WatchConnectivityTransportKind: String, Codable, Equatable, Sendable {
    case message = "sendMessage"
    case userInfo = "transferUserInfo"

    public var displayLabel: String {
        rawValue
    }
}

public struct WatchConnectivityTransferRecord: Codable, Equatable, Sendable {
    public let date: Date
    public let transport: WatchConnectivityTransportKind
    public let detail: String

    public init(date: Date, transport: WatchConnectivityTransportKind, detail: String) {
        self.date = date
        self.transport = transport
        self.detail = detail
    }

    public var summaryLabel: String {
        guard !detail.isEmpty else {
            return transport.displayLabel
        }

        return "\(transport.displayLabel) · \(detail)"
    }
}

public struct WatchConnectivityDiagnosticsRow: Equatable, Identifiable, Sendable {
    public let title: String
    public let value: String
    public let systemImageName: String

    public var id: String {
        title
    }

    public init(title: String, value: String, systemImageName: String) {
        self.title = title
        self.value = value
        self.systemImageName = systemImageName
    }
}

public struct WatchConnectivityDiagnosticsSummary: Equatable, Sendable {
    public let headline: String
    public let detail: String
    public let systemImageName: String
    public let tintName: String
    public let rows: [WatchConnectivityDiagnosticsRow]

    public init(
        headline: String,
        detail: String,
        systemImageName: String,
        tintName: String,
        rows: [WatchConnectivityDiagnosticsRow]
    ) {
        self.headline = headline
        self.detail = detail
        self.systemImageName = systemImageName
        self.tintName = tintName
        self.rows = rows
    }
}

public struct WatchConnectivityDiagnosticsSnapshot: Codable, Equatable, Sendable {
    public let isSupported: Bool
    public let activationState: WatchConnectivityActivationState
    public let isPaired: Bool
    public let isWatchAppInstalled: Bool
    public let isReachable: Bool
    public let lastOutbound: WatchConnectivityTransferRecord?
    public let lastInbound: WatchConnectivityTransferRecord?
    public let lastErrorText: String?

    public init(
        isSupported: Bool,
        activationState: WatchConnectivityActivationState,
        isPaired: Bool,
        isWatchAppInstalled: Bool,
        isReachable: Bool,
        lastOutbound: WatchConnectivityTransferRecord? = nil,
        lastInbound: WatchConnectivityTransferRecord? = nil,
        lastErrorText: String? = nil
    ) {
        self.isSupported = isSupported
        self.activationState = activationState
        self.isPaired = isPaired
        self.isWatchAppInstalled = isWatchAppInstalled
        self.isReachable = isReachable
        self.lastOutbound = lastOutbound
        self.lastInbound = lastInbound
        self.lastErrorText = lastErrorText
    }

    public static let unsupported = WatchConnectivityDiagnosticsSnapshot(
        isSupported: false,
        activationState: .notActivated,
        isPaired: false,
        isWatchAppInstalled: false,
        isReachable: false
    )

    public var summary: WatchConnectivityDiagnosticsSummary {
        let status = statusPresentation
        var rows = [
            WatchConnectivityDiagnosticsRow(
                title: "支持状态",
                value: isSupported ? "可用" : "不可用",
                systemImageName: isSupported ? "iphone" : "iphone.slash"
            ),
            WatchConnectivityDiagnosticsRow(
                title: "激活状态",
                value: activationState.displayLabel,
                systemImageName: "bolt.horizontal.circle"
            ),
            WatchConnectivityDiagnosticsRow(
                title: "配对",
                value: isPaired ? "已配对" : "未配对",
                systemImageName: "applewatch"
            ),
            WatchConnectivityDiagnosticsRow(
                title: "Watch App",
                value: isWatchAppInstalled ? "已安装" : "未安装",
                systemImageName: "app.badge"
            ),
            WatchConnectivityDiagnosticsRow(
                title: "可达性",
                value: isReachable ? "实时可达" : "需要队列",
                systemImageName: "dot.radiowaves.left.and.right"
            ),
            WatchConnectivityDiagnosticsRow(
                title: "最近发送",
                value: lastOutbound?.summaryLabel ?? "暂无",
                systemImageName: "arrow.up.circle.fill"
            ),
            WatchConnectivityDiagnosticsRow(
                title: "最近回传",
                value: lastInbound?.summaryLabel ?? "暂无",
                systemImageName: "arrow.down.circle.fill"
            )
        ]

        if let lastErrorText, !lastErrorText.isEmpty {
            rows.append(WatchConnectivityDiagnosticsRow(
                title: "最近错误",
                value: lastErrorText,
                systemImageName: "exclamationmark.circle"
            ))
        }

        return WatchConnectivityDiagnosticsSummary(
            headline: status.headline,
            detail: status.detail,
            systemImageName: status.systemImageName,
            tintName: status.tintName,
            rows: rows
        )
    }

    private var statusPresentation: (
        headline: String,
        detail: String,
        systemImageName: String,
        tintName: String
    ) {
        guard isSupported else {
            return (
                "WatchConnectivity 不可用",
                "当前设备无法建立 iPhone 与 Apple Watch 的同步会话。",
                "exclamationmark.triangle.fill",
                "orange"
            )
        }

        guard activationState == .activated else {
            return (
                "Watch 会话未激活",
                "等待 WCSession 激活完成；若持续停留，请检查配对状态和最近错误。",
                "bolt.horizontal.circle.fill",
                "orange"
            )
        }

        guard isPaired else {
            return (
                "未检测到配对 Watch",
                "需要已配对的 Apple Watch 才能接收今日任务。",
                "applewatch.slash",
                "orange"
            )
        }

        guard isWatchAppInstalled else {
            return (
                "Watch App 未安装",
                "iPhone 已就绪，但 companion Watch App 尚未安装或尚未被系统识别。",
                "app.badge.checkmark",
                "orange"
            )
        }

        guard isReachable else {
            return (
                "Watch 已就绪，等待实时可达",
                "Watch 暂不在前台或不可实时连接，任务会通过 transferUserInfo 排队。",
                "tray.and.arrow.down.fill",
                "blue"
            )
        }

        return (
            "Watch 可实时发送",
            "会话已激活且 Watch 实时可达，今日任务会优先通过 sendMessage 发送。",
            "applewatch.radiowaves.left.and.right",
            "green"
        )
    }
}
