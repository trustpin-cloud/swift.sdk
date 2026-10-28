import Combine
import Foundation

@MainActor
final class AttestationViewModel: ObservableObject {
    @Published private(set) var status: AttestationStatus = .notConfigured
    @Published private(set) var isBusy = false
    @Published private(set) var lastOutcome: AttestedCallOutcome?
    @Published private(set) var isConfigured = false

    private let setUpAttestation: SetUpAttestationUseCase
    private let fetchAttestedResource: FetchAttestedResourceUseCase
    private let resetAttestation: ResetAttestationUseCase
    private let signOutSession: SignOutSessionUseCase
    private let attestationRepository: AttestationRepository
    private let logRepository: LogRepository
    private let session: PinningSession

    init(
        setUpAttestation: SetUpAttestationUseCase,
        fetchAttestedResource: FetchAttestedResourceUseCase,
        resetAttestation: ResetAttestationUseCase,
        signOutSession: SignOutSessionUseCase,
        attestationRepository: AttestationRepository,
        logRepository: LogRepository,
        session: PinningSession
    ) {
        self.setUpAttestation = setUpAttestation
        self.fetchAttestedResource = fetchAttestedResource
        self.resetAttestation = resetAttestation
        self.signOutSession = signOutSession
        self.attestationRepository = attestationRepository
        self.logRepository = logRepository
        self.session = session

        // Every state transition goes to the on-screen log too, so the device
        // sign-off can be read without a console.
        attestationRepository.observeStatus { [weak self] status in
            Task { @MainActor [weak self] in
                guard let self, self.status != status else { return }
                self.status = status
                self.logRepository.append("🛡 Attestation state: \(status.label)", level: status.isReady ? .success : .info)
            }
        }
    }

    /// Pinning must be configured first: the verifier calls are pinned by it.
    var canSetUp: Bool { session.isConfigured && !isConfigured && !isBusy }
    var canCall: Bool { isConfigured && !isBusy }

    func setUp() {
        guard canSetUp else { return }
        isBusy = true
        Task { @MainActor in
            defer { isBusy = false }
            do {
                try await setUpAttestation()
                isConfigured = true
                status = attestationRepository.status
            } catch {
                status = .failed(reason: error.localizedDescription, retryAt: .distantFuture)
            }
        }
    }

    func callProtectedEndpoint() {
        guard canCall else { return }
        isBusy = true
        Task { @MainActor in
            defer { isBusy = false }
            lastOutcome = try? await fetchAttestedResource()
        }
    }

    func reset() {
        guard isConfigured, !isBusy else { return }
        isBusy = true
        Task { @MainActor in
            defer { isBusy = false }
            await resetAttestation()
            lastOutcome = nil
        }
    }

    /// Binding-change case of the device sign-off: a new session value on the
    /// next call makes the SDK renew the token for that binding.
    func signOut() {
        guard isConfigured else { return }
        signOutSession()
        lastOutcome = nil
    }
}
