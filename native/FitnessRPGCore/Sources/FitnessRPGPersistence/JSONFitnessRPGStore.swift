import Foundation
@_exported import FitnessRPGCore

public struct PersistenceLoadResult<Value: Equatable & Sendable>: Equatable, Sendable {
    public let value: Value
    public let warning: String?

    public init(value: Value, warning: String? = nil) {
        self.value = value
        self.warning = warning
    }
}

public final class JSONFitnessRPGStore: @unchecked Sendable {
    public static let currentSchemaVersion = 1

    private let directoryURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(directoryURL: URL, fileManager: FileManager = .default) {
        self.directoryURL = directoryURL
        self.fileManager = fileManager

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .secondsSince1970
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        self.decoder = decoder
    }

    public func loadTrainingDays() -> PersistenceLoadResult<[TrainingDayRecord]> {
        readCollection(filename: "training-days.json", defaultValue: [])
    }

    public func saveTrainingDays(_ records: [TrainingDayRecord]) throws {
        try write(records, filename: "training-days.json")
    }

    public func loadStoryProgression() -> PersistenceLoadResult<StoryProgression> {
        readValue(
            filename: "story-progress.json",
            defaultValue: StoryProgression.initial(updatedAt: Date(timeIntervalSince1970: 0))
        )
    }

    public func saveStoryProgression(_ progression: StoryProgression) throws {
        try write(progression, filename: "story-progress.json")
    }

    public func loadMemoryEntries() -> PersistenceLoadResult<[MemoryEntry]> {
        readCollection(filename: "memory-entries.json", defaultValue: [])
    }

    public func saveMemoryEntries(_ entries: [MemoryEntry]) throws {
        try write(entries, filename: "memory-entries.json")
    }

    public func appendMemoryEntry(_ entry: MemoryEntry) throws {
        var entries = loadMemoryEntries().value
        entries.append(entry)
        try saveMemoryEntries(entries)
    }

    private func readCollection<Element: Codable & Equatable & Sendable>(
        filename: String,
        defaultValue: [Element]
    ) -> PersistenceLoadResult<[Element]> {
        readValue(filename: filename, defaultValue: defaultValue)
    }

    private func readValue<Value: Codable & Equatable & Sendable>(
        filename: String,
        defaultValue: Value
    ) -> PersistenceLoadResult<Value> {
        let url = directoryURL.appendingPathComponent(filename)

        guard fileManager.fileExists(atPath: url.path) else {
            return PersistenceLoadResult(value: defaultValue)
        }

        do {
            let data = try Data(contentsOf: url)
            let document = try decoder.decode(JSONDocument<Value>.self, from: data)
            guard document.schemaVersion == JSONFitnessRPGStore.currentSchemaVersion else {
                return PersistenceLoadResult(
                    value: defaultValue,
                    warning: "\(filename) 使用不支持的 schema version：\(document.schemaVersion)"
                )
            }
            return PersistenceLoadResult(value: document.value)
        } catch {
            return PersistenceLoadResult(
                value: defaultValue,
                warning: "\(filename) 读取失败：\(error.localizedDescription)"
            )
        }
    }

    private func write<Value: Codable & Sendable>(_ value: Value, filename: String) throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let document = JSONDocument(schemaVersion: JSONFitnessRPGStore.currentSchemaVersion, value: value)
        let data = try encoder.encode(document)
        try data.write(to: directoryURL.appendingPathComponent(filename), options: [.atomic])
    }
}

private struct JSONDocument<Value: Codable & Sendable>: Codable, Sendable {
    let schemaVersion: Int
    let value: Value
}
