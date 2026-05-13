import Combine
import Foundation

@MainActor
final class LogsViewModel: ObservableObject {
    @Published private(set) var logs: [LogEntry] = []

    private var cancellables = Set<AnyCancellable>()

    init(logRepository: LogRepository) {
        logRepository.logsPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.logs, on: self)
            .store(in: &cancellables)
    }

    var formattedLogs: String {
        logs.map { $0.formattedMessage }.joined(separator: "\n")
    }
}
