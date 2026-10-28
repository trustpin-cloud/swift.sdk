import Foundation
import TrustPinAttestKit
import TrustPinKit

/// Composition root: wires Data implementations into Domain use cases and
/// hands fully-built view models to the Presentation layer.
@MainActor
final class AppContainer: ObservableObject {
    let session: PinningSession
    let configurationViewModel: ConfigurationViewModel
    let connectionTestingViewModel: ConnectionTestingViewModel
    let pinningLogsViewModel: LogsViewModel
    let attestationViewModel: AttestationViewModel
    let attestationLogsViewModel: LogsViewModel

    init() {
        // One log per tab: pinning events and attestation events never mix.
        let logRepository: LogRepository = InMemoryLogRepository()
        let attestationLogRepository: LogRepository = InMemoryLogRepository()
        let configurationRepository: PinningRepository = TrustPinConfigurationRepository()
        let networkRepository: PinnedNetworkRepository = TrustPinNetworkRepository()
        let certificateRepository: CertificateRepository = TrustPinCertificateRepository()

        let configurePinning = ConfigurePinningUseCase(
            pinningRepository: configurationRepository,
            logRepository: logRepository
        )
        let configureFromBundle = ConfigureFromBundleUseCase(
            pinningRepository: configurationRepository,
            logRepository: logRepository
        )
        let testConnection = TestPinnedConnectionUseCase(
            networkRepository: networkRepository,
            logRepository: logRepository
        )
        let fetchCertificate = FetchCertificateUseCase(
            certificateRepository: certificateRepository,
            logRepository: logRepository
        )
        let clearLogs = ClearLogsUseCase(logRepository: logRepository)
        let attestationRepository: AttestationRepository = TrustPinAttestRepository()
        let setUpAttestation = SetUpAttestationUseCase(
            attestationRepository: attestationRepository,
            logRepository: attestationLogRepository
        )
        let fetchAttestedResource = FetchAttestedResourceUseCase(
            attestationRepository: attestationRepository,
            logRepository: attestationLogRepository
        )
        let resetAttestation = ResetAttestationUseCase(
            attestationRepository: attestationRepository,
            logRepository: attestationLogRepository
        )
        let signOutSession = SignOutSessionUseCase(
            attestationRepository: attestationRepository,
            logRepository: attestationLogRepository
        )
        // Each framework logs into its own tab's log (and the console).
        let sdkLogForwarder = SDKLogForwarder(pinningLog: logRepository, attestationLog: attestationLogRepository)
        TrustPin.setLogSink(sdkLogForwarder)
        TrustPinAttest.setLogSink(sdkLogForwarder)

        let session = PinningSession()
        self.session = session
        self.configurationViewModel = ConfigurationViewModel(
            configurePinning: configurePinning,
            configureFromBundle: configureFromBundle,
            session: session
        )
        self.connectionTestingViewModel = ConnectionTestingViewModel(
            testConnection: testConnection,
            fetchCertificate: fetchCertificate,
            clearLogs: clearLogs,
            logRepository: logRepository,
            session: session
        )
        self.pinningLogsViewModel = LogsViewModel(logRepository: logRepository)
        self.attestationLogsViewModel = LogsViewModel(logRepository: attestationLogRepository)
        self.attestationViewModel = AttestationViewModel(
            setUpAttestation: setUpAttestation,
            fetchAttestedResource: fetchAttestedResource,
            resetAttestation: resetAttestation,
            signOutSession: signOutSession,
            attestationRepository: attestationRepository,
            logRepository: attestationLogRepository,
            session: session
        )

        // Match the Android sample's startup banner: confirm the app launched
        // and that SDK info-level diagnostics will be visible in the feed below.
        logRepository.append("📱 TrustPin iOS Sample started", level: .info)
        logRepository.append("🔧 TrustPin configured for info logging", level: .info)
        attestationLogRepository.append("🛡 Attestation log: TrustPinAttest events and protected calls", level: .info)
        attestationLogRepository.append("ℹ️ Configure pinning in the Pinning tab first; verifier calls are pinned by it", level: .info)
    }
}
