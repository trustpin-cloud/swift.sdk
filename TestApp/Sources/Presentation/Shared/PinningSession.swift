import Foundation

@MainActor
final class PinningSession: ObservableObject {
    @Published private(set) var isConfigured = false

    func markConfigured() {
        isConfigured = true
    }

    func markUnconfigured() {
        isConfigured = false
    }
}
