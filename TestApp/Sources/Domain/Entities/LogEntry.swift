import Foundation

enum LogLevel: Sendable {
    case info
    case success
    case warning
    case error
    case debug

    var icon: String {
        switch self {
        case .info: return "📱"
        case .success: return "✅"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .debug: return "🔍"
        }
    }
}

struct LogEntry: Identifiable, Sendable {
    let id = UUID()
    let message: String
    let level: LogLevel
    let timestamp: Date

    var formattedMessage: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return "[\(formatter.string(from: timestamp))] \(level.icon) \(message)"
    }
}
