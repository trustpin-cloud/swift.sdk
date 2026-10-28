import Alamofire
import Foundation
import TrustPinKit

/// An Alamofire redirect handler that removes a TrustPin instance's
/// attestation headers from a redirected request and adds the ones supplied
/// for the new destination, so they never follow a redirect unchecked.
/// Install it next to ``TrustPinAttestationAdapter``:
///
/// ```swift
/// let session = Session(
///     interceptor: Interceptor(adapters: [TrustPinAttestationAdapter()]),
///     serverTrustManager: ServerTrustManager(evaluators: [
///         "api.example.com": TrustPinServerTrustEvaluating()
///     ]),
///     redirectHandler: TrustPinAttestationRedirectHandler()
/// )
/// ```
///
/// Built exclusively on public SDK API
/// (``TrustPinKit/TrustPin/redirectedRequest(_:)``).
public struct TrustPinAttestationRedirectHandler: RedirectHandler {

    private let instance: TrustPin

    /// Creates a redirect handler bound to a TrustPin instance.
    ///
    /// - Parameter instance: The instance whose attestation provider supplies
    ///   the headers. Defaults to ``TrustPinKit/TrustPin/default``.
    public init(instance: TrustPin = .default) {
        self.instance = instance
    }

    public func task(
        _ task: URLSessionTask,
        willBeRedirectedTo request: URLRequest,
        for response: HTTPURLResponse,
        completion: @escaping (URLRequest?) -> Void
    ) {
        let instance = self.instance
        let reply = Completion(completion)
        Task { reply.call(await instance.redirectedRequest(request)) }
    }

    /// Carries Alamofire's non-`@Sendable` completion into the task.
    /// `@unchecked Sendable`: the closure is called exactly once, from that
    /// task, and never stored elsewhere (R-013-6).
    private final class Completion: @unchecked Sendable {
        private let body: (URLRequest?) -> Void
        init(_ body: @escaping (URLRequest?) -> Void) { self.body = body }
        func call(_ request: URLRequest?) { body(request) }
    }
}
