import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ConfigurationView(
                        organizationId: $viewModel.organizationId,
                        projectId: $viewModel.projectId,
                        publicKey: $viewModel.publicKey,
                        currentMode: $viewModel.currentMode,
                        isConfigured: viewModel.isConfigured,
                        onSetup: viewModel.setupTrustPin,
                        onToggleMode: viewModel.toggleModeAlert
                    )
                    
                    ConnectionTestingView(
                        testURL: $viewModel.testURL,
                        isConfigured: viewModel.isConfigured,
                        isTesting: viewModel.isTesting,
                        statusMessage: viewModel.statusMessage,
                        onTest: viewModel.testConnection,
                        onFetchCertificate: viewModel.fetchCertificate,
                        onClearLog: viewModel.clearLog
                    )
                    
                    LogOutputView(logs: viewModel.logs)
                }
                .padding()
            }
            .alert("Change Pinning Mode", isPresented: $viewModel.showModeAlert) {
                Button("OK") { }
            } message: {
                Text("To change the pinning mode, modify the 'mode' parameter in the setupTrustPin() function code:\n\n• .strict for production (blocks unregistered domains)\n• .permissive for development (allows unregistered domains)")
            }
            .navigationTitle("TrustPin Sample App")
            .navigationBarTitleDisplayMode(.automatic)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    ContentView()
}
