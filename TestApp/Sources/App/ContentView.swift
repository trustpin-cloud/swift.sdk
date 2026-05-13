import SwiftUI

struct ContentView: View {
    let container: AppContainer

    var body: some View {
        NavigationView {
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

                    LogOutputView(viewModel: container.logsViewModel)
                }
                .padding()
            }
            .navigationTitle("TrustPin Sample App")
            .navigationBarTitleDisplayMode(.automatic)
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
