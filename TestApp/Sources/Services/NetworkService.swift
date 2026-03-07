import Foundation
import TrustPinKit

final actor NetworkService {
    private let sessionDelegate: URLSessionDelegate!

    init() {
        self.sessionDelegate = TrustPin.makeURLSessionDelegate()
    }
    
    func testConnection(url: String) async throws -> NetworkTestResult {
        guard let url = URL(string: url) else {
            throw NetworkServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("TrustPin-iOS-Sample/1.0", forHTTPHeaderField: "User-Agent")
        
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config, delegate: sessionDelegate, delegateQueue: nil)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            let httpResponse = response as? HTTPURLResponse
            let responseString = String(data: data, encoding: .utf8) ?? ""
            let preview = String(responseString.prefix(200))
            
            return NetworkTestResult(
                success: true,
                statusCode: httpResponse?.statusCode,
                responsePreview: preview + (responseString.count > 200 ? "..." : "")
            )
        } catch {
            return NetworkTestResult(
                success: false,
                error: error
            )
        }
    }
}

enum NetworkServiceError: LocalizedError {
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        }
    }
}
