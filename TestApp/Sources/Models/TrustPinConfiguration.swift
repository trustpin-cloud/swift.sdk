import Foundation
import TrustPinKit

struct TrustPinConfiguration {
    let organizationId: String
    let projectId: String
    let publicKey: String
    let mode: TrustPinMode
    
    static let `default` = TrustPinConfiguration(
        organizationId: "fb52418e-b5ae-4bff-b973-6da9ae07ba00",
        projectId: "c14cf5c1-9a37-4204-b48e-0bf4c95b28f3",
        publicKey: "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEvYfRJiY51wo1p2fyDt2CqOW6jGxoyZCNJXAEMPw3ZqVcjAZkSBARxWBQlFJ+si8FCReuVplDHFWwXt7nfpFNLw==",
        mode: .strict
    )
    
    var isValid: Bool {
        !organizationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !projectId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !publicKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
