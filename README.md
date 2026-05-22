# TrustPin iOS SDK

[![Swift](https://img.shields.io/badge/Swift-5.5%2B-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-13.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-TrustPin-green.svg)](LICENSE)

[TrustPin](https://trustpin.cloud/) is a modern, lightweight, and secure iOS/macOS library that enforces **SSL Certificate Pinning** in native applications. Built with Swift Concurrency and following OWASP recommendations, it prevents man-in-the-middle (MITM) attacks by validating server authenticity at the TLS level.

## 🚀 Key Features

- ✅ **Modern Swift Concurrency** — `async`/`await` throughout
- ✅ **Flexible pinning modes** — strict for production, permissive for development
- ✅ **Multiple hash algorithms** — SHA-256 and SHA-512 certificate validation
- ✅ **Signed configuration** — cryptographically signed pinning payloads
- ✅ **Integration choices** — `URLSessionDelegate`, system-wide `URLProtocol`, or static helpers
- ✅ **Intelligent caching** — fresh-cache + stale-fallback so a CDN hiccup never strands the app
- ✅ **Configurable logging** — verbosity levels for development and production
- ✅ **Cross-platform** — iOS, macOS, watchOS, tvOS, Mac Catalyst, visionOS

---

## 📑 Table of Contents

- [Platform Requirements](#-platform-requirements)
- [Installation](#-installation)
- [Quick Setup](#-quick-setup)
- [Setup via `TrustPin-Info.plist`](#-setup-via-trustpin-infoplist-ios)
- [Integration Approaches](#-integration-approaches)
- [Usage Examples](#-usage-examples)
- [Pinning Modes](#-pinning-modes)
- [Error Handling](#-error-handling)
- [Logging](#-logging)
- [Best Practices](#-best-practices)
- [API Reference](#-api-reference)
- [Troubleshooting](#-troubleshooting)
- [Documentation, License & Support](#-documentation)

---

## 📋 Platform Requirements

| Platform     | Minimum Version |
|--------------|-----------------|
| iOS          | 13.0+           |
| macOS        | 13.0+           |
| watchOS      | 7.0+            |
| tvOS         | 13.0+           |
| Mac Catalyst | 13.0+           |
| visionOS     | 2.0+            |

Swift 5.5+ required for `async`/`await`.

---

## 📦 Installation

### Swift Package Manager (recommended)

In Xcode: **File → Add Package Dependencies**, then enter:

```
https://github.com/trustpin-cloud/swift.sdk
```

Select version `5.0.0` or later.

#### Manual `Package.swift`

```swift
dependencies: [
    .package(url: "https://github.com/trustpin-cloud/swift.sdk", from: "5.0.0")
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

```ruby
pod 'TrustPinKit'
```

```bash
pod install
```

---

## 🔧 Quick Setup

```swift
import TrustPinKit

let config = TrustPinConfiguration(
    organizationId: "your-org-id",
    projectId:      "your-project-id",
    publicKey:      "your-base64-public-key",
    mode:           .strict
)
try await TrustPin.setup(config)
```

> 💡 Find your credentials in the [TrustPin Dashboard](https://app.trustpin.cloud).
>
> ⚠️ Call `TrustPin.setup(_:)` **once** during your app's lifecycle. Concurrent setup calls throw `TrustPinErrors.invalidProjectConfig`. Subsequent calls after success return immediately.

### Recommended fail-closed pattern

A common integration mistake is to wrap `setup` in `try? await ...` and continue to make network calls if it fails. The result is an unpinned application whenever the CDN hiccups. **Treat any `TrustPinErrors` from `setup` as a hard stop**, and pair it with `requirePinned()` before constructing any pinned `URLSession`:

```swift
do {
    try await TrustPin.setup(config)
    try await TrustPin.requirePinned()  // belt-and-suspenders
} catch {
    return showRetryUI(error)            // do NOT fall through to unpinned networking
}

let session = URLSession(
    configuration: .default,
    delegate: TrustPin.makeURLSessionDelegate(),
    delegateQueue: nil
)
```

---

## 📄 Setup via `TrustPin-Info.plist` (iOS)

As an alternative to the programmatic initializer, ship the credentials in a bundled property list and load them at startup:

```swift
let config = try TrustPinConfiguration.fromPlist()
try await TrustPin.setup(config)
```

### Schema

Add `TrustPin-Info.plist` to your target's **Copy Bundle Resources** with these keys:

| Key                | Required | Type   | Notes |
| ------------------ | -------- | ------ | ----- |
| `OrganizationId`   | ✅        | String | Non-empty |
| `ProjectId`        | ✅        | String | Non-empty |
| `PublicKey`        | ✅        | String | Base64 |
| `Mode`             | ❌        | String | `"strict"` (default) or `"permissive"` (lowercase only) |
| `ConfigurationURL` | ❌        | String | Must be HTTPS |

Unknown top-level keys are ignored, so adding fields ahead of an SDK update is safe.

### Multi-environment setup

**Per-target (recommended).** Create separate Xcode targets for `Dev` / `Staging` / `Prod`, ship a distinct `TrustPin-Info.plist` per target, and call `fromPlist()` with no arguments. The right file is resolved automatically.

**Per-scheme.** When a single target needs to swap files:

```swift
#if DEBUG
let config = try TrustPinConfiguration.fromPlist(fileName: "TrustPin-Info-Debug.plist")
#else
let config = try TrustPinConfiguration.fromPlist(fileName: "TrustPin-Info.plist")
#endif
try await TrustPin.setup(config)
```

### Notes

- **Returns a value, not a side effect.** Pass the returned `TrustPinConfiguration` to `TrustPin.setup(_:)` (or `TrustPin.instance(id:).setup(_:)` for a named instance).
- **The plist ships in the app bundle.** It is not a secret — `PublicKey` is the verification key for signed pin payloads, not key material.
- **All parse failures collapse to `TrustPinErrors.invalidProjectConfig`.** A descriptive reason is written to `stderr` with the `[TrustPin]` prefix.
- **iOS-only API.** The Android SDK ships an equivalent file-based setup via `trustpin.json` in assets.

---

## 🛠 Integration Approaches

| Approach | Best for | Coverage |
|----------|----------|----------|
| **URLSessionDelegate** (recommended) | Most apps; precise control | Specific `URLSession` instances |
| **System-wide URLProtocol** | Third-party library protection, legacy code | All `URLSession` requests |
| **Static helpers** | Explicit per-request pinning | Individual requests |

### URLSessionDelegate (default & recommended)
- Precise control — only specific `URLSession` instances are pinned
- No global state changes
- Mixes pinned and non-pinned sessions in the same app

### System-wide URLProtocol
- Automatically secures every `URLSession` request, including `URLSession.shared`
- Protects third-party libraries layered over `URLSession`
- ⚠️ Affects every `URLSession` instance in the app

### Static helpers
- Explicit per-request intent; clear migration path from legacy `URLSession` code
- Useful for tests that need to isolate pinned vs unpinned requests

---

## 🛠 Usage Examples

### URLSessionDelegate (recommended)

```swift
import TrustPinKit

final class NetworkManager {
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

### System-wide URLProtocol

```swift
// Auto-register at setup time:
try await TrustPin.setup(config, autoRegisterURLProtocol: true)

// Or toggle manually:
TrustPin.registerURLProtocol()
TrustPin.unregisterURLProtocol()

// URLSession.shared now applies pinning automatically.
let (data, _) = try await URLSession.shared.data(from: url)
```

### Static helpers

```swift
// async/await
let (data, _) = try await TrustPinURLProtocol.data(from: url)

// Completion handler
let task = TrustPinURLProtocol.dataTask(with: url) { data, response, error in
    // ...
}
task.resume()

// Or build a custom session with pinning enabled:
let session = URLSession.trustPinSession(configuration: .ephemeral)
```

### Manual certificate verification

```swift
import TrustPinKit

let pem = """
-----BEGIN CERTIFICATE-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
-----END CERTIFICATE-----
"""

do {
    try await TrustPin.verify(domain: "api.example.com", certificate: pem)
} catch TrustPinErrors.pinsMismatch {
    // Possible MITM — do not retry.
} catch TrustPinErrors.domainNotRegistered {
    // Strict mode only.
}
```

---

## 🎯 Pinning Modes

| Mode | Behaviour |
|------|-----------|
| **`.strict`** | Throws `TrustPinErrors.domainNotRegistered` for unregistered domains. Recommended for production. |
| **`.permissive`** | Allows unregistered domains to bypass pinning. For development / dynamic endpoints. |

---

## 📊 Error Handling

Switch on `TrustPinErrors` to drive your response policy:

```swift
do {
    try await TrustPin.verify(domain: "api.example.com", certificate: pem)
} catch TrustPinErrors.domainNotRegistered {
    // Strict mode only: domain is not in your pinning configuration.
    handleUnregisteredDomain()
} catch TrustPinErrors.pinsMismatch {
    // Certificate doesn't match any configured pin — potential MITM.
    handleSecurityThreat()
} catch TrustPinErrors.allPinsExpired {
    handleExpiredPins()
} catch TrustPinErrors.invalidServerCert {
    handleInvalidCertificate()
} catch TrustPinErrors.invalidProjectConfig {
    handleConfigurationError()
} catch TrustPinErrors.errorFetchingPinningInfo {
    // Transient network / configuration fetch problem.
    handleNetworkError()
} catch TrustPinErrors.configurationValidationFailed {
    handleSignatureError()
} catch TrustPinErrors.configIntegrityFailed {
    // Configuration failed an integrity check — hard stop.
    handleIntegrityFailure()
}
```

---

## 🔍 Logging

```swift
TrustPin.set(logLevel: .debug)
// Levels: .none, .error, .info, .debug
```

Set the log level before `setup` for complete logging coverage. Use `.error` or `.none` in production.

---

## 🏗 Best Practices

### Security
- Always use `.strict` mode in production.
- Rotate pins before expiration; monitor pin-validation failures.
- Use HTTPS for all pinned domains.

### Setup
- Call `TrustPin.setup()` exactly once at app launch.
- Treat setup errors as hard stops — don't construct an unpinned `URLSession` on the failure path.
- Use `requirePinned()` as a guard before any pinned network operation.

### Development workflow
- Start in `.permissive` mode during development, then switch to `.strict` for production.
- Use `.debug` log level when troubleshooting; revert to `.error` or `.none` for release builds.

---

## 📚 API Reference

### Core types

- **`TrustPin`** — main SDK interface; default singleton + named multi-instances
- **`TrustPinConfiguration`** — value type grouping all setup options; supports `fromPlist(_:fileName:)`
- **`TrustPinMode`** — pinning behaviour (`.strict`, `.permissive`)
- **`TrustPinURLProtocol`** — `URLProtocol` for system-wide pinning (iOS 13.0+)
- **`TrustPinErrors`** — error cases (see [Error Handling](#-error-handling))
- **`TrustPinLogLevel`** — logging verbosity (`.none`, `.error`, `.info`, `.debug`)

### Methods

```swift
// ── Instances ─────────────────────────────────────────────────────────────

static let `default`: TrustPin
static func instance(id: String) throws -> TrustPin
    // `id` must match `^[a-zA-Z0-9._-]+$` — dot-separated reverse-DNS strings
    // like `"com.example.app"` are accepted. Throws `.invalidProjectConfig` if
    // `id` is `"default"`, empty, or contains disallowed characters.

// ── Setup ─────────────────────────────────────────────────────────────────

func setup(_ configuration: TrustPinConfiguration) async throws
static func setup(_ configuration: TrustPinConfiguration,
                  autoRegisterURLProtocol: Bool = false) async throws
static func TrustPinConfiguration.fromPlist(
    _ bundle: Bundle = .main,
    fileName: String = "TrustPin-Info.plist"
) throws -> TrustPinConfiguration

// ── Readiness gate ────────────────────────────────────────────────────────

func requirePinned() async throws
static func requirePinned() async throws

// ── Verification ──────────────────────────────────────────────────────────

// `timeout` is in seconds, default 30, clamped to [10, 120].
func verify(domain: String, certificate: String,
            timeout: TimeInterval = 30) async throws
static func verify(domain: String, certificate: String,
                   timeout: TimeInterval = 30) async throws

// ── Certificate fetch ─────────────────────────────────────────────────────

// Returns the server's leaf certificate as PEM. Does NOT pin-verify —
// use verify() afterwards.
func fetchCertificate(host: String, port: Int = 443,
                      timeout: TimeInterval = 30) async throws -> String
static func fetchCertificate(host: String, port: Int = 443,
                             timeout: TimeInterval = 30) async throws -> String

// ── URLSession integration ────────────────────────────────────────────────

func makeURLSessionDelegate() -> any URLSessionDelegate
static func makeURLSessionDelegate() -> any URLSessionDelegate
static func registerURLProtocol()
static func unregisterURLProtocol()

// ── Logging ───────────────────────────────────────────────────────────────

func set(logLevel: TrustPinLogLevel)
static func set(logLevel: TrustPinLogLevel)
```

### `TrustPinURLProtocol` helpers (iOS 13.0+)

```swift
// Async/await
TrustPinURLProtocol.data(for: URLRequest, using: URLSession? = nil) async throws -> (Data, URLResponse)
TrustPinURLProtocol.data(from: URL, using: URLSession? = nil) async throws -> (Data, URLResponse)
TrustPinURLProtocol.download(for: URLRequest, using: URLSession? = nil) async throws -> (URL, URLResponse)
TrustPinURLProtocol.download(from: URL, using: URLSession? = nil) async throws -> (URL, URLResponse)

// Completion handler
TrustPinURLProtocol.dataTask(with:using:completionHandler:) -> URLSessionDataTask
TrustPinURLProtocol.downloadTask(with:using:completionHandler:) -> URLSessionDownloadTask

// URLSession factory
URLSession.trustPinSession(configuration: URLSessionConfiguration = .default,
                           delegate: URLSessionDelegate? = nil,
                           delegateQueue: OperationQueue? = nil) -> URLSession
```

---

## 🐛 Troubleshooting

### Setup fails with `invalidProjectConfig`
- Verify organization ID, project ID, and public key against the dashboard.
- Check for stray whitespace or newlines in credentials.
- Ensure the public key is properly base64-encoded.
- Avoid concurrent setup calls — only one `TrustPin.setup()` per app lifecycle.

### Certificate verification fails
- Confirm the domain is registered in the TrustPin dashboard.
- Check the certificate format (must be PEM-encoded).
- Verify pins haven't expired.
- Test with `.permissive` mode first.

### Network requests hang
- Confirm you're using the correct `URLSession` delegate.
- Check for retain cycles on `URLSession`.
- Verify network connectivity.

### System-wide pinning not working
- Ensure `autoRegisterURLProtocol: true` was used during setup (or call `registerURLProtocol()` explicitly).
- Test with HTTPS URLs — HTTP is ignored.
- Confirm `URLProtocol` hasn't been unregistered elsewhere.

### Debug steps
1. Enable debug logging: `TrustPin.set(logLevel: .debug)`
2. Test in `.permissive` mode first
3. Re-verify credentials in the dashboard
4. Check pin expiration dates

---

## 📖 Documentation

- **API documentation**: [TrustPin iOS SDK docs](https://trustpin-cloud.github.io/swift.sdk/)
- **Dashboard**: [TrustPin Cloud Console](https://app.trustpin.cloud)
- **Support**: [Contact TrustPin](https://trustpin.cloud/)

## 📝 License

This project is licensed under the TrustPin Binary License Agreement — see [LICENSE](LICENSE).

**Commercial License**: for enterprise licensing or custom agreements, contact [contact@trustpin.cloud](mailto:contact@trustpin.cloud).

**Attribution required**: applications using this software must display *"Uses TrustPin™ technology – https://trustpin.cloud"*.

## 🤝 Support

- 📧 [support@trustpin.cloud](mailto:support@trustpin.cloud)
- 🌐 [https://trustpin.cloud](https://trustpin.cloud)
- 📋 [GitHub Issues](https://github.com/trustpin-cloud/swift.sdk/issues)

---

*Built with ❤️ by the TrustPin team*
