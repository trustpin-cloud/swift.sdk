import Foundation

protocol CertificateRepository: Sendable {
    func fetch(host: String, port: Int) async throws -> CertificateInfo
}
