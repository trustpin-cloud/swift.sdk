import Foundation

/// Composition root: wires Data implementations into Domain use cases and
/// hands fully-built view models to the Presentation layer.
@MainActor
final class AppContainer: ObservableObject {
    let session: PinningSession
    let configurationViewModel: ConfigurationViewModel
    let connectionTestingViewModel: ConnectionTestingViewModel
    let logsViewModel: LogsViewModel

    init() {
        let logRepository: LogRepository = InMemoryLogRepository()
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
        self.logsViewModel = LogsViewModel(logRepository: logRepository)

        // Match the Android sample's startup banner: confirm the app launched
        // and that SDK info-level diagnostics will be visible in the feed below.
        logRepository.append("📱 TrustPin iOS Sample started", level: .info)
        logRepository.append("🔧 TrustPin configured for info logging", level: .info)
    }
}
