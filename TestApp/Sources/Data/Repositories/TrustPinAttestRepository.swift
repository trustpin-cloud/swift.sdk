import Foundation
import TrustPinAttest
import TrustPinKit

/// `AttestationRepository` over the default `TrustPinAttest` instance and the
/// sample API (`cloud-console-attest-sample-apps/api-mock`): `POST /login`
/// returns a bearer token, `GET /home` requires it and verifies the
/// `TrustPin-Attestation` header, echoing the verified claims.
final class TrustPinAttestRepository: AttestationRepository, @unchecked Sendable {

    // `@unchecked Sendable`: the one mutable property is guarded by `lock`.
    private let lock = NSLock()
    private var sessionToken: String?

    /// The sample API (base URL and demo credentials), read from the bundled
    /// `api-test.plist`. The verifier itself is configured in
    /// `TrustPin-Info.plist`. The published sample ships without the file, so
    /// every value is optional and a protected call then reports
    /// `SampleAPIError.notConfigured`.
    private let sampleAPI = SampleAPIConfiguration.fromBundle()
    private var apiBaseURL: URL? { sampleAPI?.baseURL }

    /// Keys of `api-test.plist`.
    private struct SampleAPIConfiguration: Decodable {
        let APIBaseURL: String
        let Username: String
        let Password: String

        var baseURL: URL? { URL(string: APIBaseURL) }

        static func fromBundle(_ bundle: Bundle = .main) -> SampleAPIConfiguration? {
            guard let url = bundle.url(forResource: "api-test", withExtension: "plist"),
                  let data = try? Data(contentsOf: url) else { return nil }
            return try? PropertyListDecoder().decode(SampleAPIConfiguration.self, from: data)
        }
    }

    private struct LoginResponse: Decodable {
        let token: String
    }

    private struct HomeResponse: Decodable {
        let greeting: String?
        let attestation: HomeAttestation?
    }

    private struct HomeAttestation: Decodable {
        let platform: String
        let env: String
        let result: String
        let reasons: [String]
        let bound: Bool
    }

    var status: AttestationStatus { Self.map(TrustPinAttest.state) }

    func observeStatus(_ listener: @escaping @Sendable (AttestationStatus) -> Void) {
        TrustPinAttest.setStateListener { listener(Self.map($0)) }
    }

    func setUpFromBundle() async throws {
        TrustPinAttest.set(logLevel: .debug)  // the container forwards the lines to the on-screen log
        try await TrustPinAttest.setup(.fromPlist())
        // Tokens follow the session: bind them to the Authorization header the
        // protected calls carry.
        TrustPinAttest.bindToHeader("Authorization")
        TrustPinAttest.prefetch()
    }

    /// The published sample has no API URL until the integrator fills one in.
    enum SampleAPIError: LocalizedError {
        case notConfigured
        var errorDescription: String? { "Sample API is not configured: add api-test.plist (APIBaseURL, Username, Password) to the app bundle" }
    }

    func callProtectedEndpoint() async throws -> AttestedCallOutcome {
        guard let apiBaseURL else { throw SampleAPIError.notConfigured }
        // Pinned session for the sample API (the API host is a registered
        // domain of the sample project).
        let session = URLSession(
            configuration: .ephemeral,
            delegate: TrustPin.makeURLSessionDelegate(),
            delegateQueue: nil
        )
        let token = try await currentSessionToken(session: session)

        var request = URLRequest(url: apiBaseURL.appendingPathComponent("home"))
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        // The direct path: this session uses a pinning delegate, which cannot
        // add headers, so the request asks TrustPinAttest for its header.
        request = await TrustPinAttest.addingAttestation(to: request)
        let headerAttached = request.value(forHTTPHeaderField: TrustPinAttest.headerName) != nil

        let (data, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        if statusCode == 401 {
            lock.withLock { sessionToken = nil }  // session expired; next call signs in again
        }
        let home = try? JSONDecoder().decode(HomeResponse.self, from: data)
        let summary = home?.attestation.map(Self.describe)
        return AttestedCallOutcome(statusCode: statusCode, headerAttached: headerAttached, attestationSummary: summary)
    }

    func reset() async {
        await TrustPinAttest.reset()
    }

    func signOut() {
        lock.withLock { sessionToken = nil }
    }

    // MARK: - Private

    private func currentSessionToken(session: URLSession) async throws -> String {
        if let existing = lock.withLock({ sessionToken }) { return existing }
        guard let apiBaseURL, let sampleAPI else { throw SampleAPIError.notConfigured }
        var request = URLRequest(url: apiBaseURL.appendingPathComponent("login"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["username": sampleAPI.Username, "password": sampleAPI.Password])
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.userAuthenticationRequired)
        }
        let login = try JSONDecoder().decode(LoginResponse.self, from: data)
        lock.withLock { sessionToken = login.token }
        return login.token
    }

    private static func describe(_ attestation: HomeAttestation) -> String {
        var text = "\(attestation.platform)/\(attestation.env) \(attestation.result)"
        if attestation.bound { text += ", bound" }
        if !attestation.reasons.isEmpty { text += " [\(attestation.reasons.joined(separator: ", "))]" }
        return text
    }

    private static func map(_ state: TrustPinAttestState) -> AttestationStatus {
        // The SDK enum is not frozen (library evolution): handle cases a
        // newer framework may add.
        switch state {
        case .unavailable: return .unavailable
        case .attesting: return .attesting
        case .ready(let expiresAt): return .ready(expiresAt: expiresAt)
        case .failed(let error, let retryAt): return .failed(reason: error.localizedDescription, retryAt: retryAt)
        @unknown default: return .unavailable
        }
    }
}
