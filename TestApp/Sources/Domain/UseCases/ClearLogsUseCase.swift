import Foundation

struct ClearLogsUseCase: Sendable {
    let logRepository: LogRepository

    func callAsFunction() {
        logRepository.clear()
        logRepository.append("Welcome to TrustPin iOS Sample", level: .info)
        logRepository.append("Configure TrustPin and test connections...", level: .info)
        logRepository.append("🧹 Log cleared", level: .info)
    }
}
