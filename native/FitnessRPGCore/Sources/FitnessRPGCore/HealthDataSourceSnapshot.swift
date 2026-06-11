public enum HealthDataSourceStatus: String, Codable, Equatable, Sendable {
    case loading
    case healthKit
    case unavailable
    case authorizationDenied
    case insufficientData
}

public struct HealthDataSourceSnapshot: Codable, Equatable, Sendable {
    public let status: HealthDataSourceStatus
    public let missingSignalLabels: [String]

    public init(status: HealthDataSourceStatus, missingSignalLabels: [String] = []) {
        self.status = status
        self.missingSignalLabels = missingSignalLabels
    }

    public static let loading = HealthDataSourceSnapshot(status: .loading)
    public static let unavailable = HealthDataSourceSnapshot(status: .unavailable)
    public static let authorizationDenied = HealthDataSourceSnapshot(status: .authorizationDenied)
    public static let healthKit = HealthDataSourceSnapshot(status: .healthKit)

    public var sourceNote: String {
        switch status {
        case .loading:
            return "正在读取 HealthKit 数据..."
        case .healthKit:
            return "已读取 HealthKit 今日健康摘要。"
        case .unavailable:
            return "此设备不支持 HealthKit，已使用保守黄灯策略。"
        case .authorizationDenied:
            return "未完成 HealthKit 读取授权，已使用保守黄灯策略。"
        case .insufficientData:
            return "HealthKit \(missingSignalText)数据不足，已使用保守黄灯策略。"
        }
    }

    public var headline: String {
        switch status {
        case .loading:
            return "正在读取 HealthKit"
        case .healthKit:
            return "Apple Health 已接入"
        case .unavailable:
            return "HealthKit 不可用"
        case .authorizationDenied:
            return "HealthKit 权限未完成"
        case .insufficientData:
            return "HealthKit 数据不足"
        }
    }

    public var detail: String {
        switch status {
        case .loading:
            return "正在请求并读取睡眠、恢复和活动信号。"
        case .healthKit:
            return "今日 Readiness 已根据 HealthKit 睡眠、恢复和活动信号生成。"
        case .unavailable:
            return "当前设备或运行环境不提供 HealthKit 数据，系统会继续使用安全的保守黄灯策略。"
        case .authorizationDenied:
            return "可以在 iOS 设置中检查 Fitness RPG 的 HealthKit 读取权限；在完成前系统会继续使用保守黄灯策略。"
        case .insufficientData:
            return "当前缺少\(missingSignalText)信号，Readiness 会暂时使用保守黄灯策略。"
        }
    }

    public var systemImageName: String {
        switch status {
        case .loading:
            return "hourglass"
        case .healthKit:
            return "heart.text.square.fill"
        case .unavailable:
            return "iphone.slash"
        case .authorizationDenied:
            return "lock.shield.fill"
        case .insufficientData:
            return "waveform.path.ecg.rectangle"
        }
    }

    public var tintName: String {
        switch status {
        case .loading:
            return "blue"
        case .healthKit:
            return "green"
        case .unavailable, .authorizationDenied, .insufficientData:
            return "orange"
        }
    }

    public var shouldShowNotice: Bool {
        switch status {
        case .loading, .healthKit:
            return false
        case .unavailable, .authorizationDenied, .insufficientData:
            return true
        }
    }

    private var missingSignalText: String {
        guard !missingSignalLabels.isEmpty else {
            return "必要"
        }

        return missingSignalLabels.joined(separator: "、")
    }
}
