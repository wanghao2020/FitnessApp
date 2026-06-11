import Foundation
import FitnessRPGCore

struct LocalModelResourceBundleObserver {
    let bundle: Bundle
    let fileManager: FileManager
    let profile: ModelRuntimeResourceProfile
    let adapter: any GemmaLocalModelAdapting
    let resourceStatusOverride: ModelRuntimeResourcePreflightResult?

    init(
        bundle: Bundle = .main,
        fileManager: FileManager = .default,
        profile: ModelRuntimeResourceProfile = ModelRuntimeResourceCatalog.gemmaE2B,
        adapter: (any GemmaLocalModelAdapting)? = nil,
        resourceStatusOverride: ModelRuntimeResourcePreflightResult? = nil
    ) {
        self.bundle = bundle
        self.fileManager = fileManager
        self.profile = profile
        self.adapter = adapter ?? GemmaLocalModelAdapter(
            bundle: bundle,
            fileManager: fileManager,
            profile: profile
        )
        self.resourceStatusOverride = resourceStatusOverride
    }

    var provider: ResourceBackedModelDraftProvider {
        let adapter = adapter
        let textGenerator: ModelRuntimeTextGenerator?

        if adapter.isAvailable {
            textGenerator = { context in
                try await adapter.generateText(for: context)
            }
        } else {
            textGenerator = nil
        }

        return ResourceBackedModelDraftProvider(
            resourceStatus: resourceStatus,
            optionalTextGenerator: textGenerator
        )
    }

    var diagnostics: ModelRuntimeProviderDiagnostics {
        provider.diagnostics
    }

    private var resourceStatus: ModelRuntimeResourcePreflightResult {
        if let resourceStatusOverride {
            return resourceStatusOverride
        }

        return ModelRuntimeResourcePreflight.evaluate(
            providerID: profile.providerID,
            displayName: profile.displayName,
            requirements: profile.requirements,
            observations: observations
        )
    }

    private var observations: [ModelRuntimeResourceObservation] {
        ModelRuntimeResourceObservationBuilder.observations(
            requirements: profile.requirements,
            files: profile.requirements.compactMap(fileSnapshot)
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

#if DEBUG
extension LocalModelResourceBundleObserver {
    static func debugFixture(mode: ModelRuntimeDebugFixtureMode) -> LocalModelResourceBundleObserver {
        let profile = ModelRuntimeResourceCatalog.gemmaE2B
        let resourceStatus = ModelRuntimeResourcePreflight.evaluate(
            providerID: profile.providerID,
            displayName: profile.displayName,
            requirements: profile.requirements,
            observations: profile.requirements.map { requirement in
                ModelRuntimeResourceObservation(
                    requirementID: requirement.id,
                    fileName: requirement.fileName,
                    byteSize: max(requirement.minimumByteSize, 4_096)
                )
            }
        )

        return LocalModelResourceBundleObserver(
            profile: profile,
            adapter: DebugGemmaLocalModelAdapter(mode: mode),
            resourceStatusOverride: resourceStatus
        )
    }
}
#endif
