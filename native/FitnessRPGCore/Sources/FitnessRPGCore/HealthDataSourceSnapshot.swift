public enum HealthDataSourceStatus: String, Codable, Equatable, Sendable {
    case loading
    case healthKit
    case unavailable
    case authorizationDenied
    case insufficientData
}

public struct HealthDataSourceActionRow: Codable, Equatable, Identifiable, Sendable {
    public let title: String
    public let value: String
    public let systemImageName: String

    public init(title: String, value: String, systemImageName: String) {
        self.title = title
        self.value = value
        self.systemImageName = systemImageName
    }

    public var id: String {
        "\(title)-\(value)"
    }
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

    public var actionRows: [HealthDataSourceActionRow] {
        switch status {
        case .loading, .healthKit:
            return []
        case .unavailable:
            return [
                HealthDataSourceActionRow(
                    title: "下一步 · 设备",
                    value: "请在真实 iPhone 上运行；Simulator 或部分设备不提供 HealthKit 数据。",
                    systemImageName: "iphone"
                ),
                HealthDataSourceActionRow(
                    title: "当前策略",
                    value: "当前环境继续使用保守黄灯，方便安全调试和演示。",
                    systemImageName: "exclamationmark.triangle.fill"
                )
            ]
        case .authorizationDenied:
            return [
                HealthDataSourceActionRow(
                    title: "下一步 · 权限",
                    value: "打开 iOS 设置 > 健康 > 数据访问与设备 > Fitness RPG，允许读取睡眠、心率和活动。",
                    systemImageName: "checkmark.shield.fill"
                ),
                HealthDataSourceActionRow(
                    title: "当前策略",
                    value: "授权完成前继续使用保守黄灯，不会推进高强度任务。",
                    systemImageName: "exclamationmark.triangle.fill"
                )
            ]
        case .insufficientData:
            return [
                HealthDataSourceActionRow(
                    title: "缺少信号",
                    value: missingSignalText,
                    systemImageName: "waveform.path.ecg"
                ),
                HealthDataSourceActionRow(
                    title: "下一步 · 数据",
                    value: "佩戴 Apple Watch，并确认健康 App 已产生对应睡眠、恢复和活动记录。",
                    systemImageName: "applewatch.watchface"
                ),
                HealthDataSourceActionRow(
                    title: "当前策略",
                    value: "数据补齐前继续使用保守黄灯，避免在信息不足时安排高强度任务。",
                    systemImageName: "exclamationmark.triangle.fill"
                )
            ]
        }
    }

    private var missingSignalText: String {
        guard !missingSignalLabels.isEmpty else {
            return "必要"
        }

        return missingSignalLabels.joined(separator: "、")
    }
}
