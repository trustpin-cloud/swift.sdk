import Foundation

/// Discards the attested key; the next call attests a new one (a sign-out
/// flow that wants a fresh token subject).
struct ResetAttestationUseCase: Sendable {
    let attestationRepository: AttestationRepository
    let logRepository: LogRepository

    func callAsFunction() async {
        await attestationRepository.reset()
        logRepository.append("🛡 Attestation reset: the next call attests a new key", level: .info)
    }
}
