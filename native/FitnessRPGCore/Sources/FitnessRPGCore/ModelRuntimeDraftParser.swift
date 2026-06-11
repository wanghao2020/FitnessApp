import Foundation

public enum ModelRuntimeDraftParsingError: Error, Equatable, LocalizedError, Sendable {
    case emptyOutput
    case missingBody

    public var errorDescription: String? {
        switch self {
        case .emptyOutput:
            return "模型输出为空"
        case .missingBody:
            return "模型输出缺少正文"
        }
    }
}

public enum ModelRuntimeDraftParser {
    public static let defaultTitle = "本地模型建议"
    public static let defaultNextAction = "发送到 Watch"

    public static func draft(from rawOutput: String) throws -> ModelRuntimeDraft {
        let trimmedOutput = rawOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedOutput.isEmpty else {
            throw ModelRuntimeDraftParsingError.emptyOutput
        }

        if let jsonData = jsonObjectData(in: trimmedOutput),
           let payload = try? JSONDecoder().decode(Payload.self, from: jsonData) {
            return try draft(from: payload)
        }

        return try draftFromPlainText(trimmedOutput)
    }

    private static func draft(from payload: Payload) throws -> ModelRuntimeDraft {
        let body = trimmed(payload.body)
        guard !body.isEmpty else {
            throw ModelRuntimeDraftParsingError.missingBody
        }

        let title = trimmed(payload.title).isEmpty ? defaultTitle : trimmed(payload.title)
        let nextAction = trimmed(payload.nextAction).isEmpty ? defaultNextAction : trimmed(payload.nextAction)

        return ModelRuntimeDraft(
            title: bounded(title, maxLength: 36),
            body: bounded(body, maxLength: 240),
            nextAction: bounded(nextAction, maxLength: 40)
        )
    }

    private static func draftFromPlainText(_ text: String) throws -> ModelRuntimeDraft {
        let body = trimmed(text)
        guard !body.isEmpty else {
            throw ModelRuntimeDraftParsingError.emptyOutput
        }

        return ModelRuntimeDraft(
            title: defaultTitle,
            body: bounded(body, maxLength: 240),
            nextAction: defaultNextAction
        )
    }

    private static func jsonObjectData(in text: String) -> Data? {
        guard
            let start = text.firstIndex(of: "{"),
            let end = text.lastIndex(of: "}"),
            start <= end
        else {
            return nil
        }

        return String(text[start...end]).data(using: .utf8)
    }

    private static func trimmed(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private static func bounded(_ value: String, maxLength: Int) -> String {
        guard value.count > maxLength else {
            return value
        }

        return String(value.prefix(maxLength))
    }

    private struct Payload: Decodable {
        let title: String?
        let body: String?
        let nextAction: String?

        enum CodingKeys: String, CodingKey {
            case title
            case body
            case nextAction
            case nextActionSnakeCase = "next_action"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            title = try container.decodeIfPresent(String.self, forKey: .title)
            body = try container.decodeIfPresent(String.self, forKey: .body)
            nextAction = try container.decodeIfPresent(String.self, forKey: .nextAction)
                ?? container.decodeIfPresent(String.self, forKey: .nextActionSnakeCase)
        }
    }
}
