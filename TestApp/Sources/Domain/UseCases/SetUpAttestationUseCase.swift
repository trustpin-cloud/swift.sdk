import Foundation

/// Sets up `TrustPinAttest` from the bundled `TrustPin-Info.plist` after the
/// pinning configuration is in place, and starts the first attestation so the
/// protected call does not wait for it.
struct SetUpAttestationUseCase: Sendable {
    let attestationRepository: AttestationRepository
    let logRepository: LogRepository

    func callAsFunction() async throws {
        logRepository.append("🛡 Setting up TrustPinAttest from TrustPin-Info.plist...", level: .info)
        do {
            try await attestationRepository.setUpFromBundle()
            logRepository.append("✅ TrustPinAttest configured; prefetching a token", level: .success)
        } catch {
            logRepository.append("❌ TrustPinAttest setup failed: \(error.localizedDescription)", level: .error)
            throw error
        }
    }
}
