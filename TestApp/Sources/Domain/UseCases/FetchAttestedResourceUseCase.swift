import Foundation

/// Signs in to the sample API and calls its protected endpoint with the
/// attestation header, then reports what the API saw.
struct FetchAttestedResourceUseCase: Sendable {
    let attestationRepository: AttestationRepository
    let logRepository: LogRepository

    func callAsFunction() async throws -> AttestedCallOutcome {
        logRepository.append("🛡 Calling the protected sample endpoint...", level: .info)
        do {
            let outcome = try await attestationRepository.callProtectedEndpoint()
            if outcome.headerAttached {
                logRepository.append("   TrustPin-Attestation header attached", level: .info)
            } else {
                logRepository.append("   No attestation header available; request sent without it", level: .warning)
            }
            if let summary = outcome.attestationSummary {
                logRepository.append("   API verified: \(summary)", level: .info)
            }
            let succeeded = (200..<300).contains(outcome.statusCode)
            logRepository.append("✅ Protected call answered HTTP \(outcome.statusCode)", level: succeeded ? .success : .warning)
            return outcome
        } catch {
            logRepository.append("❌ Protected call failed: \(error.localizedDescription)", level: .error)
            throw error
        }
    }
}
