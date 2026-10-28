import Alamofire
import Foundation
import TrustPinKit

/// An Alamofire request adapter that adds the attestation headers of a
/// TrustPin instance to each request. Requests are never failed by the
/// adapter: when no headers are available they are sent unchanged.
///
/// ```swift
/// let session = Session(
///     interceptor: Interceptor(adapters: [TrustPinAttestationAdapter()]),
///     serverTrustManager: ServerTrustManager(evaluators: [
///         "api.example.com": TrustPinServerTrustEvaluating()
///     ])
/// )
/// ```
///
/// The adapter asks ``TrustPinKit/TrustPin/attestationHeaders(for:)`` for the
/// headers to add and never replaces a header the request already carries.
/// Like ``TrustPinServerTrustEvaluating``, it is built exclusively on public
/// SDK API.
public struct TrustPinAttestationAdapter: RequestAdapter {

    private let instance: TrustPin

    /// Creates an adapter bound to a TrustPin instance.
    ///
    /// - Parameter instance: The instance whose attestation provider supplies
    ///   the headers. Defaults to ``TrustPinKit/TrustPin/default``.
    public init(instance: TrustPin = .default) {
        self.instance = instance
    }

    public func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping @Sendable (Result<URLRequest, any Error>) -> Void
    ) {
        let instance = self.instance
        // `attestationHeaders(for:)` is bounded by the SDK and returns an
        // empty dictionary on every failure path, so this adapter has no
        // `.failure` branch by construction (R-007-9).
        Task {
            let headers = await instance.attestationHeaders(for: urlRequest)
            var request = urlRequest
            for (name, value) in headers where request.value(forHTTPHeaderField: name) == nil {
                request.setValue(value, forHTTPHeaderField: name)
            }
            completion(.success(request))
        }
    }
}
