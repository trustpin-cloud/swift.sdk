import Combine
import Foundation

@MainActor
final class LogsViewModel: ObservableObject {
    @Published private(set) var logs: [LogEntry] = []

    private var cancellables = Set<AnyCancellable>()
    private let logRepository: LogRepository

    init(logRepository: LogRepository) {
        self.logRepository = logRepository
        logRepository.logsPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.logs, on: self)
            .store(in: &cancellables)
    }

    func clear() {
        logRepository.clear()
    }

    var formattedLogs: String {
        logs.map { $0.formattedMessage }.joined(separator: "\n")
    }
}
