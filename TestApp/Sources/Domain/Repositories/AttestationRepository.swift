import Foundation

/// Boundary to the attestation SDK and the sample API it protects.
protocol AttestationRepository: Sendable {
    /// Current state, synchronous.
    var status: AttestationStatus { get }
    /// Installs the one listener the sample uses.
    func observeStatus(_ listener: @escaping @Sendable (AttestationStatus) -> Void)
    /// `TrustPinAttest.setup(.fromPlist())` on the default instance, then a prefetch.
    func setUpFromBundle() async throws
    /// Signs in to the sample API, binds tokens to the session and calls the
    /// protected endpoint with the attestation header attached.
    func callProtectedEndpoint() async throws -> AttestedCallOutcome
    /// `TrustPinAttest.reset()`: the next call attests a new key.
    func reset() async
    /// Forgets the API session: the next protected call signs in again and its
    /// new `Authorization` value re-binds the token.
    func signOut()
}
