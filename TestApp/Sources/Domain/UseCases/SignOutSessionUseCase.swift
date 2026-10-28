import Foundation

/// Discards the sample API session. The next protected call signs in again,
/// and because tokens are bound to the `Authorization` header, the new session
/// value makes the SDK renew the attestation token (binding change).
struct SignOutSessionUseCase: Sendable {
    let attestationRepository: AttestationRepository
    let logRepository: LogRepository

    func callAsFunction() {
        attestationRepository.signOut()
        logRepository.append(
            "🔑 Session discarded: the next protected call signs in again; the new session value re-binds the token (expect a token refresh, not a new key)",
            level: .info
        )
    }
}
