import Combine
import Foundation

@MainActor
final class ConnectionTestingViewModel: ObservableObject {
    @Published var testURL: String
    @Published private(set) var isTesting = false
    @Published private(set) var statusMessage = "TrustPin not configured"

    private let testConnection: TestPinnedConnectionUseCase
    private let fetchCertificate: FetchCertificateUseCase
    private let clearLogs: ClearLogsUseCase
    private let logRepository: LogRepository
    private let session: PinningSession
    private var cancellables = Set<AnyCancellable>()

    init(
        testConnection: TestPinnedConnectionUseCase,
        fetchCertificate: FetchCertificateUseCase,
        clearLogs: ClearLogsUseCase,
        logRepository: LogRepository,
        session: PinningSession,
        initialTestURL: String = "" // trustpin:sample-credential
    ) {
        self.testConnection = testConnection
        self.fetchCertificate = fetchCertificate
        self.clearLogs = clearLogs
        self.logRepository = logRepository
        self.session = session
        self.testURL = initialTestURL

        session.$isConfigured
            .map { $0 ? "TrustPin configured" : "TrustPin not configured" }
            .assign(to: \.statusMessage, on: self)
            .store(in: &cancellables)
    }

    var isConfigured: Bool { session.isConfigured }

    var trimmedURL: String {
        testURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isURLEmpty: Bool { trimmedURL.isEmpty }

    func runConnectionTest() {
        guard session.isConfigured else {
            logRepository.append("Test connection failed: TrustPin not configured", level: .warning)
            return
        }
        guard !isURLEmpty else {
            logRepository.append("Test connection failed: No URL provided", level: .warning)
            return
        }
        guard let url = URL(string: trimmedURL) else {
            logRepository.append("Test connection failed: Invalid URL", level: .error)
            return
        }

        Task { @MainActor in
            isTesting = true
            statusMessage = "Testing connection..."
            _ = await testConnection(url: url)
            isTesting = false
            statusMessage = session.isConfigured ? "TrustPin configured" : "TrustPin not configured"
        }
    }

    func runFetchCertificate() {
        guard !isURLEmpty else {
            logRepository.append("Fetch certificate failed: No URL provided", level: .warning)
            return
        }
        guard let url = URL(string: trimmedURL), let host = url.host else {
            logRepository.append("Fetch certificate failed: Invalid URL format", level: .error)
            return
        }
        let port = url.port ?? 443

        Task { @MainActor in
            isTesting = true
            statusMessage = "Fetching certificate..."
            await fetchCertificate(host: host, port: port)
            isTesting = false
            statusMessage = session.isConfigured ? "TrustPin configured" : "TrustPin not configured"
        }
    }

    func clearLog() {
        clearLogs()
    }
}
