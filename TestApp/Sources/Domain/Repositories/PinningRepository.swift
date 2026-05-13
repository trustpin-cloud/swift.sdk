import Foundation

protocol PinningRepository: Sendable {
    func configure(_ configuration: PinningConfiguration) async throws

    /// Loads credentials from a bundled `TrustPin-Info.plist`, configures the SDK
    /// against them, and returns the resulting domain configuration so the UI
    /// can reflect what was loaded.
    func configureFromBundle() async throws -> PinningConfiguration
}
