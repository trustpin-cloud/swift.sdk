import Foundation
import TrustPinAttest
import TrustPinKit

/// Forwards each framework's log lines into its tab's on-screen log
/// (TrustPinKit → Pinning, TrustPinAttest → Attestation) so the device
/// sign-off (Apple TV, Apple Watch, Vision Pro) needs no console. The default
/// sinks are replaced by this one, so the lines are also printed for Xcode's
/// console.
final class SDKLogForwarder: TrustPinLogSink, TrustPinAttestLogSink {
    private let pinningLog: LogRepository
    private let attestationLog: LogRepository

    init(pinningLog: LogRepository, attestationLog: LogRepository) {
        self.pinningLog = pinningLog
        self.attestationLog = attestationLog
    }

    func log(level: TrustPinLogLevel, instanceId: String, message: String) {
        forward(prefix: "[TrustPinKit]", level: Self.map(level), message: message, to: pinningLog)
    }

    func log(level: TrustPinAttestLogLevel, instanceId: String, message: String) {
        forward(prefix: "[TrustPinAttest]", level: Self.map(level), message: message, to: attestationLog)
    }

    private func forward(prefix: String, level: LogLevel, message: String, to logRepository: LogRepository) {
        print("\(prefix) \(message)")
        logRepository.append("\(prefix) \(message)", level: level)
    }

    private static func map(_ level: TrustPinLogLevel) -> LogLevel {
        switch level {
        case .error: return .error
        case .info: return .info
        case .debug, .none: return .debug
        @unknown default: return .debug
        }
    }

    private static func map(_ level: TrustPinAttestLogLevel) -> LogLevel {
        switch level {
        case .error: return .error
        case .warning: return .warning
        case .info: return .info
        case .debug, .none: return .debug
        @unknown default: return .debug
        }
    }
}
