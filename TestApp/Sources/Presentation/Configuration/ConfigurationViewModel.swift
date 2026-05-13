import Foundation

@MainActor
final class ConfigurationViewModel: ObservableObject {
    @Published var organizationId: String
    @Published var projectId: String
    @Published var publicKey: String
    @Published var mode: PinningMode
    @Published var showModeAlert = false

    private let configurePinning: ConfigurePinningUseCase
    private let configureFromBundle: ConfigureFromBundleUseCase
    private let session: PinningSession

    init(
        configurePinning: ConfigurePinningUseCase,
        configureFromBundle: ConfigureFromBundleUseCase,
        session: PinningSession,
        initialConfiguration: PinningConfiguration = .empty
    ) {
        // The published `swift.sdk` sample ships with blank credentials — both the
        // literals on `PinningConfiguration.empty` and the test URL elsewhere are
        // stripped at release time by the `trustpin:sample-credential` sed step in
        // `.github/workflows/deploy-version.yml`. End users paste their own
        // credentials from https://app.trustpin.cloud before tapping "Setup TrustPin".
        self.organizationId = initialConfiguration.organizationId
        self.projectId = initialConfiguration.projectId
        self.publicKey = initialConfiguration.publicKey
        self.mode = initialConfiguration.mode
        self.configurePinning = configurePinning
        self.configureFromBundle = configureFromBundle
        self.session = session
    }

    func setup() {
        let configuration = PinningConfiguration(
            organizationId: organizationId,
            projectId: projectId,
            publicKey: publicKey,
            mode: mode
        )

        Task { @MainActor in
            do {
                try await configurePinning(configuration)
                session.markConfigured()
            } catch {
                session.markUnconfigured()
            }
        }
    }

    func setupFromBundle() {
        Task { @MainActor in
            do {
                let loaded = try await configureFromBundle()
                // Reflect what the plist actually loaded so the form mirrors the
                // SDK's live state instead of whatever the user had typed before.
                organizationId = loaded.organizationId
                projectId = loaded.projectId
                publicKey = loaded.publicKey
                mode = loaded.mode
                session.markConfigured()
            } catch {
                session.markUnconfigured()
            }
        }
    }

    func toggleModeAlert() {
        showModeAlert = true
    }
}
