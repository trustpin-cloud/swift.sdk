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
    /// Signs in, then calls the sample API's sensitive endpoint with the
    /// attestation token and an assertion over the request body (spec 022).
    func callSensitiveEndpoint() async throws -> AttestedCallOutcome
    /// Installs the one event listener the sample uses; each event arrives as
    /// its description (spec 022).
    func observeEvents(_ listener: @escaping @Sendable (String) -> Void)
    /// `TrustPinAttest.reset()`: the next call attests a new key.
    func reset() async
    /// Forgets the API session: the next protected call signs in again and its
    /// new `Authorization` value re-binds the token.
    func signOut()
}
