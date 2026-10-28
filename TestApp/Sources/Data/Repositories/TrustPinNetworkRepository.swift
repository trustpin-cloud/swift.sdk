import Foundation
import TrustPinKit

final actor TrustPinNetworkRepository: PinnedNetworkRepository {
    private let sessionDelegate: URLSessionDelegate

    init() {
        self.sessionDelegate = TrustPin.makeURLSessionDelegate()
    }

    func get(url: URL) async -> ConnectionTestOutcome {
        var request = URLRequest(url: url)
        request.setValue("TrustPin-iOS-Sample/1.0", forHTTPHeaderField: "User-Agent")

        let session = URLSession(
            configuration: .ephemeral,
            delegate: sessionDelegate,
            delegateQueue: nil
        )

        do {
            let (data, response) = try await session.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            let body = String(data: data, encoding: .utf8) ?? ""
            let preview = String(body.prefix(200)) + (body.count > 200 ? "..." : "")

            return ConnectionTestOutcome(
                success: true,
                statusCode: httpResponse?.statusCode,
                responsePreview: preview
            )
        } catch {
            return ConnectionTestOutcome(success: false, error: error)
        }
    }
}
