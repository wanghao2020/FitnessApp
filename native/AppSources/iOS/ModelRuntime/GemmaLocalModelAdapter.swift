import Foundation
import FitnessRPGCore

protocol GemmaLocalModelAdapting: Sendable {
    var isAvailable: Bool { get }

    func generateText(for context: ModelRuntimeContext) async throws -> String
}

struct GemmaLocalModelAdapter: GemmaLocalModelAdapting {
    let isAvailable: Bool

    init(isAvailable: Bool = false) {
        self.isAvailable = isAvailable
    }

    func generateText(for context: ModelRuntimeContext) async throws -> String {
        throw GemmaLocalModelAdapterError.sdkNotLinked
    }
}

enum GemmaLocalModelAdapterError: Error, Equatable, LocalizedError, Sendable {
    case sdkNotLinked

    var errorDescription: String? {
        switch self {
        case .sdkNotLinked:
            return "LiteRT/Gemma SDK 尚未接入"
        }
    }
}

#if DEBUG
struct DebugGemmaLocalModelAdapter: GemmaLocalModelAdapting {
    let mode: ModelRuntimeDebugFixtureMode

    var isAvailable: Bool {
        true
    }

    func generateText(for context: ModelRuntimeContext) async throws -> String {
        switch mode {
        case .ready:
            return """
            {
              "title": "Fixture 本地建议",
              "body": "保持稳定节奏，按 Watch 步骤完成今日训练。",
              "nextAction": "发送到 Watch"
            }
            """
        case .parsingFailure:
            return "   \n\t"
        case .adapterFailure:
            throw GemmaLocalModelAdapterError.sdkNotLinked
        case .validatorFailure:
            return """
            {
              "title": "Fixture 高强度建议",
              "body": "今天直接冲刺 PR，追求最大重量和力竭。",
              "nextAction": "发送到 Watch"
            }
            """
        }
    }
}
#endif
