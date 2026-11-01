import Foundation

/// Calls the sample API's sensitive endpoint with the attestation token and an
/// assertion over the request body (spec 022), then reports what the API saw.
struct PerformSensitiveOperationUseCase: Sendable {
    let attestationRepository: AttestationRepository
    let logRepository: LogRepository

    func callAsFunction() async throws -> AttestedCallOutcome {
        logRepository.append("🔏 Calling the sensitive sample endpoint (token + assertion)...", level: .info)
        do {
            let outcome = try await attestationRepository.callSensitiveEndpoint()
            if let summary = outcome.attestationSummary {
                logRepository.append("   API verified: \(summary)", level: .info)
            }
            let succeeded = (200..<300).contains(outcome.statusCode)
            logRepository.append("✅ Sensitive call answered HTTP \(outcome.statusCode)", level: succeeded ? .success : .warning)
            return outcome
        } catch {
            logRepository.append("❌ Sensitive call failed: \(error.localizedDescription)", level: .error)
            throw error
        }
    }
}
