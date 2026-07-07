# TrustPin iOS SDK

[![Swift](https://img.shields.io/badge/Swift-6-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-15.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-TrustPin-green.svg)](LICENSE)

[TrustPin](https://trustpin.cloud/) is a modern, lightweight, and secure iOS/macOS library that enforces **SSL Certificate Pinning** in native applications. Built with Swift Concurrency and following OWASP recommendations, it prevents man-in-the-middle (MITM) attacks by validating server authenticity at the TLS level.

## 🚀 Key Features

- ✅ **Modern Swift Concurrency** — `async`/`await` throughout
- ✅ **Flexible pinning modes** — strict for production, permissive for development
- ✅ **Multiple hash algorithms** — SHA-256 and SHA-512 certificate validation
- ✅ **Signed configuration** — cryptographically signed pinning payloads
- ✅ **Integration choices** — `URLSessionDelegate`, system-wide `URLProtocol`, Alamofire adapter, or static helpers
- ✅ **Intelligent caching** — a transient network hiccup never strands the app
- ✅ **Configurable, pluggable logging** — verbosity levels plus a custom log sink hook
- ✅ **Validation telemetry** — observe pin-validation verdicts for security monitoring
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
- [Monitoring Pin Validation](#-monitoring-pin-validation)
- [Best Practices](#-best-practices)
- [API Reference](#-api-reference)
- [Troubleshooting](#-troubleshooting)
- [Documentation, License & Support](#-documentation)

---

## 📋 Platform Requirements

| Platform     | Minimum Version |
|--------------|-----------------|
| iOS          | 15.0+           |
| macOS        | 13.0+           |
| watchOS      | 8.0+            |
| tvOS         | 15.0+           |
| Mac Catalyst | 15.0+           |
| visionOS     | 2.0+            |

Built with Swift 6 (strict concurrency); the public API is async/await throughout.

---

## 📦 Installation

### Swift Package Manager (recommended)

In Xcode: **File → Add Package Dependencies**, then enter:

```
https://github.com/trustpin-cloud/swift.sdk
```

Select version `6.1.0` or later.

The package vends two products:

| Product | What it is |
|---------|------------|
| `TrustPinKit` | The SDK (binary framework) — all you need for `URLSession`-based apps |
| `TrustPinKitAlamofire` | Optional [Alamofire](https://github.com/Alamofire/Alamofire) adapter — add it only if your app networks through Alamofire |

#### Manual `Package.swift`

```swift
dependencies: [
    .package(url: "https://github.com/trustpin-cloud/swift.sdk", from: "6.1.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "TrustPinKit", package: "swift.sdk"),
            // Only when using Alamofire:
            .product(name: "TrustPinKitAlamofire", package: "swift.sdk")
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

> The `TrustPinKitAlamofire` adapter is distributed via Swift Package Manager
> only.

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
> ⚠️ Call `TrustPin.setup(_:)` **once** during your app's lifecycle. Setup is one-shot: a second call after success throws `TrustPinErrors.alreadyInitialized`, and concurrent setup calls throw `TrustPinErrors.invalidProjectConfig`.

`setup` performs **local validation only** — it checks your credentials, stores them, and starts a *background* fetch of the pinning configuration. It never blocks app launch on the network.

### Recommended fail-closed pattern

If your app must not start networking without a validated pinning payload, gate on `awaitConfiguration(timeout:)` and treat any error as a hard stop:

```swift
do {
    try await TrustPin.setup(config)                    // local validation only
    try await TrustPin.awaitConfiguration(timeout: 10)  // fail-closed gate: fetch + signature + integrity
} catch {
    return showRetryUI(error)                            // do NOT fall through to unpinned networking
}

let session = URLSession(
    configuration: .default,
    delegate: TrustPin.makeURLSessionDelegate(),
    delegateQueue: nil
)
```

Apps that prefer zero launch latency can skip the gate — `verify` is fail-closed and refuses connections whenever the configuration cannot be fetched and validated. To check payload state synchronously (without triggering a fetch), read `await TrustPin.isConfigurationLoaded`.

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
| **Alamofire adapter** | Apps networking through Alamofire | Specific Alamofire `Session` instances |
| **Static helpers** | Explicit per-request pinning | Individual requests |

### URLSessionDelegate (default & recommended)
- Precise control — only specific `URLSession` instances are pinned
- No global state changes
- Mixes pinned and non-pinned sessions in the same app
- Already have your own session delegate? Compose them with
  `TrustPin.makeURLSessionDelegate(forwardingTo:)` — pinning answers
  server-trust challenges, everything else reaches your delegate

### Alamofire adapter (`TrustPinKitAlamofire`)
- One-line wiring into Alamofire's `ServerTrustManager`
- Pair with App Transport Security: plain `http://` requests never perform a
  TLS handshake and are never pin-validated

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

### Alamofire

```swift
import Alamofire
import TrustPinKit
import TrustPinKitAlamofire

// After TrustPin.setup(...):
let session = Session(serverTrustManager: ServerTrustManager(evaluators: [
    "api.example.com": TrustPinServerTrustEvaluating()
]))

// Named instances and a custom per-evaluation timeout are supported:
let pinned = TrustPinServerTrustEvaluating(instance: try TrustPin.instance(id: "payments"),
                                           timeout: 15)
```

The evaluator blocks Alamofire's session delegate queue while verification
runs (bounded by `timeout`). The first handshake after launch may include the
pinning-configuration fetch inside that window — call
`try await TrustPin.awaitConfiguration()` once at startup to keep handshakes
fast.

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

By default, log output goes to unified logging (`os.Logger`, subsystem
`cloud.trustpin.swift`, category = instance id). To route messages into your
own logging pipeline instead, install a global `TrustPinLogSink`. One sink
serves all instances and receives every message after per-instance level
filtering, tagged with the producing instance id:

```swift
TrustPin.setLogSink(TrustPinClosureLogSink { level, instanceId, message in
    myLogger.log("[\(instanceId)] \(message)")
})

TrustPin.setLogSink(nil)   // restore the default sink
```

Sinks are called synchronously from SDK internals, including TLS-handshake
paths: keep them fast and non-blocking, don't perform I/O inline, and never
call back into TrustPin from a sink.

---

## 📡 Monitoring Pin Validation

To feed pin-validation verdicts into your security monitoring — for example,
reporting suspected MITM attempts to your backend — install a global
`TrustPinValidationListener`:

```swift
final class SecurityMonitor: TrustPinValidationListener {
    func onValidationFailure(instanceId: String, domain: String,
                             error: TrustPinErrors, presentedCertificate: Data) {
        // Fires only for definitive verdicts: .pinsMismatch, .allPinsExpired,
        // .domainNotRegistered. `presentedCertificate` is the DER-encoded leaf
        // as received from the network — treat it as untrusted input.
    }

    func onValidationSuccess(instanceId: String, domain: String) {
        // Optional — default implementation does nothing.
    }
}

TrustPin.setValidationListener(SecurityMonitor())   // pass nil to detach
```

The listener is **observe-only**: it is invoked strictly after the verdict is
decided and cannot veto, approve, or alter a connection. Transient conditions
(configuration fetch failures, timeouts) and permissive-mode connections to
unregistered domains produce no callbacks. Like log sinks, listeners are
called synchronously from TLS-handshake paths — keep them non-blocking and
never call back into TrustPin.

---

## 🏗 Best Practices

### Security
- Always use `.strict` mode in production.
- Rotate pins before expiration; monitor pin-validation failures.
- Use HTTPS for all pinned domains.

### Setup
- Call `TrustPin.setup()` exactly once at app launch.
- Treat setup errors as hard stops — don't construct an unpinned `URLSession` on the failure path.
- Gate on `awaitConfiguration(timeout:)` before constructing pinned sessions when your app must not run without a validated payload.

### Development workflow
- Start in `.permissive` mode during development, then switch to `.strict` for production.
- Use `.debug` log level when troubleshooting; revert to `.error` or `.none` for release builds.

---

## 📚 API Reference

### Core types

- **`TrustPin`** — main SDK interface; default singleton + named multi-instances
- **`TrustPinConfiguration`** — value type grouping all setup options; supports `fromPlist(_:fileName:)`
- **`TrustPinMode`** — pinning behaviour (`.strict`, `.permissive`)
- **`TrustPinURLProtocol`** — `URLProtocol` for system-wide pinning
- **`TrustPinErrors`** — error cases (see [Error Handling](#-error-handling))
- **`TrustPinLogLevel`** — logging verbosity (`.none`, `.error`, `.info`, `.debug`)
- **`TrustPinLogSink`** / **`TrustPinClosureLogSink`** — pluggable log transport (see [Logging](#-logging))
- **`TrustPinValidationListener`** — observe-only validation telemetry hook (see [Monitoring Pin Validation](#-monitoring-pin-validation))
- **`TrustPinServerTrustEvaluating`** *(TrustPinKitAlamofire)* — Alamofire `ServerTrustEvaluating` adapter

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

// Waits for the configuration to be fetched, signature-verified, and accepted
// by the integrity check. `timeout` is in seconds, default 30, clamped to [10, 120].
func awaitConfiguration(timeout: TimeInterval = 30) async throws
static func awaitConfiguration(timeout: TimeInterval = 30) async throws

// Synchronous payload-state read — never triggers a fetch.
var isConfigurationLoaded: Bool { get async }
static var isConfigurationLoaded: Bool { get async }

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

// Composes pinning with an existing app delegate: server-trust challenges get
// the pinning verdict, every other callback reaches `delegate` unchanged.
func makeURLSessionDelegate(forwardingTo delegate: any URLSessionDelegate) -> any URLSessionDelegate
static func makeURLSessionDelegate(forwardingTo delegate: any URLSessionDelegate) -> any URLSessionDelegate

static func registerURLProtocol()
static func unregisterURLProtocol()

// ── Logging ───────────────────────────────────────────────────────────────

func set(logLevel: TrustPinLogLevel)
static func set(logLevel: TrustPinLogLevel)

// Global log sink; one sink serves all instances. Pass nil to restore the
// default sink (unified logging).
static func setLogSink(_ sink: TrustPinLogSink?)

// ── Validation telemetry ──────────────────────────────────────────────────

// Global observe-only listener for pin-validation verdicts; nil detaches.
static func setValidationListener(_ listener: TrustPinValidationListener?)
```

### `TrustPinURLProtocol` helpers

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
