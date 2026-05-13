import CryptoKit
import Foundation
import TrustPinKit

final actor TrustPinCertificateRepository: CertificateRepository {
    func fetch(host: String, port: Int) async throws -> CertificateInfo {
        let pem = try await TrustPin.fetchCertificate(host: host, port: port)
        return CertificateInfo(
            host: host,
            port: port,
            pem: pem,
            sha256Fingerprint: Self.sha256Hex(of: pem)
        )
    }

    private static func sha256Hex(of pem: String) -> String {
        guard let data = pem.data(using: .utf8) else { return "" }
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
