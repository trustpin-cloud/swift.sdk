import Foundation
import Combine

protocol LoggingServiceProtocol {
    var logs: AnyPublisher<[LogEntry], Never> { get }
    func log(_ message: String, level: LogLevel)
    func clear()
}

final class LoggingService: LoggingServiceProtocol {
    private let logsSubject = CurrentValueSubject<[LogEntry], Never>([])
    
    var logs: AnyPublisher<[LogEntry], Never> {
        logsSubject.eraseToAnyPublisher()
    }
    
    init() {
        log("TrustPin iOS Sample started", level: .info)
    }
    
    func log(_ message: String, level: LogLevel) {
        let entry = LogEntry(message: message, level: level, timestamp: Date())
        var currentLogs = logsSubject.value
        currentLogs.append(entry)
        logsSubject.send(currentLogs)
    }
    
    func clear() {
        logsSubject.send([])
        log("Log cleared", level: .info)
    }
}