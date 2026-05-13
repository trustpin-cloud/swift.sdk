import Foundation

/// Loads credentials from `TrustPin-Info.plist` and runs the same configuration
/// pipeline as the manual path. Mirrors ``ConfigurePinningUseCase`` so that the
/// two entry points stay symmetric in logging and error handling.
struct ConfigureFromBundleUseCase: Sendable {
    let pinningRepository: PinningRepository
    let logRepository: LogRepository

    func callAsFunction() async throws -> PinningConfiguration {
        logRepository.append("⚙️ Loading TrustPin-Info.plist from bundle...", level: .info)

        do {
            let configuration = try await pinningRepository.configureFromBundle()

            logRepository.append("   Organization ID: \(LogRedaction.identifier(configuration.organizationId))", level: .debug)
            logRepository.append("   Project ID: \(LogRedaction.identifier(configuration.projectId))", level: .debug)
            logRepository.append("   Public Key: \(LogRedaction.secret(configuration.publicKey))", level: .debug)
            logRepository.append("   Mode: \(configuration.mode == .strict ? "Strict" : "Permissive")", level: .info)
            logRepository.append("✅ TrustPin configured from TrustPin-Info.plist", level: .success)

            return configuration
        } catch {
            logRepository.append("❌ Failed to configure from TrustPin-Info.plist: \(error.localizedDescription)", level: .error)
            throw error
        }
    }
}
