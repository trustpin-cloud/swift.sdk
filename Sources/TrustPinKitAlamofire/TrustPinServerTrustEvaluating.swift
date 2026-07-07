import Alamofire
import Foundation
import Security
import TrustPinKit

/// Alamofire `ServerTrustEvaluating` adapter for TrustPinKit.
///
/// Wires TrustPin pinning into an Alamofire `Session` as a one-liner, so the
/// evaluation sequence cannot be assembled incorrectly:
///
/// ```swift
/// let session = Session(serverTrustManager: ServerTrustManager(evaluators: [
///     "api.example.com": TrustPinServerTrustEvaluating()
/// ]))
/// ```
///
/// The evaluator performs the same sequence as the SDK's own
/// `URLSessionDelegate`: OS chain evaluation with an SSL policy bound to the
/// host, then leaf-certificate pin verification through
/// ``TrustPinKit/TrustPin/verify(domain:certificate:timeout:)``. It is built
/// exclusively on public SDK API — this module contains no SDK internals.
///
/// ## Blocking behavior
///
/// `ServerTrustEvaluating.evaluate` is synchronous, so this adapter blocks
/// its calling thread (Alamofire's session delegate queue — never the Swift
/// cooperative pool) while the async verification runs. The wait is bounded
/// by the bridge itself: it parks for at most the SDK's clamped timeout plus
/// a small grace period, then throws ``TrustPinKit/TrustPinErrors/timeout`` —
/// so even a regression in the SDK's own timeout path can never wedge the
/// session delegate queue.
///
/// The first handshake after app launch may include the pinning-configuration
/// fetch inside that window. To keep handshakes fast, await readiness once at
/// startup:
///
/// ```swift
/// try await TrustPin.awaitConfiguration()
/// ```
///
/// ## Cleartext caveat
///
/// Plain `http://` requests never perform a TLS handshake and are never
/// pin-validated. Pair the adapter with App Transport Security (no arbitrary
/// loads) so cleartext traffic cannot bypass pinning.
public struct TrustPinServerTrustEvaluating: ServerTrustEvaluating {

    /// The SDK's documented `verify(timeout:)` clamp bounds. The bridge's
    /// fail-safe deadline must never undercut the SDK's own timeout, or a
    /// caller-supplied sub-minimum timeout (clamped *up* by the SDK) would
    /// make the bridge give up before `verify` resolves.
    private static let sdkMinimumTimeout: TimeInterval = 10
    private static let sdkMaximumTimeout: TimeInterval = 120
    /// Matches the SDK's fallback for non-finite timeout values.
    private static let sdkDefaultTimeout: TimeInterval = 30
    /// Grace beyond the SDK's clamped timeout before the bridge's own
    /// fail-safe fires. Reached only if the SDK's timeout path regresses.
    private static let bridgeGracePeriod: TimeInterval = 5

    private let instance: TrustPin
    private let timeout: TimeInterval

    /// Creates an evaluator bound to a TrustPin instance.
    ///
    /// - Parameters:
    ///   - instance: The pinning context to verify against. Defaults to
    ///     ``TrustPinKit/TrustPin/default``.
    ///   - timeout: Upper bound, in seconds, for one evaluation (clamped into
    ///     the SDK's documented timeout range). Defaults to 30.
    public init(instance: TrustPin = .default, timeout: TimeInterval = 30) {
        self.instance = instance
        self.timeout = timeout
    }

    public func evaluate(_ trust: SecTrust, forHost host: String) throws {
        // 1. OS chain evaluation, hostname-bound — the same coverage the
        //    SDK's own URLSession delegate applies before pinning.
        let policy = SecPolicyCreateSSL(true, host as CFString)
        guard SecTrustSetPolicies(trust, policy) == errSecSuccess else {
            throw TrustPinErrors.invalidServerCert
        }
        var evaluationError: CFError?
        guard SecTrustEvaluateWithError(trust, &evaluationError) else {
            throw TrustPinErrors.invalidServerCert
        }

        // 2. Leaf certificate → PEM.
        guard let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
              let leaf = chain.first else {
            throw TrustPinErrors.invalidServerCert
        }
        let der = SecCertificateCopyData(leaf) as Data
        let pem = "-----BEGIN CERTIFICATE-----\n"
            + der.base64EncodedString(options: [.lineLength64Characters, .endLineWithLineFeed])
            + "\n-----END CERTIFICATE-----"

        // 3. Bridge the synchronous evaluator onto the async verify API.
        //    The verification runs in its own task; this (Alamofire delegate
        //    queue) thread parks on the semaphore. `verify(timeout:)` always
        //    resolves within its clamped timeout, so the bounded wait below
        //    is a fail-safe, not the primary timeout: it protects the
        //    delegate queue from wedging if the SDK's async timeout path
        //    ever regresses. A late signal on the abandoned semaphore is
        //    harmless (the task keeps it alive until after signaling).
        let outcome = OutcomeBox()
        let semaphore = DispatchSemaphore(value: 0)
        let instance = self.instance
        let timeout = self.timeout
        Task.detached {
            do {
                try await instance.verify(domain: host, certificate: pem, timeout: timeout)
                outcome.set(nil)
            } catch {
                outcome.set(error)
            }
            semaphore.signal()
        }

        let requested = timeout.isFinite ? timeout : Self.sdkDefaultTimeout
        let clamped = min(max(requested, Self.sdkMinimumTimeout), Self.sdkMaximumTimeout)
        guard semaphore.wait(timeout: .now() + clamped + Self.bridgeGracePeriod) != .timedOut else {
            throw TrustPinErrors.timeout
        }

        if let error = outcome.take() {
            throw error
        }
    }
}

/// Thread-safe, single-assignment error slot for the sync↔async bridge.
private final class OutcomeBox: @unchecked Sendable {
    private let lock = NSLock()
    private var error: Error?

    func set(_ newError: Error?) {
        lock.lock()
        error = newError
        lock.unlock()
    }

    func take() -> Error? {
        lock.lock()
        defer { lock.unlock() }
        return error
    }
}
