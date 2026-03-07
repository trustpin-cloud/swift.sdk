import Foundation

struct NetworkTestResult {
    let success: Bool
    let statusCode: Int?
    let responsePreview: String?
    let error: Error?
    let timestamp: Date
    
    init(success: Bool, statusCode: Int? = nil, responsePreview: String? = nil, error: Error? = nil) {
        self.success = success
        self.statusCode = statusCode
        self.responsePreview = responsePreview
        self.error = error
        self.timestamp = Date()
    }
}