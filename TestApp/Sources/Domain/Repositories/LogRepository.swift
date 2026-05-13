import Combine
import Foundation

protocol LogRepository: AnyObject, Sendable {
    var logsPublisher: AnyPublisher<[LogEntry], Never> { get }
    func append(_ message: String, level: LogLevel)
    func clear()
}
