import Foundation

/// The attestation state as the sample shows it; mirrors `TrustPinAttestState`
/// without exposing the SDK type to the Presentation layer.
enum AttestationStatus: Equatable, Sendable {
    case notConfigured
    case unavailable
    case attesting
    case ready(expiresAt: Date)
    case failed(reason: String, retryAt: Date)

    var label: String {
        switch self {
        case .notConfigured: return "Attestation not configured"
        case .unavailable: return "No token yet"
        case .attesting: return "Attesting…"
        case .ready(let expiresAt):
            let formatter = DateFormatter()
            formatter.timeStyle = .medium
            return "Token ready until \(formatter.string(from: expiresAt))"
        case .failed(let reason, let retryAt):
            if retryAt == .distantFuture { return "Failed: \(reason) (no automatic retry)" }
            let formatter = DateFormatter()
            formatter.timeStyle = .medium
            return "Failed: \(reason), retry at \(formatter.string(from: retryAt))"
        }
    }

    var isReady: Bool {
        if case .ready = self { return true }
        return false
    }
}

/// What the protected sample API call reported.
struct AttestedCallOutcome: Equatable, Sendable {
    let statusCode: Int
    let headerAttached: Bool
    /// The API's echo of the token it verified (platform, environment,
    /// result, binding), when the response carried one.
    let attestationSummary: String?
}
