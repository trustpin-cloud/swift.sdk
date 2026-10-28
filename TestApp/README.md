# TestApp - TrustPinKit and TrustPinAttestKit Example

This is a sample iOS app demonstrating how to use TrustPinKit (certificate pinning) and TrustPinAttestKit (app attestation) in a SwiftUI application.

## Prerequisites

This TestApp uses [Tuist](https://tuist.io) for project generation. Install Tuist first:

```bash
# Install Tuist
curl -Ls https://install.tuist.io | bash

# Or using Homebrew
brew install tuist
```

## Running the Example

### Using Tuist (Recommended)

1. **Navigate to the TestApp directory**:
   ```bash
   cd TestApp
   ```

2. **Generate the Xcode project**:
   ```bash
   tuist generate
   ```

3. **Open the generated project**:
   ```bash
   tuist generate --open
   ```

4. **Run the app** on simulator or device using Xcode

## Integration Example

The TestApp shows how to:

1. **Setup TrustPinKit** in your app
2. **Configure certificate pinning** for your API endpoints  
3. **Handle URLSession** with automatic certificate validation
4. **Implement proper error handling** for pinning failures

## Configuration

The published sample ships without credentials. Add a `TrustPin-Info.plist`
to `Sources/` (and list it under `resources` in `Project.swift`) with your
project's values, or enter them on the Configuration card:

| Key | Purpose |
| --- | --- |
| `OrganizationId`, `ProjectId`, `PublicKey`, `Mode` | certificate pinning (`TrustPin.setup(.fromPlist())`) |
| `AttestVerifierURL`, `AttestedHosts` | app attestation (`TrustPinAttest.setup(.fromPlist())`); the verifier host must be one of your pinned domains |

The attestation card needs an App ID with the App Attest capability (the
`Sources/TestApp.entitlements` file requests the development environment) and
a backend that verifies the `TrustPin-Attestation` header. For the protected
call, add an `api-test.plist` to `Sources/` with the keys `APIBaseURL`,
`Username` and `Password` of your test API, and list it under `resources` in
`Project.swift`; the published copy ships without one. Simulators cannot run App Attest; set
`TRUSTPIN_DEBUG_TOKEN` in the scheme if your verifier issues debug tokens.

## Code Structure

- `Sources/App/` - App entry point, dependency container, root view
- `Sources/Domain/` - Entities, repository protocols and use cases
- `Sources/Data/` - Repositories over TrustPinKit and TrustPinAttestKit, SDK log forwarding
- `Sources/Presentation/` - Configuration, connection testing, attestation and log cards
- `Sources/Assets.xcassets` - App icons and colors
- `Sources/LaunchScreen.storyboard` - Launch screen
- `Sources/TestApp.entitlements` - App Attest entitlement
- `Project.swift` - Tuist project configuration
- `Tuist.swift` - Tuist configuration

## Key Features Demonstrated

- ✅ TrustPin initialization with organization credentials
- ✅ URLSession integration with TrustPinURLSessionDelegate
- ✅ Error handling for certificate pinning failures
- ✅ Network request examples with automatic validation
- ✅ SwiftUI integration patterns
- ✅ Proper iOS app structure with Tuist
- ✅ App attestation with TrustPinAttestKit: setup, token binding to the session,
  the `TrustPin-Attestation` header on a protected call, reset

## Development

### Installing Tuist

Install Tuist to manage the project dependencies and generate Xcode projects:

```bash
# Install Tuist
curl -Ls https://install.tuist.io | bash

# Or using Homebrew
brew install tuist
```

For more information, visit: [tuist.io](https://tuist.io)

### Creating the Xcode Project

Once Tuist is installed, generate the Xcode project:

```bash
# Clean generated files
tuist clean

# Install dependencies
tuist install

# Generate Xcode project
tuist generate
```

## Learn More

- [Tuist Documentation](https://docs.tuist.io)
- [TrustPinKit Documentation](../README.md)