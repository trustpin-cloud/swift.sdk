import Foundation

/// Disclosure-minimising helpers for log lines.
///
/// The sample is read by integrators copy-pasting patterns into their own apps,
/// so the rule is: never put a raw identifier, secret, or certificate body into
/// a log line. Use these helpers at every level — `.debug` is louder than
/// `.info`, not less safe.
internal enum LogRedaction {
    /// `fb52418e-b5ae-4bff-b973-6da9ae07ba00` → `fb52418e…`
    internal static func identifier(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 9 else { return "…" }
        return "\(trimmed.prefix(8))…"
    }

    /// Length-only summary for opaque secrets like base64-encoded public keys.
    internal static func secret(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return "<redacted, \(trimmed.count) chars>"
    }

    /// `ab12cd34ef56…7890abcd` → `ab12cd34…abcd` — keeps enough entropy at the
    /// ends for spot-checking against a known-good value without disclosing the
    /// full digest.
    internal static func fingerprint(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 12 else { return trimmed }
        return "\(trimmed.prefix(8))…\(trimmed.suffix(4))"
    }

    /// Counts characters and lines so PEM bodies never appear verbatim in logs.
    /// Integrators who need the raw PEM should consume `CertificateInfo` from
    /// the use case directly and present it in a dedicated copy-friendly UI —
    /// the application log is not the right surface for cryptographic material.
    internal static func pemSummary(_ pem: String) -> String {
        let lines = pem.split(whereSeparator: \.isNewline).count
        return "<PEM, \(pem.count) chars, \(lines) lines>"
    }

    /// `https://api.example.com/v1/health?token=xyz` → `https://api.example.com`
    internal static func hostOnly(_ url: URL) -> String {
        guard let scheme = url.scheme, let host = url.host else { return "<invalid url>" }
        if let port = url.port { return "\(scheme)://\(host):\(port)" }
        return "\(scheme)://\(host)"
    }

    /// Drops the query string and fragment but retains scheme/host/path, so
    /// the request target is identifiable for debugging without leaking tokens
    /// embedded in query parameters.
    internal static func pathOnly(_ url: URL) -> String {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.query = nil
        components?.fragment = nil
        return components?.string ?? hostOnly(url)
    }
}
