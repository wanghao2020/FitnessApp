import Foundation

public enum ModelRuntimeResourceKind: String, Codable, Equatable, Sendable {
    case model
    case tokenizer
    case config
    case other
}

public enum ModelRuntimeResourceState: String, Codable, Equatable, Sendable {
    case ready
    case missing
    case invalid
}

public struct ModelRuntimeResourceRequirement: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let displayName: String
    public let kind: ModelRuntimeResourceKind
    public let fileName: String
    public let minimumByteSize: Int

    public init(
        id: String,
        displayName: String,
        kind: ModelRuntimeResourceKind,
        fileName: String,
        minimumByteSize: Int
    ) {
        self.id = id
        self.displayName = displayName
        self.kind = kind
        self.fileName = fileName
        self.minimumByteSize = max(0, minimumByteSize)
    }
}

public struct ModelRuntimeResourceObservation: Codable, Equatable, Sendable {
    public let requirementID: String
    public let fileName: String
    public let byteSize: Int

    public init(requirementID: String, fileName: String, byteSize: Int) {
        self.requirementID = requirementID
        self.fileName = fileName
        self.byteSize = max(0, byteSize)
    }
}

public struct ModelRuntimeResourceStatus: Codable, Equatable, Identifiable, Sendable {
    public let requirementID: String
    public let displayName: String
    public let kind: ModelRuntimeResourceKind
    public let fileName: String
    public let state: ModelRuntimeResourceState
    public let detail: String

    public var id: String {
        requirementID
    }

    public init(
        requirementID: String,
        displayName: String,
        kind: ModelRuntimeResourceKind,
        fileName: String,
        state: ModelRuntimeResourceState,
        detail: String
    ) {
        self.requirementID = requirementID
        self.displayName = displayName
        self.kind = kind
        self.fileName = fileName
        self.state = state
        self.detail = detail
    }
}

public struct ModelRuntimeResourcePreflightResult: Codable, Equatable, Sendable {
    public let providerID: String
    public let displayName: String
    public let state: ModelRuntimeProviderState
    public let message: String
    public let statuses: [ModelRuntimeResourceStatus]

    public init(
        providerID: String,
        displayName: String,
        state: ModelRuntimeProviderState,
        message: String,
        statuses: [ModelRuntimeResourceStatus]
    ) {
        self.providerID = providerID
        self.displayName = displayName
        self.state = state
        self.message = message
        self.statuses = statuses
    }
}

public enum ModelRuntimeResourcePreflight {
    public static func evaluate(
        providerID: String,
        displayName: String,
        requirements: [ModelRuntimeResourceRequirement],
        observations: [ModelRuntimeResourceObservation]
    ) -> ModelRuntimeResourcePreflightResult {
        var observationsByID: [String: ModelRuntimeResourceObservation] = [:]
        for observation in observations {
            observationsByID[observation.requirementID] = observation
        }

        let statuses = requirements.map { requirement in
            status(for: requirement, observation: observationsByID[requirement.id])
        }
        let blockingStatus = statuses.first { $0.state != .ready }
        let providerState: ModelRuntimeProviderState = blockingStatus == nil ? .ready : .unavailable
        let message = blockingStatus?.detail ?? "\(statuses.count) 个模型资源就绪"

        return ModelRuntimeResourcePreflightResult(
            providerID: providerID,
            displayName: displayName,
            state: providerState,
            message: message,
            statuses: statuses
        )
    }

    private static func status(
        for requirement: ModelRuntimeResourceRequirement,
        observation: ModelRuntimeResourceObservation?
    ) -> ModelRuntimeResourceStatus {
        guard let observation else {
            return ModelRuntimeResourceStatus(
                requirementID: requirement.id,
                displayName: requirement.displayName,
                kind: requirement.kind,
                fileName: requirement.fileName,
                state: .missing,
                detail: "缺少 \(requirement.displayName)：\(requirement.fileName)"
            )
        }

        guard observation.byteSize >= requirement.minimumByteSize else {
            return ModelRuntimeResourceStatus(
                requirementID: requirement.id,
                displayName: requirement.displayName,
                kind: requirement.kind,
                fileName: observation.fileName,
                state: .invalid,
                detail: "\(requirement.displayName) 文件过小：\(observation.byteSize) / \(requirement.minimumByteSize) bytes"
            )
        }

        return ModelRuntimeResourceStatus(
            requirementID: requirement.id,
            displayName: requirement.displayName,
            kind: requirement.kind,
            fileName: observation.fileName,
            state: .ready,
            detail: "\(requirement.displayName) 已就绪：\(observation.fileName)"
        )
    }
}
