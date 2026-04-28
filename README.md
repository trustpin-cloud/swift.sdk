# TrustPin iOS SDK

[![Swift](https://img.shields.io/badge/Swift-5.5%2B-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-13.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-TrustPin-green.svg)](LICENSE)

[TrustPin](https://trustpin.cloud/) is a modern, lightweight, and secure iOS/macOS library designed to enforce **SSL Certificate Pinning** for native applications. Built with Swift Concurrency and following OWASP security recommendations, TrustPin prevents man-in-the-middle (MITM) attacks by ensuring server authenticity at the TLS level.

## 🚀 Key Features

- ✅ **Modern Swift Concurrency** - Built with `async`/`await` for seamless integration
- ✅ **Flexible Pinning Modes** - Strict validation or permissive mode for development
- ✅ **Multiple Hash Algorithms** - SHA-256 and SHA-512 certificate validation
- ✅ **Signed Configuration** - Cryptographically signed pinning configurations
- ✅ **Multiple Integration Options** - System-wide URLProtocol, URLSessionDelegate, or static helper methods
- ✅ **Intelligent Caching** - 10-minute configuration cache with stale fallback
- ✅ **Comprehensive Logging** - Configurable log levels for debugging and monitoring
- ✅ **Cross-Platform** - iOS, macOS, watchOS, tvOS, and Mac Catalyst support
- ✅ **Enhanced Security** - Advanced signature verification with multiple authentication methods

---

## 📋 Platform Requirements

| Platform | Minimum Version | URLProtocol System-Wide Pinning |
|----------|----------------|----------------------------------|
| iOS | 13.0+ | ✅ Supported |
| macOS | 13.0+ | ✅ Supported |
| watchOS | 7.0+ | ✅ Supported |
| tvOS | 13.0+ | ✅ Supported |
| Mac Catalyst | 13.0+ | ✅ Supported |
| visionOS | 2.0+ | ✅ Supported |

**Required:** Swift 5.5+ for async/await support
**Note:** URLProtocol-based features require iOS 13.0+ (available on all supported platforms)

---

## 📦 Installation

### Swift Package Manager (Recommended)

Add TrustPin to your project using Xcode:

1. **File → Add Package Dependencies**
2. **Enter repository URL:**
   ```
   https://github.com/trustpin-cloud/swift.sdk
   ```
3. **Select version:** `4.1.0` or later

#### Manual Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/trustpin-cloud/swift.sdk", from: "4.1.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "TrustPinKit", package: "TrustPin-Swift")
        ]
    )
]
```

### CocoaPods

Add TrustPin to your `Podfile`:

```ruby
pod 'TrustPinKit'
```

Then run:
```bash
pod install
```

The podspec is hosted at [TrustPin Swift SDK](https://github.com/trustpin-cloud/swift.sdk) and published to the CocoaPods trunk.

---

## 🔧 Quick Setup

### 1. Import and Configure

```swift
import TrustPinKit

// Configure TrustPin with your project credentials
let config = TrustPinConfiguration(
    organizationId: "your-org-id",
    projectId: "your-project-id",
    publicKey: "your-base64-public-key",
    mode: .strict  // Recommended
)
try await TrustPin.setup(config)
```

> 💡 **Find your credentials** in the [TrustPin Dashboard](https://app.trustpin.cloud)

> ⚠️ **Important**: `TrustPin.setup()` must be called only once during your app's lifecycle. Concurrent setup calls are not supported and will throw `TrustPinErrors.invalidProjectConfig`. If already initialized, subsequent calls will return immediately.

### 2. Choose Your Pinning Mode

TrustPin offers two validation modes:

#### Strict Mode (Recommended)
```swift
let config = TrustPinConfiguration(
    organizationId: "your-org-id",
    projectId: "your-project-id",
    publicKey: "your-base64-public-key",
    mode: .strict  // Throws error for unregistered domains
)
try await TrustPin.setup(config)
```

#### Permissive Mode (Development & Testing)
```swift
let config = TrustPinConfiguration(
    organizationId: "your-org-id",
    projectId: "your-project-id",
    publicKey: "your-base64-public-key",
    mode: .permissive  // Allows unregistered domains to bypass pinning
)
try await TrustPin.setup(config)
```

### 3. Integration Approach

TrustPin requires you to explicitly choose how to integrate certificate pinning into your app. The recommended approach is to use `TrustPin.makeURLSessionDelegate()` for specific sessions, providing precise control over which connections are pinned.

#### URLSessionDelegate (Recommended - Default)
```swift
let config = TrustPinConfiguration(
    organizationId: "your-org-id",
    projectId: "your-project-id",
    publicKey: "your-base64-public-key"
)
try await TrustPin.setup(config)

// Use TrustPin.makeURLSessionDelegate() to bind a delegate to the default instance
let trustPinDelegate = TrustPin.makeURLSessionDelegate()
let session = URLSession(
    configuration: .default,
    delegate: trustPinDelegate,
    delegateQueue: nil
)
```

#### System-Wide URLProtocol (Advanced Use Cases)
```swift
let config = TrustPinConfiguration(
    organizationId: "your-org-id",
    projectId: "your-project-id",
    publicKey: "your-base64-public-key"
)
try await TrustPin.setup(config, autoRegisterURLProtocol: true)

// All URLSession instances now automatically use certificate pinning
// Including URLSession.shared and third-party networking libraries
```

#### Manual URLProtocol Control (Advanced)
```swift
let config = TrustPinConfiguration(
    organizationId: "your-org-id",
    projectId: "your-project-id",
    publicKey: "your-base64-public-key"
)
try await TrustPin.setup(config)

// Manually enable/disable system-wide pinning when needed
TrustPin.registerURLProtocol()    // Enable
TrustPin.unregisterURLProtocol()  // Disable
```

> 💡 **Recommendation**: Use URLSessionDelegate (default) for precise control and best practices. Use system-wide URLProtocol only when you need to protect third-party libraries or cannot modify URLSession creation code.

---

## 🛠 Integration Approaches

TrustPin offers three integration methods:

| Approach | Best For | Setup Complexity | Coverage |
|----------|----------|------------------|----------|
| **URLSessionDelegate** (Recommended) | Most applications, precise control | 🟢 Minimal | Specific URLSession instances |
| **System-Wide URLProtocol** | Third-party library protection, legacy code | 🟡 Medium | All URLSession requests |
| **Helper Methods** | Explicit control, static method preference | 🟠 Per-request | Individual requests |

### When to Choose Each Approach

#### URLSessionDelegate (Default & Recommended)
- ✅ **Precise control**: Only specific URLSession instances use pinning
- ✅ **Best practices**: Explicit delegate pattern following Apple guidelines
- ✅ **Custom delegation**: Integrate with existing URLSessionDelegate code
- ✅ **Selective pinning**: Mix pinned and non-pinned sessions in same app
- ✅ **Predictable behavior**: No global state changes

#### System-Wide URLProtocol
- ✅ **Broad protection**: Automatically secures all URLSession requests
- ✅ **Zero configuration**: Works with existing networking code without changes
- ✅ **Third-party compatibility**: Protects libraries using URLSession
- ⚠️ **Global impact**: Affects all URLSession instances in the app

#### Helper Methods
- ✅ **Explicit requests**: Clear intent for which requests use pinning  
- ✅ **Static methods**: Functional programming style
- ✅ **Migration friendly**: Easy drop-in replacements for existing URLSession calls
- ✅ **Testing isolation**: Test pinned vs non-pinned requests separately

---

## 🛠 Usage Examples

### URLSessionDelegate Integration (Recommended)

The recommended approach — use `TrustPin.makeURLSessionDelegate()` for precise control over which URLSessions use certificate pinning:

```swift
import TrustPinKit

// In your AppDelegate or App struct
func configureApp() async throws {
    // Setup TrustPin
    let config = TrustPinConfiguration(
        organizationId: "your-org-id",
        projectId: "your-project-id",
        publicKey: "your-base64-public-key"
    )
    try await TrustPin.setup(config)
}

// Create a network manager with pinned URLSession
class NetworkManager {
    private let trustPinDelegate = TrustPin.makeURLSessionDelegate()
    private lazy var session = URLSession(
        configuration: .default,
        delegate: trustPinDelegate,
        delegateQueue: nil
    )

    func fetchData() async throws -> Data {
        let url = URL(string: "https://api.example.com/data")!
        let (data, _) = try await session.data(from: url)
        return data
    }

    func fetchWithCustomConfig() async throws -> Data {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30

        let customSession = URLSession(
            configuration: config,
            delegate: trustPinDelegate,
            delegateQueue: nil
        )

        let url = URL(string: "https://api.example.com/secure")!
        let (data, _) = try await customSession.data(from: url)
        return data
    }
}
```

> 🎯 **Benefits**:
> - Explicit control over which sessions use pinning
> - No global state changes
> - Follows Apple's recommended patterns
> - Easy to test and debug

### System-Wide Certificate Pinning (Advanced)

For scenarios where you need to protect third-party libraries or cannot modify URLSession creation:

```swift
import TrustPinKit

// In your AppDelegate or App struct
func configureApp() async throws {
    // Setup TrustPin with system-wide URLProtocol registration
    let config = TrustPinConfiguration(
        organizationId: "your-org-id",
        projectId: "your-project-id",
        publicKey: "your-base64-public-key"
    )
    try await TrustPin.setup(config, autoRegisterURLProtocol: true)

    // That's it! All URLSession requests now use certificate pinning
}

// Anywhere in your app - pinning works automatically
class NetworkManager {
    func fetchData() async throws -> Data {
        // URLSession.shared automatically uses certificate pinning
        let url = URL(string: "https://api.example.com/data")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}

// Third-party libraries using URLSession are also protected!
// Alamofire, URLSession-based HTTP clients, etc. automatically get pinning
```

> ⚠️ **Note**: This approach affects all URLSession instances globally. Use with caution.

#### Manual URLProtocol Control (Advanced)

For advanced scenarios where you need control over URLProtocol registration:

```swift
// Setup without auto-registration
let config = TrustPinConfiguration(
    organizationId: "your-org-id",
    projectId: "your-project-id",
    publicKey: "your-base64-public-key"
)
try await TrustPin.setup(config)

// Manually register when needed
TrustPin.registerURLProtocol()

// Unregister when no longer needed
TrustPin.unregisterURLProtocol()
```

### URLProtocol Helper Methods (Alternative API)

For scenarios where you prefer explicit control or want to use static helper methods:

```swift
import TrustPinKit

class NetworkManager {
    
    // Async/await examples
    func fetchDataWithHelpers() async throws -> Data {
        let url = URL(string: "https://api.example.com/data")!
        let (data, _) = try await TrustPinURLProtocol.data(from: url)
        return data
    }
    
    func downloadFileWithHelpers() async throws -> URL {
        let request = URLRequest(url: URL(string: "https://api.example.com/file.pdf")!)
        let (fileURL, _) = try await TrustPinURLProtocol.download(for: request)
        return fileURL
    }
    
    // Completion handler examples
    func fetchDataWithCompletionHandler() {
        let url = URL(string: "https://api.example.com/data")!
        let task = TrustPinURLProtocol.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            if let data = data {
                print("Received \(data.count) bytes")
            }
        }
        task.resume()
    }
    
    // Custom session with pinning
    func useCustomTrustPinSession() async throws -> Data {
        let session = URLSession.trustPinSession(
            configuration: .ephemeral
        )
        
        let url = URL(string: "https://api.example.com/data")!
        let (data, _) = try await session.data(from: url)
        return data
    }
}
```

> 💡 **When to use helper methods**:
> - When you need explicit control over individual requests
> - For codebases that prefer static method calls
> - When migrating from other networking libraries
> - For testing scenarios where you want to isolate pinned requests

### Automatic URLSession Integration

The traditional delegate-based approach (still fully supported):

```swift
import TrustPinKit

class NetworkManager {
    private let trustPinDelegate = TrustPin.makeURLSessionDelegate()
    private lazy var session = URLSession(
        configuration: .default,
        delegate: trustPinDelegate,
        delegateQueue: nil
    )
    
    func fetchData() async throws -> Data {
        let url = URL(string: "https://api.example.com/data")!
        let (data, _) = try await session.data(from: url)
        return data
    }
}
```

### Manual Certificate Verification

For custom networking stacks or certificate inspection:

```swift
import TrustPinKit

// Verify a PEM-encoded certificate for a specific domain
let domain = "api.example.com"
let pemCertificate = """
-----BEGIN CERTIFICATE-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
-----END CERTIFICATE-----
"""

do {
    try await TrustPin.verify(domain: domain, certificate: pemCertificate)
    print("✅ Certificate is valid and matches configured pins")
} catch TrustPinErrors.domainNotRegistered {
    print("⚠️ Domain not configured for pinning")
} catch TrustPinErrors.pinsMismatch {
    print("❌ Certificate doesn't match any configured pins")
} catch {
    print("💥 Verification failed: \(error)")
}
```

### Setup and Initialization

```swift
import TrustPinKit

class AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        Task {
            do {
                // Setup TrustPin once during app launch
                let config = TrustPinConfiguration(
                    organizationId: "your-org-id",
                    projectId: "your-project-id",
                    publicKey: "your-public-key"
                )
                try await TrustPin.setup(config)
                print("✅ TrustPin initialized successfully")
            } catch {
                print("❌ TrustPin setup failed: \(error)")
            }
        }
        
        return true
    }
}
```

---

## 🔧 Integration Examples

### With Alamofire

Alamofire installs its own `SessionDelegate`, so `TrustPin.makeURLSessionDelegate()`
cannot be plugged in directly. The supported route is to wire TrustPin into
Alamofire's `ServerTrustManager` via a custom `ServerTrustEvaluating` that pulls the
leaf certificate from the `SecTrust` and forwards it to `TrustPin.verify`. Because
`ServerTrustEvaluating` is synchronous and `TrustPin.verify` is `async`, you'll
need to bridge with a semaphore — which is acceptable on Alamofire's serial trust
queue but should not be copied into other contexts. If you'd like a fully-supported
adapter, please open an issue against the SDK.

### With Custom URLSession

```swift
import Foundation
import TrustPinKit

class SecureNetworkClient {
    private let trustPinDelegate = TrustPin.makeURLSessionDelegate()
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config, delegate: trustPinDelegate, delegateQueue: nil)
    }()
    
    func performSecureRequest(to url: URL) async throws -> (Data, URLResponse) {
        return try await urlSession.data(from: url)
    }
}
```

---

## 🎯 Pinning Modes Explained

| Mode | Behavior | Use Case |
|------|----------|----------|
| **`.strict`** | ❌ Throws `TrustPinErrors.domainNotRegistered` for unregistered domains | **Production environments** where all connections should be validated |
| **`.permissive`** | ✅ Allows unregistered domains to bypass pinning | **Development/Testing** or apps connecting to dynamic domains |

### When to Use Each Mode

#### Strict Mode (`.strict`)
- ✅ **Production applications**
- ✅ **High-security environments**  
- ✅ **Known, fixed set of API endpoints**
- ✅ **Compliance requirements**

#### Permissive Mode (`.permissive`)
- ✅ **Development and staging**
- ✅ **Applications with dynamic/unknown endpoints**
- ✅ **Gradual migration to certificate pinning**
- ✅ **Third-party SDK integrations**

---

## 📊 Error Handling

TrustPin provides detailed error types for proper handling:

```swift
do {
    try await TrustPin.verify(domain: "api.example.com", certificate: pemCert)
} catch TrustPinErrors.domainNotRegistered {
    // Domain not configured in TrustPin (only in strict mode)
    handleUnregisteredDomain()
} catch TrustPinErrors.pinsMismatch {
    // Certificate doesn't match configured pins - possible MITM
    handleSecurityThreat()
} catch TrustPinErrors.allPinsExpired {
    // All pins for domain have expired
    handleExpiredPins()
} catch TrustPinErrors.invalidServerCert {
    // Certificate format is invalid
    handleInvalidCertificate()
} catch TrustPinErrors.invalidProjectConfig {
    // Setup parameters are invalid
    handleConfigurationError()
} catch TrustPinErrors.errorFetchingPinningInfo {
    // Network error fetching configuration
    handleNetworkError()
} catch TrustPinErrors.configurationValidationFailed {
    // configuration signature validation failed
    handleSignatureError()
}
```

---

## 🔍 Logging and Debugging

TrustPin provides comprehensive logging for debugging and monitoring:

```swift
// Set log level before setup
await TrustPin.set(logLevel: .debug)

// Available log levels:
// .none     - No logging
// .error    - Errors only  
// .info     - Errors and informational messages
// .debug    - All messages including debug information
```

---

## 🏗 Best Practices

### Setup and Initialization

1. **Call `TrustPin.setup()` only once** during app launch (typically in `AppDelegate`)
2. **Handle setup errors gracefully** - don't block app launch if TrustPin fails
3. **Set log level before setup** for complete logging coverage
4. **Never call setup concurrently** - it's not supported and will throw errors
5. **Use Task/async context** for setup in synchronous app lifecycle methods

### Security Recommendations

1. **Always use `.strict` mode in production**
2. **Rotate pins before expiration**
3. **Monitor pin validation failures**
4. **Use HTTPS for all pinned domains**
5. **Keep public keys secure and version-controlled**

### Performance Optimization

1. **Cache TrustPin configuration** (handled automatically)
2. **Reuse URLSession instances** with TrustPin delegate
3. **Use appropriate log levels** (`.error` or `.none` in production)
4. **Initialize early** to avoid setup delays during first network requests

### Development Workflow

1. **Start with `.permissive` mode** during development
2. **Test all endpoints** with pinning enabled
3. **Validate pin configurations** in staging
4. **Switch to `.strict` mode** for production releases
5. **Use debug logging** to troubleshoot pinning issues

---

## 🔧 Advanced Configuration

### Custom URLSession Configuration

```swift
let trustPinDelegate = TrustPin.makeURLSessionDelegate()

let configuration = URLSessionConfiguration.default
configuration.timeoutIntervalForRequest = 30
configuration.timeoutIntervalForResource = 300
configuration.httpMaximumConnectionsPerHost = 4

let session = URLSession(
    configuration: configuration,
    delegate: trustPinDelegate,
    delegateQueue: OperationQueue()
)
```

### Error Recovery Strategies

```swift
func performNetworkRequest() async -> Data? {
    do {
        return try await secureNetworkRequest()
    } catch TrustPinErrors.domainNotRegistered {
        // Log security event but continue in permissive mode
        logger.warning("Unregistered domain accessed")
        return try await fallbackNetworkRequest()
    } catch TrustPinErrors.pinsMismatch {
        // This is a serious security issue - do not retry
        logger.critical("Certificate pinning failed - possible MITM attack")
        throw SecurityError.potentialMITMAttack
    }
}
```

---

## 📚 API Reference

### Core Classes

- **`TrustPin`** - Main SDK interface; supports a default singleton and named multi-instances
- **`TrustPinConfiguration`** - Value type grouping all setup options (v3 preferred)
- **`TrustPinMode`** - Enum defining pinning behavior modes (`.strict`, `.permissive`)
- **`TrustPin.makeURLSessionDelegate()`** - Returns a `URLSessionDelegate` bound to a TrustPin instance for per-session pinning
- **`TrustPinURLProtocol`** - URLProtocol implementation for system-wide pinning (iOS 13.0+)
- **`TrustPinErrors`** - Error types for detailed error handling
- **`TrustPinLogLevel`** - Logging configuration options (`.none`, `.error`, `.info`, `.debug`)

### Key Methods

#### Core TrustPin API

```swift
// ── Instance creation ──────────────────────────────────────────────────────

// Default instance (used by all static convenience methods)
static let `default`: TrustPin

// Named instance for library / multi-tenant use (process-global, thread-safe registry)
static func instance(id: String) -> TrustPin

// ── Setup (preferred — struct-based) ──────────────────────────────────────

// Instance method
func setup(_ configuration: TrustPinConfiguration) async throws

// Static convenience (delegates to TrustPin.default)
static func setup(_ configuration: TrustPinConfiguration,
                  autoRegisterURLProtocol: Bool = false) async throws

// ── Verification ──────────────────────────────────────────────────────────

func verify(domain: String, certificate: String) async throws          // instance
static func verify(domain: String, certificate: String) async throws   // → TrustPin.default

// ── Certificate fetch utility ────────────────────────────────────────────

// Opens an ephemeral TLS connection, returns the leaf certificate as PEM.
// Does NOT perform pin verification — use verify() after.
func fetchCertificate(host: String, port: Int = 443) async throws -> String
static func fetchCertificate(host: String, port: Int = 443) async throws -> String

// ── URLSessionDelegate (instance-bound) ──────────────────────────────────

func makeURLSessionDelegate() -> any URLSessionDelegate
static func makeURLSessionDelegate() -> any URLSessionDelegate

// ── System-wide URLProtocol control (default instance only) ──────────────

static func registerURLProtocol()    // Enable system-wide pinning
static func unregisterURLProtocol()  // Disable system-wide pinning

// ── Logging ───────────────────────────────────────────────────────────────

func set(logLevel: TrustPinLogLevel)          // instance
static func set(logLevel: TrustPinLogLevel)   // → TrustPin.default
```

#### URLProtocol Helper Methods (iOS 13.0+)

```swift
// Async/await data methods with automatic pinning
TrustPinURLProtocol.data(for: URLRequest, using: URLSession? = nil) async throws -> (Data, URLResponse)
TrustPinURLProtocol.data(from: URL, using: URLSession? = nil) async throws -> (Data, URLResponse)

// Async/await download methods with automatic pinning
TrustPinURLProtocol.download(for: URLRequest, using: URLSession? = nil) async throws -> (URL, URLResponse)
TrustPinURLProtocol.download(from: URL, using: URLSession? = nil) async throws -> (URL, URLResponse)

// Completion handler methods with automatic pinning
TrustPinURLProtocol.dataTask(with: URLRequest, using: URLSession? = nil, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
TrustPinURLProtocol.dataTask(with: URL, using: URLSession? = nil, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask

TrustPinURLProtocol.downloadTask(with: URLRequest, using: URLSession? = nil, completionHandler: @escaping @Sendable (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask
TrustPinURLProtocol.downloadTask(with: URL, using: URLSession? = nil, completionHandler: @escaping @Sendable (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask

// Create URLSession with pinning enabled
URLSession.trustPinSession(configuration: URLSessionConfiguration = .default, 
                          delegate: URLSessionDelegate? = nil, 
                          delegateQueue: OperationQueue? = nil) -> URLSession
```

---

## 🐛 Troubleshooting

### Common Issues

#### **Setup Fails with `invalidProjectConfig`**
- ✅ Verify organization ID, project ID, and public key are correct
- ✅ Check for extra whitespace or newlines in credentials
- ✅ Ensure public key is properly base64-encoded
- ✅ **Avoid concurrent setup calls** - only call `TrustPin.setup()` once per app lifecycle
- ✅ **Check for multiple setup attempts** - if already initialized, subsequent calls return immediately

#### **Certificate Verification Fails**
- ✅ Confirm domain is registered in TrustPin dashboard
- ✅ Check certificate format (must be PEM-encoded)
- ✅ Verify pins haven't expired
- ✅ Test with `.permissive` mode first

#### **Network Requests Hang**
- ✅ Ensure you're using the correct URLSession delegate
- ✅ Check for retain cycles with URLSession
- ✅ Verify network connectivity
- ✅ Check if URLProtocol is properly registered (when using system-wide pinning)

#### **System-Wide Pinning Not Working**
- ✅ Verify `autoRegisterURLProtocol: true` was used during setup (not enabled by default)
- ✅ Check that you're testing with HTTPS URLs (HTTP is ignored)
- ✅ Ensure URLProtocol hasn't been unregistered elsewhere in the app
- ✅ Test with `TrustPin.registerURLProtocol()` to manually register if not done during setup

#### **URLProtocol Helper Methods Not Found**
- ✅ Ensure you're targeting iOS 13.0+ or equivalent platform versions
- ✅ Check that TrustPin has been set up before using helper methods
- ✅ Use `TrustPinURLProtocol.` prefix for static helper methods
- ✅ Import `TrustPinKit` module

### Debug Steps

1. **Enable debug logging**: `await TrustPin.set(logLevel: .debug)`
2. **Test with permissive mode** first
3. **Verify credentials** in TrustPin dashboard
4. **Check certificate expiration** dates

---

## 📖 Documentation

- **API Documentation**: [TrustPin iOS SDK Docs](https://trustpin-cloud.github.io/swift.sdk/)
- **Dashboard**: [TrustPin Cloud Console](https://app.trustpin.cloud)
- **Support**: [Contact TrustPin](https://trustpin.cloud/)

---

## 📝 License

This project is licensed under the TrustPin Binary License Agreement - see the [LICENSE](LICENSE) file for details.

**Commercial License**: For enterprise licensing or custom agreements, contact [contact@trustpin.cloud](mailto:contact@trustpin.cloud)

**Attribution Required**: When using this software, you must display "Uses TrustPin™ technology – https://trustpin.cloud" in your application.

---

## 🤝 Support & Feedback

We welcome your feedback and questions!

- 📧 **Email**: [support@trustpin.cloud](mailto:support@trustpin.cloud)
- 🌐 **Website**: [https://trustpin.cloud](https://trustpin.cloud)
- 📋 **Issues**: [GitHub Issues](https://github.com/trustpin-cloud/swift.sdk/issues)

---

*Built with ❤️ by the TrustPin team*