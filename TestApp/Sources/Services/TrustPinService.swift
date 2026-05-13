import Foundation
import TrustPinKit

final actor TrustPinService {
    private(set) var isConfigured = false
    
    func configure(_ configuration: TrustPinConfiguration) async throws {
        guard configuration.isValid else {
            throw TrustPinServiceError.invalidConfiguration
        }
        
        setLogLevel(.debug)
        
        let trustPinConfig = TrustPinKit.TrustPinConfiguration(
            organizationId: configuration.organizationId.trimmingCharacters(in: .whitespacesAndNewlines),
            projectId: configuration.projectId.trimmingCharacters(in: .whitespacesAndNewlines),
            publicKey: configuration.publicKey.trimmingCharacters(in: .whitespacesAndNewlines),
            mode: configuration.mode
        )
        try await TrustPin.setup(trustPinConfig)
        
        isConfigured = true
    }
    
    func setLogLevel(_ level: TrustPinLogLevel) {
        TrustPin.set(logLevel: level)
    }
}

enum TrustPinServiceError: LocalizedError {
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Invalid TrustPin configuration: Missing required fields"
        }
    }
}
