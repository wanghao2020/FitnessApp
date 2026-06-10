import Foundation

public enum SyncMessageKind: String, Codable, Equatable, Sendable {
    case quest
    case executionLogs
}

public enum SyncPayloadError: Error, Equatable, Sendable {
    case missingEnvelopeData
    case unsupportedSchemaVersion(Int)
    case unexpectedKind(expected: SyncMessageKind, actual: SyncMessageKind)
}

public struct SyncEnvelope: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1
    public static let dictionaryPayloadKey = "fitnessRPGSyncEnvelope"

    public let schemaVersion: Int
    public let kind: SyncMessageKind
    public let encodedAt: Date
    public let payloadData: Data

    public init(
        schemaVersion: Int = SyncEnvelope.currentSchemaVersion,
        kind: SyncMessageKind,
        encodedAt: Date = Date(),
        payloadData: Data
    ) {
        self.schemaVersion = schemaVersion
        self.kind = kind
        self.encodedAt = encodedAt
        self.payloadData = payloadData
    }

    public init<Payload: Encodable>(
        schemaVersion: Int,
        kind: SyncMessageKind,
        encodedAt: Date,
        payload: Payload
    ) throws {
        self.init(
            schemaVersion: schemaVersion,
            kind: kind,
            encodedAt: encodedAt,
            payloadData: try SyncEnvelope.makeEncoder().encode(payload)
        )
    }

    public init<Payload: Encodable>(
        schemaVersion: Int = SyncEnvelope.currentSchemaVersion,
        kind: SyncMessageKind,
        payload: Payload,
        encodedAt: Date = Date()
    ) throws {
        try self.init(
            schemaVersion: schemaVersion,
            kind: kind,
            encodedAt: encodedAt,
            payload: payload
        )
    }

    public func decodePayload<Payload: Decodable>(
        _ type: Payload.Type,
        expectedKind: SyncMessageKind
    ) throws -> Payload {
        guard schemaVersion == SyncEnvelope.currentSchemaVersion else {
            throw SyncPayloadError.unsupportedSchemaVersion(schemaVersion)
        }

        guard kind == expectedKind else {
            throw SyncPayloadError.unexpectedKind(expected: expectedKind, actual: kind)
        }

        return try SyncEnvelope.makeDecoder().decode(Payload.self, from: payloadData)
    }

    public func toDictionary() throws -> [String: Any] {
        [
            SyncEnvelope.dictionaryPayloadKey: try SyncEnvelope.makeEncoder().encode(self)
        ]
    }

    public static func fromDictionary(_ dictionary: [String: Any]) throws -> SyncEnvelope {
        guard let data = dictionary[SyncEnvelope.dictionaryPayloadKey] as? Data else {
            throw SyncPayloadError.missingEnvelopeData
        }

        return try SyncEnvelope.makeDecoder().decode(SyncEnvelope.self, from: data)
    }

    public static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.timeIntervalSince1970)
        }
        return encoder
    }

    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let seconds = try container.decode(Double.self)
            return Date(timeIntervalSince1970: seconds)
        }
        return decoder
    }
}

public struct QuestSyncPayload: Codable, Equatable, Sendable {
    public let quest: DailyQuest
    public let readinessColor: ReadinessColor
    public let generatedAt: Date

    public init(quest: DailyQuest, readinessColor: ReadinessColor, generatedAt: Date = Date()) {
        self.quest = quest
        self.readinessColor = readinessColor
        self.generatedAt = generatedAt
    }
}

public struct ExecutionLogSyncPayload: Codable, Equatable, Sendable {
    public let questTitle: String
    public let logs: [ExecutionLog]
    public let sentAt: Date

    public init(questTitle: String, logs: [ExecutionLog], sentAt: Date = Date()) {
        self.questTitle = questTitle
        self.logs = logs
        self.sentAt = sentAt
    }
}
