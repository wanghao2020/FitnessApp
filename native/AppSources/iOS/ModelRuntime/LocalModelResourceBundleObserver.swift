import Foundation
import FitnessRPGCore

struct LocalModelResourceBundleObserver {
    static let providerID = "gemma-e2b"
    static let displayName = "Gemma E2B Local"

    let bundle: Bundle
    let fileManager: FileManager
    let requirements: [ModelRuntimeResourceRequirement]

    init(
        bundle: Bundle = .main,
        fileManager: FileManager = .default,
        requirements: [ModelRuntimeResourceRequirement] = Self.defaultRequirements
    ) {
        self.bundle = bundle
        self.fileManager = fileManager
        self.requirements = requirements
    }

    var diagnostics: ModelRuntimeProviderDiagnostics {
        let preflight = ModelRuntimeResourcePreflight.evaluate(
            providerID: Self.providerID,
            displayName: Self.displayName,
            requirements: requirements,
            observations: observations
        )

        return ModelRuntimeProviderDiagnostics(
            providerID: Self.providerID,
            displayName: Self.displayName,
            resourceStatus: preflight
        )
    }

    private var observations: [ModelRuntimeResourceObservation] {
        ModelRuntimeResourceObservationBuilder.observations(
            requirements: requirements,
            files: requirements.compactMap(fileSnapshot)
        )
    }

    private func fileSnapshot(for requirement: ModelRuntimeResourceRequirement) -> ModelRuntimeResourceFileSnapshot? {
        guard let url = resourceURL(for: requirement.fileName) else {
            return nil
        }

        let byteSize = fileByteSize(at: url)
        return ModelRuntimeResourceFileSnapshot(fileName: requirement.fileName, byteSize: byteSize)
    }

    private func resourceURL(for fileName: String) -> URL? {
        if let resourceURL = bundle.resourceURL?.appendingPathComponent(fileName),
           fileManager.fileExists(atPath: resourceURL.path) {
            return resourceURL
        }

        let path = fileName as NSString
        let resourceName = path.deletingPathExtension
        let resourceExtension = path.pathExtension
        return bundle.url(
            forResource: resourceName,
            withExtension: resourceExtension.isEmpty ? nil : resourceExtension
        )
    }

    private func fileByteSize(at url: URL) -> Int {
        guard
            let attributes = try? fileManager.attributesOfItem(atPath: url.path),
            let size = attributes[.size] as? NSNumber
        else {
            return 0
        }

        return size.intValue
    }
}

private extension LocalModelResourceBundleObserver {
    static var defaultRequirements: [ModelRuntimeResourceRequirement] {
        [
            ModelRuntimeResourceRequirement(
                id: "model",
                displayName: "Model 文件",
                kind: .model,
                fileName: "gemma-e2b.task",
                minimumByteSize: 1_024
            ),
            ModelRuntimeResourceRequirement(
                id: "tokenizer",
                displayName: "Tokenizer 文件",
                kind: .tokenizer,
                fileName: "tokenizer.model",
                minimumByteSize: 1
            )
        ]
    }
}
