import Combine
import Foundation

final class InMemoryLogRepository: LogRepository, @unchecked Sendable {
    private let logsSubject = CurrentValueSubject<[LogEntry], Never>([])

    var logsPublisher: AnyPublisher<[LogEntry], Never> {
        logsSubject.eraseToAnyPublisher()
    }

    init() {
        append("TrustPin iOS Sample started", level: .info)
    }

    func append(_ message: String, level: LogLevel) {
        let entry = LogEntry(message: message, level: level, timestamp: Date())
        var current = logsSubject.value
        current.append(entry)
        logsSubject.send(current)
    }

    func clear() {
        logsSubject.send([])
    }
}
