import SwiftUI

struct ContentView: View {
    let container: AppContainer

    var body: some View {
        TabView {
            PinningTab(container: container)
                .tabItem { Label("Pinning", systemImage: "lock.shield") }

            AttestationTab(container: container)
                .tabItem { Label("Attestation", systemImage: "checkmark.seal") }
        }
    }
}

/// First tab: pinning configuration, connection tests and the pinning log
/// (TrustPinKit lines and the sample's pinning actions).
struct PinningTab: View {
    let container: AppContainer

    var body: some View {
        SampleNavigation {
            ScrollView {
                VStack(spacing: 16) {
                    StatusHeader(
                        session: container.session,
                        viewModel: container.connectionTestingViewModel
                    )

                    ConfigurationView(
                        viewModel: container.configurationViewModel,
                        session: container.session
                    )

                    ConnectionTestingView(
                        viewModel: container.connectionTestingViewModel
                    )

                    LogOutputView(viewModel: container.pinningLogsViewModel, title: "Pinning Log")
                }
                .padding()
            }
            .navigationTitle("Pinning")
            .sampleTitleDisplayMode()
        }
    }
}

/// Second tab: attestation and its own log (TrustPinAttest lines, state
/// transitions and the protected calls).
struct AttestationTab: View {
    let container: AppContainer

    var body: some View {
        SampleNavigation {
            ScrollView {
                VStack(spacing: 16) {
                    StatusHeader(
                        session: container.session,
                        viewModel: container.connectionTestingViewModel
                    )

                    AttestationView(
                        viewModel: container.attestationViewModel,
                        session: container.session
                    )

                    LogOutputView(viewModel: container.attestationLogsViewModel, title: "Attestation Log")
                }
                .padding()
            }
            .navigationTitle("Attestation")
            .sampleTitleDisplayMode()
        }
    }
}

/// Top-level status banner. Mirrors the Android sample's `tvStatus` row that
/// sits above the action buttons so the user can see the SDK state at a glance
/// without scrolling to the connection-testing card.
struct StatusHeader: View {
    @ObservedObject var session: PinningSession
    @ObservedObject var viewModel: ConnectionTestingViewModel

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(session.isConfigured ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            Text("Status: \(viewModel.statusMessage)")
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(session.isConfigured ? Color.green.opacity(0.12) : Color.red.opacity(0.12))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(session.isConfigured ? Color.green.opacity(0.4) : Color.red.opacity(0.4), lineWidth: 1)
        )
    }
}
