import Foundation
import FitnessRPGCore

struct LocalModelResourceBundleObserver {
    let bundle: Bundle
    let fileManager: FileManager
    let profile: ModelRuntimeResourceProfile

    init(
        bundle: Bundle = .main,
        fileManager: FileManager = .default,
        profile: ModelRuntimeResourceProfile = ModelRuntimeResourceCatalog.gemmaE2B
    ) {
        self.bundle = bundle
        self.fileManager = fileManager
        self.profile = profile
    }

    var provider: ResourceBackedModelDraftProvider {
        ResourceBackedModelDraftProvider(resourceStatus: resourceStatus)
    }

    var diagnostics: ModelRuntimeProviderDiagnostics {
        provider.diagnostics
    }

    private var resourceStatus: ModelRuntimeResourcePreflightResult {
        ModelRuntimeResourcePreflight.evaluate(
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
