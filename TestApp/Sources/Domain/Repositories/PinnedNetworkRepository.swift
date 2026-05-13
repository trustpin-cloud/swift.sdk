import Foundation

protocol PinnedNetworkRepository: Sendable {
    func get(url: URL) async -> ConnectionTestOutcome
}
