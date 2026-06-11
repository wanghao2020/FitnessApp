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
