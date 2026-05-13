import Foundation
import TrustPinKit

final actor TrustPinConfigurationRepository: PinningRepository {
    func configure(_ configuration: PinningConfiguration) async throws {
        TrustPin.set(logLevel: .info)

        let sdkConfiguration = TrustPinKit.TrustPinConfiguration(
            organizationId: configuration.organizationId,
            projectId: configuration.projectId,
            publicKey: configuration.publicKey,
            mode: configuration.mode
        )
        try await TrustPin.setup(sdkConfiguration)
    }

    func configureFromBundle() async throws -> PinningConfiguration {
        TrustPin.set(logLevel: .info)

        let sdkConfiguration = try TrustPinKit.TrustPinConfiguration.fromPlist()
        try await TrustPin.setup(sdkConfiguration)

        return PinningConfiguration(
            organizationId: sdkConfiguration.organizationId,
            projectId: sdkConfiguration.projectId,
            publicKey: sdkConfiguration.publicKey,
            mode: sdkConfiguration.mode
        )
    }
}
