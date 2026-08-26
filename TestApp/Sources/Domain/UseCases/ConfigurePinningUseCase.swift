import Foundation

struct ConfigurePinningUseCase: Sendable {
    let pinningRepository: PinningRepository
    let logRepository: LogRepository

    func callAsFunction(_ configuration: PinningConfiguration) async throws {
        let sanitized = configuration.sanitized
        guard sanitized.isValid else {
            logRepository.append("❌ Configuration failed: Missing required fields", level: .error)
            throw PinningSetupError.invalidConfiguration
        }

        logRepository.append("⚙️ Configuring TrustPin...", level: .info)
        logRepository.append("   Organization ID: \(LogRedaction.identifier(sanitized.organizationId))", level: .debug)
        logRepository.append("   Project ID: \(LogRedaction.identifier(sanitized.projectId))", level: .debug)
        logRepository.append("   Public Key: \(LogRedaction.secret(sanitized.publicKey))", level: .debug)
        logRepository.append(
            pinningRepository.embeddedSeedAvailable
                ? "   Embedded configuration: TrustPin-Seed.b64 (used only if every online source is unreachable)"
                : "   Embedded configuration: none (TrustPin-Seed.b64 is empty)",
            level: .info
        )

        do {
            try await pinningRepository.configure(sanitized)
            logRepository.append("   Mode: \(sanitized.mode == .strict ? "Strict" : "Permissive")", level: .info)
            logRepository.append("✅ TrustPin configuration successful", level: .success)
        } catch {
            logRepository.append("❌ TrustPin configuration failed: \(error.localizedDescription)", level: .error)
            throw error
        }
    }
}

enum PinningSetupError: LocalizedError {
    case invalidConfiguration

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Invalid TrustPin configuration: Missing required fields"
        }
    }
}
