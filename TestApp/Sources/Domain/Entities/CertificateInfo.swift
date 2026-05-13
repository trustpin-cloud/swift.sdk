import Foundation

struct CertificateInfo: Sendable {
    let host: String
    let port: Int
    let pem: String
    let sha256Fingerprint: String
}
