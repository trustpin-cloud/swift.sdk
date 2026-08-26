import Foundation
import TrustPinKit

final actor TrustPinConfigurationRepository: PinningRepository {

    /// Predefined bundle resource for the embedded (last-resort) configuration.
    /// The repository ships it as an **empty** file so the resource always
    /// exists; drop the signed payload downloaded from the dashboard into it
    /// to exercise the cold-start path. An empty file means "no seed" — the
    /// SDK would reject it at setup, so it is only passed through when it
    /// has content.
    private static let seedResourceName = "TrustPin-Seed"
    private static let seedResourceExtension = "b64"

    nonisolated var embeddedSeedAvailable: Bool { Self.embeddedSeedURL() != nil }

    func configure(_ configuration: PinningConfiguration) async throws {
        TrustPin.set(logLevel: .info)

        let sdkConfiguration = TrustPinKit.TrustPinConfiguration(
            organizationId: configuration.organizationId,
            projectId: configuration.projectId,
            publicKey: configuration.publicKey,
            mode: configuration.mode,
            configurationURL: nil,
            embeddedConfigurationURL: Self.embeddedSeedURL()
        )
        try await TrustPin.setup(sdkConfiguration)
    }

    func configureFromBundle() async throws -> PinningConfiguration {
        TrustPin.set(logLevel: .info)

        var sdkConfiguration = try TrustPinKit.TrustPinConfiguration.fromPlist()
        // The plist deliberately omits `EmbeddedConfigurationFile` (the
        // resource is empty until a real seed is dropped in); attach the seed
        // programmatically when it has content.
        if sdkConfiguration.embeddedConfigurationURL == nil, let seedURL = Self.embeddedSeedURL() {
            sdkConfiguration = TrustPinKit.TrustPinConfiguration(
                organizationId: sdkConfiguration.organizationId,
                projectId: sdkConfiguration.projectId,
                publicKey: sdkConfiguration.publicKey,
                mode: sdkConfiguration.mode,
                configurationURL: sdkConfiguration.configurationURL,
                embeddedConfigurationURL: seedURL
            )
        }
        try await TrustPin.setup(sdkConfiguration)

        return PinningConfiguration(
            organizationId: sdkConfiguration.organizationId,
            projectId: sdkConfiguration.projectId,
            publicKey: sdkConfiguration.publicKey,
            mode: sdkConfiguration.mode
        )
    }

    /// The bundled seed, or `nil` when the resource is missing or empty.
    private static func embeddedSeedURL() -> URL? {
        guard let url = Bundle.main.url(forResource: seedResourceName, withExtension: seedResourceExtension),
              let size = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? Int,
              size > 0 else {
            return nil
        }
        return url
    }
}
