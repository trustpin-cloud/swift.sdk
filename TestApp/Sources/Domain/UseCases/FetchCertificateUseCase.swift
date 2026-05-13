import Foundation

struct FetchCertificateUseCase: Sendable {
    let certificateRepository: CertificateRepository
    let logRepository: LogRepository

    func callAsFunction(host: String, port: Int) async {
        logRepository.append("🔐 Fetching certificate from: \(host):\(port)", level: .info)
        do {
            let info = try await certificateRepository.fetch(host: host, port: port)
            logRepository.append("✅ Certificate fetched successfully!", level: .success)
            // Fingerprint and PEM are redacted in logs by design — if you need
            // the raw values to configure TrustPin, surface them through a
            // dedicated copy-friendly UI using `CertificateInfo`, not the log.
            logRepository.append("🔑 Certificate SHA256: \(LogRedaction.fingerprint(info.sha256Fingerprint))", level: .info)
            logRepository.append("📜 Certificate body: \(LogRedaction.pemSummary(info.pem))", level: .debug)
        } catch {
            logRepository.append("❌ Failed to fetch certificate: \(error.localizedDescription)", level: .error)
        }
    }
}
