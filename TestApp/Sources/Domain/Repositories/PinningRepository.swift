import Foundation

protocol PinningRepository: Sendable {
    /// `true` when the app bundle ships a non-empty `TrustPin-Seed.b64`. Both
    /// configuration paths hand it to the SDK as the embedded configuration
    /// so the cold-start fallback can be exercised (airplane mode + first
    /// launch).
    var embeddedSeedAvailable: Bool { get }

    func configure(_ configuration: PinningConfiguration) async throws

    /// Loads credentials from a bundled `TrustPin-Info.plist`, configures the SDK
    /// against them, and returns the resulting domain configuration so the UI
    /// can reflect what was loaded.
    func configureFromBundle() async throws -> PinningConfiguration
}
