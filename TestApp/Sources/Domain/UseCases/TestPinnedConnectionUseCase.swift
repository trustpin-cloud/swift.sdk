import Foundation

struct TestPinnedConnectionUseCase: Sendable {
    let networkRepository: PinnedNetworkRepository
    let logRepository: LogRepository

    @discardableResult
    func callAsFunction(url: URL) async -> ConnectionTestOutcome {
        // Pin validation happens inside the TLS handshake, so a plain-HTTP
        // request would never be pin-checked at all. Reject it here instead of
        // logging a "validated" success for a connection TrustPin never saw.
        guard url.scheme?.lowercased() == "https" else {
            logRepository.append(
                "❌ Test rejected: only https:// URLs are pin-validated — plain HTTP performs no TLS handshake, so TrustPin never sees the connection.",
                level: .error
            )
            return ConnectionTestOutcome(success: false, error: URLError(.unsupportedURL))
        }

        logRepository.append("🌐 Testing connection to: \(LogRedaction.hostOnly(url))", level: .info)
        logRepository.append("   Method: GET", level: .debug)
        logRepository.append("   URL: \(LogRedaction.pathOnly(url))", level: .debug)
        logRepository.append("   User-Agent: TrustPin-iOS-Sample/1.0", level: .debug)
        logRepository.append("🔒 Using TrustPin SSL certificate validation", level: .info)

        let outcome = await networkRepository.get(url: url)
        if outcome.success {
            logRepository.append("✅ Connection test successful!", level: .success)
            if let statusCode = outcome.statusCode {
                logRepository.append("   Status: \(statusCode)", level: .debug)
            }
            if let preview = outcome.responsePreview {
                logRepository.append("   Response preview: \(preview)", level: .debug)
            }
        } else if let error = outcome.error {
            logRepository.append("❌ Connection failed: \(error.localizedDescription)", level: .error)
        }
        return outcome
    }
}
