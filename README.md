# TrustPin Swift SDK

[![Swift](https://img.shields.io/badge/Swift-6-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-blue.svg)](#-platform-requirements)
[![License](https://img.shields.io/badge/License-TrustPin-green.svg)](LICENSE)

[TrustPin](https://trustpin.cloud/) is a modern, lightweight, and secure library for Apple platforms that enforces **SSL Certificate Pinning** in native applications. Built with Swift Concurrency and following OWASP recommendations, it prevents man-in-the-middle (MITM) attacks by validating server authenticity at the TLS level. The optional **TrustPinAttestKit** framework adds app attestation: it proves to your backend that requests come from your genuine app on a genuine Apple device.

## 🚀 Key Features

- ✅ **Modern Swift Concurrency** — `async`/`await` throughout
- ✅ **Flexible pinning modes** — strict for production, permissive for development
- ✅ **Multiple hash algorithms** — SHA-256 and SHA-512 certificate validation
- ✅ **Signed configuration** — cryptographically signed pinning payloads
- ✅ **Integration choices** — `URLSessionDelegate`, system-wide `URLProtocol`, Alamofire adapter, or static helpers
- ✅ **Intelligent caching** — a transient network hiccup never strands the app
- ✅ **Configurable, pluggable logging** — verbosity levels plus a custom log sink hook
- ✅ **Validation telemetry** — observe pin-validation verdicts for security monitoring
- ✅ **Attestation headers hook** — a registered provider's headers ride along on HTTPS requests through the URLProtocol and Alamofire integrations
- ✅ **App attestation** — `TrustPinAttestKit` proves app and device provenance with App Attest and adds the token to your requests
- ✅ **Cross-platform** — iOS, macOS, watchOS, tvOS, Mac Catalyst, visionOS

---

## 📑 Table of Contents

- [Platform Requirements](#-platform-requirements)
- [Installation](#-installation)
- [Quick Setup](#-quick-setup)
- [Setup via `TrustPin-Info.plist`](#-setup-via-trustpin-infoplist-ios)
- [Embedded configuration](#-embedded-configuration)
- [Integration Approaches](#-integration-approaches)
- [Usage Examples](#-usage-examples)
- [App attestation (TrustPinAttestKit)](#-app-attestation-trustpinattestkit)
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
| watchOS      | 9.0+            |
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

Select version `7.0.1` or later.

The package vends three products:

| Product | What it is |
|---------|------------|
| `TrustPinKit` | The SDK (binary framework) — all you need for `URLSession`-based apps |
| `TrustPinKitAlamofire` | Optional [Alamofire](https://github.com/Alamofire/Alamofire) adapter — add it only if your app networks through Alamofire; requires Alamofire 5.10 or later |
| `TrustPinAttestKit` | Optional app attestation (binary framework) — add it only if your backend verifies attestation tokens; brings `TrustPinKit` with it |

#### Manual `Package.swift`

```swift
dependencies: [
    .package(url: "https://github.com/trustpin-cloud/swift.sdk", from: "7.0.1")
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

To add app attestation, also add the `TrustPinAttestKit` product (it brings
`TrustPinKit` with it):

```swift
.product(name: "TrustPinAttestKit", package: "swift.sdk")
```

### CocoaPods

```ruby
pod 'TrustPinKit'
# Optional, for app attestation (depends on TrustPinKit at the same version):
pod 'TrustPinAttestKit'
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
| `ConfigurationURL` | ❌        | String | Must be HTTPS and point at a public host; loopback and private addresses are rejected |
| `EmbeddedConfigurationFile` | ❌ | String | Resource filename of the bundled signed configuration (see [Embedded configuration](#-embedded-configuration)) |

Unknown top-level keys are ignored, so adding fields ahead of an SDK update is safe.
The attestation keys `AttestVerifierURL` and `AttestedHosts` live in the same file; see [App attestation](#-app-attestation-trustpinattest).

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

## 🧷 Embedded configuration

TrustPin fetches its signed pinning configuration online and keeps the last validated one on the device. For the one case where neither exists — an app's **very first start while every configuration source is unreachable** — you can ship a signed configuration inside the app bundle as a last-resort fallback.

```swift
let seed = Bundle.main.url(forResource: "trustpin-seed", withExtension: "b64")
try await TrustPin.setup(TrustPinConfiguration(
    organizationId: "your-org-id",
    projectId:      "your-project-id",
    publicKey:      "your-base64-public-key",
    embeddedConfigurationURL: seed
))
```

Or, with `TrustPin-Info.plist`, add `EmbeddedConfigurationFile` with the resource filename.

**Requirements**

- **Use it only in apps protected by RASP** (runtime application self-protection) that guards bundled resources against modification. An unprotected app must not ship an embedded configuration.
- **The file must be the unmodified signed payload** downloaded from the TrustPin dashboard for this project. It is verified against `publicKey` at `setup`; `setup` throws `invalidProjectConfig` if the file is not a bundled resource, cannot be read, or does not verify.
- **Regenerate it in your CI pipeline on every release**, so it is never older than the app that ships it. Pins expire on their own schedule — an embedded configuration whose pins have all expired is equivalent to having no fallback.

**Behaviour**

- It is never preferred over an online source or over a configuration the SDK has already fetched and validated.
- It is subject to the same integrity checks as any other configuration: a device that has already trusted a newer configuration will not accept an older embedded one.
- The Android SDK exposes the equivalent option; the file format is identical.

**Trying it with the sample app.** `Sample/TestApp` ships an empty `TrustPin-Seed.b64` resource and passes it to the SDK whenever it has content. Paste the signed payload for your project into that file, put the device in airplane mode, launch the app fresh (or reinstall so no earlier configuration is retained) and tap *Setup* — the log shows the configuration being served from the embedded file, and pinned requests to your domains still verify.

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
- Requires Alamofire 5.10 or later.
- One-line wiring into Alamofire's `ServerTrustManager`
- `TrustPinAttestationAdapter` adds the headers a registered attestation provider supplies
- Pair with App Transport Security: plain `http://` requests never perform a
  TLS handshake and are never pin-validated

### System-wide URLProtocol
- Automatically secures every `URLSession` request, including `URLSession.shared`
- Protects third-party libraries layered over `URLSession`
- Adds the headers a registered attestation provider supplies (default instance)
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

To add attestation headers to Alamofire requests, install
`TrustPinAttestationAdapter` as a request adapter; it adds the headers the
instance's attestation provider supplies and never fails a request:

```swift
let session = Session(
    interceptor: Interceptor(adapters: [TrustPinAttestationAdapter()]),
    serverTrustManager: ServerTrustManager(evaluators: [
        "api.example.com": TrustPinServerTrustEvaluating()
    ]),
    redirectHandler: TrustPinAttestationRedirectHandler()  // headers re-requested on redirects
)
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

### Attestation headers

When an attestation provider is registered on the default instance, the
URLProtocol adds the headers it supplies to every HTTPS request before
sending it. The TrustPinAttestKit framework registers itself when it is set up;
you can also register your own provider:

```swift
TrustPin.setAttestationProvider(myProvider)   // any TrustPinAttestationProvider
TrustPin.setAttestationProvider(nil)          // stop adding headers
```

Headers the request already carries are kept, a provider that does not answer
in time is skipped for that request, and a provider can never affect pinning.
Attestation headers never follow a redirect unchecked: on a redirect, the
URLProtocol, TrustPin's session delegates and the Alamofire redirect handler
remove them and ask the provider again for the new destination. A provider
declares the headers it owns in `headerNames`; a header it returns without
declaring it is ignored. If your session uses neither
TrustPin's delegate nor the URLProtocol, do the same in your own redirect
callback:

```swift
func urlSession(_ session: URLSession, task: URLSessionTask,
                willPerformHTTPRedirection response: HTTPURLResponse,
                newRequest: URLRequest,
                completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
    Task { completionHandler(await TrustPin.redirectedRequest(newRequest)) }
}
```
For requests sent through your own `URLSession` (a pinning delegate, not the
URLProtocol), ask for the headers yourself, or use
`TrustPinAttest.addingAttestation(to:)` when TrustPinAttest is set up:

```swift
var request = URLRequest(url: url)
for (name, value) in await TrustPin.attestationHeaders(for: request) {
    request.setValue(value, forHTTPHeaderField: name)
}
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

## 🛡 App attestation (TrustPinAttestKit)

`TrustPinAttestKit` proves to your backend that requests come from your genuine
app on a genuine Apple device, using Apple's App Attest and the verifier you
run. It ships as a second framework next to `TrustPinKit` (SwiftPM product
`TrustPinAttestKit`, CocoaPods `TrustPinAttestKit`) and is released at the same
version. Import `TrustPinAttestKit`; its API lives on the `TrustPinAttest`
type.

### Configuration

Add two keys to the same `TrustPin-Info.plist` that holds your pinning
configuration:

| Key | Required | Type | Notes |
| --- | --- | --- | --- |
| `AttestVerifierURL` | ✅ | String | HTTPS base URL of your attestation verifier, without the version segment (`https://api.example.com/attest`) |
| `AttestedHosts` | ✅ | Array of String | Hosts that receive the `TrustPin-Attestation` header; `*.example.com` covers one label. IP addresses are not accepted |

Register the verifier's domain in your TrustPin project: calls to the
verifier are pinned by the `TrustPin` instance with the same identifier, and
in strict mode an unregistered verifier host is never reached. The app needs
the App Attest entitlement (`com.apple.developer.devicecheck.appattest-environment`).

### Setup

Set up pinning first, then attestation:

```swift
import TrustPinKit
import TrustPinAttestKit

try await TrustPin.setup(.fromPlist())
try await TrustPinAttest.setup(.fromPlist())
TrustPinAttest.bindToHeader("Authorization")   // bind tokens to the session
TrustPinAttest.prefetch()                       // so the first request does not wait
```

### Where the header comes from

- **Automatically** on requests to the configured hosts that go through
  `TrustPinURLProtocol` (default instance) or an Alamofire session using
  `TrustPinAttestationAdapter`.
- **Your own `URLSession`** (a pinning delegate cannot change headers):

  ```swift
  let request = await TrustPinAttest.addingAttestation(to: URLRequest(url: url))
  ```

- **Other clients** (gRPC, WebSockets): `try await TrustPinAttest.getToken()`.

The SDK never blocks or fails your requests. When no token is available the
request is sent without the header and your backend decides how to treat it.

### Binding

`setTokenBinding(_:)` binds every token to a value of your choice;
`bindToHeader("Authorization")` binds each request's token to that header's
value on the request. The value never leaves the device. A change of binding
renews the token.

`prefetch()` with `bindToHeader(_:)` attests early but cannot bind (there is no
request yet): the first bound request renews the token once more, cheaply. If
your verifier requires a binding, nothing can be prefetched until one is
known; use `setTokenBinding(_:)` with the session value before `prefetch()`.
With header binding, `getToken()` returns a token bound to the most recent request
this instance saw; use `setTokenBinding(_:)` for clients that send no such
request. `setTokenBinding(nil)` removes the fixed binding only.

### State and logging

`TrustPinAttest.state` is `unavailable`, `attesting`, `ready(expiresAt:)` or
`failed(_, retryAt:)`; `setStateListener(_:)` observes changes. Like every
TrustPin enum, `TrustPinAttestState` and `TrustPinAttestError` may gain cases
in a minor release: switch over them with `@unknown default`.
`TrustPinAttest.set(logLevel:)` and `TrustPinAttest.setLogSink(_:)` control the
framework's own logging, off by default.
`TrustPinAttest.setLogSink(TrustPinAttestClosureLogSink { level, instanceId, message in … })`
routes the attestation framework's log to your pipeline; pass `nil` to restore
the default sink. `await TrustPinAttest.reset()` discards the attested key
so the next request attests a new one.

### Simulators

Simulators cannot run App Attest. For development, your verifier's operator
can issue a debug token; set it as `TRUSTPIN_DEBUG_TOKEN` in the Xcode scheme's
environment (never in the app bundle). On devices without App Attest the
state is `failed(.unsupportedDevice, …)` and no header is sent.

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

Logging is **off by default** (`.none`). Set a level before `setup` for complete
logging coverage. Use `.error` or `.none` in production.

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

// Embedded (last-resort) configuration — see "Embedded configuration" above.
TrustPinConfiguration(organizationId:projectId:publicKey:mode:configurationURL:
                      embeddedConfigurationURL: URL?)

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

// ── Attestation ───────────────────────────────────────────────────────────

// Headers a registered provider supplies are added to HTTPS requests sent
// through the URLProtocol (default instance) and the Alamofire adapter.
// Nothing changes until a provider is registered; nil removes it.
func setAttestationProvider(_ provider: (any TrustPinAttestationProvider)?)
static func setAttestationProvider(_ provider: (any TrustPinAttestationProvider)?)

// The provider's headers for a request, for sessions you build yourself.
// Empty when no provider is set, the request is not HTTPS, or the provider
// does not answer in time.
func attestationHeaders(for request: URLRequest) async -> [String: String]
static func attestationHeaders(for request: URLRequest) async -> [String: String]
func redirectedRequest(_ request: URLRequest) async -> URLRequest
static func redirectedRequest(_ request: URLRequest) async -> URLRequest

protocol TrustPinAttestationProvider: Sendable {
    var headerNames: Set<String> { get }
    func attestationHeaders(for request: URLRequest) async -> [String: String]
}

// TrustPinKitAlamofire
struct TrustPinAttestationAdapter: RequestAdapter { init(instance: TrustPin = .default) }
struct TrustPinAttestationRedirectHandler: RedirectHandler { init(instance: TrustPin = .default) }

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

### `TrustPinAttest`

```swift
// Instances pair with the TrustPin instance of the same id.
static let `default`: TrustPinAttest
static func instance(id: String) throws -> TrustPinAttest
static let headerName: String                       // "TrustPin-Attestation"

func setup(_ configuration: TrustPinAttestConfiguration) async throws
func prefetch()
func getToken() async throws -> String
func addingAttestation(to request: URLRequest) async -> URLRequest
func attestationHeaders(for request: URLRequest) async -> [String: String]
func setTokenBinding(_ value: String?)
func bindToHeader(_ name: String?)
var state: TrustPinAttestState { get }
func setStateListener(_ listener: (@Sendable (TrustPinAttestState) -> Void)?)
func reset() async
func set(logLevel: TrustPinAttestLogLevel)
// Every call above also exists as a static convenience on `default`.
static func setLogSink(_ sink: (any TrustPinAttestLogSink)?)
struct TrustPinAttestClosureLogSink: TrustPinAttestLogSink {
    init(_ handler: @escaping @Sendable (TrustPinAttestLogLevel, String, String) -> Void)
}

struct TrustPinAttestConfiguration {
    init(verifierURL: URL, attestedHosts: [String]) throws
    static func fromPlist(_ bundle: Bundle = .main, fileName: String = "TrustPin-Info.plist") throws -> TrustPinAttestConfiguration
}

enum TrustPinAttestState { case unavailable, attesting, ready(expiresAt: Date), failed(TrustPinAttestError, retryAt: Date) }
enum TrustPinAttestError { case invalidConfiguration, alreadyInitialized, notSetUp, unsupportedDevice,
                           evidenceUnavailable, bindingRequired, attestationFailed(reasons: [String]), verifierUnavailable }
// Both enums may gain cases in a minor release; switch with `@unknown default`.
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

### Attestation header missing (requests answered 401 by your backend)
- Read `TrustPinAttest.state`, or set `TrustPinAttest.set(logLevel: .debug)` and look at the log.
- `failed(.attestationFailed(reasons:), …)`: your verifier rejected the app. Check that its policy lists your team ID and bundle identifier and that the App Attest entitlement is on the App ID. `reasons` carries the verifier's codes, or one the framework supplies itself: `http_<status>` for an error response without a readable body, `invalid_key` or `invalid_input` for a local App Attest failure. After a refusal the framework waits before trying again, also across launches. Once the cause is fixed, `await TrustPinAttest.reset()` retries at once.
- `failed(.verifierUnavailable, …)` in strict mode: register the verifier's domain in your TrustPin project; an unregistered host is never reached.
- `failed(.bindingRequired, …)`: your verifier requires a binding; call `setTokenBinding(_:)` or `bindToHeader(_:)` before the first request.
- `failed(.unsupportedDevice, …)`: simulators, devices without App Attest, or devices where App Attest keeps rejecting new keys; use a debug token on simulators (see [Simulators](#simulators)).
- No header on a request that should carry one: the host must match `AttestedHosts`, and a session with a pinning delegate needs `addingAttestation(to:)`.

### Debug steps
1. Enable debug logging: `TrustPin.set(logLevel: .debug)` (and `TrustPinAttest.set(logLevel: .debug)`)
2. Test in `.permissive` mode first
3. Re-verify credentials in the dashboard
4. Check pin expiration dates

---

## 📖 Documentation

- **API documentation**: [TrustPinKit](https://docs.trustpin.cloud/sdk/swift) · [TrustPinAttestKit](https://docs.trustpin.cloud/sdk/swift)
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
