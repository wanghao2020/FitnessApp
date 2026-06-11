import Foundation
import FitnessRPGCore
#if canImport(LiteRTLM) && FITNESSRPG_ENABLE_LITERTLM
import LiteRTLM
#endif

protocol GemmaLocalModelAdapting: Sendable {
    var isAvailable: Bool { get }

    func generateText(for context: ModelRuntimeContext) async throws -> String
}

struct GemmaLocalModelAdapter: GemmaLocalModelAdapting, @unchecked Sendable {
    let bundle: Bundle
    let fileManager: FileManager
    let profile: ModelRuntimeResourceProfile
    let maximumTokenCount: Int

    init(
        bundle: Bundle = .main,
        fileManager: FileManager = .default,
        profile: ModelRuntimeResourceProfile = ModelRuntimeResourceCatalog.gemmaE2B,
        maximumTokenCount: Int = 512
    ) {
        self.bundle = bundle
        self.fileManager = fileManager
        self.profile = profile
        self.maximumTokenCount = max(1, maximumTokenCount)
    }

    var isAvailable: Bool {
        #if canImport(LiteRTLM) && FITNESSRPG_ENABLE_LITERTLM
        return modelResourceURL != nil
        #else
        return false
        #endif
    }

    func generateText(for context: ModelRuntimeContext) async throws -> String {
        guard let modelResourceURL else {
            throw GemmaLocalModelAdapterError.modelResourceMissing(modelResourceFileName)
        }

        #if canImport(LiteRTLM) && FITNESSRPG_ENABLE_LITERTLM
        return try await LiteRTLMGemmaTextGenerator.generateText(
            modelURL: modelResourceURL,
            context: context,
            maximumTokenCount: maximumTokenCount
        )
        #else
        throw GemmaLocalModelAdapterError.sdkNotLinked
        #endif
    }

    private var modelResourceFileName: String {
        profile.requirements.first { $0.kind == .model }?.fileName ?? profile.requirements.first?.fileName ?? ""
    }

    private var modelResourceURL: URL? {
        guard !modelResourceFileName.isEmpty else {
            return nil
        }

        if let resourceURL = bundle.resourceURL?.appendingPathComponent(modelResourceFileName),
           fileManager.fileExists(atPath: resourceURL.path) {
            return resourceURL
        }

        let path = modelResourceFileName as NSString
        let resourceName = path.deletingPathExtension
        let resourceExtension = path.pathExtension
        return bundle.url(
            forResource: resourceName,
            withExtension: resourceExtension.isEmpty ? nil : resourceExtension
        )
    }
}

enum GemmaLocalModelAdapterError: Error, Equatable, LocalizedError, Sendable {
    case sdkNotLinked
    case modelResourceMissing(String)

    var errorDescription: String? {
        switch self {
        case .sdkNotLinked:
            return "LiteRT/Gemma SDK 尚未接入"
        case let .modelResourceMissing(fileName):
            return "缺少 LiteRT-LM 模型包：\(fileName)"
        }
    }
}

#if canImport(LiteRTLM) && FITNESSRPG_ENABLE_LITERTLM
private enum LiteRTLMGemmaTextGenerator {
    static func generateText(
        modelURL: URL,
        context: ModelRuntimeContext,
        maximumTokenCount: Int
    ) async throws -> String {
        let prompt = ModelRuntimePromptFormatter.prompt(for: context)
        let engineConfig = EngineConfig(
            modelPath: modelURL.path,
            backend: .gpu,
            maxNumTokens: maximumTokenCount,
            cacheDir: NSTemporaryDirectory()
        )
        let engine = Engine(engineConfig: engineConfig)
        try await engine.initialize()
        let conversationConfig = ConversationConfig(systemMessage: Message(prompt.systemInstruction))
        let conversation = try await engine.createConversation(with: conversationConfig)
        let response = try await conversation.sendMessage(Message(prompt.userMessage))
        return response.toString
    }
}
#endif

#if DEBUG
struct DebugGemmaLocalModelAdapter: GemmaLocalModelAdapting {
    let mode: ModelRuntimeDebugFixtureMode

    var isAvailable: Bool {
        true
    }

    func generateText(for context: ModelRuntimeContext) async throws -> String {
        switch mode {
        case .ready:
            if context.questTitle == "周训练总结" {
                return """
                {
                  "title": "Fixture 周回顾润色",
                  "body": "本周训练节奏已经记录清楚，下周继续按确定性计划推进，并保留安全边界。",
                  "nextAction": "查看下周计划"
                }
                """
            }

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
